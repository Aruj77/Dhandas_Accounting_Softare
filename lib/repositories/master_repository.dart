// lib/repositories/master_repository.dart
import '../models/item_master_model.dart';
import '../models/party_master_model.dart';
import '../services/storage_service.dart';

/// Strongly-typed domain representation of company master records.
class CompanyMasters {
  final List<PartyMasterModel> debtors;
  final List<PartyMasterModel> creditors;
  final List<ItemMasterModel> items;
  final List<String> series;
  final Map<String, dynamic> seriesSettings;
  final List<String> saleTypes;
  final List<String> billSundries;
  final List<String> materialCenters;
  final List<String> units;
  final List<String> taxCategories;
  final List<String> accountGroups;

  const CompanyMasters({
    this.debtors = const [],
    this.creditors = const [],
    this.items = const [],
    this.series = const ['Main'],
    this.seriesSettings = const {},
    this.saleTypes = const [],
    this.billSundries = const [],
    this.materialCenters = const [],
    this.units = const [],
    this.taxCategories = const [],
    this.accountGroups = const [],
  });

  factory CompanyMasters.fromJson(Map<String, dynamic> raw) {
    PartyMasterModel parseParty(dynamic d, String defaultGroup) {
      if (d is Map<String, dynamic>) {
        return PartyMasterModel.fromJson(d);
      } else if (d is Map) {
        return PartyMasterModel.fromJson(Map<String, dynamic>.from(d));
      }
      return PartyMasterModel(group: defaultGroup);
    }

    ItemMasterModel parseItem(dynamic i) {
      if (i is! Map) return ItemMasterModel.empty();
      return ItemMasterModel(
        name: i['name']?.toString() ?? '',
        hsn: i['hsn']?.toString() ?? '',
        unit: i['unit']?.toString() ?? 'PCS',
        taxCategory: i['taxCategory']?.toString() ?? 'GST 18%',
        taxRate: (i['taxRate'] as num?)?.toDouble() ?? 18.0,
        salesPrice: (i['salesPrice'] as num?)?.toDouble() ?? 0.0,
        purchasePrice: (i['purchasePrice'] as num?)?.toDouble() ?? 0.0,
        mrp: (i['mrp'] as num?)?.toDouble() ?? 0.0,
      );
    }

    List<String> extractStringList(String key) {
      return (raw[key] as List? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final seriesList = extractStringList('series');
    if (!seriesList.contains('Main')) {
      seriesList.insert(0, 'Main');
    }

    final rawSettings = raw['seriesSettings'];
    final Map<String, dynamic> settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : <String, dynamic>{};

    return CompanyMasters(
      debtors: (raw['debtors'] as List? ?? [])
          .map((d) => parseParty(d, 'Sundry Debtors'))
          .toList(),
      creditors: (raw['creditors'] as List? ?? [])
          .map((c) => parseParty(c, 'Sundry Creditors'))
          .toList(),
      items: (raw['items'] as List? ?? []).map(parseItem).toList(),
      series: seriesList,
      seriesSettings: settings,
      saleTypes: extractStringList('saleTypes'),
      billSundries: extractStringList('billSundries'),
      materialCenters: extractStringList('materialCenters'),
      units: extractStringList('units'),
      taxCategories: extractStringList('taxCategories'),
      accountGroups: extractStringList('accountGroups'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtors': debtors.map((d) => d.toJson()).toList(),
      'creditors': creditors.map((c) => c.toJson()).toList(),
      'items': items
          .map((i) => {
                'name': i.name,
                'hsn': i.hsn,
                'unit': i.unit,
                'taxCategory': i.taxCategory,
                'taxRate': i.taxRate,
                'salesPrice': i.salesPrice,
                'purchasePrice': i.purchasePrice,
                'mrp': i.mrp,
              })
          .toList(),
      'series': series,
      'seriesSettings': seriesSettings,
      'saleTypes': saleTypes,
      'billSundries': billSundries,
      'materialCenters': materialCenters,
      'units': units,
      'taxCategories': taxCategories,
      'accountGroups': accountGroups,
    };
  }

  List<String> getSimpleList(String key) {
    switch (key) {
      case 'materialCenters':
        return materialCenters;
      case 'accountGroups':
        return accountGroups;
      case 'billSundries':
        return billSundries;
      case 'units':
        return units;
      case 'saleTypes':
        return saleTypes;
      case 'taxCategories':
        return taxCategories;
      default:
        return const [];
    }
  }
}

/// Central repository encapsulating master data mutations and file persistence.
class MasterRepository {
  MasterRepository._();

  /// Loads all master entities for a company.
  static Future<CompanyMasters> loadMasters({required String folderPath}) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    return CompanyMasters.fromJson(raw);
  }

  /// Saves the complete company master dataset.
  static Future<void> saveMasters({
    required String folderPath,
    required CompanyMasters masters,
  }) async {
    await StorageService.saveCompanyMasters(
      folderPath: folderPath,
      mastersData: masters.toJson(),
    );
  }

  /// Adds or updates a party in debtors or creditors based on its group.
  static Future<void> upsertParty({
    required String folderPath,
    required PartyMasterModel party,
    String? oldName,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final targetName = (oldName ?? party.name).trim().toLowerCase();

    void remove(String key) {
      final list = (raw[key] as List? ?? []).where((p) {
        final pName = (p['name'] ?? '').toString().trim().toLowerCase();
        return pName != targetName;
      }).toList();
      raw[key] = list;
    }

    remove('debtors');
    remove('creditors');

    final isCreditor = party.group.trim().toLowerCase().contains('creditor');
    final listKey = isCreditor ? 'creditors' : 'debtors';
    final targetList = List<Map<String, dynamic>>.from(
      (raw[listKey] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    targetList.add(party.toJson());
    raw[listKey] = targetList;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }

  /// Deletes a party ledger by name from debtors and creditors.
  static Future<void> deleteParty({
    required String folderPath,
    required String partyName,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final targetName = partyName.trim().toLowerCase();

    void remove(String key) {
      final list = (raw[key] as List? ?? []).where((p) {
        final pName = (p['name'] ?? '').toString().trim().toLowerCase();
        return pName != targetName;
      }).toList();
      raw[key] = list;
    }

    remove('debtors');
    remove('creditors');

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }

  /// Adds or updates an inventory item record.
  static Future<void> upsertItem({
    required String folderPath,
    required ItemMasterModel item,
    String? oldName,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final itemsList = List<Map<String, dynamic>>.from(
      (raw['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final targetName = (oldName ?? item.name).trim().toLowerCase();

    final itemMap = {
      'name': item.name,
      'hsn': item.hsn,
      'unit': item.unit,
      'taxCategory': item.taxCategory,
      'taxRate': item.taxRate,
      'salesPrice': item.salesPrice,
      'purchasePrice': item.purchasePrice,
      'mrp': item.mrp,
    };

    final idx = itemsList.indexWhere(
      (i) => (i['name'] ?? '').toString().trim().toLowerCase() == targetName,
    );

    if (idx != -1) {
      itemsList[idx] = itemMap;
    } else {
      itemsList.add(itemMap);
    }
    raw['items'] = itemsList;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }

  /// Deletes an inventory item by name.
  static Future<void> deleteItem({
    required String folderPath,
    required String itemName,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final targetName = itemName.trim().toLowerCase();
    final itemsList = (raw['items'] as List? ?? []).where((i) {
      return (i['name'] ?? '').toString().trim().toLowerCase() != targetName;
    }).toList();
    raw['items'] = itemsList;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }

  /// Adds or updates a voucher numbering series configuration.
  static Future<void> upsertSeries({
    required String folderPath,
    required String seriesName,
    required Map<String, dynamic> seriesSettings,
    String? oldName,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final seriesList = List<String>.from(raw['series'] ?? ['Main']);
    final settingsMap = Map<String, dynamic>.from(raw['seriesSettings'] ?? {});

    if (oldName != null && oldName.trim().isNotEmpty) {
      final oldIdx = seriesList.indexWhere(
        (s) => s.trim().toLowerCase() == oldName.trim().toLowerCase(),
      );
      if (oldIdx != -1) {
        seriesList[oldIdx] = seriesName;
      } else if (!seriesList.contains(seriesName)) {
        seriesList.add(seriesName);
      }
      settingsMap.remove(oldName);
    } else {
      if (!seriesList.any((s) => s.trim().toLowerCase() == seriesName.trim().toLowerCase())) {
        seriesList.add(seriesName);
      }
    }

    settingsMap[seriesName] = seriesSettings;
    raw['series'] = seriesList;
    raw['seriesSettings'] = settingsMap;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }

  /// Deletes a voucher series configuration (default 'Main' series cannot be removed).
  static Future<bool> deleteSeries({
    required String folderPath,
    required String seriesName,
  }) async {
    if (seriesName.trim().toLowerCase() == 'main') {
      return false;
    }
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final seriesList = List<String>.from(raw['series'] ?? ['Main']);
    seriesList.removeWhere((s) => s.trim().toLowerCase() == seriesName.trim().toLowerCase());
    if (!seriesList.contains('Main')) {
      seriesList.insert(0, 'Main');
    }

    final settingsMap = Map<String, dynamic>.from(raw['seriesSettings'] ?? {});
    settingsMap.remove(seriesName);

    raw['series'] = seriesList;
    raw['seriesSettings'] = settingsMap;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
    return true;
  }

  /// Adds a simple master item (material centers, account groups, bill sundries, etc.).
  static Future<bool> addSimpleMaster({
    required String folderPath,
    required String key,
    required String value,
  }) async {
    final clean = value.trim();
    if (clean.isEmpty) return false;

    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final list = List<String>.from(raw[key] ?? []);
    if (list.any((e) => e.trim().toLowerCase() == clean.toLowerCase())) {
      return false;
    }
    list.add(clean);
    raw[key] = list;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
    return true;
  }

  /// Updates a simple master item.
  static Future<bool> updateSimpleMaster({
    required String folderPath,
    required String key,
    required String oldValue,
    required String newValue,
  }) async {
    final cleanOld = oldValue.trim();
    final cleanNew = newValue.trim();
    if (cleanNew.isEmpty || cleanOld.toLowerCase() == cleanNew.toLowerCase()) {
      return false;
    }

    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final list = List<String>.from(raw[key] ?? []);
    final idx = list.indexWhere((e) => e.trim().toLowerCase() == cleanOld.toLowerCase());
    if (idx != -1) {
      list[idx] = cleanNew;
    } else {
      list.add(cleanNew);
    }
    raw[key] = list;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
    return true;
  }

  /// Deletes a simple master item.
  static Future<void> deleteSimpleMaster({
    required String folderPath,
    required String key,
    required String value,
  }) async {
    final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
    final list = List<String>.from(raw[key] ?? []);
    list.removeWhere((e) => e.trim().toLowerCase() == value.trim().toLowerCase());
    raw[key] = list;

    await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  }
}