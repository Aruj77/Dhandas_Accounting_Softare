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
  KeyboardShortcutSettings _keyboardSettings = KeyboardShortcutSettings.defaults();

  @override
  void initState() {
    super.initState();
    _openNode = widget.openCompanyFocusNode ?? FocusNode();
    _createNode = widget.createCompanyFocusNode ?? FocusNode();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var settings = await KeyboardShortcutService.loadSettings();
    final normalized = <String, String>{};
    settings.shortcuts.forEach((key, val) {
      String clean = val;
      if (val.toLowerCase() == 'escape') clean = 'Esc';
      else if (val.toLowerCase().startsWith('f') && int.tryParse(val.substring(1)) != null) clean = val.toUpperCase();
      normalized[key] = clean;
    });
    settings = settings.copyWith(shortcuts: normalized);

    if (mounted) {
      setState(() {
        _keyboardSettings = settings;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final openLabel = KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.openCompanyAction);
    final createLabel = KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.createCompanyAction);

    return ModernGlassCard(
      gradientColors: AppColors.companyGlassGradient.colors,
      borderColor: AppColors.borderSubtle,
      glowColor: AppColors.primary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.apartment_rounded,
            title: 'Company',
            subtitle: 'Create a new business or access an existing one',
            badgeGradient: [AppColors.primarySemiLight, AppColors.primary],
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
                    if (KeyboardShortcutService.isRight(event)) {
                      _createNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isLeft(event)) {
                      widget.onMoveToSidebar?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(event)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(event)) {
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
                              ),
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.folder_open_rounded,
                      title: 'Open Company',
                      subtitle: 'Open an existing workspace',
                      iconColor: AppColors.primary,
                      iconBackground: AppColors.primaryLight,
                      onTap: widget.onOpenCompany,
                      shortcutBadge: openLabel,
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
                    if (KeyboardShortcutService.isLeft(event)) {
                      _openNode.requestFocus();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isRight(event)) {
                      widget.onMoveRight?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isDown(event)) {
                      widget.onMoveDown?.call();
                      return KeyEventResult.handled;
                    } else if (KeyboardShortcutService.isConfirm(event)) {
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
                        color: _isCreateFocused ? AppColors.success : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isCreateFocused
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Company',
                      subtitle: 'Set up a new organization',
                      iconColor: AppColors.success,
                      iconBackground: AppColors.successLight,
                      onTap: widget.onCreateCompany,
                      shortcutBadge: createLabel,
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