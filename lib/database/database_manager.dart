// desktop/lib/database/database_manager.dart
import 'dart:io';
import 'package:drift/native.dart';
import 'app_database.dart';

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager instance = DatabaseManager._();

  final Map<String, AppDatabase> _cachedDatabases = {};

  AppDatabase getSeriesDatabase({
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

    final dbPath = '${fyDir.path}${Platform.pathSeparator}${vchBase}_$cleanSeries.sqlite';

    return _cachedDatabases.putIfAbsent(dbPath, () {
      final file = File(dbPath);
      return AppDatabase(NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          rawDb.execute('PRAGMA journal_mode = WAL;');
          rawDb.execute('PRAGMA synchronous = NORMAL;');
          rawDb.execute('PRAGMA temp_store = MEMORY;');
          rawDb.execute('PRAGMA cache_size = -64000;');
        },
      ));
    });
  }

  Future<void> disposeCompany(String companyFolderPath) async {
    final pathsToRemove = _cachedDatabases.keys
        .where((k) => k.startsWith(companyFolderPath))
        .toList();

    for (final path in pathsToRemove) {
      final db = _cachedDatabases.remove(path);
      await db?.close();
    }
  }
}