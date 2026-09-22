import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/app_date_utils.dart';
import 'company_directory_service.dart';

class StorageService {
  /// One open [AppDatabase] per company folder, keyed by folderId. Kept
  /// alive across calls so switching back to a company doesn't reopen the
  /// file every time; closed explicitly on directory migration.
  static final Map<String, Future<AppDatabase>> _dbCache = {};
  static final Map<int, Map<String, dynamic>> _masterExtras = {};

  static Future<AppDatabase?> _dbFor(String? folderPath) async {
    final folderId = _folderId(folderPath);
    if (folderId == null) return null;
    return _dbCache.putIfAbsent(folderId, () async {
      final root = await CompanyDirectoryService.getRootDirectory();
      final file = CompanyDirectoryService.companyDbFile(root, folderId);
      return AppDatabase.forFile(file);
    });
  }

  static String? _folderId(String? folderPath) {
    final s = folderPath?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  /// Closes every open company DB connection. Must be called before moving
  /// or deleting files on disk (e.g. directory migration) to release locks.
  static Future<void> closeAll() async {
    for (final future in _dbCache.values) {
      final db = await future;
      await db.close();
    }
    _dbCache.clear();
  }

  /// The single company row inside a per-company DB — created once when the
  /// company folder is set up, always id 1 in practice but fetched to be safe.
  static Future<int> _requireCompanyId(AppDatabase db) async {
    final row = await db.select(db.companies).getSingleOrNull();
    if (row == null) throw StateError('Company database has no company row');
    return row.id;
  }

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
      },
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
      'BAG',
      'BAL',
      'BDL',
      'BOX',
      'BTL',
      'BUN',
      'CAN',
      'CBM',
      'CCM',
      'CMS',
      'CTN',
      'DOZ',
      'DRM',
      'GGK',
      'GMS',
      'GRS',
      'GYD',
      'KGS',
      'KLR',
      'KME',
      'MLT',
      'MTR',
      'MTS',
      'NOS',
      'PAC',
      'PCS',
      'PRS',
      'QTL',
      'ROL',
      'SET',
      'SQF',
      'SQM',
      'SQY',
      'TBS',
      'TGM',
      'THD',
      'TON',
      'TUB',
      'UGS',
      'UNT',
      'YDS',
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
    'materialCenters': ['Main Store', 'Warehouse', 'Godown'],
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

  /// Root directory holding all company folders (saved pref, or a sane
  /// default under the app's own documents dir — never bare "C:\").
  static Future<String?> getSavedDirectory() =>
      CompanyDirectoryService.getRootDirectory();

  /// Directory migration: closes all open company DBs, moves every company
  /// folder from the current root to [path], and remembers [path]. Safe to
  /// call with the same path (no-op move).
  static Future<void> saveDirectory(String path) async {
    final oldRoot = await CompanyDirectoryService.getRootDirectory();
    await closeAll(); // release SQLite file locks before moving files
    await CompanyDirectoryService.migrateRoot(oldRoot, path);
  }

  static String normalizeFySlug(String fy) =>
      fy.replaceAll(' ', '_').replaceAll('/', '-');

  static Future<String> getNextCompanyFolderId(String baseDirectoryPath) =>
      CompanyDirectoryService.nextFolderId(baseDirectoryPath);

