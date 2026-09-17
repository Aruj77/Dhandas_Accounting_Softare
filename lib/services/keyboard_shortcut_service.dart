import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/keyboard/keyboard_action.dart';

/// Per-user keyboard configuration. Loaded/saved from SharedPreferences,
/// which is per-device/user storage — so remaps here are personal, never
/// global. [KeyboardAction] ids stay the single source of truth for what
/// a shortcut *means*; this class only stores which physical key each
/// action is currently bound to.
class KeyboardShortcutSettings {
  final bool keyboardIntensiveMode;
  final bool useNumpadNavigation;
  final Map<String, String> shortcuts;

  const KeyboardShortcutSettings({
    required this.keyboardIntensiveMode,
    required this.useNumpadNavigation,
    required this.shortcuts,
  });

  factory KeyboardShortcutSettings.defaults() {
    return KeyboardShortcutSettings(
      keyboardIntensiveMode: true,
      useNumpadNavigation: true,
      shortcuts: Map<String, String>.from(
        KeyboardShortcutService.defaultShortcuts,
      ),
    );
  }

  KeyboardShortcutSettings copyWith({
    bool? keyboardIntensiveMode,
    bool? useNumpadNavigation,
    Map<String, String>? shortcuts,
  }) {
    return KeyboardShortcutSettings(
      keyboardIntensiveMode:
          keyboardIntensiveMode ?? this.keyboardIntensiveMode,
      useNumpadNavigation: useNumpadNavigation ?? this.useNumpadNavigation,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  Map<String, dynamic> toJson() => {
    'keyboardIntensiveMode': keyboardIntensiveMode,
    'useNumpadNavigation': useNumpadNavigation,
    'shortcuts': shortcuts,
  };

  factory KeyboardShortcutSettings.fromJson(Map<String, dynamic> json) {
    final defaults = KeyboardShortcutSettings.defaults();
    final rawShortcuts = json['shortcuts'];

    final parsedShortcuts = <String, String>{
      ...defaults.shortcuts,
      if (rawShortcuts is Map)
        ...rawShortcuts.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
    };

    return KeyboardShortcutSettings(
      keyboardIntensiveMode: json['keyboardIntensiveMode'] is bool
          ? json['keyboardIntensiveMode'] as bool
          : defaults.keyboardIntensiveMode,
      useNumpadNavigation: json['useNumpadNavigation'] is bool
          ? json['useNumpadNavigation'] as bool
          : defaults.useNumpadNavigation,
      shortcuts: parsedShortcuts,
    );
  }
}

class KeyboardShortcutOption {
  final String id;
  final String label;
  const KeyboardShortcutOption({required this.id, required this.label});
}

class KeyboardShortcutDefinition {
  final String actionId;
  final String title;
  final String description;
  final List<KeyboardShortcutOption> options;

  const KeyboardShortcutDefinition({
    required this.actionId,
    required this.title,
    required this.description,
    required this.options,
  });
}

/// Persistence + keymap for user-configurable shortcuts.
///
/// Action ids are NOT redefined here — they are the same ids from
/// [KeyboardAction], so [KeyboardRegistry]'s configurable-action list and
/// this service can never drift apart (DRY: one id, one meaning).
class KeyboardShortcutService {
  static const String _prefsKey = 'dhandas_keyboard_shortcut_settings';

  // Back-compat aliases (kept so existing screens like voucher_entry_screen
  // keep compiling); they simply point at the canonical KeyboardAction ids.
  static const String goBackAction = KeyboardAction.back;
  static const String moveUpAction = KeyboardAction.up;
  static const String moveDownAction = KeyboardAction.down;
  static const String moveLeftAction = KeyboardAction.left;
  static const String moveRightAction = KeyboardAction.right;
  static const String activateAction = KeyboardAction.activate;
  static const String openCompanyAction = KeyboardAction.openCompany;
  static const String createCompanyAction = KeyboardAction.createCompany;
  static const String changeDirectoryAction = KeyboardAction.changeDirectory;
  static const String openSettingsAction = KeyboardAction.settings;
  static const String switchWorkspaceAction = KeyboardAction.switchWorkspace;
  static const String saveVoucherAction = KeyboardAction.saveVoucher;

  // ------------------------------------------------------------
  // Key IDs (physical keys a user can bind an action to)
  // ------------------------------------------------------------
  static const String keyEscape = 'escape';
  static const String keyArrowUp = 'arrowUp';
  static const String keyArrowDown = 'arrowDown';
  static const String keyArrowLeft = 'arrowLeft';
  static const String keyArrowRight = 'arrowRight';
  static const String keyEnter = 'enter';
  static const String keyNumpadEnter = 'numpadEnter';
  static const String keyNumpad8 = 'numpad8';
  static const String keyNumpad2 = 'numpad2';
  static const String keyNumpad4 = 'numpad4';
  static const String keyNumpad6 = 'numpad6';
  static const String keyF1 = 'f1';
  static const String keyF2 = 'f2';
  static const String keyF3 = 'f3';
  static const String keyF4 = 'f4';
  static const String keyF5 = 'f5';
  static const String keyF6 = 'f6';
  static const String keyF7 = 'f7';
  static const String keyF8 = 'f8';
  static const String keyF9 = 'f9';
  static const String keyF10 = 'f10';
  static const String keyF11 = 'f11';
  static const String keyF12 = 'f12';
  static const String keySpace = 'space';
  static const String keyTab = 'tab';
  static const String keyDelete = 'delete';
  // Ctrl combos, for actions that don't map naturally to a bare F-key.
  static const String keyCtrlN = 'ctrlN';
  static const String keyCtrlS = 'ctrlS';
  static const String keyCtrlD = 'ctrlD';
  static const String keyCtrlP = 'ctrlP';
  static const String keyCtrlE = 'ctrlE';

  // ------------------------------------------------------------
  // Global defaults — Tally/Busy-style keymap so the app is fully
  // usable without a mouse out of the box. Users may override any
  // of these; overrides are stored personally (SharedPreferences).
  // ------------------------------------------------------------
  static const Map<String, String> defaultShortcuts = {
    goBackAction: keyEscape,
    moveUpAction: keyArrowUp,
    moveDownAction: keyArrowDown,
    moveLeftAction: keyArrowLeft,
    moveRightAction: keyArrowRight,
    activateAction: keyEnter,

    KeyboardAction.help: keyF1,
    saveVoucherAction: keyF2,
    openCompanyAction: keyF3,
    createCompanyAction: keyF4,
    KeyboardAction.search: keyF5,
    changeDirectoryAction: keyF6,
    KeyboardAction.edit: keyF7,
    switchWorkspaceAction: keyF8,
    KeyboardAction.goTo: keyF9,
    openSettingsAction: keyF12,

    KeyboardAction.newRecord: keyCtrlN,
    KeyboardAction.save: keyCtrlS,
    KeyboardAction.duplicate: keyCtrlD,
    KeyboardAction.print: keyCtrlP,
    KeyboardAction.export: keyCtrlE,
    KeyboardAction.delete: keyDelete,
  };

  static const List<KeyboardShortcutOption> _options = [
    KeyboardShortcutOption(id: keyEscape, label: 'Escape'),
    KeyboardShortcutOption(id: keyArrowUp, label: 'Arrow Up'),
    KeyboardShortcutOption(id: keyArrowDown, label: 'Arrow Down'),
    KeyboardShortcutOption(id: keyArrowLeft, label: 'Arrow Left'),
    KeyboardShortcutOption(id: keyArrowRight, label: 'Arrow Right'),
    KeyboardShortcutOption(id: keyNumpad8, label: 'Numpad 8'),
    KeyboardShortcutOption(id: keyNumpad2, label: 'Numpad 2'),
    KeyboardShortcutOption(id: keyNumpad4, label: 'Numpad 4'),
    KeyboardShortcutOption(id: keyNumpad6, label: 'Numpad 6'),
    KeyboardShortcutOption(id: keyEnter, label: 'Enter'),
    KeyboardShortcutOption(id: keyNumpadEnter, label: 'Numpad Enter'),
    KeyboardShortcutOption(id: keyEscape, label: 'Escape'),
    KeyboardShortcutOption(id: keySpace, label: 'Space'),
    KeyboardShortcutOption(id: keyDelete, label: 'Delete'),
    KeyboardShortcutOption(id: keyF1, label: 'F1'),
    KeyboardShortcutOption(id: keyF2, label: 'F2'),
    KeyboardShortcutOption(id: keyF3, label: 'F3'),
    KeyboardShortcutOption(id: keyF4, label: 'F4'),
    KeyboardShortcutOption(id: keyF5, label: 'F5'),
    KeyboardShortcutOption(id: keyF6, label: 'F6'),
    KeyboardShortcutOption(id: keyF7, label: 'F7'),
    KeyboardShortcutOption(id: keyF8, label: 'F8'),
    KeyboardShortcutOption(id: keyF9, label: 'F9'),
    KeyboardShortcutOption(id: keyF10, label: 'F10'),
    KeyboardShortcutOption(id: keyF11, label: 'F11'),
    KeyboardShortcutOption(id: keyF12, label: 'F12'),
    KeyboardShortcutOption(id: keyCtrlN, label: 'Ctrl+N'),
    KeyboardShortcutOption(id: keyCtrlS, label: 'Ctrl+S'),
    KeyboardShortcutOption(id: keyCtrlD, label: 'Ctrl+D'),
    KeyboardShortcutOption(id: keyCtrlP, label: 'Ctrl+P'),
    KeyboardShortcutOption(id: keyCtrlE, label: 'Ctrl+E'),
  ];

  /// Every user-remappable shortcut, shown as-is on the Settings screen.
  static final List<KeyboardShortcutDefinition> definitions = [
    KeyboardShortcutDefinition(
      actionId: moveUpAction,
      title: 'Move Up',
      description: 'Move to the previous target.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: moveDownAction,
      title: 'Move Down',
      description: 'Move to the next target.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: moveLeftAction,
      title: 'Move Left',
      description: 'Move to the previous column.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: moveRightAction,
      title: 'Move Right',
      description: 'Move to the next column.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: activateAction,
      title: 'Activate Selection',
      description: 'Open or select the current target.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: goBackAction,
      title: 'Go Back',
      description: 'Close current screen/dialog.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.help,
      title: 'Help',
      description: 'Show keyboard shortcut help.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.search,
      title: 'Search',
      description: 'Open search.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.goTo,
      title: 'Go To',
      description: 'Open the Go To navigation.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.newRecord,
      title: 'New',
      description: 'Create a new record.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.save,
      title: 'Save',
      description: 'Save the current record.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.edit,
      title: 'Edit',
      description: 'Edit the selected record.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.delete,
      title: 'Delete',
      description: 'Delete the selected record.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.duplicate,
      title: 'Duplicate',
      description: 'Duplicate the selected record.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.print,
      title: 'Print',
      description: 'Print the current document/report.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: KeyboardAction.export,
      title: 'Export',
      description: 'Export the current data.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: openCompanyAction,
      title: 'Open Company',
      description: 'Open company selection.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: createCompanyAction,
      title: 'Create Company',
      description: 'Create a new company.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: changeDirectoryAction,
      title: 'Change Data Directory',
      description: 'Change local data directory.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: openSettingsAction,
      title: 'Open Settings',
      description: 'Open application settings.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: switchWorkspaceAction,
      title: 'Switch Workspace',
      description: 'Return to workspace home.',
      options: _options,
    ),
    KeyboardShortcutDefinition(
      actionId: saveVoucherAction,
      title: 'Save Voucher',
      description: 'Save current voucher.',
      options: _options,
    ),
  ];

  // ------------------------------------------------------------
  // Persistence (personal — one device/user's SharedPreferences)
  // ------------------------------------------------------------
  static Future<KeyboardShortcutSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return KeyboardShortcutSettings.defaults();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return KeyboardShortcutSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return KeyboardShortcutSettings.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      // Corrupt preference data should never block the app from starting.
    }
    return KeyboardShortcutSettings.defaults();
  }

