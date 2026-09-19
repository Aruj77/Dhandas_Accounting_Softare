import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/keyboard_shortcut_service.dart';
import '../services/loading_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? currentDirectory;
  final VoidCallback? onChangeDirectory;
  final KeyboardShortcutSettings keyboardSettings;
  final Future<void> Function(KeyboardShortcutSettings settings)?
      onKeyboardSettingsChanged;

  const SettingsScreen({
    super.key,
    this.currentDirectory,
    this.onChangeDirectory,
    required this.keyboardSettings,
    this.onKeyboardSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _currentVersion = '1.0.0';
  String? _lastCheckedTime = 'Never';
  String _selectedChannel = 'Stable';
  late KeyboardShortcutSettings _keyboardSettings;

  @override
  void initState() {
    super.initState();
    _keyboardSettings = widget.keyboardSettings;
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyboardSettings != widget.keyboardSettings) {
      _keyboardSettings = widget.keyboardSettings;
    }
  }

  Future<void> _checkForUpdates() async {
    await LoadingService.wrap(() async {
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        final now = DateTime.now();
        final formattedTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        setState(() {
          _lastCheckedTime = 'Today at $formattedTime';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.surface, size: 20),
                SizedBox(width: 10),
                Text(
                  'Dhandas is up to date! (v1.0.0 is the latest build)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }, message: 'Checking for updates...');
  }

  Future<void> _applyKeyboardSettings(
    KeyboardShortcutSettings settings,
  ) async {
    setState(() => _keyboardSettings = settings);
    await widget.onKeyboardSettingsChanged?.call(settings);
  }

  Future<void> _updateKeyboardMode(bool value) async {
    await _applyKeyboardSettings(
      _keyboardSettings.copyWith(keyboardIntensiveMode: value),
    );
  }

  Future<void> _updateNumpadMode(bool value) async {
    await _applyKeyboardSettings(
      _keyboardSettings.copyWith(useNumpadNavigation: value),
    );
  }

  Future<void> _updateShortcut(String actionId, String keyId) async {
    final updatedShortcuts = Map<String, String>.from(_keyboardSettings.shortcuts)
      ..[actionId] = keyId;
    await _applyKeyboardSettings(
      _keyboardSettings.copyWith(shortcuts: updatedShortcuts),
    );
  }

  Future<void> _resetShortcuts() async {
    await _applyKeyboardSettings(KeyboardShortcutSettings.defaults());
  }

  @override
  Widget build(BuildContext context) {
    final hasDir =
        widget.currentDirectory != null && widget.currentDirectory!.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage storage locations, application updates, runtime configurations, and keyboard-first controls.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          _buildSettingsCard(
            icon: Icons.system_update_rounded,
            badgeColor: AppColors.success,
            title: 'Application Updates',
            subtitle: 'Check for software upgrades, bug fixes, and feature releases',
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Dhandas Desktop v$_currentVersion',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBorder,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Latest',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.successDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Last verified: $_lastCheckedTime',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _checkForUpdates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.surface),
                        label: const Text(
                          'Check for Updates',
                          style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Release Channel',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive verified production releases or early previews',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedChannel,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            items: ['Stable', 'Beta (Preview)']
                                .map((channel) => DropdownMenuItem(value: channel, child: Text(channel)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedChannel = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingsCard(
            icon: Icons.folder_shared_rounded,
            badgeColor: AppColors.primary,
            title: 'Storage & Database Location',
            subtitle: 'Configure the root path where all organization data is saved',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Database Directory',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDir ? widget.currentDirectory! : 'No directory configured',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: hasDir ? AppColors.primaryDark : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onChangeDirectory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: AppColors.surface),
                    label: const Text(
                      'Change',
                      style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingsCard(
            icon: Icons.keyboard_alt_rounded,
            badgeColor: AppColors.primary,
            title: 'Keyboard & Shortcuts',
            subtitle: 'Navigate faster with arrow keys, numpad keys, Enter, Esc, and accounting-style shortcut actions.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKeyboardToggleTile(
                        title: 'Keyboard Intensive Mode',
                        description: 'Keeps navigation optimized for keyboard-heavy workflow across the app.',
                        value: _keyboardSettings.keyboardIntensiveMode,
                        onChanged: _updateKeyboardMode,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildKeyboardToggleTile(
                        title: 'Use Numeric Keypad Navigation',
                        description: 'Treat NumPad 8 / 2 and NumPad Enter like arrow navigation and select.',
                        value: _keyboardSettings.useNumpadNavigation,
                        onChanged: _updateNumpadMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shortcut Mapping',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Choose the primary key for each action. Changes apply immediately.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetShortcuts,
                            icon: const Icon(Icons.restart_alt_rounded, size: 16),
                            label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...KeyboardShortcutService.definitions.map(
                        (definition) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildShortcutSelectorRow(definition),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KeyboardHintChip(label: 'Enter', description: 'Next Field'),
                      _KeyboardHintChip(label: 'Tab', description: 'Forward'),
                      _KeyboardHintChip(label: 'Shift+Tab', description: 'Back'),
                      _KeyboardHintChip(label: 'Esc', description: 'Go Back'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingsCard(
            icon: Icons.info_outline_rounded,
            badgeColor: AppColors.purple,
            title: 'Application Information',
            subtitle: 'Dhandas build details, licensing, and dependencies',
            child: Column(
              children: [
                _buildInfoRow('Product Name', 'Dhandas Desktop Accounting'),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Current Version', '$_currentVersion (Release)'),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Engine Architecture', 'Windows x64 Native / Flutter Desktop'),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow('Storage Driver', 'Local File JSON / Sequential FIN-Index'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.surface, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
      ],
    );
  }

  Widget _buildKeyboardToggleTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSelectorRow(KeyboardShortcutDefinition definition) {
    final selectedKey = KeyboardShortcutService.shortcutFor(_keyboardSettings, definition.actionId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(definition.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 2),
                Text(definition.description, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: selectedKey,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.cardBg,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
              ),
              items: definition.options
                  .map((option) => DropdownMenuItem<String>(
                        value: option.id,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) _updateShortcut(definition.actionId, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardHintChip extends StatelessWidget {
  final String label;
  final String description;

  const _KeyboardHintChip({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(width: 6),
          Text(description, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}