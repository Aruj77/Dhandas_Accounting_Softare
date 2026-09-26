import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/keyboard_shortcut_service.dart';

class PrintStudioConfirmDialog extends StatefulWidget {
  final String vchNo;

  const PrintStudioConfirmDialog({super.key, required this.vchNo});

  @override
  State<PrintStudioConfirmDialog> createState() => _PrintStudioConfirmDialogState();
}

class _PrintStudioConfirmDialogState extends State<PrintStudioConfirmDialog> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Print Invoice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
      content: Text(
        'Sales invoice [${widget.vchNo}] saved successfully.\n\nOpen Print Studio preview now?',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (KeyboardShortcutService.isConfirm(event)) {
              Navigator.pop(context, true);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasFocus ? AppColors.primary : Colors.transparent,
                    width: 2.2,
                  ),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Open Print Studio',
                    style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w800),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}