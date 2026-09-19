// lib/constants/voucher_theme_config.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class VoucherThemeTokens {
  final Color primary;
  final Color primaryContainer;
  final Color background;
  final Color surface;
  final Color border;
  final Color onPrimary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Gradient headerGradient;

  const VoucherThemeTokens({
    required this.primary,
    required this.primaryContainer,
    required this.background,
    required this.surface,
    required this.border,
    required this.onPrimary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.headerGradient,
  });

  static VoucherThemeTokens resolve(String voucherType) {
    final vch = voucherType.toLowerCase();
    if (vch.contains('sale')) {
      return const VoucherThemeTokens(
        primary: AppColors.primaryAccent,
        primaryContainer: AppColors.primaryLight,
        background: AppColors.background,
        surface: AppColors.surface,
        border: AppColors.border,
        onPrimary: AppColors.surface,
        onSurface: AppColors.primaryDark,
        onSurfaceVariant: AppColors.textSecondary,
        headerGradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('purchase')) {
      return const VoucherThemeTokens(
        primary: AppColors.purple,
        primaryContainer: AppColors.purpleLight,
        background: AppColors.purpleLight,
        surface: AppColors.surface,
        border: AppColors.border,
        onPrimary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        headerGradient: LinearGradient(
          colors: [AppColors.purple, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('payment')) {
      return const VoucherThemeTokens(
        primary: AppColors.errorDark,
        primaryContainer: AppColors.errorLight,
        background: AppColors.errorLight,
        surface: AppColors.surface,
        border: AppColors.border,
        onPrimary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        headerGradient: LinearGradient(
          colors: [AppColors.errorDark, AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('receipt')) {
      return const VoucherThemeTokens(
        primary: AppColors.success,
        primaryContainer: AppColors.successLight,
        background: AppColors.successLight,
        surface: AppColors.surface,
        border: AppColors.successBorder,
        onPrimary: AppColors.surface,
        onSurface: AppColors.successDark,
        onSurfaceVariant: AppColors.textSecondary,
        headerGradient: LinearGradient(
          colors: [AppColors.successDark, AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('contra')) {
      return const VoucherThemeTokens(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        background: AppColors.background,
        surface: AppColors.surface,
        border: AppColors.border,
        onPrimary: AppColors.surface,
        onSurface: AppColors.primaryDark,
        onSurfaceVariant: AppColors.textSecondary,
        headerGradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      // Default / Journal
      return const VoucherThemeTokens(
        primary: AppColors.textSecondary,
        primaryContainer: AppColors.cardBg,
        background: AppColors.background,
        surface: AppColors.surface,
        border: AppColors.border,
        onPrimary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
        headerGradient: LinearGradient(
          colors: [AppColors.textSecondary, AppColors.textMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
  }
}