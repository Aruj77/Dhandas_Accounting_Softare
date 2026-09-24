// desktop/lib/database/app_database.dart
import 'package:drift/drift.dart';
import 'database_manager.dart';

part 'app_database.g.dart';

class VouchersTable extends Table {
  TextColumn get id => text()();

  // Multi-Branch HLC & Conflict Resolution Columns
  TextColumn get hlcTimestamp => text().withDefault(const Constant('0:0:origin'))();
  TextColumn get originNodeId => text().withDefault(const Constant('primary'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Core Voucher Data Columns
  TextColumn get voucherNumber => text()();
  TextColumn get voucherType => text()();
  TextColumn get date => text()();
  TextColumn get series => text().withDefault(const Constant('Main'))();
  TextColumn get partyName => text()();
  RealColumn get grandTotal => real()();
  RealColumn get subTotal => real()();
  RealColumn get totalTax => real()();
  TextColumn get payloadJson => text()();

  // Regulatory E-Invoice & IRP Metadata Columns
  TextColumn get irn => text().nullable()();
  TextColumn get ackNo => text().nullable()();
  TextColumn get signedQrCode => text().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [VouchersTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Delegates to [DatabaseManager] to ensure WAL mode, caching, and pragma optimization.
  factory AppDatabase.forCompany(String companyFolderPath) {
    return DatabaseManager.instance.getCompanyDatabase(companyFolderPath: companyFolderPath);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(vouchersTable, vouchersTable.hlcTimestamp);
            await m.addColumn(vouchersTable, vouchersTable.originNodeId);
            await m.addColumn(vouchersTable, vouchersTable.isDeleted);
            await m.addColumn(vouchersTable, vouchersTable.irn);
            await m.addColumn(vouchersTable, vouchersTable.ackNo);
            await m.addColumn(vouchersTable, vouchersTable.signedQrCode);
          }
        },
      );

  // Queries
  Future<List<VouchersTableData>> getUnsyncedVouchers() =>
      (select(vouchersTable)..where((t) => t.isSynced.equals(false) & t.isDeleted.equals(false))).get();

  Future<void> markAsSynced(List<String> ids) =>
      (update(vouchersTable)..where((t) => t.id.isIn(ids))).write(
        const VouchersTableCompanion(isSynced: Value(true)),
      );

  Future<void> softDeleteVoucher(String id, String hlc) =>
      (update(vouchersTable)..where((t) => t.id.equals(id))).write(
        VouchersTableCompanion(
          isDeleted: const Value(true),
          hlcTimestamp: Value(hlc),
          isSynced: const Value(false),
        ),
      );
}