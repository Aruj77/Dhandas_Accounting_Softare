import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_shortcuts.dart';
import 'voucher_item_row.dart';

class ItemMasterModel {
  final String name;
  final String hsn;
  final String unit;
  final String taxCategory;
  final double taxRate;
  final double salesPrice;
  final double purchasePrice;
  final double mrp;

  const ItemMasterModel({
    required this.name,
    required this.hsn,
    required this.unit,
    required this.taxCategory,
    required this.taxRate,
    required this.salesPrice,
    required this.purchasePrice,
    required this.mrp,
  });
}

class VoucherItemsTable extends StatelessWidget {
  final List<VoucherItemRow> items;
  final List<ItemMasterModel> availableItems;
  final bool isInterState;
  final double totalQty;
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalAmount;
  final VoidCallback onAddRow;
  final void Function(int index, String field) onRowEnter;
  final void Function(int index) onAddItem;
  final void Function(int index, ItemMasterModel selectedItem) onItemSelected;
  final VoidCallback onTabToSundry;

  const VoucherItemsTable({
    super.key,
    required this.items,
    required this.availableItems,
    required this.isInterState,
    required this.totalQty,
    required this.totalTaxable,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalAmount,
    required this.onAddRow,
    required this.onRowEnter,
    required this.onAddItem,
    required this.onItemSelected,
    required this.onTabToSundry,
  });

  String _getUnitString(dynamic unitValue) {
    if (unitValue is TextEditingController) {
      return unitValue.text.isNotEmpty ? unitValue.text : 'Pcs';
    }
    return unitValue?.toString() ?? 'Pcs';
  }

  FocusNode? _focusForField(VoucherItemRow row, String field) {
    switch (field) {
      case 'item':
        return row.itemFocus;
      case 'qty':
        return row.qtyFocus;
      case 'price':
        return row.priceFocus;
      case 'taxable':
        return row.taxableFocus;
      case 'cgst':
        return isInterState ? null : row.cgstFocus;
      case 'sgst':
        return isInterState ? null : row.sgstFocus;
      case 'igst':
        return isInterState ? row.igstFocus : null;
      case 'amount':
        return row.amountFocus;
    }
    return null;
  }

