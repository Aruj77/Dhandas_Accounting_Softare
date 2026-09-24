// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum NotificationType { success, error, warning, info }

class NotificationService {
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    if (!context.mounted) return;
    
    // Clear active snackbars to prevent visual stacking queues
    ScaffoldMessenger.of(context).clearSnackBars();

    final (Color bgCol, Color fgCol, IconData defaultIcon) = switch (type) {
      NotificationType.success => (AppColors.success, AppColors.surface, Icons.check_circle_rounded),
      NotificationType.error => (AppColors.error, AppColors.surface, Icons.error_outline_rounded),
      NotificationType.warning => (AppColors.warning, AppColors.surface, Icons.warning_amber_rounded),
      NotificationType.info => (AppColors.primary, AppColors.surface, Icons.info_outline_rounded),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: fgCol, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fgCol,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgCol,
        behavior: behavior,
        duration: duration,
        action: action,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: behavior == SnackBarBehavior.floating ? const EdgeInsets.all(16) : null,
      ),
    );
  }
}