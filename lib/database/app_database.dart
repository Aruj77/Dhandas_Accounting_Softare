// desktop/lib/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

part 'app_database.g.dart';

class VouchersTable extends Table {
  TextColumn get id => text()();
  TextColumn get voucherNumber => text()();
  TextColumn get voucherType => text()();
  TextColumn get date => text()();
  TextColumn get series => text().withDefault(const Constant('Main'))();
  TextColumn get partyName => text()();
  RealColumn get grandTotal => real()();
  RealColumn get subTotal => real()();
  RealColumn get totalTax => real()();
  TextColumn get payloadJson => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [VouchersTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Factory for single company root database (company.sqlite)
  factory AppDatabase.forCompany(String companyFolderPath) {
    return AppDatabase(LazyDatabase(() async {
      final file = File('$companyFolderPath${Platform.pathSeparator}company.sqlite');
      return NativeDatabase.createInBackground(file);
    }));
  }

  /// Factory that targets isolated series files: DHAN-001 / 2025-26 / sales_main.sqlite
  factory AppDatabase.forSeriesFile({
    required String companyFolderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
  }) {
    final fySlug = financialYear.replaceAll(' ', '_').replaceAll('/', '-');
    final fyDir = Directory('$companyFolderPath${Platform.pathSeparator}$fySlug');
    
    if (!fyDir.existsSync()) {
      fyDir.createSync(recursive: true);
    }

    final vchBase = voucherType.toLowerCase().contains('sale')
        ? 'sales'
        : voucherType.toLowerCase().contains('purchase')
            ? 'purchase'
            : voucherType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    // Convert to lowercase first so uppercase letters (like 'M' in 'Main') don't become underscores
    final cleanSeries = (seriesName != null && seriesName.trim().isNotEmpty)
        ? seriesName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
        : 'main';

    final dbFilePath = '${fyDir.path}${Platform.pathSeparator}${vchBase}_$cleanSeries.sqlite';

    return AppDatabase(LazyDatabase(() async {
      final file = File(dbFilePath);
      return NativeDatabase.createInBackground(file);
    }));
  }

  @override
  int get schemaVersion => 1;

  Future<List<VouchersTableData>> getUnsyncedVouchers() =>
      (select(vouchersTable)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markAsSynced(List<String> ids) =>
      (update(vouchersTable)..where((t) => t.id.isIn(ids))).write(
        const VouchersTableCompanion(isSynced: Value(true)),
      );
}