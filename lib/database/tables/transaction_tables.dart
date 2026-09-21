import 'package:drift/drift.dart';
import 'core_tables.dart';

/// Header. One voucher = one business transaction (invoice/payment/journal...).
class Vouchers extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  IntColumn get voucherTypeId => integer().references(VoucherTypes, #id)();
  TextColumn get voucherNumber => text()();
  DateTimeColumn get voucherDate => dateTime()();
  IntColumn get partyId => integer().nullable().references(Accounts, #id)();
  TextColumn get narration => text().nullable()();
  TextColumn get referenceNumber => text().nullable()();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, voucherTypeId, voucherNumber},
      ];
}

/// The double-entry lines. Every voucher must have sum(dr) == sum(cr); this
/// invariant is enforced in [AccountingDao.saveVoucher], never trusted from UI.
class VoucherEntries extends Table with SyncColumns {
  IntColumn get voucherId => integer().references(Vouchers, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get drCr => text()(); // 'dr' | 'cr'
  RealColumn get amount => real()();
  // Optional inventory linkage (nullable -> keeps pure-financial vouchers lean)
  IntColumn get itemId => integer().nullable().references(Items, #id)();
  IntColumn get godownId => integer().nullable().references(Godowns, #id)();
  RealColumn get qty => real().nullable()();
  RealColumn get rate => real().nullable()();
}

/// cgst | sgst | igst | cess — kept structured (not JSON) because reports/TB
/// need to aggregate on it; raw govt payloads still go through JSON (GST API).
class GstTaxLines extends Table with SyncColumns {
  IntColumn get voucherEntryId => integer().references(VoucherEntries, #id)();
  TextColumn get taxType => text()();
  RealColumn get rate => real()();
  RealColumn get amount => real()();
}

/// Derived-but-persisted stock movement, one row per item movement on a
/// voucher entry. Kept separate from VoucherEntries so pure stock reports
/// (qty in/out/balance) never need to join financial rows.
class StockLedgerEntries extends Table with SyncColumns {
  IntColumn get voucherId => integer().references(Vouchers, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  IntColumn get godownId => integer().nullable().references(Godowns, #id)();
  DateTimeColumn get entryDate => dateTime()();
  RealColumn get qtyIn => real().withDefault(const Constant(0))();
  RealColumn get qtyOut => real().withDefault(const Constant(0))();
  RealColumn get rate => real().withDefault(const Constant(0))();
}
