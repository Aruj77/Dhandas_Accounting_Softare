// lib/widgets/voucher/popup/voucher_dialog_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../services/focus_policy_service.dart';

class VoucherDialogUtils {
  static void showMissingVchNoWarning({
    required BuildContext context,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MissingVchNoDialog(
        onConfirm: onConfirm,
        onCancel: onCancel,
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
      builder: (ctx) => _MasterNotFoundDialog(
        title: title,
        message: message,
        onAdd: onAdd,
        onCancel: onCancel,
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
      builder: (ctx) => _TaxMismatchDialog(
        enteredType: enteredType,
        partyBelongsToText: partyBelongsToText,
        onAdjust: onAdjust,
        onCancel: onCancel,
      ),
    );
  }

  static Future<bool> showUnsavedChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _UnsavedChangesDialog(),
    );
    return result ?? false;
  }
}

// ---------------------------------------------------------------------------
// 1. Unsaved Changes Warning Dialog (Focus on "Keep Editing")
// ---------------------------------------------------------------------------
class _UnsavedChangesDialog extends StatefulWidget {
  const _UnsavedChangesDialog();

  @override
  State<_UnsavedChangesDialog> createState() => _UnsavedChangesDialogState();
}

class _UnsavedChangesDialogState extends State<_UnsavedChangesDialog> {
  final FocusNode _keepEditingNode = FocusNode();
  final FocusNode _discardNode = FocusNode();

  @override
  void dispose() {
    _keepEditingNode.dispose();
    _discardNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.unsavedChangesDialog,
      nodeMap: {
        FocusFieldNode.confirmNoButton: _keepEditingNode, // Default Focus Target
        FocusFieldNode.confirmYesButton: _discardNode,
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.errorDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Unsaved Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved changes in this voucher. Discard and return to workspace?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          _FocusableDialogButton(
            focusNode: _keepEditingNode,
            isPrimary: false,
            label: 'Keep Editing',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 8),
          _FocusableDialogButton(
            focusNode: _discardNode,
            isPrimary: true,
            isDanger: true,
            label: 'Discard & Exit',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Missing Voucher Number Warning Dialog
// ---------------------------------------------------------------------------
class _MissingVchNoDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _MissingVchNoDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_MissingVchNoDialog> createState() => _MissingVchNoDialogState();
}

class _MissingVchNoDialogState extends State<_MissingVchNoDialog> {
  final FocusNode _yesNode = FocusNode();
  final FocusNode _noNode = FocusNode();

  @override
  void dispose() {
    _yesNode.dispose();
    _noNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.missingVchNoWarningDialog,
      nodeMap: {
        FocusFieldNode.confirmYesButton: _yesNode,
        FocusFieldNode.confirmNoButton: _noNode,
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.badgeYellowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Warning',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'You are proceeding without entering voucher no. Do you want to continue?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          _FocusableDialogButton(
            focusNode: _noNode,
            isPrimary: false,
            label: 'No',
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
          ),
          const SizedBox(width: 8),
          _FocusableDialogButton(
            focusNode: _yesNode,
            isPrimary: true,
            label: 'Yes',
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirm();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Master Not Found Dialog
// ---------------------------------------------------------------------------
class _MasterNotFoundDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const _MasterNotFoundDialog({
    required this.title,
    required this.message,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<_MasterNotFoundDialog> createState() => _MasterNotFoundDialogState();
}

class _MasterNotFoundDialogState extends State<_MasterNotFoundDialog> {
  final FocusNode _addNode = FocusNode();
  final FocusNode _cancelNode = FocusNode();

  @override
  void dispose() {
    _addNode.dispose();
    _cancelNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.masterNotFoundDialog,
      nodeMap: {
        FocusFieldNode.confirmYesButton: _addNode,
        FocusFieldNode.confirmNoButton: _cancelNode,
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.badgeYellowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
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
        actions: [
          _FocusableDialogButton(
            focusNode: _cancelNode,
            isPrimary: false,
            label: 'Cancel',
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
          ),
          const SizedBox(width: 8),
          _FocusableDialogButton(
            focusNode: _addNode,
            isPrimary: true,
            label: 'Add',
            onPressed: () {
              Navigator.pop(context);
              widget.onAdd();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Tax Mismatch Dialog
// ---------------------------------------------------------------------------
class _TaxMismatchDialog extends StatefulWidget {
  final String enteredType;
  final String partyBelongsToText;
  final VoidCallback onAdjust;
  final VoidCallback onCancel;

  const _TaxMismatchDialog({
    required this.enteredType,
    required this.partyBelongsToText,
    required this.onAdjust,
    required this.onCancel,
  });

  @override
  State<_TaxMismatchDialog> createState() => _TaxMismatchDialogState();
}

class _TaxMismatchDialogState extends State<_TaxMismatchDialog> {
  final FocusNode _adjustNode = FocusNode();
  final FocusNode _continueNode = FocusNode();

  @override
  void dispose() {
    _adjustNode.dispose();
    _continueNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.taxMismatchWarningDialog,
      nodeMap: {
        FocusFieldNode.confirmYesButton: _adjustNode,
        FocusFieldNode.confirmNoButton: _continueNode,
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text(
              'Taxation Alert',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'You are entering a ${widget.enteredType} but party belongs to ${widget.partyBelongsToText}.\n\nDo you want to adjust or continue as is?',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          _FocusableDialogButton(
            focusNode: _adjustNode,
            isPrimary: true,
            label: 'Adjust Mode',
            onPressed: () {
              Navigator.pop(context);
              widget.onAdjust();
            },
          ),
          const SizedBox(width: 8),
          _FocusableDialogButton(
            focusNode: _continueNode,
            isPrimary: false,
            label: 'Continue As Is',
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Dialog Button with Prominent Visual Focus Ring
// ---------------------------------------------------------------------------
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
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          onPressed();
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
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderMedium),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
          );
        },
      ),
    );
  }
}