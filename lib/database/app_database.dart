import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'tables/core_tables.dart';
import 'tables/transaction_tables.dart';
import 'tables/sync_tables.dart';
import 'daos/accounting_dao.dart';
import 'daos/master_dao.dart';
import 'daos/voucher_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Companies,
    AccountGroups,
    Accounts,
    Godowns,
    Items,
    VoucherTypes,
    Vouchers,
    VoucherEntries,
    GstTaxLines,
    StockLedgerEntries,
    SyncQueue,
    SyncCursors,
  ],
  daos: [AccountingDao, MasterDao, VoucherDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Opens (or creates) the SQLite file for one specific company. Each
  /// company gets its own isolated file — fast open/switch, small backups,
  /// no cross-company locking.
  factory AppDatabase.forFile(File file) {
    return AppDatabase(LazyDatabase(() async {
      await file.parent.create(recursive: true);
      return NativeDatabase.createInBackground(file);
    }));
  }

  static const _uuid = Uuid();
  String newUuid() => _uuid.v4();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    // Every future schema change gets one `if (from < N)` block here —
    // additive, never destructive, so offline data always survives.
    onUpgrade: (m, from, to) async {},
  );

  /// Soft delete: never DROP a row (breaks FK history + sync); flip the flag
  /// and bump version/isDirty so the outbox picks it up.
  Future<void> softDelete<T extends Table, D>(
    TableInfo<T, D> table,
    int id,
  ) async {
    await customUpdate(
      'UPDATE ${table.actualTableName} SET deleted_at = ?, is_dirty = 1, '
      'version = version + 1 WHERE id = ?',
      variables: [Variable.withDateTime(DateTime.now()), Variable.withInt(id)],
      updates: {table},
    );
    final uuid = await uuidOf(table, id);
    await enqueueSync(table.actualTableName, uuid, 'delete', {'uuid': uuid});
  }

  /// Looks up a row's stable uuid from its local autoincrement id — used to
  /// translate FKs into outbox payloads (see daos/*.dart callers).
  Future<String> uuidOf(TableInfo table, int id) async {
    final r = await customSelect(
      'SELECT uuid FROM ${table.actualTableName} WHERE id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: {table},
    ).getSingle();
    return r.read<String>('uuid');
  }

  /// Writes one row into the outbox. [payload] must already use `*_uuid`
  /// (never local `*_id`) for every foreign key — local ids are meaningless
  /// once they leave this device.
  Future<void> enqueueSync(
    String table,
    String uuid,
    String operation,
    Map<String, dynamic> payload,
  ) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityTableName: table,
        recordUuid: uuid,
        operation: operation,
        payloadJson: jsonEncode(payload),
      ),
    );
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'dhandas.sqlite'));

    print('DATABASE PATH: ${file.path}');

    return NativeDatabase.createInBackground(file);
  });
}