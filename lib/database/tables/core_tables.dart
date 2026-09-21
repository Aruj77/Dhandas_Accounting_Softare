import 'package:drift/drift.dart';

/// Mixin: every syncable table gets an internal auto-increment [id] (fast local
/// joins/PK) + a stable [uuid] (used as the global identity for sync/backend),
/// audit timestamps and soft-delete. DRY: included via `with`.
mixin SyncColumns on Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  // Lamport-ish version counter used by the sync engine for conflict checks.
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
}

class Companies extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get gstin => text().nullable()();
  DateTimeColumn get fyStart => dateTime()();
  TextColumn get baseCurrency => text().withDefault(const Constant('INR'))();
  TextColumn get addressJson => text().nullable()(); // free-form (JSON)
}

/// Nature of an account group -> drives which financial statement it lands on.
class AccountGroups extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  TextColumn get name => text()();
  IntColumn get parentId =>
      integer().nullable().references(AccountGroups, #id)();
  // asset | liability | equity | income | expense
  TextColumn get nature => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
}

/// A "Ledger" in Tally terms = an Account in double-entry terms.
class Accounts extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  IntColumn get groupId => integer().references(AccountGroups, #id)();
  TextColumn get name => text()();
  TextColumn get openingBalanceType => text().withDefault(const Constant('dr'))();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  TextColumn get gstin => text().nullable()();
  TextColumn get contactJson => text().nullable()(); // phone/email/address (JSON)
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, name},
      ];
}

class Godowns extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  TextColumn get name => text()();
}

class Items extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  TextColumn get name => text()();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('NOS'))();
  RealColumn get gstRate => real().withDefault(const Constant(0))();
  RealColumn get openingQty => real().withDefault(const Constant(0))();
  RealColumn get openingRate => real().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, name},
      ];
}

/// sales | purchase | payment | receipt | journal | contra | credit_note | debit_note
class VoucherTypes extends Table with SyncColumns {
  IntColumn get companyId => integer().references(Companies, #id)();
  TextColumn get name => text()();
  TextColumn get nature => text()();
  TextColumn get abbreviation => text().withDefault(const Constant(''))();
}
