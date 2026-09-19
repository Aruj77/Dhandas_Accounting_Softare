import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/company/date_range_dialog.dart';
import '../../widgets/voucher/popup/voucher_modify_dialog.dart';

enum TransactionAction { add, modify, list }

class TransactionsDashboard extends StatefulWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onMoveToSidebar;
  final void Function(String voucherType)? onAddTransaction;
  final void Function(String voucherType, DateTime from, DateTime to, String series)? onShowList;
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
  static const int _totalTiles = 8;
  final List<FocusNode> _tileFocusNodes = [];
  final List<GlobalKey<PopupMenuButtonState<TransactionAction>>> _menuKeys = [];
  int? _focusedTileIndex;
  int? _hoveredTileIndex;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _totalTiles; i++) {
      _tileFocusNodes.add(FocusNode());
      _menuKeys.add(GlobalKey<PopupMenuButtonState<TransactionAction>>());
    }
  }

  @override
  void dispose() {
    for (final node in _tileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void focusFirstTile() {
    if (_tileFocusNodes.isNotEmpty) {
      _tileFocusNodes[0].requestFocus();
    }
  }

  void _handleGridKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    // NEXT (RIGHT / NUMPAD 6)
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.numpad6) {
      if (index + 1 < _totalTiles) {
        _tileFocusNodes[index + 1].requestFocus();
      }
    }
    // PREVIOUS (LEFT / NUMPAD 4)
    else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.numpad4) {
      if (index == 0) {
        widget.onMoveToSidebar?.call();
      } else {
        _tileFocusNodes[index - 1].requestFocus();
      }
    }
    // DOWN / NUMPAD 2
    else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.numpad2) {
      if (index + 3 < _totalTiles) {
        _tileFocusNodes[index + 3].requestFocus();
      } else if (index < 6) {
        _tileFocusNodes[_totalTiles - 1].requestFocus();
      }
    }
    // UP / NUMPAD 8
    else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.numpad8) {
      if (index - 3 >= 0) {
        _tileFocusNodes[index - 3].requestFocus();
      }
    }
    // ENTER / SPACE
    else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _menuKeys[index].currentState?.showButtonMenu();
    }
  }

  Future<void> _handleAction({
    required BuildContext context,
    required String voucherType,
    required TransactionAction action,
  }) async {
    // 1. ADD NEW
    if (action == TransactionAction.add) {
      widget.onAddTransaction?.call(voucherType);
      return;
    }

    // 2. MODIFY (Opens VoucherModifyDialog with default last saved voucher)
    if (action == TransactionAction.modify) {
      showDialog(
        context: context,
        builder: (ctx) => VoucherModifyDialog(
          company: widget.company,
          voucherType: voucherType,
          onVoucherUpdated: () {
            widget.onVouchersChanged?.call();
          },
        ),
      );
      return;
    }

    // 3. LIST (Opens Date Range & Series Filter before list)
    if (action == TransactionAction.list) {
      final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => DateRangeDialog(
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
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = (widget.company['companyName'] ?? 'Workspace').toString();
    final activeFy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                companyName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F1B38),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'F.Y. $activeFy',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Use [Arrow Keys / NumPad 2, 4, 6, 8] to navigate continuously across blocks, [Enter] for actions.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF637392),
            ),
          ),
          const SizedBox(height: 26),

          // SALES & OUTWARD SUPPLY
          _buildCategoryHeader(
            title: 'Sales & Outward Supplies',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF0F62FE),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTransactionTile(
                  index: 0,
                  title: 'Sales Invoice',
                  subtitle: 'Tax invoice (B2B, B2C)',
                  icon: Icons.receipt_rounded,
                  badgeGradient: const [Color(0xFF3880F6), Color(0xFF0F62FE)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  index: 1,
                  title: 'Sale Return / Credit Note',
                  subtitle: 'Goods returned by customer',
                  icon: Icons.assignment_return_rounded,
                  badgeGradient: const [Color(0xFFF6A000), Color(0xFFE08200)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  index: 2,
                  title: 'Payment In (Receipt)',
                  subtitle: 'Record customer receipt',
                  icon: Icons.arrow_downward_rounded,
                  badgeGradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // PURCHASES & INWARD SUPPLY
          _buildCategoryHeader(
            title: 'Purchases & Inward Supplies',
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF7034E6),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTransactionTile(
                  index: 3,
                  title: 'Purchase Bill',
                  subtitle: 'Vendor bill entry & ITC claim',
                  icon: Icons.inventory_rounded,
                  badgeGradient: const [Color(0xFF8E62FA), Color(0xFF6732E6)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  index: 4,
                  title: 'Purchase Return / Debit Note',
                  subtitle: 'Return stock to supplier',
                  icon: Icons.replay_rounded,
                  badgeGradient: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  index: 5,
                  title: 'Payment Out',
                  subtitle: 'Vendor payment / payout',
                  icon: Icons.arrow_upward_rounded,
                  badgeGradient: const [Color(0xFF64748B), Color(0xFF475569)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // JOURNAL & BANKING
          _buildCategoryHeader(
            title: 'Journal & Banking',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTransactionTile(
                  index: 6,
                  title: 'Journal Voucher',
                  subtitle: 'Direct debit/credit adjustment',
                  icon: Icons.menu_book_rounded,
                  badgeGradient: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  index: 7,
                  title: 'Contra Entry',
                  subtitle: 'Cash deposit or bank transfer',
                  icon: Icons.sync_alt_rounded,
                  badgeGradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
              ),
              const SizedBox(width: 16),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101B3A),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> badgeGradient,
  }) {
    final focusNode = _tileFocusNodes[index];
    final menuKey = _menuKeys[index];
    final isFocused = _focusedTileIndex == index;
    final isHovered = _hoveredTileIndex == index;

    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasNavFocus) {
        setState(() {
          if (hasNavFocus) {
            _focusedTileIndex = index;
          } else if (_focusedTileIndex == index) {
            _focusedTileIndex = null;
          }
        });
      },
      onKeyEvent: (node, event) {
        _handleGridKey(index, event);
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.numpad2 ||
                event.logicalKey == LogicalKeyboardKey.numpad4 ||
                event.logicalKey == LogicalKeyboardKey.numpad6 ||
                event.logicalKey == LogicalKeyboardKey.numpad8 ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hoveredTileIndex = index);
          focusNode.requestFocus();
        },
        onExit: (_) => setState(() => _hoveredTileIndex = null),
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
            menuKey.currentState?.showButtonMenu();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
                0, (isFocused || isHovered) ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? const Color(0xFF0F62FE)
                    : (isHovered
                        ? const Color(0xFF90B9FB)
                        : const Color(0xFFE2EAF5)),
                width: isFocused ? 2.5 : 1.2,
              ),
              boxShadow: isFocused
                  ? const [
                      BoxShadow(
                        color: Color(0x330F62FE),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : (isHovered
                      ? const [
                          BoxShadow(
                            color: Color(0x18092B60),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x06092B60),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]),
            ),
            child: PopupMenuButton<TransactionAction>(
              key: menuKey,
              tooltip: '',
              offset: const Offset(0, 78),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2EAF5), width: 1.2),
              ),
              elevation: 8,
              shadowColor: const Color(0x18092B60),
              color: Colors.white,
              onSelected: (action) => _handleAction(
                context: context,
                voucherType: title,
                action: action,
              ),
              itemBuilder: (context) => [
                _buildPopupMenuItem(
                  action: TransactionAction.add,
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: const Color(0xFF11A25B),
                  label: 'Add New',
                  description: 'Create a new $title entry',
                ),
                const PopupMenuDivider(height: 1),
                _buildPopupMenuItem(
                  action: TransactionAction.modify,
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFF0F62FE),
                  label: 'Modify',
                  description: 'Edit or amend existing voucher',
                ),
                const PopupMenuDivider(height: 1),
                _buildPopupMenuItem(
                  action: TransactionAction.list,
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: const Color(0xFF7034E6),
                  label: 'List',
                  description: 'Browse register and history',
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: badgeGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: badgeGradient.last.withValues(alpha: 0.32),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101B3A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<TransactionAction> _buildPopupMenuItem({
    required TransactionAction action,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
  }) {
    return PopupMenuItem<TransactionAction>(
      value: action,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101B3A),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}