  String? _fieldForNode(VoucherItemRow row, FocusNode node) {
    if (node == row.itemFocus) return 'item';
    if (node == row.qtyFocus) return 'qty';
    if (node == row.priceFocus) return 'price';
    if (node == row.taxableFocus) return 'taxable';
    if (node == row.cgstFocus) return 'cgst';
    if (node == row.sgstFocus) return 'sgst';
    if (node == row.igstFocus) return 'igst';
    if (node == row.amountFocus) return 'amount';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (AppShortcuts.isQuickAdd(event)) {
          final current = FocusManager.instance.primaryFocus;
          for (int i = 0; i < items.length; i++) {
            if (items[i].itemFocus == current) {
              onAddItem(i);
              return KeyEventResult.handled;
            }
          }
          onAddItem(items.length);
          return KeyEventResult.handled;
        }

        final key = event.logicalKey;
        final current = FocusManager.instance.primaryFocus;
        if (current == null) return KeyEventResult.ignored;

        // Up/Down: move to the SAME field in the previous/next item row —
        // this is what was completely missing before.
        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown) {
          for (int i = 0; i < items.length; i++) {
            final field = _fieldForNode(items[i], current);
            if (field == null) continue;
            final targetIndex = key == LogicalKeyboardKey.arrowDown
                ? i + 1
                : i - 1;
            if (targetIndex < 0 || targetIndex >= items.length)
              return KeyEventResult.ignored;
            final targetFocus = _focusForField(items[targetIndex], field);
            if (targetFocus == null) return KeyEventResult.ignored;
            targetFocus.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        // Tab: only jump to Bill Sundry from the LAST field of the LAST
        // row. Previously this fired on Tab from ANY field in the table,
        // which is why Tab always skipped straight to Sundry.
        if (key == LogicalKeyboardKey.tab && items.isNotEmpty) {
          final lastRow = items.last;
          final lastField = isInterState
              ? lastRow.igstFocus
              : lastRow.sgstFocus;
          if (current == lastRow.amountFocus || current == lastField) {
            onTabToSundry();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04092B60),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // TABLE HEADER
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    child: Text(
                      'S.N.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'Item Name & Description',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 60,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 45,
                    child: Text(
                      'Unit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 70,
                    child: Text(
                      'Price (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Taxable (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                  if (!isInterState) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 65,
                      child: Text(
                        'CGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7B9B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 65,
                      child: Text(
                        'SGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7B9B),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 85,
                      child: Text(
                        'IGST (₹)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 85,
                    child: Text(
                      'Amount (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TABLE ROWS
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5FB)),
                itemBuilder: (context, index) {
                  final row = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ), // <-- updated from 2
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF90A1BA),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: _buildItemAutocomplete(
                            row: row,
                            index: index,
                            onSubmitted: () => onRowEnter(index, 'item'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 60,
                          child: _buildSimpleGridInput(
                            controller: row.qty,
                            focusNode: row.qtyFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'qty'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 45,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5FB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2EAF5)),
                          ),
                          child: Text(
                            _getUnitString(row.unit),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 70,
                          child: _buildSimpleGridInput(
                            controller: row.price,
                            focusNode: row.priceFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'price'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          child: _buildSimpleGridInput(
                            controller: row.taxable,
                            focusNode: row.taxableFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'taxable'),
                          ),
                        ),
                        if (!isInterState) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 65,
                            child: _buildSimpleGridInput(
                              controller: row.cgst,
                              focusNode: row.cgstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'cgst'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 65,
                            child: _buildSimpleGridInput(
                              controller: row.sgst,
                              focusNode: row.sgstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'sgst'),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 85,
                            child: _buildSimpleGridInput(
                              controller: row.igst,
                              focusNode: row.igstFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'igst'),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 85,
                          child: _buildSimpleGridInput(
                            controller: row.amount,
                            focusNode: row.amountFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'amount'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // FOOTER TOTALS
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Color(0xFFF1F5FB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddRow,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 13,
                      color: Color(0xFF0F62FE),
                    ),
                    label: const Text(
                      'Add Row',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 60,
                    child: Text(
                      totalQty.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101B3A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 127),
                  SizedBox(
                    width: 80,
                    child: Text(
                      totalTaxable.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101B3A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!isInterState) ...[
                    SizedBox(
                      width: 65,
                      child: Text(
                        totalCgst.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101B3A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 65,
                      child: Text(
                        totalSgst.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101B3A),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 85,
                      child: Text(
                        totalIgst.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 85,
                    child: Text(
                      totalAmount.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F62FE),
                      ),
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

  Widget _buildItemAutocomplete({
    required VoucherItemRow row,
    required int index,
    required VoidCallback onSubmitted,
  }) {
    return SizedBox(
      height: 36,
      child: RawAutocomplete<ItemMasterModel>(
        focusNode: row.itemFocus,
        textEditingController: row.item,
        displayStringForOption: (item) => item.name,
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) return availableItems;
          return availableItems.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.hsn.toLowerCase().contains(query) ||
                item.taxCategory.toLowerCase().contains(query);
          });
        },
        onSelected: (ItemMasterModel selection) {
          row.item.text = selection.name;
          onItemSelected(index, selection);
          onSubmitted();
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD6E4F5),
                    width: 1.2,
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5FB)),
                  itemBuilder: (context, idx) {
                    final ItemMasterModel item = options.elementAt(idx);
                    return InkWell(
                      onTap: () => onSelected(item),
                      hoverColor: const Color(0xFFF4F8FE),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: Color(0xFF0F62FE),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF101B3A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'HSN: ${item.hsn}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.taxCategory,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF15803D),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return ListenableBuilder(
            listenable: focusNode,
            builder: (context, _) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  onFieldSubmitted();
                  onSubmitted();
                },
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101B3A),
                ),
                decoration: InputDecoration(
                  hintText: 'Type or select item...',
                  hintStyle: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF90A1BA),
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: focusNode.hasFocus
                      ? Focus(
                          canRequestFocus: false,
                          descendantsAreFocusable: false,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                size: 15,
                                color: Color(0xFF0F62FE),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                maxWidth: 18,
                                maxHeight: 18,
                              ),
                              onPressed: () => onAddItem(index),
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F62FE),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
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
          height: 36,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: textAlign,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101B3A),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFE5EDF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: isFocused
                      ? const Color(0xFF0F62FE)
                      : const Color(0xFFE5EDF7),
                  width: isFocused ? 1.5 : 1.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
