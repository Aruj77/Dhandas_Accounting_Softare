import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x04092B60), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: Color(0xFF10A35B)),
              SizedBox(width: 8),
              Text(
                'Taxation & Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Taxable Amount', '₹${subTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          if (!isInterState) ...[
            _buildSummaryRow('CGST Output (9.0%)', '₹${totalCgst.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _buildSummaryRow('SGST Output (9.0%)', '₹${totalSgst.toStringAsFixed(2)}'),
          ] else ...[
            _buildSummaryRow('IGST Output (18.0%)', '₹${totalIgst.toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 6),
          _buildSummaryRow('Bill Sundries / Other', '${sundryTotal >= 0 ? '+' : ''}₹${sundryTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildSummaryRow('Rounding Off', '${roundOff >= 0 ? '+' : ''}₹${roundOff.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE8EEF7), height: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF1F6FE), Color(0xFFE9F2FE)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
                Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Quit ($quitShortcutLabel)'),
              ),
              const SizedBox(width: 12),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSaveFocused ? const Color(0xFF0F62FE) : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSaveFocused
                            ? const [
                                BoxShadow(
                                  color: Color(0x330F62FE),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F62FE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'Save ($saveShortcutLabel)',
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF101B38))),
      ],
    );
  }
}