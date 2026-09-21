import 'package:drift/drift.dart';
import '../app_database.dart';

/// Converts one server row (json, snake_case keys matching column names)
/// into an insert-or-update-by-uuid for the matching Drift table. Conflict
/// target is `uuid` (not the local autoincrement `id`, which is per-device).
class RemoteRowApplier {
  final AppDatabase db;
  RemoteRowApplier(this.db);

  DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);
  double? _num(dynamic v) => v == null ? null : (v as num).toDouble();

  Future<void> apply(String table, Map<String, dynamic> r) async {
    switch (table) {
      case 'companies':
        await _upsert(
          db.companies,
          db.companies.uuid,
          CompaniesCompanion(
            uuid: Value(r['uuid']),
            name: Value(r['name']),
            gstin: Value(r['gstin']),
            fyStart: Value(_dt(r['fy_start'])!),
            baseCurrency: Value(r['base_currency'] ?? 'INR'),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'account_groups':
        await _upsert(
          db.accountGroups,
          db.accountGroups.uuid,
          AccountGroupsCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            parentId: r['parent_uuid'] == null
                ? const Value(null)
                : Value(await _localId(db.accountGroups, db.accountGroups.uuid, r['parent_uuid'])),
            name: Value(r['name']),
            nature: Value(r['nature']),
            isSystem: Value(r['is_system'] ?? false),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'accounts':
        await _upsert(
          db.accounts,
          db.accounts.uuid,
          AccountsCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            groupId: Value(await _localId(db.accountGroups, db.accountGroups.uuid, r['group_uuid'])),
            name: Value(r['name']),
            openingBalanceType: Value(r['opening_balance_type'] ?? 'dr'),
            openingBalance: Value(_num(r['opening_balance']) ?? 0),
            gstin: Value(r['gstin']),
            isSystem: Value(r['is_system'] ?? false),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'items':
        await _upsert(
          db.items,
          db.items.uuid,
          ItemsCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            name: Value(r['name']),
            hsnCode: Value(r['hsn_code']),
            unit: Value(r['unit'] ?? 'NOS'),
            gstRate: Value(_num(r['gst_rate']) ?? 0),
            openingQty: Value(_num(r['opening_qty']) ?? 0),
            openingRate: Value(_num(r['opening_rate']) ?? 0),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'godowns':
        await _upsert(
          db.godowns,
          db.godowns.uuid,
          GodownsCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            name: Value(r['name']),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'voucher_types':
        await _upsert(
          db.voucherTypes,
          db.voucherTypes.uuid,
          VoucherTypesCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            name: Value(r['name']),
            nature: Value(r['nature']),
            abbreviation: Value(r['abbreviation'] ?? ''),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'vouchers':
        await _upsert(
          db.vouchers,
          db.vouchers.uuid,
          VouchersCompanion(
            uuid: Value(r['uuid']),
            companyId: Value(await _localId(db.companies, db.companies.uuid, r['company_uuid'])),
            voucherTypeId:
                Value(await _localId(db.voucherTypes, db.voucherTypes.uuid, r['voucher_type_uuid'])),
            voucherNumber: Value(r['voucher_number']),
            voucherDate: Value(_dt(r['voucher_date'])!),
            partyId: r['party_uuid'] == null
                ? const Value(null)
                : Value(await _localId(db.accounts, db.accounts.uuid, r['party_uuid'])),
            narration: Value(r['narration']),
            referenceNumber: Value(r['reference_number']),
            isCancelled: Value(r['is_cancelled'] ?? false),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'voucher_entries':
        await _upsert(
          db.voucherEntries,
          db.voucherEntries.uuid,
          VoucherEntriesCompanion(
            uuid: Value(r['uuid']),
            voucherId: Value(await _localId(db.vouchers, db.vouchers.uuid, r['voucher_uuid'])),
            accountId: Value(await _localId(db.accounts, db.accounts.uuid, r['account_uuid'])),
            drCr: Value(r['dr_cr']),
            amount: Value(_num(r['amount'])!),
            itemId: r['item_uuid'] == null
                ? const Value(null)
                : Value(await _localId(db.items, db.items.uuid, r['item_uuid'])),
            godownId: r['godown_uuid'] == null
                ? const Value(null)
                : Value(await _localId(db.godowns, db.godowns.uuid, r['godown_uuid'])),
            qty: Value(_num(r['qty'])),
            rate: Value(_num(r['rate'])),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'gst_tax_lines':
        await _upsert(
          db.gstTaxLines,
          db.gstTaxLines.uuid,
          GstTaxLinesCompanion(
            uuid: Value(r['uuid']),
            voucherEntryId:
                Value(await _localId(db.voucherEntries, db.voucherEntries.uuid, r['voucher_entry_uuid'])),
            taxType: Value(r['tax_type']),
            rate: Value(_num(r['rate'])!),
            amount: Value(_num(r['amount'])!),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;

      case 'stock_ledger_entries':
        await _upsert(
          db.stockLedgerEntries,
          db.stockLedgerEntries.uuid,
          StockLedgerEntriesCompanion(
            uuid: Value(r['uuid']),
            voucherId: Value(await _localId(db.vouchers, db.vouchers.uuid, r['voucher_uuid'])),
            itemId: Value(await _localId(db.items, db.items.uuid, r['item_uuid'])),
            godownId: r['godown_uuid'] == null
                ? const Value(null)
                : Value(await _localId(db.godowns, db.godowns.uuid, r['godown_uuid'])),
            entryDate: Value(_dt(r['entry_date'])!),
            qtyIn: Value(_num(r['qty_in']) ?? 0),
            qtyOut: Value(_num(r['qty_out']) ?? 0),
            rate: Value(_num(r['rate']) ?? 0),
            updatedAt: Value(_dt(r['updated_at']) ?? DateTime.now()),
            deletedAt: Value(_dt(r['deleted_at'])),
            isDirty: const Value(false),
          ),
        );
        break;
    }
  }

  /// Resolves a remote uuid FK to this device's local autoincrement id.
  /// Rows always pull in parent-before-child order (see SyncService.syncAll),
  /// so the referenced row is guaranteed to exist by the time this runs.
  Future<int> _localId<T extends Table, D>(
      TableInfo<T, D> table, GeneratedColumn<String> uuidCol, String uuid) async {
    final row = await (db.customSelect(
      'SELECT id FROM ${table.actualTableName} WHERE uuid = ?',
      variables: [Variable.withString(uuid)],
      readsFrom: {table},
    ).getSingleOrNull());
    if (row == null) {
      throw StateError('Sync order error: ${table.actualTableName} $uuid not found locally yet');
    }
    return row.read<int>('id');
  }

  /// Last-write-wins guard: only overwrite the local row if the incoming
  /// `updated_at` is newer (mirrors the check the backend does on push).
  Future<void> _upsert<T extends Table, D>(
      TableInfo<T, D> table, GeneratedColumn<String> uuidCol, Insertable<D> companion) async {
    await db.into(table).insert(companion, onConflict: DoUpdate((old) => companion, target: [uuidCol]));
  }
}
