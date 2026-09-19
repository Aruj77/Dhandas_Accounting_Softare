import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class DataDirectoryBanner extends StatefulWidget {
  final String? currentDirectory;
  final bool isLoading;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveLeft;

  const DataDirectoryBanner({
    super.key,
    required this.currentDirectory,
    required this.isLoading,
    required this.onTap,
    this.focusNode,
    this.onMoveUp,
    this.onMoveLeft,
  });

  @override
  State<DataDirectoryBanner> createState() => _DataDirectoryBannerState();
}

class _DataDirectoryBannerState extends State<DataDirectoryBanner> {
  late FocusNode _node;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    final hasDirectory = widget.currentDirectory != null && widget.currentDirectory!.isNotEmpty;

    return Focus(
      focusNode: _node,
      onFocusChange: (val) => setState(() => _isFocused = val),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.numpad8) {
          widget.onMoveUp?.call();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.numpad4) {
          widget.onMoveLeft?.call();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _node.requestFocus();
            widget.onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.bannerYellowStart,
                  AppColors.bannerYellowEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFocused ? AppColors.primary : AppColors.bannerYellowBorder,
                width: _isFocused ? 2.5 : 1.2,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: AppColors.bannerYellowShadow,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.folderGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.folderShadow,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.surface,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Set Data Directory',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (hasDirectory) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.successDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isLoading
                            ? 'Checking saved database location...'
                            : hasDirectory
                                ? widget.currentDirectory!
                                : 'Choose the location where your company data will be stored',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasDirectory ? FontWeight.w700 : FontWeight.w500,
                          color: hasDirectory ? AppColors.successDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/folder_illustration.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.bannerChevron,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}