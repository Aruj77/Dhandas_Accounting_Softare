import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../utils/app_date_utils.dart';

class StorageService {
  static const String _prefDirectoryKey = 'dhandas_data_directory_path';
  static final AppDatabase _db = AppDatabase();
  static final Map<int, Map<String, dynamic>> _masterExtras = {};

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

  static Future<String?> getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefDirectoryKey) ?? 'sqlite';
  }

  static Future<void> saveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDirectoryKey, path);
  }

  static String normalizeFySlug(String fy) =>
      fy.replaceAll(' ', '_').replaceAll('/', '-');

  static Future<String> getNextCompanyFolderId(String baseDirectoryPath) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM companies',
        )
        .getSingle();
    return 'DB-${row.read<int>('next_id').toString().padLeft(4, '0')}';
  }

  static Future<String> saveCompanyLocally({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    final fy =
        (companyData['activeFinancialYear'] ??
                AppDateUtils.defaultFinancialYear)
            .toString();
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    final companyId = await _db
        .into(_db.companies)
        .insert(
          CompaniesCompanion.insert(
            uuid: _db.newUuid(),
            name:
                (companyData['companyName'] ??
                        companyData['name'] ??
                        'Untitled Company')
                    .toString(),
            fyStart: bounds.startDate,
            gstin: Value(
              _blankToNull(companyData['gstin'] ?? companyData['gstNumber']),
            ),
            addressJson: Value(_addressJson(companyData)),
          ),
        );
    await _seedCompanyMasters(companyId);
    _masterExtras[companyId] = _defaultExtras();
    return 'db:$companyId';
  }

  static Future<void> updateCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final companyId = await _companyIdFromAny(
      companyData['folderPath'] ?? companyData['companyId'],
    );
    if (companyId == null) return;
    final fy =
        (companyData['activeFinancialYear'] ??
                AppDateUtils.defaultFinancialYear)
            .toString();
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    await (_db.update(
      _db.companies,
    )..where((c) => c.id.equals(companyId))).write(
      CompaniesCompanion(
        name: Value(
          (companyData['companyName'] ??
                  companyData['name'] ??
                  'Untitled Company')
              .toString(),
        ),
        gstin: Value(
          _blankToNull(companyData['gstin'] ?? companyData['gstNumber']),
        ),
        fyStart: Value(bounds.startDate),
        addressJson: Value(_addressJson(companyData)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static Future<void> deleteCompanyLocally({
    required Map<String, dynamic> companyData,
  }) async {
    final companyId = await _companyIdFromAny(
      companyData['folderPath'] ?? companyData['companyId'],
    );
    if (companyId != null) await _db.softDelete(_db.companies, companyId);
  }

  static Future<Map<String, dynamic>> loadCompanyMasters({
    required String folderPath,
  }) async {
    final companyId = await _companyIdFromAny(folderPath);
    if (companyId == null)
      return Map<String, dynamic>.from(defaultCompanyMasters);
    await _seedCompanyMasters(companyId);

    final groups =
        await (_db.select(_db.accountGroups)..where(
              (g) => g.companyId.equals(companyId) & g.deletedAt.isNull(),
            ))
            .get();
    final groupById = {for (final g in groups) g.id: g};
    final accounts =
        await (_db.select(_db.accounts)..where(
              (a) => a.companyId.equals(companyId) & a.deletedAt.isNull(),
            ))
            .get();
    final items =
        await (_db.select(_db.items)..where(
              (i) => i.companyId.equals(companyId) & i.deletedAt.isNull(),
            ))
            .get();
    final godowns =
        await (_db.select(_db.godowns)..where(
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
    final companyId = await _companyIdFromAny(folderPath);
    if (companyId == null) return;
    _masterExtras[companyId] = Map<String, dynamic>.from(mastersData)
      ..remove('debtors')
      ..remove('creditors')
      ..remove('items')
      ..remove('accountGroups')
      ..remove('materialCenters');
    await _seedCompanyMasters(
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
          companyId,
          p['name']?.toString() ?? '',
          p['group']?.toString() ?? 'Sundry Debtors',
          gstin: p['gstin']?.toString(),
        );
    }
    for (final item in (mastersData['items'] as List? ?? [])) {
      if (item is Map) {
        await _ensureItem(
          companyId,
          item['name']?.toString() ?? '',
          hsn: item['hsn']?.toString(),
          unit: item['unit']?.toString() ?? 'PCS',
          gstRate: _num(item['taxRate']),
        );
      }
    }
    for (final g in (mastersData['materialCenters'] as List? ?? [])) {
      await _ensureGodown(companyId, g.toString());
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
    final companyId = await _companyIdFromAny(folderPath);
    if (companyId == null) return;
    await _seedCompanyMasters(companyId);
    final voucherTypeId = await _ensureVoucherType(
      companyId,
      voucherData['voucherType']?.toString() ?? 'Sales',
    );
    final partyId = await _ensurePartyFromVoucher(companyId, voucherData);
    final date =
        AppDateUtils.parseDate(voucherData['date']?.toString()) ??
        DateTime.now();
    final voucherNo = (voucherData['voucherNumber'] ?? '').toString();
    final uuid = (voucherData['id'] ?? '').toString();

    await _db.transaction(() async {
      var voucherId = await _findVoucherId(
        companyId,
        voucherTypeId,
        uuid,
        voucherNo,
      );
      if (voucherId == null) {
        voucherId = await _db
            .into(_db.vouchers)
            .insert(
              VouchersCompanion.insert(
                uuid: uuid.length == 36 ? uuid : _db.newUuid(),
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
        await (_db.update(
          _db.vouchers,
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
        await (_db.delete(
          _db.voucherEntries,
        )..where((e) => e.voucherId.equals(existingVoucherId))).go();
      }
      for (final line in await _voucherLines(companyId, voucherData, partyId)) {
        await _db
            .into(_db.voucherEntries)
            .insert(
              VoucherEntriesCompanion.insert(
                uuid: _db.newUuid(),
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
    final companyId = await _companyIdFromAny(folderPath);
    if (companyId == null) return;
    final typeId = await _ensureVoucherType(companyId, voucherType);
    final rows =
        await (_db.select(_db.vouchers)..where(
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
        await _db.softDelete(_db.vouchers, row.id);
    }
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
    required String folderPath,
    required String financialYear,
    String? voucherType,
    String? seriesName,
  }) async {
    final companyId = await _companyIdFromAny(folderPath);
    if (companyId == null) return [];
    final query = _db.select(_db.vouchers)
      ..where((v) => v.companyId.equals(companyId) & v.deletedAt.isNull());
    if (voucherType != null) {
      final typeId = await _ensureVoucherType(companyId, voucherType);
      query.where((v) => v.voucherTypeId.equals(typeId));
    }
    query.orderBy([
      (v) => OrderingTerm.desc(v.voucherDate),
      (v) => OrderingTerm.desc(v.id),
    ]);
    final vouchers = await query.get();
    final types = await (_db.select(
      _db.voucherTypes,
    )..where((t) => t.companyId.equals(companyId))).get();
    final typeById = {for (final t in types) t.id: t.name};
    final out = <Map<String, dynamic>>[];
    for (final v in vouchers) {
      out.add(
        await _voucherToMap(
          v,
          typeById[v.voucherTypeId] ?? voucherType ?? 'Voucher',
        ),
      );
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> loadCompanies(
    String directoryPath,
  ) async {
    final rows = await (_db.select(
      _db.companies,
    )..where((c) => c.deletedAt.isNull())).get();
    return rows.map((c) {
      final fy =
          '${c.fyStart.year}-${(c.fyStart.year + 1).toString().substring(2)}';
      return {
        'id': c.id,
        'companyId': 'db:${c.id}',
        'folderPath': 'db:${c.id}',
        'companyName': c.name,
        'name': c.name,
        'gstin': c.gstin ?? '',
        'financialYears': AppDateUtils.defaultFinancialYears,
        'activeFinancialYear': fy,
      };
    }).toList();
  }

  static Future<int?> _companyIdFromAny(Object? value) async {
    final s = value?.toString() ?? '';
    if (s.startsWith('db:')) return int.tryParse(s.substring(3));
    if (s.startsWith('DB-')) return int.tryParse(s.substring(3));
    return int.tryParse(s);
  }

  static Future<void> _seedCompanyMasters(
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
      await _ensureGroup(companyId, name, defaults[name] ?? 'expense');
    }
    await _ensureAccount(companyId, 'Cash', 'Cash-in-hand');
    await _ensureAccount(companyId, 'Sales', 'Sales Accounts');
    await _ensureAccount(companyId, 'Purchase', 'Purchase Accounts');
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
        companyId,
        t,
        t == 'Discount' ? 'Direct Expenses' : 'Current Liabilities',
      );
    }
    await _ensureGodown(companyId, 'Main Store');
  }

  static Future<int> _ensureGroup(
    int companyId,
    String name,
    String nature,
  ) async {
    final existing =
        await (_db.select(_db.accountGroups)..where(
              (g) => g.companyId.equals(companyId) & g.name.equals(name),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.accountGroups)
        .insert(
          AccountGroupsCompanion.insert(
            uuid: _db.newUuid(),
            companyId: companyId,
            name: name,
            nature: nature,
            isSystem: const Value(true),
          ),
        );
  }

  static Future<int> _ensureAccount(
    int companyId,
    String name,
    String groupName, {
    String? gstin,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return _ensureAccount(companyId, 'Cash', 'Cash-in-hand');
    final existing =
        await (_db.select(_db.accounts)..where(
              (a) => a.companyId.equals(companyId) & a.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    final groupId = await _ensureGroup(
      companyId,
      groupName,
      _natureForGroup(groupName),
    );
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: _db.newUuid(),
            companyId: companyId,
            groupId: groupId,
            name: clean,
            gstin: Value(_blankToNull(gstin)),
          ),
        );
  }

  static Future<int> _ensureItem(
    int companyId,
    String name, {
    String? hsn,
    String unit = 'PCS',
    double gstRate = 0,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return 0;
    final existing =
        await (_db.select(_db.items)..where(
              (i) => i.companyId.equals(companyId) & i.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.items)
        .insert(
          ItemsCompanion.insert(
            uuid: _db.newUuid(),
            companyId: companyId,
            name: clean,
            hsnCode: Value(_blankToNull(hsn)),
            unit: Value(unit),
            gstRate: Value(gstRate),
          ),
        );
  }

  static Future<int> _ensureGodown(int companyId, String name) async {
    final clean = name.trim();
    final existing =
        await (_db.select(_db.godowns)..where(
              (g) => g.companyId.equals(companyId) & g.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.godowns)
        .insert(
          GodownsCompanion.insert(
            uuid: _db.newUuid(),
            companyId: companyId,
            name: clean,
          ),
        );
  }

  static Future<int> _ensureVoucherType(int companyId, String name) async {
    final clean = name.trim().isEmpty ? 'Voucher' : name.trim();
    final existing =
        await (_db.select(_db.voucherTypes)..where(
              (t) => t.companyId.equals(companyId) & t.name.equals(clean),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.voucherTypes)
        .insert(
          VoucherTypesCompanion.insert(
            uuid: _db.newUuid(),
            companyId: companyId,
            name: clean,
            nature: _voucherNature(clean),
            abbreviation: Value(clean.substring(0, 1).toUpperCase()),
          ),
        );
  }

  static Future<int> _ensurePartyFromVoucher(
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
      companyId,
      name.isEmpty ? 'Cash' : name,
      group,
      gstin: gstin,
    );
  }

  static Future<int?> _findVoucherId(
    int companyId,
    int voucherTypeId,
    String uuid,
    String number,
  ) async {
    if (uuid.length == 36) {
      final byUuid = await (_db.select(
        _db.vouchers,
      )..where((v) => v.uuid.equals(uuid))).getSingleOrNull();
      if (byUuid != null) return byUuid.id;
    }
    final byNumber =
        await (_db.select(_db.vouchers)..where(
              (v) =>
                  v.companyId.equals(companyId) &
                  v.voucherTypeId.equals(voucherTypeId) &
                  v.voucherNumber.equals(number),
            ))
            .getSingleOrNull();
    return byNumber?.id;
  }

  static Future<List<_DbVoucherLine>> _voucherLines(
    int companyId,
    Map<String, dynamic> v,
    int partyId,
  ) async {
    final isSales = _isSales(v['voucherType']?.toString() ?? '');
    final salesOrPurchase = await _ensureAccount(
      companyId,
      isSales ? 'Sales' : 'Purchase',
      isSales ? 'Sales Accounts' : 'Purchase Accounts',
    );
    final godownId = await _ensureGodown(
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
    Voucher v,
    String typeName,
  ) async {
    final entries = await (_db.select(
      _db.voucherEntries,
    )..where((e) => e.voucherId.equals(v.id))).get();
    final accounts = await _db.select(_db.accounts).get();
    final items = await _db.select(_db.items).get();
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