  static Future<void> saveSettings(KeyboardShortcutSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
  }

  static Future<KeyboardShortcutSettings> resetToDefaults() async {
    final settings = KeyboardShortcutSettings.defaults();
    await saveSettings(settings);
    return settings;
  }

  // ------------------------------------------------------------
  // Lookup helpers
  // ------------------------------------------------------------
  static String shortcutFor(
    KeyboardShortcutSettings settings,
    String actionId,
  ) {
    return settings.shortcuts[actionId] ??
        defaultShortcuts[actionId] ??
        keyEnter;
  }

  static String labelForKey(String keyId) {
    for (final option in _options) {
      if (option.id == keyId) return option.label;
    }
    return keyId;
  }

  static String labelForAction(
    KeyboardShortcutSettings settings,
    String actionId,
  ) {
    return labelForKey(shortcutFor(settings, actionId));
  }

  static bool get _controlPressed {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  static String? keyIdFromEvent(KeyEvent event) {
    final key = event.logicalKey;

    // Ctrl-combos take priority over their bare-key meaning.
    if (_controlPressed) {
      if (key == LogicalKeyboardKey.keyN) return keyCtrlN;
      if (key == LogicalKeyboardKey.keyS) return keyCtrlS;
      if (key == LogicalKeyboardKey.keyD) return keyCtrlD;
      if (key == LogicalKeyboardKey.keyP) return keyCtrlP;
      if (key == LogicalKeyboardKey.keyE) return keyCtrlE;
    }

    if (key == LogicalKeyboardKey.escape) return keyEscape;
    if (key == LogicalKeyboardKey.arrowUp) return keyArrowUp;
    if (key == LogicalKeyboardKey.arrowDown) return keyArrowDown;
    if (key == LogicalKeyboardKey.arrowLeft) return keyArrowLeft;
    if (key == LogicalKeyboardKey.arrowRight) return keyArrowRight;
    if (key == LogicalKeyboardKey.enter) return keyEnter;
    if (key == LogicalKeyboardKey.numpadEnter) return keyNumpadEnter;
    if (key == LogicalKeyboardKey.numpad8) return keyNumpad8;
    if (key == LogicalKeyboardKey.numpad2) return keyNumpad2;
    if (key == LogicalKeyboardKey.numpad4) return keyNumpad4;
    if (key == LogicalKeyboardKey.numpad6) return keyNumpad6;
    if (key == LogicalKeyboardKey.delete) return keyDelete;
    if (key == LogicalKeyboardKey.f1) return keyF1;
    if (key == LogicalKeyboardKey.f2) return keyF2;
    if (key == LogicalKeyboardKey.f3) return keyF3;
    if (key == LogicalKeyboardKey.f4) return keyF4;
    if (key == LogicalKeyboardKey.f5) return keyF5;
    if (key == LogicalKeyboardKey.f6) return keyF6;
    if (key == LogicalKeyboardKey.f7) return keyF7;
    if (key == LogicalKeyboardKey.f8) return keyF8;
    if (key == LogicalKeyboardKey.f9) return keyF9;
    if (key == LogicalKeyboardKey.f10) return keyF10;
    if (key == LogicalKeyboardKey.f11) return keyF11;
    if (key == LogicalKeyboardKey.f12) return keyF12;
    if (key == LogicalKeyboardKey.space) return keySpace;
    if (key == LogicalKeyboardKey.tab) return keyTab;

    return null;
  }

  static bool matchesAction(
    KeyboardShortcutSettings settings,
    String actionId,
    KeyEvent event,
  ) {
    final eventKeyId = keyIdFromEvent(event);
    if (eventKeyId == null) return false;

    final configuredKey = shortcutFor(settings, actionId);
    if (configuredKey == eventKeyId) return true;

    if (!settings.useNumpadNavigation) return false;

    switch (actionId) {
      case moveUpAction:
        return eventKeyId == keyArrowUp || eventKeyId == keyNumpad8;
      case moveDownAction:
        return eventKeyId == keyArrowDown || eventKeyId == keyNumpad2;
      case moveLeftAction:
        return eventKeyId == keyArrowLeft || eventKeyId == keyNumpad4;
      case moveRightAction:
        return eventKeyId == keyArrowRight || eventKeyId == keyNumpad6;
      case activateAction:
        return eventKeyId == keyEnter || eventKeyId == keyNumpadEnter;
      default:
        return false;
    }
  }
}
