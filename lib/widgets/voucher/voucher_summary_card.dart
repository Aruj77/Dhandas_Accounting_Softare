import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class VoucherSummaryCard extends StatelessWidget {
  final bool isInterState;
  final double subTotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double sundryTotal;
  final double roundOff;
  final double grandTotal;
  final FocusNode saveButtonFocusNode;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final String saveShortcutLabel;
  final String quitShortcutLabel;

  const VoucherSummaryCard({
    super.key,
    required this.isInterState,
    required this.subTotal,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.sundryTotal,
    required this.roundOff,
    required this.grandTotal,
    required this.saveButtonFocusNode,
    required this.onSave,
    required this.onClose,
    required this.saveShortcutLabel,
    required this.quitShortcutLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.dialogShadowLight, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 15, color: AppColors.success),
              SizedBox(width: 6),
              Text(
                'Taxation & Summary',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildSummaryRow('Taxable Amount', '₹${subTotal.toStringAsFixed(2)}'),
          if (!isInterState) ...[
            _buildSummaryRow('CGST Output', '₹${totalCgst.toStringAsFixed(2)}'),
            _buildSummaryRow('SGST Output', '₹${totalSgst.toStringAsFixed(2)}'),
          ] else ...[
            _buildSummaryRow('IGST Output', '₹${totalIgst.toStringAsFixed(2)}'),
          ],
          _buildSummaryRow('Sundries', '${sundryTotal >= 0 ? '+' : ''}₹${sundryTotal.toStringAsFixed(2)}'),
          _buildSummaryRow('Rounding', '${roundOff >= 0 ? '+' : ''}₹${roundOff.toStringAsFixed(2)}'),
          const Divider(color: AppColors.border, height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.background, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text('Quit ($quitShortcutLabel)', style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Focus(
                focusNode: saveButtonFocusNode,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    onSave();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final isSaveFocused = Focus.of(context).hasFocus;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSaveFocused ? AppColors.primary : Colors.transparent,
                          width: 2.2,
                        ),
                        boxShadow: isSaveFocused
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: Text(
                          'Save ($saveShortcutLabel)',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}