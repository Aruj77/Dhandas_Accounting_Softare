import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../utils/grid_keyboard_navigator.dart';

class InteractiveDashboardCard extends StatefulWidget {
  final int index;
  final int cols;
  final FocusNode focusNode;
  final List<FocusNode> allFocusNodes;
  final List<List<int>> sections;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String shortcut;
  final VoidCallback onPrimaryAction;
  final List<Widget> actionChips;

  const InteractiveDashboardCard({
    super.key,
    required this.index,
    required this.cols,
    required this.focusNode,
    required this.allFocusNodes,
    required this.sections,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.shortcut = '',
    required this.onPrimaryAction,
    required this.actionChips,
  });

  @override
  State<InteractiveDashboardCard> createState() =>
      _InteractiveDashboardCardState();
}

class _InteractiveDashboardCardState extends State<InteractiveDashboardCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  void _scrollToCenter(BuildContext cardContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !cardContext.mounted) return;
      final box = cardContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(cardContext).size.height;
        final isFullyVisible =
            pos.dy >= 24 && (pos.dy + box.size.height) <= screenHeight - 24;

        if (!isFullyVisible) {
          Scrollable.ensureVisible(
            cardContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (cardContext) {
        return Focus(
          focusNode: widget.focusNode,
          onFocusChange: (has) {
            setState(() => _isFocused = has);
            if (has) _scrollToCenter(cardContext);
          },
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;

            if (GridKeyboardNavigator.isActionKey(event.logicalKey)) {
              widget.onPrimaryAction();
              return KeyEventResult.handled;
            }

            if (GridKeyboardNavigator.handleKeyEvent(
              currentIndex: widget.index,
              key: event.logicalKey,
              cols: widget.cols,
              focusNodes: widget.allFocusNodes,
              sections: widget.sections,
            )) {
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => _isHovered = true);
            },
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(
                0,
                (_isHovered || _isFocused) ? -3 : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isFocused
                      ? widget.color
                      : (_isHovered
                          ? widget.color.withValues(alpha: 0.35)
                          : AppColors.border),
                  width: _isFocused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isHovered || _isFocused)
                        ? widget.color.withValues(alpha: 0.10)
                        : AppColors.shadowColor,
                    blurRadius: (_isHovered || _isFocused) ? 16 : 6,
                    offset: Offset(0, (_isHovered || _isFocused) ? 6 : 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  widget.onPrimaryAction();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Shortcut
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(widget.icon, color: widget.color, size: 20),
                          ),
                          const Spacer(),
                          if (widget.shortcut.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.shortcut,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Titles & Description
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      // Single spacer pushes actions to bottom cleanly
                      const Spacer(),

                      // Action Chips in a single non-wrapping row
                      Row(
                        children: [
                          for (int i = 0; i < widget.actionChips.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Flexible(
                              fit: FlexFit.loose,
                              child: widget.actionChips[i],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}