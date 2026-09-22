import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  static OutlineInputBorder roundedBorder({
    Color? color,
    double width = 0.9,
    double radius = 12.0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: color ?? AppColors.border.withValues(alpha: 0.85),
        width: width,
      ),
    );
  }

  static InputDecoration standard({
    required String label,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: label.isNotEmpty ? label : null,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 17, color: AppColors.textSecondary)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: fillColor ?? AppColors.surface,
      border: roundedBorder(),
      enabledBorder: roundedBorder(),
      focusedBorder: roundedBorder(color: AppColors.primary, width: 1.4),
      errorBorder: roundedBorder(color: AppColors.error),
      focusedErrorBorder: roundedBorder(color: AppColors.error, width: 1.3),
    );
  }

  static InputDecoration compact({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = AppColors.cardBg,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: padding,
      filled: true,
      fillColor: fillColor,
      border: roundedBorder(radius: 8, width: 1.0),
      enabledBorder: roundedBorder(color: AppColors.border, radius: 8, width: 1.0),
      focusedBorder: roundedBorder(color: AppColors.primary, radius: 8, width: 1.4),
      errorBorder: roundedBorder(color: AppColors.error, radius: 8, width: 1.0),
      focusedErrorBorder:
          roundedBorder(color: AppColors.error, radius: 8, width: 1.3),
    );
  }
}