import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  static InputDecoration standard({
    required String label,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 17, color: AppColors.textSecondary) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: AppColors.surface,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: AppColors.primary, width: 1.4),
      errorBorder: _inputBorder(color: AppColors.error),
      focusedErrorBorder: _inputBorder(color: AppColors.error, width: 1.3),
    );
  }

  static OutlineInputBorder _inputBorder({Color? color, double width = 0.9}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color ?? AppColors.border.withValues(alpha: 0.85),
        width: width,
      ),
    );
  }
}