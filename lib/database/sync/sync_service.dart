import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../app_database.dart';
import 'remote_row_applier.dart';

/// Push-then-pull incremental sync. Push = drain [SyncQueue] outbox (rows
/// written there by application code on every mutating DAO call). Pull =
/// ask the backend for everything changed since our last cursor per table.
/// Conflict rule: last-write-wins by `updated_at`, resolved server-side.
class SyncService {
  final AppDatabase db;
  final String baseUrl;
  final String deviceId;
  late final RemoteRowApplier _applier = RemoteRowApplier(db);
  SyncService(this.db, this.baseUrl, this.deviceId);

  /// Parent-before-child order matters: a child's FK lookup (see
  /// [RemoteRowApplier._localId]) assumes the parent row already exists.
  static const _pullOrder = [
    'companies',
    'account_groups',
    'accounts',
    'items',
    'godowns',
    'voucher_types',
    'vouchers',
    'voucher_entries',
    'gst_tax_lines',
    'stock_ledger_entries',
  ];

  Future<void> syncAll() async {
    await _push();
    for (final table in _pullOrder) {
      await _pull(table);
    }
  }

  Future<void> _push() async {
    final pending = await (db.select(
      db.syncQueue,
    )..where((q) => q.synced.equals(false))).get();
    if (pending.isEmpty) return;

    final batch = pending
        .map(
          (q) => {
            'table': q.entityTableName,
            'uuid': q.recordUuid,
            'op': q.operation,
            'payload': jsonDecode(q.payloadJson),
          },
        )
        .toList();

    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/sync/push'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'changes': batch}),
    );
    if (resp.statusCode == 200) {
      await db.batch((b) {
        for (final q in pending) {
          b.update(
            db.syncQueue,
            const SyncQueueCompanion(synced: Value(true)),
            where: (t) => t.id.equals(q.id),
          );
        }
      });
    }
  }

  Future<void> _pull(String table) async {
    final cursor = await (db.select(
      db.syncCursors,
    )..where((c) => c.entityTableName.equals(table))).getSingleOrNull();
    final since = (cursor?.lastPulledAt ?? DateTime(2000)).toIso8601String();

    final resp = await http.get(
      Uri.parse('$baseUrl/api/v1/sync/pull?table=$table&since=$since'),
    );
    if (resp.statusCode != 200) return;

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final rows = body['rows'] as List<dynamic>;
    for (final row in rows) {
      await _applier.apply(table, row as Map<String, dynamic>);
    }
    await db
        .into(db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            entityTableName: table,
            lastPulledAt: DateTime.now(),
          ),
        );
  }
}
