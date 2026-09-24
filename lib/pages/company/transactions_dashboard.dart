import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/focus_policy_service.dart';
import '../../utils/app_action_bottom_sheet.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/grid_keyboard_navigator.dart';
import '../../widgets/common/dashboard_action_chip.dart';
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
  int? _focusedIndex;
  int? _hoveredIndex;

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
                  _buildHeader(companyName: companyName, financialYear: activeFy),
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

  Widget _buildHeader({required String companyName, required String financialYear}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 58,
            decoration: BoxDecoration(color: AppColors.primaryAccent, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'FY $financialYear',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Manage sales, purchases, payments and accounting entries.',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - ((cols - 1) * 14)) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: indexes.map((i) => SizedBox(width: width, child: _buildTransactionCard(i, cols))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(int index, int cols) {
    final item = _items[index];
    final isFocused = _focusedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Builder(
      builder: (cardContext) {
        return Focus(
          focusNode: _focusNodes[index],
          onFocusChange: (has) {
            setState(() => _focusedIndex = has ? index : null);
            if (has) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !cardContext.mounted) return;
                final box = cardContext.findRenderObject() as RenderBox?;
                if (box != null && box.hasSize) {
                  final pos = box.localToGlobal(Offset.zero);
                  final screenHeight = MediaQuery.of(cardContext).size.height;
                  final isFullyVisible = pos.dy >= 24 && (pos.dy + box.size.height) <= screenHeight - 24;

                  if (!isFullyVisible) {
                    Scrollable.ensureVisible(
                      cardContext,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                }
              });
            }
          },
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;

            if (GridKeyboardNavigator.isActionKey(event.logicalKey)) {
              _showTransactionActions(context, item.title);
              return KeyEventResult.handled;
            }

            if (GridKeyboardNavigator.handleKeyEvent(
              currentIndex: index,
              key: event.logicalKey,
              cols: cols,
              focusNodes: _focusNodes,
              sections: _sections,
            )) {
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => _hoveredIndex = index);
              _focusNodes[index].requestFocus();
            },
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, (isHovered || isFocused) ? -3 : 0, 0),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFocused
                      ? item.color
                      : isHovered
                          ? item.color.withValues(alpha: .35)
                          : AppColors.border,
                  width: isFocused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered || isFocused ? item.color.withValues(alpha: .10) : AppColors.shadowColor,
                    blurRadius: isHovered || isFocused ? 18 : 8,
                    offset: Offset(0, isHovered || isFocused ? 8 : 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _focusNodes[index].requestFocus();
                  _showTransactionActions(context, item.title);
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: item.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(15)),
                            child: Icon(item.icon, color: item.color, size: 23),
                          ),
                          const Spacer(),
                          if (item.shortcut.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(7)),
                              child: Text(
                                item.shortcut,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const SizedBox(height: 5),
                      Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.color)),
                      const SizedBox(height: 5),
                      Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          DashboardActionChip(
                            label: 'Add',
                            icon: Icons.add_rounded,
                            color: AppColors.success,
                            onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.add),
                          ),
                          const SizedBox(width: 7),
                          DashboardActionChip(
                            label: 'Modify',
                            icon: Icons.edit_rounded,
                            color: AppColors.primaryAccent,
                            onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.modify),
                          ),
                          const SizedBox(width: 7),
                          DashboardActionChip(
                            label: 'List',
                            icon: Icons.list_alt_rounded,
                            color: AppColors.purple,
                            onTap: () => _handleAction(context: context, voucherType: item.title, action: TransactionAction.list),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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