// lib/widgets/voucher/popup/voucher_dialog_utils.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';

class DialogActionConfig {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDanger;

  const DialogActionConfig({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
  });
}

class AppWarningDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color badgeColor;
  final Color accentColor;
  final List<DialogActionConfig> actions;
  final FocusTargetScreen focusScreen;

  const AppWarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.badgeColor = AppColors.badgeYellowBg,
    this.accentColor = AppColors.warning,
    required this.actions,
    this.focusScreen = FocusTargetScreen.voucherSaveConfirmDialog,
  });

  @override
  State<AppWarningDialog> createState() => _AppWarningDialogState();
}

class _AppWarningDialogState extends State<AppWarningDialog> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.actions.length, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty && _focusNodes.last.canRequestFocus) {
        _focusNodes.last.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: widget.focusScreen,
      nodeMap: {
        FocusFieldNode.confirmNoButton: _focusNodes.first,
        FocusFieldNode.confirmYesButton: _focusNodes.last,
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          widget.message,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: List.generate(widget.actions.length, (i) {
          final action = widget.actions[i];
          return _FocusableDialogButton(
            focusNode: _focusNodes[i],
            isPrimary: action.isPrimary,
            isDanger: action.isDanger,
            label: action.label,
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed();
            },
          );
        }),
      ),
    );
  }
}

class VoucherDialogUtils {
  static Future<bool> showUnsavedChangesDialog(BuildContext context) async {
    bool shouldExit = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppWarningDialog(
        title: 'Unsaved Changes',
        message: 'You have unsaved changes in this voucher. Discard and return to workspace?',
        icon: Icons.warning_amber_rounded,
        badgeColor: AppColors.errorLight,
        accentColor: AppColors.errorDark,
        focusScreen: FocusTargetScreen.unsavedChangesDialog,
        actions: [
          DialogActionConfig(
            label: 'Keep Editing',
            onPressed: () => shouldExit = false,
          ),
          DialogActionConfig(
            label: 'Discard & Exit',
            onPressed: () => shouldExit = true,
            isPrimary: true,
            isDanger: true,
          ),
        ],
      ),
    );
    return shouldExit;
  }

  static void showMissingVchNoWarning({
    required BuildContext context,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppWarningDialog(
        title: 'Warning',
        message: 'You are proceeding without entering voucher no. Do you want to continue?',
        focusScreen: FocusTargetScreen.missingVchNoWarningDialog,
        actions: [
          DialogActionConfig(label: 'No', onPressed: onCancel),
          DialogActionConfig(label: 'Yes', onPressed: onConfirm, isPrimary: true),
        ],
      ),
    );
  }

  static void showDuplicateVchNoWarning({
    required BuildContext context,
    required String companyName,
    required VoidCallback onNo,
    required VoidCallback onOpenVoucher,
    required VoidCallback onYes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppWarningDialog(
        title: 'Voucher Number Exists',
        message: 'This voucher no is already assigned to $companyName. Do you still want to continue?',
        focusScreen: FocusTargetScreen.duplicateVchNoWarningDialog,
        actions: [
          DialogActionConfig(label: 'No', onPressed: onNo, isPrimary: true, isDanger: true),
          DialogActionConfig(label: 'Open Voucher', onPressed: onOpenVoucher),
          DialogActionConfig(label: 'Yes', onPressed: onYes),
        ],
      ),
    );
  }

  static void showMasterNotFoundDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onAdd,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppWarningDialog(
        title: title,
        message: message,
        focusScreen: FocusTargetScreen.masterNotFoundDialog,
        actions: [
          DialogActionConfig(label: 'Cancel', onPressed: onCancel),
          DialogActionConfig(label: 'Add', onPressed: onAdd, isPrimary: true),
        ],
      ),
    );
  }

  static void showTaxMismatchWarning({
    required BuildContext context,
    required String enteredType,
    required String partyBelongsToText,
    required VoidCallback onAdjust,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppWarningDialog(
        title: 'Taxation Alert',
        message: 'You are entering a $enteredType but party belongs to $partyBelongsToText.\n\nDo you want to adjust or continue as is?',
        focusScreen: FocusTargetScreen.taxMismatchWarningDialog,
        actions: [
          DialogActionConfig(label: 'Adjust Mode', onPressed: onAdjust, isPrimary: true),
          DialogActionConfig(label: 'Continue As Is', onPressed: onCancel),
        ],
      ),
    );
  }
}

class _FocusableDialogButton extends StatelessWidget {
  final FocusNode focusNode;
  final bool isPrimary;
  final bool isDanger;
  final String label;
  final VoidCallback onPressed;

  const _FocusableDialogButton({
    required this.focusNode,
    required this.isPrimary,
    this.isDanger = false,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (KeyboardShortcutService.isConfirm(event)) {
              Navigator.pop(context, true);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          final activeRingColor = isDanger ? AppColors.errorDark : AppColors.primary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFocus ? activeRingColor : Colors.transparent,
                width: 2.2,
              ),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: activeRingColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: isPrimary
                ? ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDanger ? AppColors.error : AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderMedium),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
          );
        },
      ),
    );
  }
}