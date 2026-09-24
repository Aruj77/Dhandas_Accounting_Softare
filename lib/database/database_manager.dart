// desktop/lib/database/database_manager.dart
import 'dart:io';
import 'package:drift/native.dart';
import 'app_database.dart';

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager instance = DatabaseManager._();

  final Map<String, AppDatabase> _cachedDatabases = {};

  /// Standard SQLite tuning pragmas applied to all database instances.
  static void applyOptimizedPragmas(dynamic rawDb) {
    rawDb.execute('PRAGMA journal_mode = WAL;');
    rawDb.execute('PRAGMA synchronous = NORMAL;');
    rawDb.execute('PRAGMA temp_store = MEMORY;');
    rawDb.execute('PRAGMA cache_size = -64000;');
  }

  /// Internal helper to create a database instance with standard WAL settings.
  AppDatabase _createDatabase(File file) {
    return AppDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: applyOptimizedPragmas,
      ),
    );
  }

  /// Retrieves or opens the root company database (`company.sqlite`).
  AppDatabase getCompanyDatabase({required String companyFolderPath}) {
    final dbPath = '$companyFolderPath${Platform.pathSeparator}company.sqlite';
    return _cachedDatabases.putIfAbsent(dbPath, () {
      final file = File(dbPath);
      return _createDatabase(file);
    });
  }

  /// Resolves the absolute path for an isolated annual series database.
  static String resolveSeriesDbPath({
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

    final cleanSeries = (seriesName != null && seriesName.trim().isNotEmpty)
        ? seriesName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
        : 'main';

    return '${fyDir.path}${Platform.pathSeparator}${vchBase}_$cleanSeries.sqlite';
  }

  /// Retrieves or opens a cached series-partitioned database instance.
  AppDatabase getSeriesDatabase({
    required String companyFolderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
  }) {
    final dbPath = resolveSeriesDbPath(
      companyFolderPath: companyFolderPath,
      financialYear: financialYear,
      voucherType: voucherType,
      seriesName: seriesName,
    );

    return _cachedDatabases.putIfAbsent(dbPath, () {
      final file = File(dbPath);
      return _createDatabase(file);
    });
  }

  /// Closes and flushes all cached database connections for a specified company workspace.
  Future<void> disposeCompany(String companyFolderPath) async {
    final pathsToRemove = _cachedDatabases.keys
        .where((k) => k.startsWith(companyFolderPath))
        .toList();

    for (final path in pathsToRemove) {
      final db = _cachedDatabases.remove(path);
      await db?.close();
    }
  }

  /// Closes all open connections across all companies.
  Future<void> disposeAll() async {
    for (final db in _cachedDatabases.values) {
      await db.close();
    }
    _cachedDatabases.clear();
  }
}