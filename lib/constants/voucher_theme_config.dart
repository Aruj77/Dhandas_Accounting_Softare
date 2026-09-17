// lib/constants/voucher_theme_config.dart
import 'package:flutter/material.dart';

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
        primary: Color(0xFF2563EB), // Indigo-Blue
        primaryContainer: Color(0xFFEFF6FF),
        background: Color(0xFFF8FAFC),
        surface: Colors.white,
        border: Color(0xFFE2E8F0),
        onPrimary: Colors.white,
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF64748B),
        headerGradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('purchase')) {
      return const VoucherThemeTokens(
        primary: Color(0xFF7C3AED), // Purple-Violet
        primaryContainer: Color(0xFFF5F3FF),
        background: Color(0xFFFAF5FF),
        surface: Colors.white,
        border: Color(0xFFE9D5FF),
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E1B4B),
        onSurfaceVariant: Color(0xFF6B7280),
        headerGradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('payment')) {
      return const VoucherThemeTokens(
        primary: Color(0xFFDC2626), // Amber-Red Outflow
        primaryContainer: Color(0xFFFEF2F2),
        background: Color(0xFFFFF7ED),
        surface: Colors.white,
        border: Color(0xFFFED7AA),
        onPrimary: Colors.white,
        onSurface: Color(0xFF451A03),
        onSurfaceVariant: Color(0xFF78716C),
        headerGradient: LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('receipt')) {
      return const VoucherThemeTokens(
        primary: Color(0xFF059669), // Emerald Inflow
        primaryContainer: Color(0xFFECFDF5),
        background: Color(0xFFF0FDF4),
        surface: Colors.white,
        border: Color(0xFFA7F3D0),
        onPrimary: Colors.white,
        onSurface: Color(0xFF064E3B),
        onSurfaceVariant: Color(0xFF065F46),
        headerGradient: LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (vch.contains('contra')) {
      return const VoucherThemeTokens(
        primary: Color(0xFF0284C7), // Sky Blue
        primaryContainer: Color(0xFFF0F9FF),
        background: Color(0xFFF8FAFC),
        surface: Colors.white,
        border: Color(0xFFBAE6FD),
        onPrimary: Colors.white,
        onSurface: Color(0xFF0C4A6E),
        onSurfaceVariant: Color(0xFF64748B),
        headerGradient: LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      // Default / Journal
      return const VoucherThemeTokens(
        primary: Color(0xFF4B5563), // Neutral Slate
        primaryContainer: Color(0xFFF3F4F6),
        background: Color(0xFFF9FAFB),
        surface: Colors.white,
        border: Color(0xFFE5E7EB),
        onPrimary: Colors.white,
        onSurface: Color(0xFF111827),
        onSurfaceVariant: Color(0xFF4B5563),
        headerGradient: LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF6B7280)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
  }
}