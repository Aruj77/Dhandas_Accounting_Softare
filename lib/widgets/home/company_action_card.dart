import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../action_button.dart';
import 'glass_card.dart';

class CompanyActionCard extends StatefulWidget {
  final VoidCallback onOpenCompany;
  final VoidCallback onCreateCompany;
  final VoidCallback? onMoveToSidebar;
  final VoidCallback? onMoveRight;
  final VoidCallback? onMoveDown;
  final FocusNode? openCompanyFocusNode;
  final FocusNode? createCompanyFocusNode;

  const CompanyActionCard({
    super.key,
    required this.onOpenCompany,
    required this.onCreateCompany,
    this.onMoveToSidebar,
    this.onMoveRight,
    this.onMoveDown,
    this.openCompanyFocusNode,
    this.createCompanyFocusNode,
  });

  @override
  State<CompanyActionCard> createState() => _CompanyActionCardState();
}

class _CompanyActionCardState extends State<CompanyActionCard> {
  late FocusNode _openNode;
  late FocusNode _createNode;
  bool _isOpenFocused = false;
  bool _isCreateFocused = false;

  @override
  void initState() {
    super.initState();
    _openNode = widget.openCompanyFocusNode ?? FocusNode();
    _createNode = widget.createCompanyFocusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      gradientColors: const [Color(0xFFEFF5FF), Color(0xFFDCEBFF)],
      borderColor: const Color(0xFFC3DCFF),
      glowColor: const Color(0x180F62FE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.apartment_rounded,
            title: 'Company',
            subtitle: 'Create a new business or access an existing one',
            badgeGradient: [Color(0xFF4C93F5), AppColors.primary],
            illustrationAsset: 'assets/images/company_illustration.png',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Focus(
                  focusNode: _openNode,
                  onFocusChange: (val) => setState(() => _isOpenFocused = val),
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final key = event.logicalKey;
                    if (KeyboardShortcutService.isRight(key)) {
                      _createNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isLeft(key)) {
                      widget.onMoveToSidebar?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(key)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(key)) {
                      widget.onOpenCompany();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isOpenFocused ? AppColors.primary : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isOpenFocused
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.folder_open_rounded,
                      title: 'Open Company',
                      subtitle: 'Open an existing workspace',
                      iconColor: AppColors.primary,
                      iconBackground: const Color(0xFFE5EFFF),
                      onTap: widget.onOpenCompany,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Focus(
                  focusNode: _createNode,
                  onFocusChange: (val) => setState(() => _isCreateFocused = val),
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final key = event.logicalKey;
                    if (KeyboardShortcutService.isLeft(key)) {
                      _openNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isRight(key)) {
                      widget.onMoveRight?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(key)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(key)) {
                      widget.onCreateCompany();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isCreateFocused ? const Color(0xFF0FA75D) : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isCreateFocused
                          ? const [
                              BoxShadow(
                                color: Color(0x330FA75D),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Company',
                      subtitle: 'Set up a new organization',
                      iconColor: const Color(0xFF0FA75D),
                      iconBackground: const Color(0xFFE2F8ED),
                      onTap: widget.onCreateCompany,
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