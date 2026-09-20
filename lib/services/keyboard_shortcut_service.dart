// lib/services/keyboard_shortcut_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'keyboardIntensiveMode': keyboardIntensiveMode,
      'useNumpadNavigation': useNumpadNavigation,
      'shortcuts': shortcuts,
    };
  }

  factory KeyboardShortcutSettings.fromJson(Map<String, dynamic> json) {
    final defaultSettings = KeyboardShortcutSettings.defaults();
    final rawShortcuts = json['shortcuts'];
    final parsedShortcuts = <String, String>{
      ...defaultSettings.shortcuts,
      if (rawShortcuts is Map)
        ...rawShortcuts.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
    };

    return KeyboardShortcutSettings(
      keyboardIntensiveMode:
          json['keyboardIntensiveMode'] is bool
              ? json['keyboardIntensiveMode'] as bool
              : defaultSettings.keyboardIntensiveMode,
      useNumpadNavigation:
          json['useNumpadNavigation'] is bool
              ? json['useNumpadNavigation'] as bool
              : defaultSettings.useNumpadNavigation,
      shortcuts: parsedShortcuts,
    );
  }
}

class KeyboardShortcutOption {
  final String id;
  final String label;

  const KeyboardShortcutOption({
    required this.id,
    required this.label,
  });
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

class KeyboardShortcutService {
  static const String _prefsKey = 'dhandas_keyboard_shortcut_settings';

  // --- Reconfigurable Action Identifiers ---
  static const String goBackAction = 'goBack';
  static const String moveUpAction = 'moveUp';
  static const String moveDownAction = 'moveDown';
  static const String activateAction = 'activate';
  static const String openCompanyAction = 'openCompany';
  static const String createCompanyAction = 'createCompany';
  static const String changeDirectoryAction = 'changeDirectory';
  static const String openSettingsAction = 'openSettings';
  static const String switchWorkspaceAction = 'switchWorkspace';
  static const String saveVoucherAction = 'saveVoucher';

  // --- Fixed Hardware Action Identifiers ---
  static const String quickAddMasterAction = 'quickAddMaster'; // Alt + C
  static const String modifyMasterAction = 'modifyMaster';     // Alt + E
  static const String printInvoiceAction = 'printInvoice';     // Ctrl/Cmd + P
  static const String calculatorAction = 'calculator';         // F4

  // --- Key Code Constants ---
  static const String keyEscape = 'escape';
  static const String keyArrowUp = 'arrowUp';
  static const String keyArrowDown = 'arrowDown';
  static const String keyArrowLeft = 'arrowLeft';
  static const String keyArrowRight = 'arrowRight';
  static const String keyEnter = 'enter';
  static const String keyNumpad8 = 'numpad8';
  static const String keyNumpad2 = 'numpad2';
  static const String keyNumpad4 = 'numpad4';
  static const String keyNumpad6 = 'numpad6';
  static const String keyNumpadEnter = 'numpadEnter';
  static const String keyF2 = 'f2';
  static const String keyF3 = 'f3';
  static const String keyF4 = 'f4';
  static const String keyF5 = 'f5';
  static const String keyF6 = 'f6';
  static const String keyF7 = 'f7';
  static const String keyF8 = 'f8';
  static const String keyF9 = 'f9';
  static const String keyF10 = 'f10';
  static const String keyF12 = 'f12';
  static const String keySpace = 'space';

