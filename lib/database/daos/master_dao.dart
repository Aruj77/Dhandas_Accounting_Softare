import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/core_tables.dart';

part 'master_dao.g.dart';

/// All master (non-transactional) data: companies, chart of accounts,
/// items, godowns. Kept separate from [AccountingDao] (SOLID: single
/// responsibility — this owns masters, that owns the ledger + reports).
@DriftAccessor(tables: [Companies, AccountGroups, Accounts, Items, Godowns])
class MasterDao extends DatabaseAccessor<AppDatabase> with _$MasterDaoMixin {
  MasterDao(AppDatabase db) : super(db);

  Future<int> createCompany(String name, DateTime fyStart, {String? gstin}) {
    return into(db.companies).insert(
      CompaniesCompanion.insert(
        uuid: db.newUuid(),
        name: name,
        fyStart: fyStart,
        gstin: Value(gstin),
      ),
    );
  }

  Future<List<Account>> activeAccounts(int companyId) => (select(
    db.accounts,
  )..where((a) => a.companyId.equals(companyId) & a.deletedAt.isNull())).get();

  Future<int> createAccount({
    required int companyId,
    required int groupId,
    required String name,
    double openingBalance = 0,
    String openingBalanceType = 'dr',
    String? gstin,
  }) async {
    final uuid = db.newUuid();
    final companyUuid = await db.uuidOf(db.companies, companyId);
    final groupUuid = await db.uuidOf(db.accountGroups, groupId);
    final id = await into(db.accounts).insert(
      AccountsCompanion.insert(
        uuid: uuid,
        companyId: companyId,
        groupId: groupId,
        name: name,
        openingBalance: Value(openingBalance),
        openingBalanceType: Value(openingBalanceType),
        gstin: Value(gstin),
      ),
    );
    await db.enqueueSync('accounts', uuid, 'insert', {
      'uuid': uuid,
      'company_uuid': companyUuid,
      'group_uuid': groupUuid,
      'name': name,
      'opening_balance': openingBalance,
      'opening_balance_type': openingBalanceType,
      'gstin': gstin,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> deleteAccount(int id) => db.softDelete(db.accounts, id);

  Future<List<Item>> activeItems(int companyId) => (select(
    db.items,
  )..where((i) => i.companyId.equals(companyId) & i.deletedAt.isNull())).get();

  Future<int> createItem({
    required int companyId,
    required String name,
    String? hsnCode,
    String unit = 'NOS',
    double gstRate = 0,
  }) async {
    final uuid = db.newUuid();
    final companyUuid = await db.uuidOf(db.companies, companyId);
    final id = await into(db.items).insert(
      ItemsCompanion.insert(
        uuid: uuid,
        companyId: companyId,
        name: name,
        hsnCode: Value(hsnCode),
        unit: Value(unit),
        gstRate: Value(gstRate),
      ),
    );
    await db.enqueueSync('items', uuid, 'insert', {
      'uuid': uuid,
      'company_uuid': companyUuid,
      'name': name,
      'hsn_code': hsnCode,
      'unit': unit,
      'gst_rate': gstRate,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return id;
  }
}
