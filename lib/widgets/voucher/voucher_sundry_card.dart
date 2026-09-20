import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../services/storage_service.dart';
import 'voucher_sundry_row.dart';
import '../../../utils/smart_filter.dart';

class VoucherSundryCard extends StatelessWidget {
  final List<VoucherSundryRow> sundries;
  final List<String>? availableSundries;
  final bool autoRoundOff;
  final double roundOff;
  final VoidCallback onAddSundry;
  final VoidCallback onToggleRoundOff;
  final void Function(int index, String field) onRowEnter;
  final VoidCallback onTabToSave;

  const VoucherSundryCard({
    super.key,
    required this.sundries,
    this.availableSundries,
    required this.autoRoundOff,
    required this.roundOff,
    required this.onAddSundry,
    required this.onToggleRoundOff,
    required this.onRowEnter,
    required this.onTabToSave,
  });

  List<String> get _sundryOptions {
    if (availableSundries != null && availableSundries!.isNotEmpty) {
      return availableSundries!;
    }
    return (StorageService.defaultCompanyMasters['billSundries'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isShiftPressed) {
          onTabToSave();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2)),
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
                    Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Bill Sundry & Expenses',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
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
                      // Sundry Name Field - Bound explicitly to s.nameFocus
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 30,
                          child: RawAutocomplete<String>(
                            focusNode: s.nameFocus,
                            textEditingController: s.name,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              return SmartFilter.filterAndSort<String>(
                                items: _sundryOptions,
                                query: textEditingValue.text,
                                labelExtractor: (val) => val,
                              );
                            },
                            onSelected: (selection) {
                              s.name.text = selection;
                              if (selection == 'Round Off-' || selection.toLowerCase().contains('discount')) {
                                s.isNegative = true;
                              } else {
                                s.isNegative = false;
                              }
                              onRowEnter(idx, 'name');
                            },
                            optionsViewBuilder: (context, onSelect, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.surface,
                                  child: Container(
                                    width: 220,
                                    constraints: const BoxConstraints(maxHeight: 180),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final opt = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelect(opt),
                                          hoverColor: AppColors.primaryLight,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            child: Text(
                                              opt,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
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
                              return Focus(
                                canRequestFocus: false,
                                skipTraversal: true,
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.tab &&
                                      !HardwareKeyboard.instance.isShiftPressed) {
                                    onTabToSave();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) {
                                    onFieldSubmitted();
                                    onRowEnter(idx, 'name');
                                  },
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  decoration: InputDecoration(
                                    hintText: 'Select sundry...',
                                    hintStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    filled: true,
                                    fillColor: AppColors.cardBg,
                                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.textSecondary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
                                  ),
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
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.tab &&
                                  !HardwareKeyboard.instance.isShiftPressed) {
                                onTabToSave();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
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
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              decoration: InputDecoration(
                                hintText: '%',
                                hintStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                filled: true,
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
                              ),
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
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.tab &&
                                  !HardwareKeyboard.instance.isShiftPressed) {
                                onTabToSave();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
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
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              decoration: InputDecoration(
                                hintText: 'Amount',
                                hintStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                filled: true,
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
                              ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: autoRoundOff,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggleRoundOff(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Auto Round-off',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${roundOff >= 0 ? '+' : ''}${roundOff.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: roundOff == 0 ? AppColors.textSecondary : AppColors.primary,
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