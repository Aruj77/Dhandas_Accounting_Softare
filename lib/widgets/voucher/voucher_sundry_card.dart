import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voucher_sundry_row.dart';

class VoucherSundryCard extends StatelessWidget {
  final List<VoucherSundryRow> sundries;
  final bool autoRoundOff;
  final double roundOff;
  final VoidCallback onAddSundry;
  final VoidCallback onToggleRoundOff;
  final void Function(int index) onToggleNegative;
  final void Function(int index, String field) onRowEnter;
  final void Function(String masterType) onQuickAdd;
  final VoidCallback onTabToSave;

  const VoucherSundryCard({
    super.key,
    required this.sundries,
    required this.autoRoundOff,
    required this.roundOff,
    required this.onAddSundry,
    required this.onToggleRoundOff,
    required this.onToggleNegative,
    required this.onRowEnter,
    required this.onQuickAdd,
    required this.onTabToSave,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          onTabToSave();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x04092B60), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0F62FE)),
                    SizedBox(width: 8),
                    Text(
                      'Bill Sundry & Expenses',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onAddSundry,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Add Sundry', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sundries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final s = sundries[idx];
                return Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildGridInputWithFocus(
                        controller: s.name,
                        focusNode: s.nameFocus,
                        hint: 'Sundry name (Freight/Dis.)',
                        masterType: 'Bill Sundry',
                        onSubmitted: () => onRowEnter(idx, 'name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => onToggleNegative(idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: s.isNegative ? const Color(0xFFFFECEC) : const Color(0xFFE5F8EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.isNegative ? '(-) Sub' : '(+) Add',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: s.isNegative ? const Color(0xFFEE4343) : const Color(0xFF10A35B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _buildSimpleGridInput(
                        controller: s.amount,
                        focusNode: s.amountFocus,
                        textAlign: TextAlign.right,
                        onSubmitted: () => onRowEnter(idx, 'amount'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4EDF7)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: autoRoundOff,
                    activeColor: const Color(0xFF0F62FE),
                    onChanged: (_) => onToggleRoundOff(),
                  ),
                  const Text(
                    'Auto Round-off Grand Total',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const Spacer(),
                  Text(
                    '${roundOff >= 0 ? '+' : ''}${roundOff.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: roundOff == 0 ? const Color(0xFF64748B) : const Color(0xFF0F62FE),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridInputWithFocus({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String masterType,
    VoidCallback? onSubmitted,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return SizedBox(
          height: 38,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => onSubmitted?.call(),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF90A1BA), fontWeight: FontWeight.w400),
                  contentPadding: EdgeInsets.only(left: 10, right: isFocused ? 28 : 10, top: 8, bottom: 8),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.2)),
                ),
              ),
              if (isFocused)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: InkWell(
                    onTap: () => onQuickAdd(masterType),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: const Color(0xFF0F62FE), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.add, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleGridInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    TextAlign textAlign = TextAlign.left,
    VoidCallback? onSubmitted,
  }) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: textAlign,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted?.call(),
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFFAFBFD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.2)),
        ),
      ),
    );
  }
}