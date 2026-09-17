import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      gradientColors: const [Color(0xFFFBF4FF), Color(0xFFF3E4FF)],
      borderColor: const Color(0xFFE5CCFF),
      glowColor: const Color(0x187034E6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.layers_rounded,
            title: 'Data Management',
            subtitle: 'Secure backups and restore company records',
            badgeGradient: [Color(0xFF8E54F7), Color(0xFF7034E6)],
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
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final key = event.logicalKey;
                    if (KeyboardShortcutService.isRight(key)) {
                      _restoreNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isLeft(key)) {
                      widget.onMoveLeft?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(key)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(key)) {
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
                        color: _isBackupFocused ? const Color(0xFF7034E6) : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isBackupFocused
                          ? const [
                              BoxShadow(
                                color: Color(0x337034E6),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.backup_rounded,
                      title: 'Backup Data',
                      subtitle: 'Export safety snapshot',
                      iconColor: const Color(0xFF7034E6),
                      iconBackground: const Color(0xFFF1E6FF),
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
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final key = event.logicalKey;
                    if (KeyboardShortcutService.isLeft(key)) {
                      _backupNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isRight(key)) {
                      widget.onMoveRight?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(key)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(key)) {
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
                        color: _isRestoreFocused ? const Color(0xFF7034E6) : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isRestoreFocused
                          ? const [
                              BoxShadow(
                                color: Color(0x337034E6),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.restore_page_rounded,
                      title: 'Restore Data',
                      subtitle: 'Load backup archive',
                      iconColor: const Color(0xFFB439D1),
                      iconBackground: const Color(0xFFFCEEFF),
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