  static Future<String> saveCompanyLocally({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    final fy =
        (companyData['activeFinancialYear'] ??
                AppDateUtils.defaultFinancialYear)
            .toString();
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    final name = (companyData['companyName'] ?? companyData['name'] ?? 'Untitled Company').toString();
    final gstin = _blankToNull(companyData['gstin'] ?? companyData['gstNumber']);

    final folderId = await CompanyDirectoryService.nextFolderId(directoryPath);
    await CompanyDirectoryService.ensureCompanyFolder(directoryPath, folderId);
    final db = (await _dbFor(folderId))!;

    final companyId = await db.into(db.companies).insert(
          CompaniesCompanion.insert(
            uuid: db.newUuid(),
            name: name,
            fyStart: bounds.startDate,
            gstin: Value(gstin),
            addressJson: Value(_addressJson(companyData)),
          ),
        );
    await _seedCompanyMasters(db, companyId);
    _masterExtras[companyId] = _defaultExtras();

    await CompanyDirectoryService.upsertRegistryEntry(directoryPath, {
      'folder': folderId,
      'companyName': name,
      'name': name,
      'gstin': gstin ?? '',
      'fyStart': bounds.startDate.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    return folderId;
  }

  static Future<void> updateCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final folderId = companyData['folderPath'] ?? companyData['companyId'];
    final db = await _dbFor(folderId?.toString());
    if (db == null) return;
    final companyId = await _requireCompanyId(db);
    final fy =
        (companyData['activeFinancialYear'] ??
                AppDateUtils.defaultFinancialYear)
            .toString();
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    final name = (companyData['companyName'] ?? companyData['name'] ?? 'Untitled Company').toString();
    final gstin = _blankToNull(companyData['gstin'] ?? companyData['gstNumber']);
    await (db.update(
      db.companies,
    )..where((c) => c.id.equals(companyId))).write(
      CompaniesCompanion(
        name: Value(name),
        gstin: Value(gstin),
        fyStart: Value(bounds.startDate),
        addressJson: Value(_addressJson(companyData)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final root = await CompanyDirectoryService.getRootDirectory();
    await CompanyDirectoryService.upsertRegistryEntry(root, {
      'folder': folderId.toString(),
      'companyName': name,
      'name': name,
      'gstin': gstin ?? '',
      'fyStart': bounds.startDate.toIso8601String(),
    });
  }

  static Future<void> deleteCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final folderId = (companyData['folderPath'] ?? companyData['companyId'])?.toString();
    if (folderId == null) return;
    final db = await _dbFor(folderId);
    if (db != null) {
      final companyId = await _requireCompanyId(db);
      await db.softDelete(db.companies, companyId);
    }
    final root = await CompanyDirectoryService.getRootDirectory();
    await CompanyDirectoryService.markDeleted(root, folderId);
  }

  static Future<Map<String, dynamic>> loadCompanyMasters({
    required String folderPath,
  }) async {
    final db = await _dbFor(folderPath);
    if (db == null) return Map<String, dynamic>.from(defaultCompanyMasters);
    final companyId = await _requireCompanyId(db);
    await _seedCompanyMasters(db, companyId);

    final groups =
        await (db.select(db.accountGroups)..where(
              (g) => g.companyId.equals(companyId) & g.deletedAt.isNull(),
            ))
            .get();
    final groupById = {for (final g in groups) g.id: g};
    final accounts =
        await (db.select(db.accounts)..where(
              (a) => a.companyId.equals(companyId) & a.deletedAt.isNull(),
            ))
            .get();
    final items =
        await (db.select(db.items)..where(
              (i) => i.companyId.equals(companyId) & i.deletedAt.isNull(),
            ))
            .get();
    final godowns =
        await (db.select(db.godowns)..where(
              (g) => g.companyId.equals(companyId) & g.deletedAt.isNull(),
            ))
            .get();

    final extras = Map<String, dynamic>.from(_defaultExtras())
      ..addAll(_masterExtras[companyId] ?? {});
    final debtors = <Map<String, dynamic>>[];
    final creditors = <Map<String, dynamic>>[];
    for (final a in accounts) {
      final groupName = groupById[a.groupId]?.name ?? '';
      final row = {'name': a.name, 'gstin': a.gstin ?? '', 'group': groupName};
      if (groupName.toLowerCase().contains('debtor') ||
          groupName.toLowerCase().contains('cash'))
        debtors.add(row);
      if (groupName.toLowerCase().contains('creditor') ||
          groupName.toLowerCase().contains('cash'))
        creditors.add(row);
    }

    return {
      ...extras,
      'debtors': debtors.isEmpty ? defaultCompanyMasters['debtors'] : debtors,
      'creditors': creditors.isEmpty
          ? defaultCompanyMasters['creditors']
          : creditors,
      'items': items
          .map(
            (i) => {
              'name': i.name,
              'hsn': i.hsnCode ?? '',
              'unit': i.unit,
              'taxCategory': 'GST ${_fmtRate(i.gstRate)}%',
              'taxRate': i.gstRate,
              'salesPrice': i.openingRate,
              'purchasePrice': i.openingRate,
              'mrp': i.openingRate,
            },
          )
          .toList(),
      'materialCenters': godowns
          .map((g) => g.name)
          .toList()
          .ifEmpty(defaultCompanyMasters['materialCenters'] as List),
      'accountGroups': groups.map((g) => g.name).toList(),
    };
  }

  static Future<void> saveCompanyMasters({
    required String folderPath,
    required Map<String, dynamic> mastersData,
  }) async {
    final db = await _dbFor(folderPath);
    if (db == null) return;
    final companyId = await _requireCompanyId(db);
    _masterExtras[companyId] = Map<String, dynamic>.from(mastersData)
      ..remove('debtors')
      ..remove('creditors')
      ..remove('items')
      ..remove('accountGroups')
      ..remove('materialCenters');
    await _seedCompanyMasters(
      db,
      companyId,
      groupNames: (mastersData['accountGroups'] as List? ?? []).map(
        (e) => e.toString(),
      ),
    );
    for (final p in [
      ...(mastersData['debtors'] as List? ?? []),
      ...(mastersData['creditors'] as List? ?? []),
    ]) {
      if (p is Map)
        await _ensureAccount(
          db,
          companyId,
          p['name']?.toString() ?? '',
          p['group']?.toString() ?? 'Sundry Debtors',
          gstin: p['gstin']?.toString(),
        );
    }
    for (final item in (mastersData['items'] as List? ?? [])) {
      if (item is Map) {
        await _ensureItem(
          db,
          companyId,
          item['name']?.toString() ?? '',
          hsn: item['hsn']?.toString(),
          unit: item['unit']?.toString() ?? 'PCS',
          gstRate: _num(item['taxRate']),
        );
      }
    }
    for (final g in (mastersData['materialCenters'] as List? ?? [])) {
      await _ensureGodown(db, companyId, g.toString());
    }
  }

  static String resolveVoucherFileName(
    String voucherType, [
    String? seriesName,
  ]) => voucherType;

  static Future<void> saveVoucher({
    required String folderPath,
    required String financialYear,
    required Map<String, dynamic> voucherData,
  }) async {
    final db = await _dbFor(folderPath);
    if (db == null) return;
    final companyId = await _requireCompanyId(db);
    await _seedCompanyMasters(db, companyId);
    final voucherTypeId = await _ensureVoucherType(
      db,
      companyId,
      voucherData['voucherType']?.toString() ?? 'Sales',
    );
    final partyId = await _ensurePartyFromVoucher(db, companyId, voucherData);
    final date =
        AppDateUtils.parseDate(voucherData['date']?.toString()) ??
        DateTime.now();
    final voucherNo = (voucherData['voucherNumber'] ?? '').toString();
    final uuid = (voucherData['id'] ?? '').toString();

    await db.transaction(() async {
      var voucherId = await _findVoucherId(
        db,
        companyId,
        voucherTypeId,
        uuid,
        voucherNo,
      );
      if (voucherId == null) {
        voucherId = await db
            .into(db.vouchers)
            .insert(
              VouchersCompanion.insert(
                uuid: uuid.length == 36 ? uuid : db.newUuid(),
                companyId: companyId,
                voucherTypeId: voucherTypeId,
                voucherNumber: voucherNo,
                voucherDate: date,
                partyId: Value(partyId),
                narration: Value(voucherData['narration']?.toString()),
                referenceNumber: Value(voucherData['series']?.toString()),
              ),
            );
      } else {
        await (db.update(
          db.vouchers,
        )..where((v) => v.id.equals(voucherId!))).write(
          VouchersCompanion(
            voucherNumber: Value(voucherNo),
            voucherDate: Value(date),
            partyId: Value(partyId),
            narration: Value(voucherData['narration']?.toString()),
            referenceNumber: Value(voucherData['series']?.toString()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        final existingVoucherId = voucherId;
        await (db.delete(
          db.voucherEntries,
        )..where((e) => e.voucherId.equals(existingVoucherId))).go();
      }
      for (final line in await _voucherLines(db, companyId, voucherData, partyId)) {
        await db
            .into(db.voucherEntries)
            .insert(
              VoucherEntriesCompanion.insert(
                uuid: db.newUuid(),
                voucherId: voucherId,
                accountId: line.accountId,
                drCr: line.drCr,
                amount: line.amount,
                itemId: Value(line.itemId),
                godownId: Value(line.godownId),
                qty: Value(line.qty),
                rate: Value(line.rate),
              ),
            );
      }
    });
  }

  static Future<void> saveAllVouchers({
    required String folderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
    required List<Map<String, dynamic>> vouchers,
  }) async {
    final db = await _dbFor(folderPath);
    if (db == null) return;
    final companyId = await _requireCompanyId(db);
    final typeId = await _ensureVoucherType(db, companyId, voucherType);
    final rows =
        await (db.select(db.vouchers)..where(
              (v) =>
                  v.companyId.equals(companyId) &
                  v.voucherTypeId.equals(typeId),
            ))
            .get();
    final keep = vouchers
        .map((v) => (v['id'] ?? v['voucherNumber']).toString())
        .toSet();
    for (final row in rows) {
      if (!keep.contains(row.uuid) && !keep.contains(row.voucherNumber))
        await db.softDelete(db.vouchers, row.id);
    }
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
    required String folderPath,
    required String financialYear,
    String? voucherType,
    String? seriesName,
  }) async {
    final db = await _dbFor(folderPath);
    if (db == null) return [];
    final companyId = await _requireCompanyId(db);
    final query = db.select(db.vouchers)
      ..where((v) => v.companyId.equals(companyId) & v.deletedAt.isNull());
    if (voucherType != null) {
      final typeId = await _ensureVoucherType(db, companyId, voucherType);
      query.where((v) => v.voucherTypeId.equals(typeId));
    }
    query.orderBy([
      (v) => OrderingTerm.desc(v.voucherDate),
      (v) => OrderingTerm.desc(v.id),
    ]);
    final vouchers = await query.get();
    final types = await (db.select(
      db.voucherTypes,
    )..where((t) => t.companyId.equals(companyId))).get();
    final typeById = {for (final t in types) t.id: t.name};
    final out = <Map<String, dynamic>>[];
    for (final v in vouchers) {
      out.add(
        await _voucherToMap(
          db,
          v,
          typeById[v.voucherTypeId] ?? voucherType ?? 'Voucher',
        ),
      );
    }
    return out;
  }

  /// Fast list for the home screen: reads the JSON registry only — no
  /// per-company SQLite file is opened just to show "recent companies".
  static Future<List<Map<String, dynamic>>> loadCompanies(
    String directoryPath,
  ) async {
    final entries = await CompanyDirectoryService.listCompanies(directoryPath);
    return entries.map((c) {
      final fyStart = DateTime.tryParse(c['fyStart']?.toString() ?? '') ?? DateTime.now();
      final fy = '${fyStart.year}-${(fyStart.year + 1).toString().substring(2)}';
      final folder = c['folder'].toString();
      return {
        'id': folder,
        'companyId': folder,
        'folderPath': folder,
        'companyName': c['companyName'] ?? c['name'] ?? '',
        'name': c['name'] ?? c['companyName'] ?? '',
        'gstin': c['gstin'] ?? '',
        'financialYears': AppDateUtils.defaultFinancialYears,
        'activeFinancialYear': fy,
      };
    }).toList();
  }

  static Future<void> _seedCompanyMasters(
    AppDatabase db,
    int companyId, {
    Iterable<String> groupNames = const [],
  }) async {
    const defaults = {
      'Capital Account': 'equity',
      'Current Assets': 'asset',
      'Current Liabilities': 'liability',
      'Sundry Debtors': 'asset',
      'Sundry Creditors': 'liability',
      'Bank Accounts': 'asset',
      'Cash-in-hand': 'asset',
      'Sales Accounts': 'income',
      'Purchase Accounts': 'expense',
      'Direct Expenses': 'expense',
      'Indirect Expenses': 'expense',
    };
    for (final name in {
      ...defaults.keys,
      ...groupNames.where((e) => e.trim().isNotEmpty),
    }) {
      await _ensureGroup(db, companyId, name, defaults[name] ?? 'expense');
    }
    await _ensureAccount(db, companyId, 'Cash', 'Cash-in-hand');
    await _ensureAccount(db, companyId, 'Sales', 'Sales Accounts');
    await _ensureAccount(db, companyId, 'Purchase', 'Purchase Accounts');
    for (final t in [
      'CGST',
      'SGST',
      'IGST',
      'Round Off+',
      'Round Off-',
      'Discount',
      'Freight & Forwarding Charges',
    ]) {
      await _ensureAccount(
        db,
        companyId,
        t,
        t == 'Discount' ? 'Direct Expenses' : 'Current Liabilities',
      );
    }
    await _ensureGodown(db, companyId, 'Main Store');
  }

  static Future<int> _ensureGroup(
    AppDatabase db,
    int companyId,
    String name,
    String nature,
  ) async {
    final existing =
        await (db.select(db.accountGroups)..where(
              (g) => g.companyId.equals(companyId) & g.name.equals(name),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.accountGroups)
        .insert(
          AccountGroupsCompanion.insert(
            uuid: db.newUuid(),
            companyId: companyId,
            name: name,
            nature: nature,
            isSystem: const Value(true),
          ),
        );
  }

  static Future<int> _ensureAccount(
    AppDatabase db,
    int companyId,
    String name,
    String groupName, {
    String? gstin,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return _ensureAccount(db, companyId, 'Cash', 'Cash-in-hand');
    final existing =
        await (db.select(db.accounts)..where(
              (a) => a.companyId.equals(companyId) & a.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    final groupId = await _ensureGroup(
      db,
      companyId,
      groupName,
      _natureForGroup(groupName),
    );
    return db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: db.newUuid(),
            companyId: companyId,
            groupId: groupId,
            name: clean,
            gstin: Value(_blankToNull(gstin)),
          ),
        );
  }

  static Future<int> _ensureItem(
    AppDatabase db,
    int companyId,
    String name, {
    String? hsn,
    String unit = 'PCS',
    double gstRate = 0,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return 0;
    final existing =
        await (db.select(db.items)..where(
              (i) => i.companyId.equals(companyId) & i.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            uuid: db.newUuid(),
            companyId: companyId,
            name: clean,
            hsnCode: Value(_blankToNull(hsn)),
            unit: Value(unit),
            gstRate: Value(gstRate),
          ),
        );
  }

  static Future<int> _ensureGodown(AppDatabase db, int companyId, String name) async {
    final clean = name.trim();
    final existing =
        await (db.select(db.godowns)..where(
              (g) => g.companyId.equals(companyId) & g.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.godowns)
        .insert(
          GodownsCompanion.insert(
            uuid: db.newUuid(),
            companyId: companyId,
            name: clean,
          ),
        );
  }

  static Future<int> _ensureVoucherType(AppDatabase db, int companyId, String name) async {
    final clean = name.trim().isEmpty ? 'Voucher' : name.trim();
    final existing =
        await (db.select(db.voucherTypes)..where(
              (t) => t.companyId.equals(companyId) & t.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.voucherTypes)
        .insert(
          VoucherTypesCompanion.insert(
            uuid: db.newUuid(),
            companyId: companyId,
            name: clean,
            nature: _voucherNature(clean),
            abbreviation: Value(clean.substring(0, 1).toUpperCase()),
          ),
        );
  }

  static Future<int> _ensurePartyFromVoucher(
    AppDatabase db,
    int companyId,
    Map<String, dynamic> voucher,
  ) {
    final party = (voucher['party'] ?? 'Cash').toString();
    final name = party.split(' - ').first.trim();
    final gstin = party.contains(' - ') ? party.split(' - ').last.trim() : null;
    final group = _isSales(voucher['voucherType']?.toString() ?? '')
        ? 'Sundry Debtors'
        : 'Sundry Creditors';
    return _ensureAccount(
      db,
      companyId,
      name.isEmpty ? 'Cash' : name,
      group,
      gstin: gstin,
    );
  }

  static Future<int?> _findVoucherId(
    AppDatabase db,
    int companyId,
    int voucherTypeId,
    String uuid,
    String number,
  ) async {
    if (uuid.length == 36) {
      final byUuid = await (db.select(
        db.vouchers,
      )..where((v) => v.uuid.equals(uuid))).getSingleOrNull();
      if (byUuid != null) return byUuid.id;
    }
    final byNumber =
        await (db.select(db.vouchers)..where(
              (v) =>
                  v.companyId.equals(companyId) &
                  v.voucherTypeId.equals(voucherTypeId) &
                  v.voucherNumber.equals(number),
            ))
            .getSingleOrNull();
    return byNumber?.id;
  }

  static Future<List<_DbVoucherLine>> _voucherLines(
    AppDatabase db,
    int companyId,
    Map<String, dynamic> v,
    int partyId,
  ) async {
    final isSales = _isSales(v['voucherType']?.toString() ?? '');
    final salesOrPurchase = await _ensureAccount(
      db,
      companyId,
      isSales ? 'Sales' : 'Purchase',
      isSales ? 'Sales Accounts' : 'Purchase Accounts',
    );
    final godownId = await _ensureGodown(
      db,
      companyId,
      (v['materialCenter'] ?? 'Main Store').toString(),
    );
    final lines = <_DbVoucherLine>[];
    final grand = _num(v['grandTotal']);
    if (grand > 0)
      lines.add(_DbVoucherLine(partyId, isSales ? 'dr' : 'cr', grand));
    for (final item in (v['items'] as List? ?? [])) {
      if (item is! Map) continue;
      final amount = _num(item['taxable']);
      final itemId = await _ensureItem(
        db,
        companyId,
        item['item']?.toString() ?? '',
        hsn: item['hsn']?.toString(),
        unit: item['unit']?.toString() ?? 'PCS',
        gstRate: _num(item['gstRate']),
      );
      if (amount > 0)
        lines.add(
          _DbVoucherLine(
            salesOrPurchase,
            isSales ? 'cr' : 'dr',
            amount,
            itemId: itemId == 0 ? null : itemId,
            godownId: godownId,
            qty: _num(item['qty']),
            rate: _num(item['price']),
          ),
        );
    }
    for (final tax in ['cgst', 'sgst', 'igst']) {
      final amount = _num(v[tax]);
      if (amount > 0)
        lines.add(
          _DbVoucherLine(
            await _ensureAccount(
              db,
              companyId,
              tax.toUpperCase(),
              'Current Liabilities',
            ),
            isSales ? 'cr' : 'dr',
            amount,
          ),
        );
    }
    for (final s in (v['sundries'] as List? ?? [])) {
      if (s is! Map) continue;
      final amount = _num(s['amount']);
      if (amount <= 0) continue;
      final name = s['name']?.toString() ?? 'Sundry';
      final negative = s['isNegative'] == true || name.contains('-');
      lines.add(
        _DbVoucherLine(
          await _ensureAccount(
            db,
            companyId,
            name,
            negative ? 'Direct Expenses' : 'Current Liabilities',
          ),
          (isSales ^ negative) ? 'cr' : 'dr',
          amount,
        ),
      );
    }
    final dr = lines
        .where((l) => l.drCr == 'dr')
        .fold(0.0, (s, l) => s + l.amount);
    final cr = lines
        .where((l) => l.drCr == 'cr')
        .fold(0.0, (s, l) => s + l.amount);
    final diff = double.parse((dr - cr).toStringAsFixed(2));
    if (diff.abs() > 0.01)
      lines.add(
        _DbVoucherLine(
          await _ensureAccount(
            db,
            companyId,
            diff > 0 ? 'Round Off-' : 'Round Off+',
            'Current Liabilities',
          ),
          diff > 0 ? 'cr' : 'dr',
          diff.abs(),
        ),
      );
    return lines;
  }

  static Future<Map<String, dynamic>> _voucherToMap(
    AppDatabase db,
    Voucher v,
    String typeName,
  ) async {
    final entries = await (db.select(
      db.voucherEntries,
    )..where((e) => e.voucherId.equals(v.id))).get();
    final accounts = await db.select(db.accounts).get();
    final items = await db.select(db.items).get();
    final accById = {for (final a in accounts) a.id: a};
    final itemById = {for (final i in items) i.id: i};
    final party = v.partyId == null ? '' : accById[v.partyId]?.name ?? '';
    final itemRows = entries.where((e) => e.itemId != null).map((e) {
      final item = itemById[e.itemId];
      return {
        'item': item?.name ?? '',
        'hsn': item?.hsnCode ?? '',
        'qty': e.qty?.toString() ?? '',
        'unit': item?.unit ?? 'PCS',
        'price': e.rate?.toString() ?? '',
        'taxable': e.amount.toStringAsFixed(2),
        'cgst': '',
        'sgst': '',
        'igst': '',
        'amount': e.amount.toStringAsFixed(2),
        'gstRate': item?.gstRate ?? 0,
      };
    }).toList();
    final total = entries
        .where((e) => e.accountId == v.partyId)
        .fold(0.0, (s, e) => s + e.amount);
    return {
      'id': v.uuid,
      'voucherType': typeName,
      'voucherNumber': v.voucherNumber,
      'date': AppDateUtils.formatDate(v.voucherDate),
      'series': v.referenceNumber ?? 'Main',
      'party': party,
      'narration': v.narration ?? '',
      'items': itemRows,
      'sundries': [],
      'subTotal': itemRows.fold(0.0, (s, i) => s + _num(i['taxable'])),
      'cgst': 0.0,
      'sgst': 0.0,
      'igst': 0.0,
      'totalTax': 0.0,
      'sundryTotal': 0.0,
      'roundOff': 0.0,
      'grandTotal': total,
      'createdAt': v.createdAt.toIso8601String(),
    };
  }

  static String _natureForGroup(String group) {
    final g = group.toLowerCase();
    if (g.contains('debtor') ||
        g.contains('cash') ||
        g.contains('bank') ||
        g.contains('asset'))
      return 'asset';
    if (g.contains('creditor') || g.contains('liabilit')) return 'liability';
    if (g.contains('sales') || g.contains('income')) return 'income';
    if (g.contains('capital')) return 'equity';
    return 'expense';
  }

  static String _voucherNature(String type) =>
      type.toLowerCase().contains('purchase')
      ? 'purchase'
      : type.toLowerCase().contains('payment')
      ? 'payment'
      : type.toLowerCase().contains('receipt')
      ? 'receipt'
      : type.toLowerCase().contains('journal')
      ? 'journal'
      : type.toLowerCase().contains('contra')
      ? 'contra'
      : 'sales';
  static bool _isSales(String type) => type.toLowerCase().contains('sale');
  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
  static String _fmtRate(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();
  static String? _blankToNull(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static String? _addressJson(Map<String, dynamic> company) => jsonEncode({
    'address': company['address'],
    'state': company['state'] ?? company['stateName'],
    'pincode': company['pincode'],
  });
  static Map<String, dynamic> _defaultExtras() =>
      Map<String, dynamic>.from(defaultCompanyMasters)
        ..remove('debtors')
        ..remove('creditors')
        ..remove('items')
        ..remove('accountGroups')
        ..remove('materialCenters');
}

class _DbVoucherLine {
  final int accountId;
  final String drCr;
  final double amount;
  final int? itemId;
  final int? godownId;
  final double? qty;
  final double? rate;

  const _DbVoucherLine(
    this.accountId,
    this.drCr,
    this.amount, {
    this.itemId,
    this.godownId,
    this.qty,
    this.rate,
  });
}

extension _ListFallback on List {
  List ifEmpty(List fallback) => isEmpty ? fallback : this;
}
