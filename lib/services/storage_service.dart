import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _prefDirectoryKey = 'dhandas_data_directory_path';

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
      mastersData: {
        'debtors': [
          {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-Hand'},
        ],
        'creditors': [
          {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-Hand'},
        ],
        'items': [
          {
            'name': '3304 18% Pcs',
            'hsn': '3304',
            'unit': 'Pcs',
            'taxCategory': 'GST 18%',
            'taxRate': 18.0,
            'salesPrice': 250.0,
            'purchasePrice': 200.0,
            'mrp': 300.0,
          },
          {
            'name': '8471 18% Nos',
            'hsn': '8471',
            'unit': 'Nos',
            'taxCategory': 'GST 18%',
            'taxRate': 18.0,
            'salesPrice': 45000.0,
            'purchasePrice': 40000.0,
            'mrp': 52000.0,
          },
        ],
      },
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
      return;
    }

    final legacyFilePath = companyData['legacyFilePath']?.toString();
    if (legacyFilePath != null && await File(legacyFilePath).exists()) {
      final file = File(legacyFilePath);
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
        return;
      }
    }

    final legacyFilePath = companyData['legacyFilePath']?.toString();
    if (legacyFilePath != null) {
      final file = File(legacyFilePath);
      if (await file.exists()) {
        await file.delete();
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
          return data;
        }
      } catch (_) {}
    }

    return {
      'debtors': [
        {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-Hand'},
      ],
      'creditors': [
        {'name': 'Cash', 'gstin': '', 'group': 'Cash-in-Hand'},
      ],
      'items': [
        {
          'name': '3304 18% Pcs',
          'hsn': '3304',
          'unit': 'Pcs',
          'taxCategory': 'GST 18%',
          'taxRate': 18.0,
          'salesPrice': 250.0,
          'purchasePrice': 200.0,
          'mrp': 300.0,
        },
        {
          'name': '8471 18% Nos',
          'hsn': '8471',
          'unit': 'Nos',
          'taxCategory': 'GST 18%',
          'taxRate': 18.0,
          'salesPrice': 45000.0,
          'purchasePrice': 40000.0,
          'mrp': 52000.0,
        },
      ],
    };
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

  static String resolveVoucherFileName(String voucherType) {
    final vch = voucherType.toLowerCase().trim();
    if (vch.contains('sale')) return 'sales.json';
    if (vch.contains('purchase')) return 'purchase.json';
    if (vch.contains('payment')) return 'payment.json';
    if (vch.contains('receipt')) return 'receipt.json';
    if (vch.contains('journal')) return 'journal.json';
    if (vch.contains('contra')) return 'contra.json';
    return '${vch.replaceAll(RegExp(r'[^a-z0-9]'), '_')}.json';
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

    final targetFileName = resolveVoucherFileName(voucherData['voucherType'] ?? 'voucher');
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
      voucherList[existingIndex] = voucherData; // Update existing voucher
    } else {
      voucherList.add(voucherData); // Append new voucher
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(voucherList),
    );
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
    required String folderPath,
    required String financialYear,
    String? voucherType,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final vouchersDir = Directory(
      '$folderPath${Platform.pathSeparator}$fySlug${Platform.pathSeparator}vouchers',
    );
    if (!await vouchersDir.exists()) return [];

    final List<Map<String, dynamic>> allVouchers = [];

    if (voucherType != null) {
      final fileName = resolveVoucherFileName(voucherType);
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