import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.left,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: maxLines == 1 ? 38 : null,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            autofocus: autofocus,
            maxLines: maxLines,
            textAlign: textAlign,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            validator: validator,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: readOnly ? AppColors.background : AppColors.cardBg,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}