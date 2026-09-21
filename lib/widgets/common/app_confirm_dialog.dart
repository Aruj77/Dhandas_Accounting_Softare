import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum ConfirmDialogType {
  danger,
  warning,
  info,
}

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmDialogType type;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.type = ConfirmDialogType.warning,
    this.icon,
  });

  /// Displays the confirmation dialog and returns true if confirmed.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    ConfirmDialogType type = ConfirmDialogType.warning,
    IconData? icon,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  Color get _badgeColor {
    switch (type) {
      case ConfirmDialogType.danger:
        return AppColors.errorLight;
      case ConfirmDialogType.warning:
        return AppColors.warningLight;
      case ConfirmDialogType.info:
        return AppColors.primaryLight;
    }
  }

  Color get _primaryAccentColor {
    switch (type) {
      case ConfirmDialogType.danger:
        return AppColors.error;
      case ConfirmDialogType.warning:
        return AppColors.warning;
      case ConfirmDialogType.info:
        return AppColors.primary;
    }
  }

  IconData get _resolvedIcon {
    if (icon != null) return icon!;
    switch (type) {
      case ConfirmDialogType.danger:
        return Icons.delete_forever_rounded;
      case ConfirmDialogType.warning:
        return Icons.warning_amber_rounded;
      case ConfirmDialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_resolvedIcon, color: _primaryAccentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderMedium),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryAccentColor,
            foregroundColor: AppColors.surface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}