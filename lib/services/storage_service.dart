// desktop/lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class StorageService {
  static const String _prefDirectoryKey = 'dhandas_data_directory_path';
  static final Map<String, Map<String, dynamic>> _mastersMemoryCache = {};
  
  static const Map<String, dynamic> defaultCompanyMasters = {
    'debtors': [
      {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-hand'},
    ],
    'creditors': [
      {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-hand'},
    ],
    'items': [],
    'series': ['Main'],
    'seriesSettings': {
      'Main': {
        'name': 'Main',
        'numberingType': 'Manual',
        'renumberingFreq': 'None',
        'yearFormat': 'YY-YY',
        'yearPosition': 'As Prefix',
        'separator': '/',
        'prefix': '',
        'suffix': '',
        'startNumber': 1,
        'endNumber': 99999999,
      }
    },
    'saleTypes': [
      'Local Itemwise',
      'InterState Itemwise',
      'Local Multirate',
      'InterState Multirate',
      'Local Exempt',
      'InterState Exempt',
    ],
    'units': [
      'BAG', 'BAL', 'BDL', 'BOX', 'BTL', 'BUN', 'CAN', 'CBM', 'CCM', 'CMS',
      'CTN', 'DOZ', 'DRM', 'GGK', 'GMS', 'GRS', 'GYD', 'KGS', 'KLR', 'KME',
      'MLT', 'MTR', 'MTS', 'NOS', 'PAC', 'PCS', 'PRS', 'QTL', 'ROL', 'SET',
      'SQF', 'SQM', 'SQY', 'TBS', 'TGM', 'THD', 'TON', 'TUB', 'UGS', 'UNT', 'YDS',
    ],
    'accountGroups': [
      'Sundry Debtors',
      'Sundry Creditors',
      'Bank Accounts',
      'Cash-in-hand',
      'Direct Expenses',
      'Indirect Expenses',
      'Sales Accounts',
      'Purchase Accounts',
    ],
    'materialCenters': [
      'Main Store',
      'Warehouse',
      'Godown',
    ],
    'billSundries': [
      'CGST', 'SGST', 'IGST', 'Discount', 'Freight & Forwarding Charges', 'Round Off+', 'Round Off-'
    ],
    'taxCategories': [
      '0% Exempt', 'GST 5%', 'GST 12%', 'GST 18%', 'GST 28%',
    ],
  };

  static Future<String?> getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefDirectoryKey);
    if (path != null && await Directory(path).exists()) {
      return path;
    }
    return null;
  }

  static Future<void> saveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDirectoryKey, path);
  }

  static String normalizeFySlug(String fy) {
    return fy.replaceAll(' ', '_').replaceAll('/', '-');
  }

  static String resolveVoucherFileName(String voucherType, [String? seriesName]) {
    final vch = voucherType.toLowerCase().trim();
    String base = 'sales';
    if (vch.contains('sale')) {
      base = 'sales';
    } else if (vch.contains('purchase')) {
      base = 'purchase';
    } else if (vch.contains('payment')) {
      base = 'payment';
    } else if (vch.contains('receipt')) {
      base = 'receipt';
    } else if (vch.contains('journal')) {
      base = 'journal';
    } else if (vch.contains('contra')) {
      base = 'contra';
    } else {
      base = vch.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }

    final cleanSeries = (seriesName != null && seriesName.trim().isNotEmpty)
        ? seriesName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
        : 'main';

    return '${base}_$cleanSeries.sqlite';
  }

  static Future<String> getNextCompanyFolderId(String baseDirectoryPath) async {
    final baseDir = Directory(baseDirectoryPath);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final folderRegex = RegExp(r'^DHAN-(\d{3,}$)$', caseSensitive: false);
    int highestIndex = 0;

    await for (final entity in baseDir.list()) {
      if (entity is Directory) {
        final folderName = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        final match = folderRegex.firstMatch(folderName);
        if (match != null) {
          final parsedIndex = int.tryParse(match.group(1)!) ?? 0;
          if (parsedIndex > highestIndex) {
            highestIndex = parsedIndex;
          }
        }
      }
    }

    return 'DHAN-${(highestIndex + 1).toString().padLeft(3, '0')}';
  }

  static Future<String> saveCompanyLocally({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    final baseDir = Directory(directoryPath);
    if (!await baseDir.exists()) await baseDir.create(recursive: true);

    // Get the next guaranteed unique folder ID (e.g., DHAN-001 -> DHAN-002)
    final folderId = await getNextCompanyFolderId(directoryPath);
    final companyDir = Directory('${baseDir.path}${Platform.pathSeparator}$folderId');
    
    if (await companyDir.exists()) {
      await companyDir.delete(recursive: true);
    }
    await companyDir.create(recursive: true);

    final initialFys = ['2024-25', '2025-26', '2026-27'];
    const defaultActiveFy = '2026-27';

    final updatedData = Map<String, dynamic>.from(companyData)
      ..['id'] = folderId
      ..['companyId'] = folderId
      ..['folderPath'] = companyDir.path
      ..['financialYears'] = companyData['financialYears'] ?? initialFys
      ..['activeFinancialYear'] = companyData['activeFinancialYear'] ?? defaultActiveFy;

    for (final fy in (updatedData['financialYears'] as List)) {
      final fyDir = Directory('${companyDir.path}${Platform.pathSeparator}${normalizeFySlug(fy.toString())}');
      if (!await fyDir.exists()) await fyDir.create(recursive: true);
    }

    final file = File('${companyDir.path}${Platform.pathSeparator}company.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(updatedData));

    await saveCompanyMasters(folderPath: companyDir.path, mastersData: defaultCompanyMasters);
    return folderId;
  }

  static Future<void> updateCompanyLocally({required Map<String, dynamic> companyData}) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null && await Directory(folderPath).exists()) {
      final fys = companyData['financialYears'];
      if (fys is List) {
        for (final fy in fys) {
          final fyDir = Directory('$folderPath${Platform.pathSeparator}${normalizeFySlug(fy.toString())}');
          if (!await fyDir.exists()) await fyDir.create(recursive: true);
        }
      }
      final file = File('$folderPath${Platform.pathSeparator}company.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(companyData));
    }
  }

  static Future<void> deleteCompanyLocally({required Map<String, dynamic> companyData}) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null) {
      final dir = Directory(folderPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }

  static Future<Map<String, dynamic>> loadCompanyMasters({required String folderPath}) async {
    if (_mastersMemoryCache.containsKey(folderPath)) {
      return _mastersMemoryCache[folderPath]!;
    }

    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _mastersMemoryCache[folderPath] = data;
        return data;
      } catch (_) {}
    }
    final initial = Map<String, dynamic>.from(defaultCompanyMasters);
    await saveCompanyMasters(folderPath: folderPath, mastersData: initial);
    return initial;
  }

  static Future<void> saveCompanyMasters({
    required String folderPath,
    required Map<String, dynamic> mastersData,
  }) async {
    _mastersMemoryCache[folderPath] = mastersData;
    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(mastersData));
  }

  static Future<void> saveVoucher({
    required String folderPath,
    required String financialYear,
    required Map<String, dynamic> voucherData,
  }) async {
    final vchType = voucherData['voucherType']?.toString() ?? 'Sales Invoice';
    final seriesName = voucherData['series']?.toString() ?? 'Main';

    final db = AppDatabase.forSeriesFile(
      companyFolderPath: folderPath,
      financialYear: financialYear,
      voucherType: vchType,
      seriesName: seriesName,
    );

    final id = voucherData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await db.into(db.vouchersTable).insertOnConflictUpdate(
            VouchersTableCompanion(
              id: Value(id),
              voucherNumber: Value(voucherData['voucherNumber']?.toString() ?? ''),
              voucherType: Value(vchType),
              date: Value(voucherData['date']?.toString() ?? ''),
              series: Value(seriesName),
              partyName: Value(voucherData['party']?.toString() ?? ''),
              grandTotal: Value(double.tryParse(voucherData['grandTotal']?.toString() ?? '0') ?? 0.0),
              subTotal: Value(double.tryParse(voucherData['subTotal']?.toString() ?? '0') ?? 0.0),
              totalTax: Value(double.tryParse(voucherData['totalTax']?.toString() ?? '0') ?? 0.0),
              payloadJson: Value(jsonEncode(voucherData)),
              isSynced: const Value(false),
            ),
          );
    } finally {
      await db.close();
    }
  }

  static Future<void> saveAllVouchers({
    required String folderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
    required List<Map<String, dynamic>> vouchers,
  }) async {
    final db = AppDatabase.forSeriesFile(
      companyFolderPath: folderPath,
      financialYear: financialYear,
      voucherType: voucherType,
      seriesName: seriesName ?? 'Main',
    );

    try {
      await db.transaction(() async {
        for (final vch in vouchers) {
          final id = vch['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          await db.into(db.vouchersTable).insertOnConflictUpdate(
                VouchersTableCompanion(
                  id: Value(id),
                  voucherNumber: Value(vch['voucherNumber']?.toString() ?? ''),
                  voucherType: Value(vch['voucherType']?.toString() ?? voucherType),
                  date: Value(vch['date']?.toString() ?? ''),
                  series: Value(vch['series']?.toString() ?? seriesName ?? 'Main'),
                  partyName: Value(vch['party']?.toString() ?? ''),
                  grandTotal: Value(double.tryParse(vch['grandTotal']?.toString() ?? '0') ?? 0.0),
                  subTotal: Value(double.tryParse(vch['subTotal']?.toString() ?? '0') ?? 0.0),
                  totalTax: Value(double.tryParse(vch['totalTax']?.toString() ?? '0') ?? 0.0),
                  payloadJson: Value(jsonEncode(vch)),
                  isSynced: const Value(false),
                ),
              );
        }
      });
    } finally {
      await db.close();
    }
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
  required String folderPath,
    required String financialYear,
    String? voucherType,
    String? seriesName,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final fyDir = Directory('$folderPath${Platform.pathSeparator}$fySlug');
    if (!await fyDir.exists()) return [];

    final List<Map<String, dynamic>> allVouchers = [];
    if (voucherType != null && seriesName != null && seriesName.toLowerCase() != 'all') {
      final fileName = resolveVoucherFileName(voucherType, seriesName);
      final file = File('${fyDir.path}${Platform.pathSeparator}$fileName');
      if (await file.exists()) {
        return _fetchVouchersFromFile(file);
      }
      return [];
    }
    await for (final entity in fyDir.list()) {
      if (entity is File && entity.path.endsWith('.sqlite')) {
        final fileName = entity.uri.pathSegments.last.toLowerCase();
        
        if (voucherType != null) {
          final targetBase = voucherType.toLowerCase().contains('sale') ? 'sales' : 'purchase';
          if (!fileName.contains(targetBase)) continue;
        }
        if (seriesName != null && seriesName.toLowerCase() != 'all') {
          final cleanSeries = seriesName.trim().toLowerCase();
          if (!fileName.contains(cleanSeries)) continue;
        }

        final vouchers = await _fetchVouchersFromFile(entity);
        allVouchers.addAll(vouchers);
      }
    }
    return allVouchers;
  }

  static Future<List<Map<String, dynamic>>> _fetchVouchersFromFile(File file) async {
    final db = AppDatabase(NativeDatabase(file));
    final List<Map<String, dynamic>> vouchers = [];
    try {
      final rows = await db.select(db.vouchersTable).get();
      for (final r in rows) {
        vouchers.add(jsonDecode(r.payloadJson) as Map<String, dynamic>);
      }
    } catch (_) {
      // Handle read errors silently or log in debug mode
    } finally {
      await db.close();
    }
    return vouchers;
  }

  static Future<List<Map<String, dynamic>>> loadCompanies(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final List<Map<String, dynamic>> companies = [];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final companyJsonFile = File('${entity.path}${Platform.pathSeparator}company.json');
        if (await companyJsonFile.exists()) {
          try {
            final content = await companyJsonFile.readAsString();
            final data = jsonDecode(content);
            if (data is Map<String, dynamic>) {
              data['folderPath'] = entity.path;
              companies.add(data);
            }
          } catch (_) {}
        }
      }
    }
    return companies;
  }
}