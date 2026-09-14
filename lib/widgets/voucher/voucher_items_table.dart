import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voucher_item_row.dart';

class VoucherItemsTable extends StatelessWidget {
  final List<VoucherItemRow> items;
  final bool isInterState;
  final double totalQty;
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalAmount;
  final VoidCallback onAddRow;
  final void Function(int index, String field) onRowEnter;
  final void Function(String masterType) onQuickAdd;
  final VoidCallback onTabToSundry;

  const VoucherItemsTable({
    super.key,
    required this.items,
    required this.isInterState,
    required this.totalQty,
    required this.totalTaxable,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalAmount,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x04092B60), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // TABLE HEADER
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 32, child: Text('S.N.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  const Expanded(flex: 5, child: Text('Item Name & Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 65, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 50, child: Text('Unit', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 75, child: Text('Price (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 85, child: Text('Taxable (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  if (!isInterState) ...[
                    const SizedBox(width: 8),
                    const SizedBox(width: 70, child: Text('CGST (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                    const SizedBox(width: 8),
                    const SizedBox(width: 70, child: Text('SGST (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  ] else ...[
                    const SizedBox(width: 8),
                    const SizedBox(width: 90, child: Text('IGST (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7E22CE)))),
                  ],
                  const SizedBox(width: 8),
                  const SizedBox(width: 90, child: Text('Amount (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                ],
              ),
            ),

            // SCROLLABLE TABLE ROWS (20 items max height)
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                itemBuilder: (context, index) {
                  final row = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF90A1BA))),
                        ),
                        Expanded(
                          flex: 5,
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
                          width: 65,
                          child: _buildSimpleGridInput(
                            controller: row.qty,
                            focusNode: row.qtyFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5FB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2EAF5)),
                          ),
                          child: Text(
                            _getUnitString(row.unit),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 75,
                          child: _buildSimpleGridInput(
                            controller: row.price,
                            focusNode: row.priceFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'price'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 85,
                          child: _buildSimpleGridInput(
                            controller: row.taxable,
                            focusNode: row.taxableFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'taxable'),
                          ),
                        ),
                        if (!isInterState) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: _buildSimpleGridInput(
                              controller: row.cgst,
                              focusNode: row.cgstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'cgst'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: _buildSimpleGridInput(
                              controller: row.sgst,
                              focusNode: row.sgstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'sgst'),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: _buildSimpleGridInput(
                              controller: row.igst,
                              focusNode: row.igstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'igst'),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            row.amount.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // FIXED TABLE TOTALS BAR AT THE BOTTOM
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddRow,
                    icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF0F62FE)),
                    label: const Text('Add Row', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F62FE))),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 65,
                    child: Text(totalQty.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                  ),
                  const SizedBox(width: 133),
                  SizedBox(
                    width: 85,
                    child: Text(totalTaxable.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                  ),
                  const SizedBox(width: 8),
                  if (!isInterState) ...[
                    SizedBox(
                      width: 70,
                      child: Text(totalCgst.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(totalSgst.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 90,
                      child: Text(totalIgst.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF7E22CE))),
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(totalAmount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
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
          height: 34,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => onSubmitted?.call(),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF90A1BA), fontWeight: FontWeight.w400),
                  contentPadding: EdgeInsets.only(left: 8, right: isFocused ? 26 : 8, top: 5, bottom: 5),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.6)),
                ),
              ),
              if (isFocused)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: InkWell(
                    onTap: () => onQuickAdd(masterType),
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: const Color(0xFF0F62FE), borderRadius: BorderRadius.circular(3)),
                      child: const Icon(Icons.add, size: 10, color: Colors.white),
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
          height: 34,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: textAlign,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isFocused ? const Color(0xFF0F62FE) : const Color(0xFFE5EDF7),
                  width: isFocused ? 1.6 : 1.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}