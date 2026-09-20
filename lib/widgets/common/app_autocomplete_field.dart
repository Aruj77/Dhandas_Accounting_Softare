import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../../utils/smart_filter.dart';

typedef OptionItemBuilder<T> = Widget Function(BuildContext context, T option);

class AppAutocompleteField<T extends Object> extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<T> items;
  final String Function(T) labelExtractor;
  final ValueChanged<T> onSelected;
  final OptionItemBuilder<T>? optionItemBuilder;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final double dropdownWidth;
  final double maxDropdownHeight;
  final double height;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onFieldSubmitted;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool showDropdownArrow;

  const AppAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.items,
    required this.labelExtractor,
    required this.onSelected,
    this.optionItemBuilder,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.dropdownWidth = 320,
    this.maxDropdownHeight = 240,
    this.height = 36,
    this.onQuickAdd,
    this.onFieldSubmitted,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.showDropdownArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (onQuickAdd != null && KeyboardShortcutService.isQuickAdd(event)) {
          onQuickAdd!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: height,
        child: RawAutocomplete<T>(
          focusNode: focusNode,
          textEditingController: controller,
          displayStringForOption: (item) => labelExtractor(item),
          optionsBuilder: (TextEditingValue textEditingValue) {
            return SmartFilter.filterAndSort<T>(
              items: items,
              query: textEditingValue.text,
              labelExtractor: labelExtractor,
            );
          },
          onSelected: (T selection) {
            controller.text = labelExtractor(selection);
            onSelected(selection);
            onFieldSubmitted?.call();
          },
          optionsViewBuilder: (context, onSelect, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                shadowColor: AppColors.shadowColor,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
                child: Container(
                  width: dropdownWidth,
                  constraints: BoxConstraints(maxHeight: maxDropdownHeight),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.background,
                    ),
                    itemBuilder: (context, index) {
                      final T option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelect(option),
                        hoverColor: AppColors.primaryLight,
                        child: optionItemBuilder != null
                            ? optionItemBuilder!(context, option)
                            : _buildDefaultOptionTile(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, textController, fieldFocusNode, onSubmitted) {
            return ListenableBuilder(
              listenable: fieldFocusNode,
              builder: (context, _) {
                final hasFocus = fieldFocusNode.hasFocus;
                return TextFormField(
                  controller: textController,
                  focusNode: fieldFocusNode,
                  validator: validator,
                  textCapitalization: textCapitalization,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    onSubmitted();
                    onFieldSubmitted?.call();
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hintText,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    hintStyle: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: prefixIcon != null
                        ? Icon(prefixIcon, size: 14, color: AppColors.primary)
                        : null,
                    suffixIcon: _buildSuffixIcon(hasFocus),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 24,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.3,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool hasFocus) {
    if (hasFocus && onQuickAdd != null) {
      return ExcludeFocus(
        excluding: true,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          child: IconButton(
            focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
            icon: const Icon(Icons.add_circle, size: 17, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 22, maxHeight: 22),
            onPressed: onQuickAdd,
          ),
        ),
      );
    }
    if (showDropdownArrow) {
      return const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppColors.textSecondary,
      );
    }
    return null;
  }

  Widget _buildDefaultOptionTile(T option) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        labelExtractor(option),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}