import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _prefDirectoryKey = 'dhandas_data_directory_path';

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
      'Add. Cess on GST',
      'Add. Cess on GST (ITC-None)',
      'Cess on GST',
      'Cess on GST (ITC-None)',
      'CGST',
      'CGST (ITC-None)',
      'Discount',
      'Freight & Forwarding Charges',
      'IGST',
      'IGST (Export / SEZ Unit)',
      'IGST (ITC-None)',
      'Round Off-',
      'Round Off+',
      'SGST',
      'SGST (ITC-None)',
      'TCS (Tax Collected at Source)',
      'TDS on Pymt./Purc. of Goods',
    ],
    'taxCategories': [
      '0% Exempt',
      'GST 3%',
      'GST 5%',
      'GST 12%',
      'GST 18%',
      'GST 28%',
      'GST 40%',
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

  static Future<String> getNextCompanyFolderId(String baseDirectoryPath) async {
    final baseDir = Directory(baseDirectoryPath);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final folderRegex = RegExp(r'^DHAN-(\d{4,})$', caseSensitive: false);
    int highestIndex = 0;

    await for (final entity in baseDir.list()) {
      if (entity is Directory) {
        final folderName = entity.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last;
        final match = folderRegex.firstMatch(folderName);
        if (match != null) {
          final parsedIndex = int.tryParse(match.group(1)!) ?? 0;
          if (parsedIndex > highestIndex) {
            highestIndex = parsedIndex;
          }
        }
      }
    }

    final nextIndex = highestIndex + 1;
    final paddedNumber = nextIndex.toString().padLeft(4, '0');
    return 'DHAN-$paddedNumber';
  }

  static Future<String> saveCompanyLocally({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    final baseDir = Directory(directoryPath);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final folderId = await getNextCompanyFolderId(directoryPath);
    final companyDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}$folderId',
    );
    if (!await companyDir.exists()) {
      await companyDir.create(recursive: true);
    }

    final initialFys = ['2024-25', '2025-26', '2026-27'];
    const defaultActiveFy = '2026-27';

    final updatedData = Map<String, dynamic>.from(companyData)
      ..['companyId'] = folderId
      ..['folderPath'] = companyDir.path
      ..['financialYears'] = companyData['financialYears'] ?? initialFys
      ..['activeFinancialYear'] =
          companyData['activeFinancialYear'] ?? defaultActiveFy;

    for (final fy in (updatedData['financialYears'] as List)) {
      final fyDir = Directory(
        '${companyDir.path}${Platform.pathSeparator}${normalizeFySlug(fy.toString())}${Platform.pathSeparator}vouchers',
      );
      if (!await fyDir.exists()) {
        await fyDir.create(recursive: true);
      }
    }

    final file = File(
      '${companyDir.path}${Platform.pathSeparator}company.json',
    );

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedData),
    );

    await saveCompanyMasters(
      folderPath: companyDir.path,
      mastersData: defaultCompanyMasters,
    );

    return folderId;
  }

  static Future<void> updateCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null && await Directory(folderPath).exists()) {
      final fys = companyData['financialYears'];
      if (fys is List) {
        for (final fy in fys) {
          final fyDir = Directory(
            '$folderPath${Platform.pathSeparator}${normalizeFySlug(fy.toString())}${Platform.pathSeparator}vouchers',
          );
          if (!await fyDir.exists()) {
            await fyDir.create(recursive: true);
          }
        }
      }

      final file = File('$folderPath${Platform.pathSeparator}company.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(companyData),
      );
    }
  }

  static Future<void> deleteCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null) {
      final dir = Directory(folderPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  static Future<Map<String, dynamic>> loadCompanyMasters({
    required String folderPath,
  }) async {
    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map<String, dynamic>) {
          bool needsResave = false;

          // Migrate missing keys for previously created companies
          defaultCompanyMasters.forEach((key, value) {
            if (!data.containsKey(key) || data[key] == null) {
              data[key] = value;
              needsResave = true;
            }
          });

          if (needsResave) {
            await saveCompanyMasters(folderPath: folderPath, mastersData: data);
          }

          return data;
        }
      } catch (_) {}
    }

    final initialMasters = Map<String, dynamic>.from(defaultCompanyMasters);
    await saveCompanyMasters(
      folderPath: folderPath,
      mastersData: initialMasters,
    );
    return initialMasters;
  }

  static Future<void> saveCompanyMasters({
    required String folderPath,
    required Map<String, dynamic> mastersData,
  }) async {
    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(mastersData),
    );
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
      base = vch.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }

    if (seriesName != null &&
        seriesName.trim().isNotEmpty &&
        seriesName.toLowerCase() != 'main') {
      final cleanSeries = seriesName
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .toLowerCase();
      return '${base}_$cleanSeries.json';
    }
    return '$base.json';
  }

  static Future<void> saveVoucher({
    required String folderPath,
    required String financialYear,
    required Map<String, dynamic> voucherData,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final vouchersDir = Directory(
      '$folderPath${Platform.pathSeparator}$fySlug${Platform.pathSeparator}vouchers',
    );
    if (!await vouchersDir.exists()) {
      await vouchersDir.create(recursive: true);
    }

    final seriesName = voucherData['series']?.toString();
    final targetFileName =
        resolveVoucherFileName(voucherData['voucherType'] ?? 'voucher', seriesName);
    final file = File('${vouchersDir.path}${Platform.pathSeparator}$targetFileName');

    List<dynamic> voucherList = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final parsed = jsonDecode(content);
        if (parsed is List) {
          voucherList = parsed;
        }
      } catch (_) {}
    }

    final newVchNo = voucherData['voucherNumber']?.toString().trim() ?? '';
    final existingIndex = voucherList.indexWhere((item) =>
        item is Map<String, dynamic> &&
        (item['voucherNumber']?.toString().trim() ?? '') == newVchNo);

    if (existingIndex != -1 && newVchNo.isNotEmpty) {
      voucherList[existingIndex] = voucherData;
    } else {
      voucherList.add(voucherData);
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(voucherList),
    );
  }

  static Future<void> saveAllVouchers({
    required String folderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
    required List<Map<String, dynamic>> vouchers,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final vouchersDir = Directory(
      '$folderPath${Platform.pathSeparator}$fySlug${Platform.pathSeparator}vouchers',
    );
    if (!await vouchersDir.exists()) {
      await vouchersDir.create(recursive: true);
    }

    final targetFileName = resolveVoucherFileName(voucherType, seriesName);
    final file = File('${vouchersDir.path}${Platform.pathSeparator}$targetFileName');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(vouchers),
    );
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
    required String folderPath,
    required String financialYear,
    String? voucherType,
    String? seriesName,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final vouchersDir = Directory(
      '$folderPath${Platform.pathSeparator}$fySlug${Platform.pathSeparator}vouchers',
    );
    if (!await vouchersDir.exists()) return [];

    final List<Map<String, dynamic>> allVouchers = [];

    if (voucherType != null) {
      final fileName = resolveVoucherFileName(voucherType, seriesName);
      final file = File('${vouchersDir.path}${Platform.pathSeparator}$fileName');
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is List) {
            allVouchers.addAll(data.whereType<Map<String, dynamic>>());
          }
        } catch (_) {}
      }
      return allVouchers;
    }

    await for (final entity in vouchersDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final data = jsonDecode(content);
          if (data is List) {
            allVouchers.addAll(data.whereType<Map<String, dynamic>>());
          } else if (data is Map<String, dynamic>) {
            allVouchers.add(data);
          }
        } catch (_) {}
      }
    }
    return allVouchers;
  }

  static Future<List<Map<String, dynamic>>> loadCompanies(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final List<Map<String, dynamic>> companies = [];

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final companyJsonFile = File(
          '${entity.path}${Platform.pathSeparator}company.json',
        );
        if (await companyJsonFile.exists()) {
          try {
            final content = await companyJsonFile.readAsString();
            final data = jsonDecode(content);
            if (data is Map<String, dynamic>) {
              data['folderPath'] = entity.path;
              data['companyId'] ??= entity.uri.pathSegments
                  .where((segment) => segment.isNotEmpty)
                  .last;
              data['financialYears'] ??= ['2024-25', '2025-26', '2026-27'];
              data['activeFinancialYear'] ??= '2026-27';
              companies.add(data);
            }
          } catch (_) {}
        }
      }
    }

    return companies;
  }
}