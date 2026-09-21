import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/core_tables.dart';
import '../tables/transaction_tables.dart';

part 'voucher_dao.g.dart';

/// Read-side queries for voucher list/search screens — separated from
/// [AccountingDao] so hot OLTP reads never compete with the write/report path.
@DriftAccessor(tables: [Vouchers, VoucherEntries, Accounts])
class VoucherDao extends DatabaseAccessor<AppDatabase> with _$VoucherDaoMixin {
  VoucherDao(AppDatabase db) : super(db);

  Stream<List<Voucher>> watchVouchers(int companyId, int voucherTypeId) {
    return (select(db.vouchers)
          ..where(
            (v) =>
                v.companyId.equals(companyId) &
                v.voucherTypeId.equals(voucherTypeId) &
                v.deletedAt.isNull(),
          )
          ..orderBy([(v) => OrderingTerm.desc(v.voucherDate)]))
        .watch();
  }

  Future<List<VoucherEntry>> entriesFor(int voucherId) => (select(
    db.voucherEntries,
  )..where((e) => e.voucherId.equals(voucherId) & e.deletedAt.isNull())).get();

  /// Ledger (account statement) view: running balance for one account.
  Future<List<Map<String, dynamic>>> ledgerStatement(
    int accountId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await customSelect(
      '''
      SELECT v.voucher_date AS d, v.voucher_number AS num, v.narration AS narration,
             ve.dr_cr AS dr_cr, ve.amount AS amount
      FROM voucher_entries ve
      JOIN vouchers v ON v.id = ve.voucher_id
      WHERE ve.account_id = ? AND v.voucher_date BETWEEN ? AND ?
        AND v.deleted_at IS NULL AND ve.deleted_at IS NULL AND v.is_cancelled = 0
      ORDER BY v.voucher_date, v.id
      ''',
      variables: [
        Variable.withInt(accountId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {db.voucherEntries, db.vouchers},
    ).get();
    double bal = 0;
    return rows.map((r) {
      final amt = r.read<double>('amount');
      bal += r.read<String>('dr_cr') == 'dr' ? amt : -amt;
      return {
        'date': r.read<DateTime>('d'),
        'voucher_no': r.read<String>('num'),
        'narration': r.read<String?>('narration'),
        'dr_cr': r.read<String>('dr_cr'),
        'amount': amt,
        'running_balance': bal,
      };
    }).toList();
  }
}
