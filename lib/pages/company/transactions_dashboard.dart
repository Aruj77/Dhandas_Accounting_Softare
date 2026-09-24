import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/focus_policy_service.dart';
import '../../utils/app_action_bottom_sheet.dart';
import '../../utils/app_date_utils.dart';
import '../../widgets/common/dashboard_action_chip.dart';
import '../../widgets/common/interactive_dashboard_card.dart';
import '../../widgets/common/company_dashboard_header.dart';
import '../../widgets/company/date_range_dialog.dart';
import '../../widgets/voucher/popup/voucher_modify_dialog.dart';

enum TransactionAction { add, modify, list }

class _TxItem {
  final String title, subtitle, description, shortcut;
  final IconData icon;
  final Color color;

  const _TxItem(
    this.title,
    this.subtitle,
    this.description,
    this.icon,
    this.color, [
    this.shortcut = '',
  ]);
}

class TransactionsDashboard extends StatefulWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onMoveToSidebar;
  final void Function(String voucherType)? onAddTransaction;
  final void Function(
    String voucherType,
    DateTime from,
    DateTime to,
    String series,
  )? onShowList;
  final VoidCallback? onVouchersChanged;

  const TransactionsDashboard({
    super.key,
    required this.company,
    this.onMoveToSidebar,
    this.onAddTransaction,
    this.onShowList,
    this.onVouchersChanged,
  });

  @override
  State<TransactionsDashboard> createState() => TransactionsDashboardState();
}

class TransactionsDashboardState extends State<TransactionsDashboard> {
  static const List<_TxItem> _items = [
    _TxItem('Sales Invoice', 'Create customer invoices', 'B2B, B2C and GST tax invoices', Icons.receipt_long_rounded, AppColors.primaryAccent, 'F4'),
    _TxItem('Sale Return / Credit Note', 'Reverse customer sales', 'Returns, credit notes and adjustments', Icons.assignment_return_rounded, AppColors.warning),
    _TxItem('Payment In', 'Record customer receipts', 'Cash, bank and customer collections', Icons.south_west_rounded, AppColors.success, 'F6'),
    _TxItem('Purchase Bill', 'Enter supplier invoices', 'Purchase bills and input tax credit', Icons.inventory_2_rounded, AppColors.purple, 'F5'),
    _TxItem('Purchase Return / Debit Note', 'Return goods to suppliers', 'Returns, debit notes and adjustments', Icons.keyboard_return_rounded, AppColors.error),
    _TxItem('Payment Out', 'Record supplier payments', 'Vendor payments and expenses', Icons.north_east_rounded, AppColors.textSecondary, 'F7'),
    _TxItem('Journal Voucher', 'Make accounting adjustments', 'Direct debit and credit adjustments', Icons.menu_book_rounded, AppColors.primary, 'F8'),
    _TxItem('Contra Entry', 'Transfer between cash & bank', 'Cash deposit, withdrawal and transfers', Icons.swap_horiz_rounded, AppColors.primaryAccent, 'F9'),
  ];

  static const List<List<int>> _sections = [
    [0, 1, 2], // Sales
    [3, 4, 5], // Purchases
    [6, 7],    // Banking & Journal
  ];

  late final List<FocusNode> _focusNodes = List.generate(_items.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void focusFirstTile() {
    if (_focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
  }

  Future<void> _handleAction({
    required BuildContext context,
    required String voucherType,
    required TransactionAction action,
  }) async {
    switch (action) {
      case TransactionAction.add:
        widget.onAddTransaction?.call(voucherType);
        break;
      case TransactionAction.modify:
        showDialog(
          context: context,
          builder: (_) => VoucherModifyDialog(
            company: widget.company,
            voucherType: voucherType,
            onVoucherUpdated: () => widget.onVouchersChanged?.call(),
          ),
        );
        break;
      case TransactionAction.list:
        final fy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => DateRangeDialog(
            company: widget.company,
            financialYear: fy,
            voucherType: voucherType,
          ),
        );
        if (result != null) {
          widget.onShowList?.call(
            voucherType,
            result['from'] as DateTime,
            result['to'] as DateTime,
            result['series']?.toString() ?? 'All',
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = (widget.company['companyName'] ?? 'Workspace').toString();
    final activeFy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();

    return AutoScreenFocus(
      screen: FocusTargetScreen.homeDashboard,
      nodeMap: {
        FocusFieldNode.firstField: _focusNodes.first,
      },
      child: Container(
        color: AppColors.background,
        child: LayoutBuilder(
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
                    subtitle: 'Manage sales, purchases, payments and accounting entries.',
                    accentColor: AppColors.primaryAccent,
                  ),
                  const SizedBox(height: 30),
                  _buildCategorySection('Sales', 'Customer invoices, returns and receipts', Icons.trending_up_rounded, AppColors.primaryAccent, _sections[0], cols),
                  const SizedBox(height: 22),
                  _buildCategorySection('Purchases', 'Supplier bills, returns and payments', Icons.shopping_bag_outlined, AppColors.purple, _sections[1], cols),
                  const SizedBox(height: 22),
                  _buildCategorySection('Banking & Journal', 'Cash transfers and accounting adjustments', Icons.account_balance_rounded, AppColors.primary, _sections[2], cols),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, String desc, IconData icon, Color color, List<int> indexes, int cols) {
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
              final item = _items[idx];
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
                shortcut: item.shortcut,
                onPrimaryAction: () => _showTransactionActions(context, item.title),
                actionChips: [
                  DashboardActionChip(
                    label: 'Add',
                    icon: Icons.add_rounded,
                    color: AppColors.success,
                    onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.add),
                  ),
                  DashboardActionChip(
                    label: 'Modify',
                    icon: Icons.edit_rounded,
                    color: AppColors.primaryAccent,
                    onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.modify),
                  ),
                  DashboardActionChip(
                    label: 'List',
                    icon: Icons.list_alt_rounded,
                    color: AppColors.purple,
                    onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.list),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionActions(BuildContext context, String voucherType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppActionBottomSheet(
        title: voucherType,
        subtitle: 'Choose an action',
        actions: [
          AppActionItem(
            title: 'Add New',
            desc: 'Create a new transaction',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.success,
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(context: context, voucherType: voucherType, action: TransactionAction.add);
            },
          ),
          AppActionItem(
            title: 'Modify',
            desc: 'Edit an existing transaction',
            icon: Icons.edit_note_rounded,
            color: AppColors.primaryAccent,
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(context: context, voucherType: voucherType, action: TransactionAction.modify);
            },
          ),
          AppActionItem(
            title: 'List',
            desc: 'View transaction register',
            icon: Icons.list_alt_rounded,
            color: AppColors.purple,
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(context: context, voucherType: voucherType, action: TransactionAction.list);
            },
          ),
        ],
      ),
    );
  }
}