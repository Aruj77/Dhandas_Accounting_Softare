import 'package:flutter/material.dart';
import '../../widgets/company/date_range_dialog.dart';

enum TransactionAction { add, modify, list }

class TransactionsDashboard extends StatelessWidget {
  final Map<String, dynamic> company;
  final void Function(String voucherType)? onAddTransaction;
  final void Function(String voucherType, DateTime from, DateTime to)? onShowList;

  const TransactionsDashboard({
    super.key,
    required this.company,
    this.onAddTransaction,
    this.onShowList,
  });

  Future<void> _handleAction({
    required BuildContext context,
    required String voucherType,
    required TransactionAction action,
  }) async {
    if (action == TransactionAction.add) {
      onAddTransaction?.call(voucherType);
      return;
    }

    if (action == TransactionAction.list) {
      final fy = (company['activeFinancialYear'] ?? '2026-27').toString();
      final result = await showDialog<Map<String, DateTime>>(
        context: context,
        builder: (ctx) => DateRangeDialog(
          financialYear: fy,
          voucherType: voucherType,
        ),
      );

      if (result != null) {
        onShowList?.call(voucherType, result['from']!, result['to']!);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modify / Edit — $voucherType'),
        backgroundColor: const Color(0xFF0F62FE),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = (company['companyName'] ?? 'Workspace').toString();
    final activeFy = (company['activeFinancialYear'] ?? '2026-27').toString();

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
            'Record vouchers, issue tax invoices, manage returns and track financial flow.',
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
                  context: context,
                  title: 'Sales Invoice',
                  subtitle: 'Tax invoice (B2B, B2C)',
                  icon: Icons.receipt_rounded,
                  badgeGradient: const [Color(0xFF3880F6), Color(0xFF0F62FE)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  context: context,
                  title: 'Sale Return / Credit Note',
                  subtitle: 'Goods returned by customer',
                  icon: Icons.assignment_return_rounded,
                  badgeGradient: const [Color(0xFFF6A000), Color(0xFFE08200)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  context: context,
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
                  context: context,
                  title: 'Purchase Bill',
                  subtitle: 'Vendor bill entry & ITC claim',
                  icon: Icons.inventory_rounded,
                  badgeGradient: const [Color(0xFF8E62FA), Color(0xFF6732E6)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  context: context,
                  title: 'Purchase Return / Debit Note',
                  subtitle: 'Return stock to supplier',
                  icon: Icons.replay_rounded,
                  badgeGradient: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  context: context,
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
                  context: context,
                  title: 'Journal Voucher',
                  subtitle: 'Direct debit/credit adjustment',
                  icon: Icons.menu_book_rounded,
                  badgeGradient: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionTile(
                  context: context,
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
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> badgeGradient,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<TransactionAction>(
            tooltip: '',
            offset: const Offset(0, 78),
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06092B60),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
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
                          color: badgeGradient.last.withOpacity(0.32),
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
        );
      },
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
              color: iconColor.withOpacity(0.1),
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