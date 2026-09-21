import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'voucher_item_row.dart';
import '../../constants/app_colors.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../../models/item_master_model.dart';
import '../common/app_autocomplete_field.dart';

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
        if (KeyboardShortcutService.isQuickAdd(event)) {
          onAddItem(items.length);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // TABLE HEADER
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1.2),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      'S.N.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      'Item Name & Description',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Unit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: Text(
                      'Price (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'Taxable (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Amount (₹) [Alt+E]',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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
                    const Divider(height: 1, color: AppColors.background),
                itemBuilder: (context, index) {
                  final row = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: AppAutocompleteField<ItemMasterModel>(
                            controller: row.item,
                            focusNode: row.itemFocus,
                            items: availableItems,
                            hintText: 'Type or select item...',
                            dropdownWidth: 380,
                            showDropdownArrow: false,
                            labelExtractor: (item) => item.name,
                            onQuickAdd: () => onAddItem(index),
                            onSelected: (selected) =>
                                onItemSelected(index, selected),
                            onFieldSubmitted: () => onRowEnter(index, 'item'),
                            optionItemBuilder: (context, item) => Padding(
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
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
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
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.taxCategory,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.successDark,
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            _getUnitString(row.unit),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
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
                        SizedBox(
                          width: 140,
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
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: AppColors.background)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onAddRow,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Add Row',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 90,
                    child: Text(
                      totalQty.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 190),
                  SizedBox(
                    width: 130,
                    child: Text(
                      totalTaxable.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Text(
                      totalAmount.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
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
              color: AppColors.primaryDark,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: isFocused ? AppColors.primary : AppColors.border,
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
