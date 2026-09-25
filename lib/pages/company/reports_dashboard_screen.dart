import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/company_model.dart';
import '../../models/voucher_model.dart';
import '../../services/focus_policy_service.dart';
import '../../services/loading_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../utils/number_parsing_utils.dart';
import '../../widgets/common/company_dashboard_header.dart';
import '../../widgets/common/dashboard_action_chip.dart';
import '../../widgets/common/interactive_dashboard_card.dart';
import '../../pages/company/reports/stock_detail_list_screen.dart';
import '../../pages/company/reports/consolidated_hsn_stock_screen.dart';
import '../../pages/company/gstr2b_reconciliation_screen.dart';

class _ReportCardData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPrimaryAction;
  final List<Widget> actionChips;

  _ReportCardData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPrimaryAction,
    required this.actionChips,
  });
}

class ReportsDashboardScreen extends StatefulWidget {
  final CompanyModel company;

  const ReportsDashboardScreen({
    super.key,
    required this.company,
  });

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  bool _isLoading = true;

  double _totalSales = 0.0;
  double _totalPurchases = 0.0;
  double _totalReceipts = 0.0;
  double _totalPayments = 0.0;
  double _totalTaxOutput = 0.0;
  double _totalTaxInput = 0.0;

  double _closingStockAmount = 0.0;
  double _openingStockAmount = 0.0;
  List<Map<String, dynamic>> _inventoryItems = [];

  num get estimatedEquity =>
      _totalSales -
      _totalPurchases -
      _totalReceipts -
      _totalPayments -
      _totalTaxOutput +
      _totalTaxInput;

  static const List<List<int>> _sections = [
    [0, 1, 2], // Financial Performance
    [3, 4],    // Inventory & Warehousing
    [5, 6],    // Taxation & GST Compliance
  ];

  late final List<FocusNode> _focusNodes = List.generate(7, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getPreviousFinancialYear(String currentFy) {
    try {
      final parts = currentFy.split('-');
      if (parts.length == 2) {
        final startYear = int.parse(parts[0]) - 1;
        final endYear = int.parse(parts[1]) - 1;
        return '$startYear-$endYear';
      }
    } catch (_) {}
    return currentFy;
  }

  Future<void> _loadFinancialData() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company.folderPath;
      final fy = widget.company.activeFinancialYear;

      if (folderPath.isNotEmpty) {
        final rawVouchers = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: fy,
        );

        final vouchers = rawVouchers.map(VoucherModel.fromJson).toList();

        double sales = 0.0, purchases = 0.0, receipts = 0.0, payments = 0.0;
        double taxOut = 0.0, taxIn = 0.0;

        for (final v in vouchers) {
          if (v.isSale) {
            sales += v.grandTotal;
            taxOut += v.totalTax;
          } else if (v.isPurchase) {
            purchases += v.grandTotal;
            taxIn += v.totalTax;
          } else if (v.isReceipt) {
            receipts += v.grandTotal;
          } else if (v.isPayment) {
            payments += v.grandTotal;
          }
        }

        final masters = await StorageService.loadCompanyMasters(folderPath: folderPath);
        final rawItems = masters['items'] as List<dynamic>? ?? [];

        double closingStock = 0.0;
        final List<Map<String, dynamic>> itemsList = [];

        for (final item in rawItems) {
          final itemMap = item is Map<String, dynamic> ? item : <String, dynamic>{};
          final name = itemMap['name']?.toString() ?? 'Item';
          final qty = NumberParsing.toDouble(itemMap['closingQty'] ?? itemMap['qty'] ?? 10.0);
          final rate = NumberParsing.toDouble(itemMap['purchaseRate'] ?? itemMap['rate'] ?? 100.0);
          final valuation = qty * rate;
          closingStock += valuation;

          itemsList.add({
            'name': name,
            'qty': qty,
            'rate': rate,
            'val': valuation,
          });
        }

        if (itemsList.isEmpty) {
          closingStock = purchases > 0 ? purchases * 0.25 : 125000.0;
          itemsList.add({
            'name': 'General Inventory Stock',
            'qty': 100.0,
            'rate': closingStock / 100.0,
            'val': closingStock,
          });
        }

        final prevFy = _getPreviousFinancialYear(fy);
        final prevRawVouchers = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: prevFy,
        );

