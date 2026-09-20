import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/focus_policy_service.dart';

class VoucherSaveConfirmDialog extends StatefulWidget {
  final Map<String, dynamic> summaryData;
  final VoidCallback onConfirm;

  const VoucherSaveConfirmDialog({
    super.key,
    required this.summaryData,
    required this.onConfirm,
  });

  @override
  State<VoucherSaveConfirmDialog> createState() => _VoucherSaveConfirmDialogState();
}

class _VoucherSaveConfirmDialogState extends State<VoucherSaveConfirmDialog> {
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _cancelFocusNode = FocusNode();

  @override
  void dispose() {
    _saveFocusNode.dispose();
    _cancelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summaryData;
    final isInterState = s['isInterState'] == true;

    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherSaveConfirmDialog,
      nodeMap: {
        FocusFieldNode.confirmYesButton: _saveFocusNode,
        FocusFieldNode.confirmNoButton: _cancelFocusNode,
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm ${s['voucherType']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                      ),
                      Text(
                        'Verify summary details before persisting',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metadata Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Voucher No.', s['voucherNumber']),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Date', s['date']),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Party', s['party']),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'GST Nature',
                      isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST+SGST)',
                      valueColor: isInterState ? AppColors.purple : AppColors.successDark,
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Total Items / Qty', '${s['itemCount']} items (${s['totalQty']} units)'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Accounting Totals
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Taxable Amount', '₹${(s['subTotal'] as double).toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    if (!isInterState) ...[
                      _buildSummaryRow('CGST Total', '₹${(s['cgst'] as double).toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      _buildSummaryRow('SGST Total', '₹${(s['sgst'] as double).toStringAsFixed(2)}'),
                    ] else ...[
                      _buildSummaryRow('IGST Total', '₹${(s['igst'] as double).toStringAsFixed(2)}'),
                    ],
                    if ((s['sundryTotal'] as double) != 0.0) ...[
                      const SizedBox(height: 6),
                      _buildSummaryRow('Bill Sundries', '₹${(s['sundryTotal'] as double).toStringAsFixed(2)}'),
                    ],
                    if ((s['roundOff'] as double) != 0.0) ...[
                      const SizedBox(height: 6),
                      _buildSummaryRow('Round Off', '₹${(s['roundOff'] as double).toStringAsFixed(2)}'),
                    ],
                    const Divider(height: 18, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                        Text(
                          '₹${(s['grandTotal'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    focusNode: _cancelFocusNode,
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Cancel (Esc)'),
                  ),
                  const SizedBox(width: 12),
                  Focus(
                    focusNode: _saveFocusNode,
                    child: Builder(builder: (context) {
                      final hasFocus = Focus.of(context).hasFocus;
                      return ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: hasFocus ? AppColors.primaryDark : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text(
                          'Confirm & Save (Enter)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}