  // --- Directional & Confirm Navigation Helpers ---
  static bool isUp(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.numpad8;

  static bool isDown(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.numpad2;

  static bool isLeft(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.numpad4;

  static bool isRight(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.numpad6;

  static bool isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space;

  static bool isExit(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.escape;

  // --- Universal Event-Level Matching Helpers ---

  /// Alt + C: Quick add an item, party, or master ledger
  static bool isQuickAdd(KeyEvent event) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC;
  }

  /// Alt + E: Edit active master or open line-level tax details
  static bool isModifyOrTaxDetails(KeyEvent event) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.keyE;
  }

  /// Ctrl + P / Cmd + P: Print Preview Studio
  static bool isPrint(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyP;
  }

  /// F4: Quick Calculator
  static bool isCalculator(KeyEvent event) {
    return event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f4;
  }

  /// F2 or Ctrl + S: Standard Save
  static bool isSave(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    final isCtrlS = (hw.isControlPressed || hw.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyS;
    return event.logicalKey == LogicalKeyboardKey.f2 || isCtrlS;
  }

  /// Check any Alt + [Key] combination
  static bool isAltKey(KeyEvent event, LogicalKeyboardKey key) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == key;
  }

  /// Check any Ctrl / Cmd + [Key] combination
  static bool isControlKey(KeyEvent event, LogicalKeyboardKey key) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == key;
  }

  // --- Defaults & Settings ---
  static const Map<String, String> defaultShortcuts = {
    goBackAction: keyEscape,
    moveUpAction: keyArrowUp,
    moveDownAction: keyArrowDown,
    activateAction: keyEnter,
    openCompanyAction: keyF3,
    createCompanyAction: keyF4,
    changeDirectoryAction: keyF6,
    openSettingsAction: keyF12,
    switchWorkspaceAction: keyF8,
    saveVoucherAction: keyF2,
  };

  static const List<KeyboardShortcutOption> _navigationOptions = [
    KeyboardShortcutOption(id: keyArrowUp, label: 'Arrow Up'),
    KeyboardShortcutOption(id: keyArrowDown, label: 'Arrow Down'),
    KeyboardShortcutOption(id: keyNumpad8, label: 'Numpad 8'),
    KeyboardShortcutOption(id: keyNumpad2, label: 'Numpad 2'),
    KeyboardShortcutOption(id: keyEnter, label: 'Enter'),
    KeyboardShortcutOption(id: keyNumpadEnter, label: 'Numpad Enter'),
    KeyboardShortcutOption(id: keyEscape, label: 'Esc'),
    KeyboardShortcutOption(id: keySpace, label: 'Space'),
    KeyboardShortcutOption(id: keyF2, label: 'F2'),
    KeyboardShortcutOption(id: keyF3, label: 'F3'),
    KeyboardShortcutOption(id: keyF4, label: 'F4'),
    KeyboardShortcutOption(id: keyF6, label: 'F6'),
    KeyboardShortcutOption(id: keyF8, label: 'F8'),
    KeyboardShortcutOption(id: keyF10, label: 'F10'),
    KeyboardShortcutOption(id: keyF12, label: 'F12'),
  ];

  static final List<KeyboardShortcutDefinition> definitions = [
    KeyboardShortcutDefinition(
      actionId: moveUpAction,
      title: 'Move Up',
      description: 'Move to the previous menu item or keyboard target.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: moveDownAction,
      title: 'Move Down',
      description: 'Move to the next menu item or keyboard target.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: activateAction,
      title: 'Activate Selection',
      description: 'Open the selected action or confirm the highlighted target.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: goBackAction,
      title: 'Go Back',
      description: 'Close the current view, dialog, or go to the previous layer.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: openCompanyAction,
      title: 'Open Company',
      description: 'Open the company selection dialog from the home workspace.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: createCompanyAction,
      title: 'Create Company',
      description: 'Start a new company setup quickly from the keyboard.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: changeDirectoryAction,
      title: 'Change Data Directory',
      description: 'Open the storage directory chooser.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: openSettingsAction,
      title: 'Open Settings',
      description: 'Jump straight into Settings and Preferences.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: switchWorkspaceAction,
      title: 'Switch Workspace',
      description: 'Leave the active company and return to the workspace home.',
      options: _navigationOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: saveVoucherAction,
      title: 'Save Voucher',
      description: 'Save the current voucher entry screen.',
      options: _navigationOptions,
    ),
  ];

  static Future<KeyboardShortcutSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return KeyboardShortcutSettings.defaults();
    }

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
    } catch (_) {}

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

  static String shortcutFor(KeyboardShortcutSettings settings, String actionId) {
    return settings.shortcuts[actionId] ?? defaultShortcuts[actionId] ?? keyEnter;
  }

  static String labelForKey(String keyId) {
    for (final definition in definitions) {
      for (final option in definition.options) {
        if (option.id == keyId) {
          return option.label;
        }
      }
    }
    return keyId;
  }

  static String labelForAction(
    KeyboardShortcutSettings settings,
    String actionId,
  ) {
    return labelForKey(shortcutFor(settings, actionId));
  }

  static String? keyIdFromEvent(KeyEvent event) {
    final key = event.logicalKey;

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
    if (key == LogicalKeyboardKey.f2) return keyF2;
    if (key == LogicalKeyboardKey.f3) return keyF3;
    if (key == LogicalKeyboardKey.f4) return keyF4;
    if (key == LogicalKeyboardKey.f5) return keyF5;
    if (key == LogicalKeyboardKey.f6) return keyF6;
    if (key == LogicalKeyboardKey.f7) return keyF7;
    if (key == LogicalKeyboardKey.f8) return keyF8;
    if (key == LogicalKeyboardKey.f9) return keyF9;
    if (key == LogicalKeyboardKey.f10) return keyF10;
    if (key == LogicalKeyboardKey.f12) return keyF12;
    if (key == LogicalKeyboardKey.space) return keySpace;

    return null;
  }

  static bool matchesAction(
    KeyboardShortcutSettings settings,
    String actionId,
    KeyEvent event,
  ) {
    final eventKeyId = keyIdFromEvent(event);
    if (eventKeyId == null) {
      return false;
    }

    final configuredKey = shortcutFor(settings, actionId);
    if (configuredKey == eventKeyId) {
      return true;
    }

    if (!settings.useNumpadNavigation) {
      return false;
    }

    return switch (actionId) {
      moveUpAction =>
        eventKeyId == keyArrowUp || eventKeyId == keyNumpad8,
      moveDownAction =>
        eventKeyId == keyArrowDown || eventKeyId == keyNumpad2,
      activateAction =>
        eventKeyId == keyEnter || eventKeyId == keyNumpadEnter,
      _ => false,
    };
  }
}