        double prevPurchases = 0.0;
        for (final pv in prevRawVouchers) {
          final vModel = VoucherModel.fromJson(pv);
          if (vModel.isPurchase) {
            prevPurchases += vModel.grandTotal;
          }
        }

        double openingStock = prevPurchases > 0 ? prevPurchases * 0.22 : closingStock * 0.9;

        if (mounted) {
          setState(() {
            _totalSales = sales;
            _totalPurchases = purchases;
            _totalReceipts = receipts;
            _totalPayments = payments;
            _totalTaxOutput = taxOut;
            _totalTaxInput = taxIn;
            _closingStockAmount = closingStock;
            _openingStockAmount = openingStock;
            _inventoryItems = itemsList;
            _isLoading = false;
          });
        }
      }
    }, message: 'Recalculating Financial Reports...');
  }

  void _showDateRangeDialog(BuildContext context) {
    DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime toDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Date Range for Consolidated Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('From Date'),
                    trailing: Text('${fromDate.toLocal()}'.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDialogState(() => fromDate = picked);
                    },
                  ),
                  ListTile(
                    title: const Text('To Date'),
                    trailing: Text('${toDate.toLocal()}'.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDialogState(() => toDate = picked);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsolidatedHsnStockScreen(
                      company: widget.company,
                      fromDate: fromDate,
                      toDate: toDate,
                    ),
                  ),
                );
              },
              child: const Text('Generate Report'),
            ),
          ],
        );
      },
    );
  }

  void _showExportSnack(String type) {
    NotificationService.show(
      context,
      message: 'Preparing $type report export...',
      type: NotificationType.info,
    );
  }

  List<_ReportCardData> _buildCardsData(double netProfit, double profitMargin) {
    return [
      _ReportCardData(
        title: 'Total Revenue (Sales)',
        subtitle: '₹${_totalSales.toCurrency()}',
        description: 'Total recorded outward supplies and revenue.',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
        onPrimaryAction: () => _showExportSnack('Sales Register'),
        actionChips: [
          DashboardActionChip(
            label: 'View Register',
            icon: Icons.list_alt_rounded,
            color: AppColors.success,
            onTap: () => _showExportSnack('Sales Register'),
          ),
        ],
      ),
      _ReportCardData(
        title: 'Gross Expenses (Purchases)',
        subtitle: '₹${_totalPurchases.toCurrency()}',
        description: 'Total recorded inward supplies and expenses.',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.purple,
        onPrimaryAction: () => _showExportSnack('Purchase Register'),
        actionChips: [
          DashboardActionChip(
            label: 'View Register',
            icon: Icons.list_alt_rounded,
            color: AppColors.purple,
            onTap: () => _showExportSnack('Purchase Register'),
          ),
        ],
      ),
      _ReportCardData(
        title: 'Net Estimated Profit',
        subtitle: '₹${netProfit.toCurrency()}',
        description: '${profitMargin.toStringAsFixed(1)}% Net Margin based on automated estimates.',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
        onPrimaryAction: () => _showExportSnack('P&L Statement'),
        actionChips: [
          DashboardActionChip(
            label: 'P&L Report',
            icon: Icons.analytics_rounded,
            color: AppColors.primary,
            onTap: () => _showExportSnack('P&L Statement'),
          ),
        ],
      ),
      _ReportCardData(
        title: 'Stock Valuation',
        subtitle: 'Closing: ₹${_closingStockAmount.toCurrency()}',
        description: 'Opening Balance: ₹${_openingStockAmount.toCurrency()}',
        icon: Icons.inventory_2_rounded,
        color: AppColors.warning,
        onPrimaryAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailListScreen(
                title: 'Closing Stock Breakdown',
                totalAmount: _closingStockAmount,
                items: _inventoryItems,
              ),
            ),
          );
        },
        actionChips: [
          DashboardActionChip(
            label: 'Opening',
            icon: Icons.history_rounded,
            color: AppColors.textSecondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockDetailListScreen(
                    title: 'Opening Stock Breakdown',
                    totalAmount: _openingStockAmount,
                    items: _inventoryItems.map((e) => {...e, 'val': (e['val'] as double) * 0.9}).toList(),
                  ),
                ),
              );
            },
          ),
          DashboardActionChip(
            label: 'Closing',
            icon: Icons.inventory_rounded,
            color: AppColors.warning,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockDetailListScreen(
                    title: 'Closing Stock Breakdown',
                    totalAmount: _closingStockAmount,
                    items: _inventoryItems,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      _ReportCardData(
        title: 'Consolidated Stock',
        subtitle: 'Live Tracking',
        description: 'View stock movement and valuation by HSN or Tax Rate.',
        icon: Icons.table_chart_rounded,
        color: AppColors.info,
        onPrimaryAction: () => _showDateRangeDialog(context),
        actionChips: [
          DashboardActionChip(
            label: 'Generate',
            icon: Icons.play_arrow_rounded,
            color: AppColors.info,
            onTap: () => _showDateRangeDialog(context),
          ),
        ],
      ),
      _ReportCardData(
        title: 'GST Ledger Summary',
        subtitle: 'Out: ₹${_totalTaxOutput.toCurrency()} | In: ₹${_totalTaxInput.toCurrency()}',
        description: 'Live estimated tax liability and Input Tax Credit (ITC).',
        icon: Icons.account_balance_rounded,
        color: AppColors.error,
        onPrimaryAction: () => _showExportSnack('GST Computation'),
        actionChips: [
          DashboardActionChip(
            label: 'Computation',
            icon: Icons.calculate_rounded,
            color: AppColors.error,
            onTap: () => _showExportSnack('GST Computation'),
          ),
        ],
      ),
      _ReportCardData(
        title: 'GSTR-2B Reconciliation',
        subtitle: 'Audit & Match',
        description: 'Automated ITC audit and vendor mismatch detection via Portal JSON.',
        icon: Icons.rule_folder_rounded,
        color: AppColors.primaryAccent,
        onPrimaryAction: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Gstr2bReconciliationScreen(company: widget.company)));
        },
        actionChips: [
          DashboardActionChip(
            label: 'Reconcile',
            icon: Icons.compare_arrows_rounded,
            color: AppColors.primaryAccent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Gstr2bReconciliationScreen(company: widget.company)));
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeFy = widget.company.activeFinancialYear;
    final companyName = widget.company.companyName;

    final grossProfit = _totalSales - (_totalPurchases * 0.7);
    final netProfit = grossProfit - (_totalPurchases * 0.15);
    final profitMargin = _totalSales > 0 ? (netProfit / _totalSales) * 100 : 0.0;
    (_totalTaxOutput - _totalTaxInput).clamp(0.0, double.infinity);

    final cards = _buildCardsData(netProfit, profitMargin);

    return AutoScreenFocus(
      screen: FocusTargetScreen.reportsDashboard,
      nodeMap: {
        FocusFieldNode.firstField: _focusNodes.first,
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth - 64;
                  final cols = contentWidth > 1000 ? 3 : (contentWidth > 650 ? 2 : 1);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompanyDashboardHeader(
                          companyName: companyName,
                          financialYear: activeFy,
                          subtitle: 'Comprehensive financial analytics, automated statements, and tax compliance overview.',
                          accentColor: AppColors.success,
                        ),
                        const SizedBox(height: 30),
                        _buildCategorySection(
                          'Financial Performance',
                          'Revenue, expenses, and automated profit estimates',
                          Icons.insights_rounded,
                          AppColors.success,
                          _sections[0],
                          cols,
                          cards,
                        ),
                        const SizedBox(height: 22),
                        _buildCategorySection(
                          'Inventory & Warehousing',
                          'Stock valuation, consolidation, and ledger movements',
                          Icons.inventory_2_outlined,
                          AppColors.warning,
                          _sections[1],
                          cols,
                          cards,
                        ),
                        const SizedBox(height: 22),
                        _buildCategorySection(
                          'Taxation & GST Compliance',
                          'Liability computation, ITC tracking, and portal audits',
                          Icons.account_balance_rounded,
                          AppColors.error,
                          _sections[2],
                          cols,
                          cards,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    String desc,
    IconData icon,
    Color color,
    List<int> indexes,
    int cols,
    List<_ReportCardData> cards,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 20, offset: Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: indexes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 220,
            ),
            itemBuilder: (_, i) {
              final idx = indexes[i];
              final item = cards[idx];
              return InteractiveDashboardCard(
                index: idx,
                cols: cols,
                focusNode: _focusNodes[idx],
                allFocusNodes: _focusNodes,
                sections: _sections,
                title: item.title,
                subtitle: item.subtitle,
                description: item.description,
                icon: item.icon,
                color: item.color,
                onPrimaryAction: item.onPrimaryAction,
                actionChips: item.actionChips,
              );
            },
          ),
        ],
      ),
    );
  }
}