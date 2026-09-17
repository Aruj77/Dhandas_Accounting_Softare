import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voucher_item_row.dart';
import './../../constants/app_shortcuts.dart';

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
  final double totalAmount;
  final VoidCallback onAddRow;
  final void Function(int index, String field) onRowEnter;
  final void Function(int index) onAddItem;
  final void Function(int index, ItemMasterModel selectedItem) onItemSelected;
  final void Function(int index) onOpenTaxDetails;
  final VoidCallback onTabToSundry;

  const VoucherItemsTable({
    super.key,
    required this.items,
    required this.availableItems,
    required this.isInterState,
    required this.totalQty,
    required this.totalTaxable,
    required this.totalAmount,
    required this.onAddRow,
    required this.onRowEnter,
    required this.onAddItem,
    required this.onItemSelected,
    required this.onOpenTaxDetails,
    required this.onTabToSundry,
  });

  String _getUnitString(dynamic unitValue) {
    if (unitValue is TextEditingController) {
      return unitValue.text.isNotEmpty ? unitValue.text : 'Pcs';
    }
    return unitValue?.toString() ?? 'Pcs';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (AppShortcuts.isQuickAdd(event)) {
          onAddItem(items.length);
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
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 32, child: Text('S.N.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  Expanded(flex: 6, child: Text('Item Name & Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  SizedBox(width: 10),
                  SizedBox(width: 90, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  SizedBox(width: 10),
                  SizedBox(width: 60, child: Text('Unit', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  SizedBox(width: 10),
                  SizedBox(width: 110, child: Text('Price (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  SizedBox(width: 10),
                  SizedBox(width: 130, child: Text('Taxable (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Text('Amount (₹) [Alt+E]', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE))),
                  ),
                ],
              ),
            ),

            // TABLE ROWS
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                itemBuilder: (context, index) {
                  final row = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF90A1BA))),
                        ),
                        Expanded(
                          flex: 6,
                          child: _buildItemAutocomplete(
                            row: row,
                            index: index,
                            onSubmitted: () => onRowEnter(index, 'item'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: _buildSimpleGridInput(
                            controller: row.qty,
                            focusNode: row.qtyFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'qty'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 60,
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
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: _buildSimpleGridInput(
                            controller: row.price,
                            focusNode: row.priceFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'price'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: _buildSimpleGridInput(
                            controller: row.taxable,
                            focusNode: row.taxableFocus,
                            textAlign: TextAlign.right,
                            onSubmitted: () => onRowEnter(index, 'taxable'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Amount with Alt+E shortcut handling
                        SizedBox(
                          width: 140,
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (AppShortcuts.isTaxDetails(event)) {
                                onOpenTaxDetails(index);
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: _buildSimpleGridInput(
                              controller: row.amount,
                              focusNode: row.amountFocus,
                              textAlign: TextAlign.right,
                              onSubmitted: () => onRowEnter(index, 'amount'),
                            ),
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
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFF1F5FB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddRow,
                    icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF0F62FE)),
                    label: const Text('Add Row', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F62FE))),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 90,
                    child: Text(totalQty.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                  ),
                  const SizedBox(width: 190),
                  SizedBox(
                    width: 130,
                    child: Text(totalTaxable.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF101B3A))),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Text(totalAmount.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
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
                  border: Border.all(color: const Color(0xFFD6E4F5), width: 1.2),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                  itemBuilder: (context, idx) {
                    final ItemMasterModel item = options.elementAt(idx);
                    return InkWell(
                      onTap: () => onSelected(item),
                      hoverColor: const Color(0xFFF4F8FE),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF0F62FE)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text('HSN: ${item.hsn}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Text(item.taxCategory, style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
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
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                decoration: InputDecoration(
                  hintText: 'Type or select item...',
                  hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF90A1BA), fontWeight: FontWeight.w400),
                  suffixIcon: focusNode.hasFocus
                      ? Focus(
                          canRequestFocus: false,
                          descendantsAreFocusable: false,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              icon: const Icon(Icons.add_circle, size: 16, color: Color(0xFF0F62FE)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(maxWidth: 20, maxHeight: 20),
                              onPressed: () => onAddItem(index),
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5)),
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
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isFocused ? const Color(0xFF0F62FE) : const Color(0xFFE5EDF7),
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