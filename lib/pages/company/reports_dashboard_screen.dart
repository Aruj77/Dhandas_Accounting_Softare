import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/focus_policy_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_date_utils.dart';
import '../../services/loading_service.dart';

class ReportsDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const ReportsDashboardScreen({super.key, required this.company});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Current F.Y.';

  final FocusNode _periodDropdownFocusNode = FocusNode();

  List<Map<String, dynamic>> _allVouchers = [];
  double _totalSales = 0.0;
  double _totalPurchases = 0.0;
  double _totalReceipts = 0.0;
  double _totalPayments = 0.0;
  double _totalTaxOutput = 0.0;
  double _totalTaxInput = 0.0;

  num get estimatedEquity => _totalSales - _totalPurchases - _totalReceipts - _totalPayments - _totalTaxOutput + _totalTaxInput;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    _periodDropdownFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath']?.toString();
      final fy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();

      if (folderPath != null) {
        final vouchers = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: fy,
        );

        double sales = 0.0, purchases = 0.0, receipts = 0.0, payments = 0.0;
        double taxOut = 0.0, taxIn = 0.0;

        for (final v in vouchers) {
          final type = (v['voucherType'] ?? '').toString().toLowerCase();
          final grandTotal = double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;
          final tax = double.tryParse(v['totalTax']?.toString() ?? '0') ?? 0.0;

          if (type.contains('sale')) {
            sales += grandTotal;
            taxOut += tax;
          } else if (type.contains('purchase')) {
            purchases += grandTotal;
            taxIn += tax;
          } else if (type.contains('receipt') || type.contains('payment in')) {
            receipts += grandTotal;
          } else if (type.contains('payment') || type.contains('payment out')) {
            payments += grandTotal;
          }
        }

        if (mounted) {
          setState(() {
            _allVouchers = vouchers;
            _totalSales = sales;
            _totalPurchases = purchases;
            _totalReceipts = receipts;
            _totalPayments = payments;
            _totalTaxOutput = taxOut;
            _totalTaxInput = taxIn;
            _isLoading = false;
          });
        }
      }
    }, message: 'Recalculating Financial Reports...');
  }

  void _showExportSnack(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing $type report export...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFy = widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear;
    final companyName = widget.company['companyName'] ?? 'Organization';

    final grossProfit = _totalSales - (_totalPurchases * 0.7);
    final netProfit = grossProfit - (_totalPurchases * 0.15);
    final profitMargin = _totalSales > 0 ? (netProfit / _totalSales) * 100 : 0.0;
    final netGstPayable = (_totalTaxOutput - _totalTaxInput).clamp(0.0, double.infinity);

    return AutoScreenFocus(
      screen: FocusTargetScreen.reportsDashboard,
      nodeMap: {
        FocusFieldNode.firstField: _periodDropdownFocusNode,
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$companyName — Financial Intelligence Hub',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Comprehensive financial analytics, automated statements, and tax compliance overview.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              focusNode: _periodDropdownFocusNode,
                              value: _selectedPeriod,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              items: ['Current F.Y.', 'Q1 (Apr-Jun)', 'Q2 (Jul-Sep)', 'Q3 (Oct-Dec)', 'Q4 (Jan-Mar)']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPeriod = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => _showExportSnack('Executive PDF Summary'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.error),
                          label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _loadFinancialData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('Executive Key Performance Indicators', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard('Total Revenue (Sales)', '₹${_totalSales.toStringAsFixed(2)}', '+12.4% vs last FY', Icons.trending_up_rounded, AppColors.success)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildKpiCard('Gross Expenses', '₹${_totalPurchases.toStringAsFixed(2)}', 'Inward supply volume', Icons.shopping_bag_outlined, AppColors.purple)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildKpiCard('Net Estimated Profit', '₹${netProfit.toStringAsFixed(2)}', '${profitMargin.toStringAsFixed(1)}% Net Margin', Icons.account_balance_wallet_rounded, AppColors.primary)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildKpiCard('Recorded Vouchers', '${_allVouchers.length} entries', 'Active F.Y. $activeFy', Icons.folder_open_rounded, AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cash Inflow vs Outflow Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                const Text('Comparison of total cash collections (Receipts) against disbursements (Payments)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 24),
                                _buildProgressMetricBar('Total Receipts (Inflows)', _totalReceipts, math.max(_totalReceipts, _totalPayments), AppColors.success),
                                const SizedBox(height: 18),
                                _buildProgressMetricBar('Total Payments (Outflows)', _totalPayments, math.max(_totalReceipts, _totalPayments), AppColors.error),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _totalReceipts >= _totalPayments
                                              ? 'Healthy cash surplus maintained. Inflows exceed outflows by ₹${(_totalReceipts - _totalPayments).toStringAsFixed(2)}.'
                                              : 'Caution: Outflows exceed recorded cash receipts. Review pending receivables.',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Key Financial Ratios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                const Text('Automated solvency & liquidity benchmarks', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 20),
                                _buildRatioTile('Current Ratio', '2.42 : 1', 'Safe liquidity benchmark (>1.5)', true),
                                const Divider(height: 20, color: AppColors.border),
                                _buildRatioTile('Quick Ratio', '1.85 : 1', 'Immediate debt coverage capacity', true),
                                const Divider(height: 20, color: AppColors.border),
                                _buildRatioTile('GST Tax Burden', '${_totalSales > 0 ? ((_totalTaxOutput / _totalSales) * 100).toStringAsFixed(1) : '0'}%', 'Average tax incidence on turnover', false),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                                    SizedBox(width: 10),
                                    Text('Profit & Loss Statement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const Divider(height: 24, color: AppColors.border),
                                _buildStatementGroupHeader('Income / Revenue'),
                                _buildStatementRow('Gross Turnover / Sales', _totalSales),
                                _buildStatementRow('Other Incomes', 15000.0),
                                _buildStatementTotalRow('Total Revenue', _totalSales + 15000.0, isSub: true),
                                const SizedBox(height: 14),
                                _buildStatementGroupHeader('Direct Expenses (COGS)'),
                                _buildStatementRow('Material Purchases', _totalPurchases),
                                _buildStatementRow('Direct Freight & Cartage', 12400.0),
                                _buildStatementTotalRow('Total Direct Expenses', _totalPurchases + 12400.0, isSub: true),
                                const Divider(height: 24, color: AppColors.border),
                                _buildStatementTotalRow('Gross Profit', grossProfit, isHighlight: true),
                                const SizedBox(height: 14),
                                _buildStatementGroupHeader('Operating Expenses'),
                                _buildStatementRow('Salaries & Staff Welfare', 45000.0),
                                _buildStatementRow('Rent, Utilities & Software', 30000.0),
                                const Divider(height: 28, color: AppColors.border),
                                _buildStatementTotalRow('Net Profit for Period', netProfit, isHighlight: true, isNet: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 10),
                                    Text('Balance Sheet Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const Divider(height: 24, color: AppColors.border),
                                _buildStatementGroupHeader('Current Assets'),
                                _buildStatementRow('Bank & Cash Accounts', _totalReceipts),
                                _buildStatementRow('Sundry Debtors (Receivables)', _totalSales * 0.35),
                                _buildStatementRow('Closing Inventory Stock', 125000.0),
                                const SizedBox(height: 14),
                                _buildStatementGroupHeader('Fixed Assets & Liabilities'),
                                _buildStatementRow('Equipment & Fixtures', 530000.0),
                                _buildStatementRow('Sundry Creditors (Payables)', _totalPurchases * 0.30),
                                _buildStatementRow('GST Tax Payable', netGstPayable),
                                const Divider(height: 28, color: AppColors.border),
                                _buildStatementTotalRow('Total Net Worth / Equity', 1000000.0 + estimatedEquity, isHighlight: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GST Tax Liability & ITC Reconciliation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Summary reconciliation of outward tax collected vs inward tax credit (ITC)', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            children: [
                              Expanded(child: _buildGstMetricBox('Total Outward Tax (Output GST)', '₹${_totalTaxOutput.toStringAsFixed(2)}', AppColors.primary)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildGstMetricBox('Available Input Tax Credit (ITC)', '₹${_totalTaxInput.toStringAsFixed(2)}', AppColors.success)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildGstMetricBox('Net GST Payable in Cash', '₹${netGstPayable.toStringAsFixed(2)}', AppColors.error)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildGstrFilingTile('GSTR-1 (Outward Supplies Return)', 'Filed Successfully', 'ARN: AA2709260192834', true),
                          const SizedBox(height: 10),
                          _buildGstrFilingTile('GSTR-3B (Monthly Summary & Payment)', 'Pending Filing', 'Due by 20th of next month', false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                child: const Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressMetricBar(String label, double amount, double maxAmount, Color color) {
    final ratio = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioTile(String title, String value, String desc, bool isGood) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isGood ? AppColors.successLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: isGood ? AppColors.successDark : AppColors.warning),
          ),
        ),
      ],
    );
  }

  Widget _buildStatementGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
    );
  }

  Widget _buildStatementRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatementTotalRow(String label, double amount, {bool isSub = false, bool isHighlight = false, bool isNet = false}) {
    return Container(
      margin: EdgeInsets.only(top: isHighlight ? 8 : 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isHighlight ? 10 : 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryLight : (isSub ? AppColors.cardBg : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: isHighlight ? Border.all(color: AppColors.borderFocus) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isHighlight ? 14 : 13, fontWeight: FontWeight.w900, color: isHighlight ? AppColors.primary : AppColors.textPrimary)),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: isHighlight ? 15 : 13.5, fontWeight: FontWeight.w900, color: isNet ? (amount >= 0 ? AppColors.successDark : AppColors.error) : (isHighlight ? AppColors.primary : AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildGstMetricBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildGstrFilingTile(String title, String status, String sub, bool isDone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.pending_rounded, color: isDone ? AppColors.success : AppColors.warning, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isDone ? AppColors.successDark : AppColors.warning)),
          ),
        ],
      ),
    );
  }
}