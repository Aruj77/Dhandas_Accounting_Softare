import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/core_tables.dart';
import '../tables/transaction_tables.dart';

part 'accounting_dao.g.dart';

class VoucherLineInput {
  final int accountId;
  final String drCr; // 'dr' | 'cr'
  final double amount;
  final int? itemId;
  final int? godownId;
  final double? qty;
  final double? rate;
  VoucherLineInput({
    required this.accountId,
    required this.drCr,
    required this.amount,
    this.itemId,
    this.godownId,
    this.qty,
    this.rate,
  });
}

class TrialBalanceRow {
  final int accountId;
  final String accountName;
  final String nature;
  final double debit;
  final double credit;
  TrialBalanceRow(
    this.accountId,
    this.accountName,
    this.nature,
    this.debit,
    this.credit,
  );
}

@DriftAccessor(tables: [Vouchers, VoucherEntries, Accounts, AccountGroups])
class AccountingDao extends DatabaseAccessor<AppDatabase>
    with _$AccountingDaoMixin {
  AccountingDao(AppDatabase db) : super(db);

  /// Single source of truth for writing a transaction. Rejects any voucher
  /// whose lines don't balance -> the ledger can never go out of balance.
  Future<int> saveVoucher({
    required int companyId,
    required int voucherTypeId,
    required String voucherNumber,
    required DateTime voucherDate,
    int? partyId,
    String? narration,
    required List<VoucherLineInput> lines,
  }) {
    final dr = lines
        .where((l) => l.drCr == 'dr')
        .fold(0.0, (s, l) => s + l.amount);
    final cr = lines
        .where((l) => l.drCr == 'cr')
        .fold(0.0, (s, l) => s + l.amount);
    if ((dr - cr).abs() > 0.01) {
      throw StateError('Unbalanced voucher: dr=$dr cr=$cr');
    }
    return transaction(() async {
      final companyUuid = await db.uuidOf(db.companies, companyId);
      final voucherTypeUuid = await db.uuidOf(db.voucherTypes, voucherTypeId);
      final partyUuid = partyId == null
          ? null
          : await db.uuidOf(db.accounts, partyId);
      final voucherUuid = db.newUuid();

      final voucherId = await into(db.vouchers).insert(
        VouchersCompanion.insert(
          uuid: voucherUuid,
          companyId: companyId,
          voucherTypeId: voucherTypeId,
          voucherNumber: voucherNumber,
          voucherDate: voucherDate,
          partyId: Value(partyId),
          narration: Value(narration),
        ),
      );
      await db.enqueueSync('vouchers', voucherUuid, 'insert', {
        'uuid': voucherUuid,
        'company_uuid': companyUuid,
        'voucher_type_uuid': voucherTypeUuid,
        'voucher_number': voucherNumber,
        'voucher_date': voucherDate.toIso8601String(),
        'party_uuid': partyUuid,
        'narration': narration,
        'updated_at': DateTime.now().toIso8601String(),
      });

      for (final l in lines) {
        final entryUuid = db.newUuid();
        final accountUuid = await db.uuidOf(db.accounts, l.accountId);
        final itemUuid = l.itemId == null
            ? null
            : await db.uuidOf(db.items, l.itemId!);
        final godownUuid = l.godownId == null
            ? null
            : await db.uuidOf(db.godowns, l.godownId!);

        await into(db.voucherEntries).insert(
          VoucherEntriesCompanion.insert(
            uuid: entryUuid,
            voucherId: voucherId,
            accountId: l.accountId,
            drCr: l.drCr,
            amount: l.amount,
            itemId: Value(l.itemId),
            godownId: Value(l.godownId),
            qty: Value(l.qty),
            rate: Value(l.rate),
          ),
        );
        await db.enqueueSync('voucher_entries', entryUuid, 'insert', {
          'uuid': entryUuid,
          'voucher_uuid': voucherUuid,
          'account_uuid': accountUuid,
          'dr_cr': l.drCr,
          'amount': l.amount,
          'item_uuid': itemUuid,
          'godown_uuid': godownUuid,
          'qty': l.qty,
          'rate': l.rate,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      return voucherId;
    });
  }

  /// Trial balance as-of [asOf]: opening balance + all posted movement.
  /// Pure SQL aggregation -> fast even with years of vouchers.
  Future<List<TrialBalanceRow>> trialBalance(
    int companyId,
    DateTime asOf,
  ) async {
    final rows = await customSelect(
      '''
      SELECT a.id AS account_id, a.name AS account_name, g.nature AS nature,
        a.opening_balance AS opening_balance, a.opening_balance_type AS ob_type,
        COALESCE(SUM(CASE WHEN ve.dr_cr = 'dr' THEN ve.amount ELSE 0 END), 0) AS dr_sum,
        COALESCE(SUM(CASE WHEN ve.dr_cr = 'cr' THEN ve.amount ELSE 0 END), 0) AS cr_sum
      FROM accounts a
      JOIN account_groups g ON g.id = a.group_id
      LEFT JOIN voucher_entries ve ON ve.account_id = a.id AND ve.deleted_at IS NULL
      LEFT JOIN vouchers v ON v.id = ve.voucher_id
        AND v.deleted_at IS NULL AND v.is_cancelled = 0 AND v.voucher_date <= ?
      WHERE a.company_id = ? AND a.deleted_at IS NULL
      GROUP BY a.id
      HAVING dr_sum <> 0 OR cr_sum <> 0 OR opening_balance <> 0
      ORDER BY g.nature, a.name
      ''',
      variables: [Variable.withDateTime(asOf), Variable.withInt(companyId)],
      readsFrom: {
        db.accounts,
        db.accountGroups,
        db.voucherEntries,
        db.vouchers,
      },
    ).get();

    return rows.map((r) {
      final ob = r.read<double>('opening_balance');
      final obDr = r.read<String>('ob_type') == 'dr' ? ob : 0.0;
      final obCr = r.read<String>('ob_type') == 'cr' ? ob : 0.0;
      final dr = obDr + r.read<double>('dr_sum');
      final cr = obCr + r.read<double>('cr_sum');
      final net = dr - cr;
      return TrialBalanceRow(
        r.read<int>('account_id'),
        r.read<String>('account_name'),
        r.read<String>('nature'),
        net > 0 ? net : 0,
        net < 0 ? -net : 0,
      );
    }).toList();
  }

  /// Profit & Loss for [from]..[to]: income/expense group nature only, no
  /// opening balance (P&L is period-bound, unlike the balance sheet).
  Future<Map<String, double>> profitAndLoss(
    int companyId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await customSelect(
      '''
      SELECT g.nature AS nature,
        SUM(CASE WHEN ve.dr_cr = 'cr' THEN ve.amount ELSE -ve.amount END) AS net
      FROM voucher_entries ve
      JOIN accounts a ON a.id = ve.account_id
      JOIN account_groups g ON g.id = a.group_id
      JOIN vouchers v ON v.id = ve.voucher_id
      WHERE a.company_id = ? AND g.nature IN ('income','expense')
        AND v.voucher_date BETWEEN ? AND ?
        AND v.deleted_at IS NULL AND v.is_cancelled = 0 AND ve.deleted_at IS NULL
      GROUP BY g.nature
      ''',
      variables: [
        Variable.withInt(companyId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {
        db.voucherEntries,
        db.accounts,
        db.accountGroups,
        db.vouchers,
      },
    ).get();
    final income = rows.firstWhere(
      (r) => r.read<String>('nature') == 'income',
      orElse: () => null as dynamic,
    );
    final expense = rows.firstWhere(
      (r) => r.read<String>('nature') == 'expense',
      orElse: () => null as dynamic,
    );
    final incomeTotal = income == null ? 0.0 : income.read<double>('net');
    final expenseTotal = expense == null ? 0.0 : -expense.read<double>('net');
    return {
      'income': incomeTotal,
      'expense': expenseTotal,
      'net_profit': incomeTotal - expenseTotal,
    };
  }

  /// Balance sheet as-of [asOf]: assets/liabilities/equity nature only,
  /// carrying cumulative balance since inception (reuses [trialBalance]).
  Future<Map<String, List<TrialBalanceRow>>> balanceSheet(
    int companyId,
    DateTime asOf,
  ) async {
    final tb = await trialBalance(companyId, asOf);
    return {
      'assets': tb.where((r) => r.nature == 'asset').toList(),
      'liabilities': tb.where((r) => r.nature == 'liability').toList(),
      'equity': tb.where((r) => r.nature == 'equity').toList(),
    };
  }

  /// Multi-year comparison: one aggregate P&L figure per financial year,
  /// combining SQL grouping with the same accounting rules as [profitAndLoss].
  Future<List<Map<String, dynamic>>> multiYearPnl(
    int companyId,
    List<DateTime> fyStarts,
    List<DateTime> fyEnds,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < fyStarts.length; i++) {
      final r = await profitAndLoss(companyId, fyStarts[i], fyEnds[i]);
      out.add({'fy_start': fyStarts[i], ...r});
    }
    return out;
  }
}
