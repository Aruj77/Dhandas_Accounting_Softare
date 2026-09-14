import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/voucher/voucher_item_row.dart';

class VoucherItemsTable extends StatelessWidget {
  final List<VoucherItemRow> items;
  final bool isInterState;
  final double subTotal;
  final double totalTax;
  final VoidCallback onAddRow;
  final void Function(int index, String field) onRowEnter;
  final void Function(String masterType) onQuickAdd;
  final VoidCallback onTabToSundry;

  const VoucherItemsTable({
    super.key,
    required this.items,
    required this.isInterState,
    required this.subTotal,
    required this.totalTax,
    required this.onAddRow,
    required this.onRowEnter,
    required this.onQuickAdd,
    required this.onTabToSundry,
  });

  String _getUnitString(dynamic unitValue) {
    if (unitValue is TextEditingController) {
      return unitValue.text.isNotEmpty ? unitValue.text : 'PCS';
    }
    return unitValue?.toString() ?? 'PCS';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          onTabToSundry();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
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
            // TABLE HEADER
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 36,
                    child: Text(
                      'S.N.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 6,
                    child: Text(
                      'Item Name & Description',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 75,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 55,
                    child: Text(
                      'Unit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      'Price (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 95,
                    child: Text(
                      'Taxable (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  if (!isInterState) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 85,
                      child: Text(
                        'CGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7B9B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 85,
                      child: Text(
                        'SGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7B9B),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 105,
                      child: Text(
                        'IGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 105,
                    child: Text(
                      'Amount (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TABLE ROWS
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
              itemBuilder: (context, index) {
                final row = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF90A1BA),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: _buildGridInputWithFocus(
                          controller: row.item,
                          focusNode: row.itemFocus,
                          hint: 'Type or select item...',
                          masterType: 'Item',
                          onSubmitted: () => onRowEnter(index, 'item'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        child: _buildSimpleGridInput(
                          controller: row.qty,
                          focusNode: row.qtyFocus,
                          textAlign: TextAlign.right,
                          onSubmitted: () => onRowEnter(index, 'qty'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Non-navigable Unit badge
                      Container(
                        width: 55,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5FB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2EAF5)),
                        ),
                        child: Text(
                          _getUnitString(row.unit),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: _buildSimpleGridInput(
                          controller: row.price,
                          focusNode: row.priceFocus,
                          textAlign: TextAlign.right,
                          onSubmitted: () => onRowEnter(index, 'price'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Editable Taxable Field
                      SizedBox(
                        width: 95,
                        child: _buildSimpleGridInput(
                          controller: row.taxable,
                          focusNode: row.taxableFocus,
                          textAlign: TextAlign.right,
                          onSubmitted: () => onRowEnter(index, 'taxable'),
                        ),
                      ),
                      if (!isInterState) ...[
                        const SizedBox(width: 8),
                        // Editable CGST Field
                        SizedBox(
                          width: 85,
                          child: _buildSimpleGridInput(
                            controller: row.cgst,
                            focusNode: row.cgstFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'cgst'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Editable SGST Field
                        SizedBox(
                          width: 85,
                          child: _buildSimpleGridInput(
                            controller: row.sgst,
                            focusNode: row.sgstFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'sgst'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        // Editable IGST Field
                        SizedBox(
                          width: 105,
                          child: _buildSimpleGridInput(
                            controller: row.igst,
                            focusNode: row.igstFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'igst'),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Non-navigable computed Amount
                      SizedBox(
                        width: 105,
                        child: Text(
                          row.amount.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101B3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // TABLE ACTIONS & SUMMARY BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: Color(0xFFF1F5FB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddRow,
                    icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0F62FE)),
                    label: const Text(
                      'Add Item Row',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Total Taxable:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7B9B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${subTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101B3A),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Total GST:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7B9B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${totalTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0FA75D),
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
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101B3A),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF90A1BA),
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: EdgeInsets.only(
                    left: 10,
                    right: isFocused ? 28 : 10,
                    top: 8,
                    bottom: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.8),
                  ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F62FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: textAlign,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101B3A),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isFocused ? const Color(0xFF0F62FE) : const Color(0xFFE5EDF7),
                  width: isFocused ? 1.8 : 1.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}