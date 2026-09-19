import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voucher_sundry_row.dart';

class VoucherSundryCard extends StatelessWidget {
  final List<VoucherSundryRow> sundries;
  final bool autoRoundOff;
  final double roundOff;
  final VoidCallback onAddSundry;
  final VoidCallback onToggleRoundOff;
  final void Function(int index, String field) onRowEnter;
  final VoidCallback onTabToSave;

  const VoucherSundryCard({
    super.key,
    required this.sundries,
    required this.autoRoundOff,
    required this.roundOff,
    required this.onAddSundry,
    required this.onToggleRoundOff,
    required this.onRowEnter,
    required this.onTabToSave,
  });

  static const List<String> fixedSundryOptions = [
    'Add. Cess on GST',
    'Add. Cess on GST (ITC-None)',
    'Cess on GST',
    'Cess on GST (ITC-None)',
    'CGST',
    'CGST (ITC-None)',
    'Discount',
    'Freight & Forwarding Charges',
    'IGST',
    'IGST (Export / SEZ Unit)',
    'IGST (ITC-None)',
    'Round Off-',
    'Round Off+',
    'SGST',
    'SGST (ITC-None)',
    'TCS (Tax Collected at Source)',
    'TDS on Pymt./Purc. of Goods',
  ];

  @override
  Widget build(BuildContext context) {
    const customCellBorderColor = Color.fromARGB(255, 204, 219, 241);

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          onTabToSave();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: customCellBorderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x04092B60), blurRadius: 8, offset: Offset(0, 2)),
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
                    Icon(Icons.tune_rounded, size: 15, color: Color(0xFF0F62FE)),
                    SizedBox(width: 6),
                    Text(
                      'Bill Sundry & Expenses',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onAddSundry,
                  icon: const Icon(Icons.add, size: 13),
                  label: const Text('Add', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 100,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sundries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, idx) {
                  final s = sundries[idx];
                  return Row(
                    children: [
                      // Sundry Name Field
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 30,
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: s.name.text),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') return fixedSundryOptions;
                              return fixedSundryOptions.where((opt) => opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (selection) {
                              s.name.text = selection;
                              if (selection == 'Round Off-' || selection == 'Discount') {
                                s.isNegative = true;
                              } else {
                                s.isNegative = false;
                              }
                              onRowEnter(idx, 'name');
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              controller.addListener(() => s.name.text = controller.text);
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  onFieldSubmitted();
                                  onRowEnter(idx, 'name');
                                },
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                                decoration: InputDecoration(
                                  hintText: 'Select sundry...',
                                  hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF90A1BA)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFBFD),
                                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFF64748B)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Percentage Field
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: s.percent,
                            focusNode: s.percentFocus,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => onRowEnter(idx, 'percent'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                            decoration: InputDecoration(
                              hintText: '%',
                              hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF90A1BA)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              filled: true,
                              fillColor: const Color(0xFFFAFBFD),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Amount Field
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: s.amount,
                            focusNode: s.amountFocus,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => onRowEnter(idx, 'amount'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF90A1BA)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              filled: true,
                              fillColor: const Color(0xFFFAFBFD),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: customCellBorderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Auto Round-off Container (border removed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: autoRoundOff,
                      activeColor: const Color(0xFF0F62FE),
                      onChanged: (_) => onToggleRoundOff(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Auto Round-off',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const Spacer(),
                  Text(
                    '${roundOff >= 0 ? '+' : ''}${roundOff.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
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
}