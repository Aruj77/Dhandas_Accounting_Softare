import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../action_button.dart';
import 'glass_card.dart';

class DataActionCard extends StatefulWidget {
  final VoidCallback? onBackup;
  final VoidCallback? onRestore;
  final FocusNode? backupFocusNode;
  final FocusNode? restoreFocusNode;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback? onMoveDown;

  const DataActionCard({
    super.key,
    this.onBackup,
    this.onRestore,
    this.backupFocusNode,
    this.restoreFocusNode,
    this.onMoveLeft,
    this.onMoveRight,
    this.onMoveDown,
  });

  @override
  State<DataActionCard> createState() => _DataActionCardState();
}

class _DataActionCardState extends State<DataActionCard> {
  late FocusNode _backupNode;
  late FocusNode _restoreNode;
  bool _isBackupFocused = false;
  bool _isRestoreFocused = false;

  @override
  void initState() {
    super.initState();
    _backupNode = widget.backupFocusNode ?? FocusNode();
    _restoreNode = widget.restoreFocusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      gradientColors: const [AppColors.purpleSemiLight, AppColors.purpleSemiLight],
      borderColor: AppColors.purpleBorder,
      glowColor: AppColors.purple.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.layers_rounded,
            title: 'Data Management',
            subtitle: 'Secure backups and restore company records',
            badgeGradient: [AppColors.purpleLight, AppColors.purple],
            illustrationAsset: 'assets/images/data_illustration.png',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Focus(
                  focusNode: _backupNode,
                  onFocusChange: (val) => setState(() => _isBackupFocused = val),
                  onKeyEvent: (node, event) {
                    if (KeyboardShortcutService.isRight(event)) {
                      _restoreNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isLeft(event)) {
                      widget.onMoveLeft?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(event)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(event)) {
                      widget.onBackup?.call();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isBackupFocused ? AppColors.purple : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isBackupFocused
                          ? [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.backup_rounded,
                      title: 'Backup Data',
                      subtitle: 'Export safety snapshot',
                      iconColor: AppColors.purple,
                      iconBackground: AppColors.purpleLight,
                      onTap: () => widget.onBackup?.call(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Focus(
                  focusNode: _restoreNode,
                  onFocusChange: (val) => setState(() => _isRestoreFocused = val),
                  onKeyEvent: (node, event) {
                    if (KeyboardShortcutService.isLeft(event)) {
                      _backupNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isRight(event)) {
                      widget.onMoveRight?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(event)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(event)) {
                      widget.onRestore?.call();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isRestoreFocused ? AppColors.purple : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isRestoreFocused
                          ? [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.restore_page_rounded,
                      title: 'Restore Data',
                      subtitle: 'Load backup archive',
                      iconColor: AppColors.purple,
                      iconBackground: AppColors.purpleLight,
                      onTap: () => widget.onRestore?.call(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}