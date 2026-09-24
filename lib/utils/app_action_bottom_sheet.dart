// lib/widgets/common/app_action_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class AppActionItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AppActionItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class AppActionBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<AppActionItem> actions;

  const AppActionBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  State<AppActionBottomSheet> createState() => _AppActionBottomSheetState();
}

class _AppActionBottomSheetState extends State<AppActionBottomSheet> {
  late final List<FocusNode> _focusNodes = List.generate(widget.actions.length, (_) => FocusNode());
  int _focusedIdx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
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
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ...List.generate(widget.actions.length, (i) {
              final item = widget.actions[i];
              final isFocused = _focusedIdx == i;

              return Padding(
                padding: EdgeInsets.only(bottom: i < widget.actions.length - 1 ? 10 : 0),
                child: Focus(
                  focusNode: _focusNodes[i],
                  autofocus: i == 0,
                  onFocusChange: (has) {
                    if (has) setState(() => _focusedIdx = i);
                  },
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    final k = event.logicalKey;

                    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.numpadEnter) {
                      item.onTap();
                      return KeyEventResult.handled;
                    }
                    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.numpad2) {
                      final next = (i + 1) % widget.actions.length;
                      _focusNodes[next].requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.numpad8) {
                      final prev = (i - 1 + widget.actions.length) % widget.actions.length;
                      _focusNodes[prev].requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: isFocused ? item.color.withValues(alpha: .06) : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFocused ? item.color : AppColors.border,
                        width: isFocused ? 2.5 : 1.0,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: item.color.withValues(alpha: .25),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: item.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.desc,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isFocused ? item.color : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}