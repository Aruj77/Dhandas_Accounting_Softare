// desktop/lib/services/keyboard_shortcut_service.dart
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
      keyboardIntensiveMode: keyboardIntensiveMode ?? this.keyboardIntensiveMode,
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
      keyboardIntensiveMode: json['keyboardIntensiveMode'] is bool
          ? json['keyboardIntensiveMode'] as bool
          : defaultSettings.keyboardIntensiveMode,
      useNumpadNavigation: json['useNumpadNavigation'] is bool
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

  // --- Dynamic Action Identifiers ---
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
  static const String quickAddMasterAction = 'quickAddMaster';
  static const String modifyMasterAction = 'modifyMaster';
  static const String previousVoucherAction = 'previousVoucher';
  static const String nextVoucherAction = 'nextVoucher';
  static const String printInvoiceAction = 'printInvoice';
  static const String calculatorAction = 'calculator';
  static const String exportExcelAction = 'exportExcel';
  static const String exportJsonAction = 'exportJson';
  static const String columnsDialogAction = 'columnsDialog';

  // Transaction Specific Actions
  static const String addSalesInvoiceAction = 'addSalesInvoice';
  static const String addSaleReturnAction = 'addSaleReturn';
  static const String addPaymentInAction = 'addPaymentIn';
  static const String addPurchaseBillAction = 'addPurchaseBill';
  static const String addPurchaseReturnAction = 'addPurchaseReturn';
  static const String addPaymentOutAction = 'addPaymentOut';
  static const String addJournalVoucherAction = 'addJournalVoucher';
  static const String addContraEntryAction = 'addContraEntry';

  // --- Default Key Mappings ---
  static const Map<String, String> defaultShortcuts = {
    goBackAction: 'Esc',
    moveUpAction: 'ArrowUp',
    moveDownAction: 'ArrowDown',
    activateAction: 'Enter',
    openCompanyAction: 'F3',
    createCompanyAction: 'F4',
    changeDirectoryAction: 'F6',
    openSettingsAction: 'F12',
    switchWorkspaceAction: 'F8',
    
    saveVoucherAction: 'F2',
    quickAddMasterAction: 'Ctrl+C',
    modifyMasterAction: 'Ctrl+E',
    previousVoucherAction: 'Ctrl+B',
    nextVoucherAction: 'Ctrl+N',
    printInvoiceAction: 'Ctrl+P',
    calculatorAction: 'F4',
    exportExcelAction: 'Ctrl+E',
    exportJsonAction: 'Ctrl+J',
    columnsDialogAction: 'Ctrl+Q',

    addSalesInvoiceAction: 'F3',
    addSaleReturnAction: 'Shift+F3',
    addPaymentInAction: 'F6',
    addPurchaseBillAction: 'F4',
    addPurchaseReturnAction: 'Shift+F4',
    addPaymentOutAction: 'F7',
    addJournalVoucherAction: 'F8',
    addContraEntryAction: 'F9',
  };

  // --- Universal Structural Navigation Helpers ---
  static bool isUp(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.numpad8;
  }

  static bool isDown(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.numpad2;
  }

  static bool isLeft(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.numpad4;
  }

  static bool isRight(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.numpad6;
  }

  static bool isConfirm(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.enter ||
           event.logicalKey == LogicalKeyboardKey.numpadEnter ||
           event.logicalKey == LogicalKeyboardKey.space;
  }

  static bool isExit(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.escape;
  }

  static bool isBackspace(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.backspace;
  }

  static bool isTab(KeyEvent event, {bool requireUnshifted = false}) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.tab) return false;
    if (requireUnshifted && HardwareKeyboard.instance.isShiftPressed) return false;
    return true;
  }

  // --- Convenience Hardware Wrappers for UI Widgets ---
  static bool isQuickAdd(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyC;
  }

  static bool isModifyOrTaxDetails(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyE;
  }

  static bool isPreviousVoucher(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyB;
  }

  static bool isNextVoucher(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyN;
  }

  static bool isPrint(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyP;
  }

  static bool isExportExcel(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && hw.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyE;
  }

  static bool isExportJson(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyJ;
  }

  static bool isColumnsDialog(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    return (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyQ;
  }

  static bool isCalculator(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    return event.logicalKey == LogicalKeyboardKey.f4;
  }

  static bool isSave(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final hw = HardwareKeyboard.instance;
    final isCtrlS = (hw.isControlPressed || hw.isMetaPressed) && event.logicalKey == LogicalKeyboardKey.keyS;
    return event.logicalKey == LogicalKeyboardKey.f2 || isCtrlS;
  }

  static String? extractCharOrNumpad(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
    if (event.character != null && event.character!.isNotEmpty) return event.character;

    final numpadMap = {
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
      LogicalKeyboardKey.numpadAdd: '+',
      LogicalKeyboardKey.numpadSubtract: '-',
      LogicalKeyboardKey.numpadMultiply: '*',
      LogicalKeyboardKey.numpadDivide: '/',
      LogicalKeyboardKey.numpadDecimal: '.',
    };

    return numpadMap[event.logicalKey];
  }

  // --- Dynamic String Parsing for Shortcut Mapping ---
  static String? keyIdFromEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;

    final key = event.logicalKey;
    final hw = HardwareKeyboard.instance;
    final isShift = hw.isShiftPressed;
    final isCtrl = hw.isControlPressed || hw.isMetaPressed;

    String prefix = '';
    if (isCtrl) prefix += 'Ctrl+';
    if (isShift) prefix += 'Shift+';

    // F-Keys
    if (key == LogicalKeyboardKey.f2) return '${prefix}F2';
    if (key == LogicalKeyboardKey.f3) return '${prefix}F3';
    if (key == LogicalKeyboardKey.f4) return '${prefix}F4';
    if (key == LogicalKeyboardKey.f5) return '${prefix}F5';
    if (key == LogicalKeyboardKey.f6) return '${prefix}F6';
    if (key == LogicalKeyboardKey.f7) return '${prefix}F7';
    if (key == LogicalKeyboardKey.f8) return '${prefix}F8';
    if (key == LogicalKeyboardKey.f9) return '${prefix}F9';
    if (key == LogicalKeyboardKey.f10) return '${prefix}F10';
    if (key == LogicalKeyboardKey.f12) return '${prefix}F12';

    // System/Navigation Keys
    if (key == LogicalKeyboardKey.escape) return '${prefix}Esc';
    if (key == LogicalKeyboardKey.enter) return '${prefix}Enter';
    if (key == LogicalKeyboardKey.numpadEnter) return '${prefix}NumpadEnter';
    if (key == LogicalKeyboardKey.space) return '${prefix}Space';
    if (key == LogicalKeyboardKey.arrowUp) return '${prefix}ArrowUp';
    if (key == LogicalKeyboardKey.arrowDown) return '${prefix}ArrowDown';
    if (key == LogicalKeyboardKey.arrowLeft) return '${prefix}ArrowLeft';
    if (key == LogicalKeyboardKey.arrowRight) return '${prefix}ArrowRight';
    if (key == LogicalKeyboardKey.numpad8) return '${prefix}Numpad8';
    if (key == LogicalKeyboardKey.numpad2) return '${prefix}Numpad2';
    if (key == LogicalKeyboardKey.numpad4) return '${prefix}Numpad4';
    if (key == LogicalKeyboardKey.numpad6) return '${prefix}Numpad6';

    // Alpha keys for combinations (Ctrl+C, Ctrl+P, etc.)
    if (key == LogicalKeyboardKey.keyB) return '${prefix}B';
    if (key == LogicalKeyboardKey.keyC) return '${prefix}C';
    if (key == LogicalKeyboardKey.keyE) return '${prefix}E';
    if (key == LogicalKeyboardKey.keyJ) return '${prefix}J';
    if (key == LogicalKeyboardKey.keyN) return '${prefix}N';
    if (key == LogicalKeyboardKey.keyP) return '${prefix}P';
    if (key == LogicalKeyboardKey.keyQ) return '${prefix}Q';
    if (key == LogicalKeyboardKey.keyS) return '${prefix}S';

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
    
    if (actionId == saveVoucherAction && eventKeyId == 'Ctrl+S') return true;

    if (configuredKey == eventKeyId) {
      return true;
    }

    if (!settings.useNumpadNavigation) return false;

    return switch (actionId) {
      moveUpAction => eventKeyId == 'ArrowUp' || eventKeyId == 'Numpad8',
      moveDownAction => eventKeyId == 'ArrowDown' || eventKeyId == 'Numpad2',
      activateAction => eventKeyId == 'Enter' || eventKeyId == 'NumpadEnter',
      _ => false,
    };
  }

  static String shortcutFor(KeyboardShortcutSettings settings, String actionId) {
    return settings.shortcuts[actionId] ?? defaultShortcuts[actionId] ?? 'Enter';
  }

  static String labelForKey(String keyId) {
    return keyId; 
  }

  static String labelForAction(KeyboardShortcutSettings settings, String actionId) {
    return labelForKey(shortcutFor(settings, actionId));
  }

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
  
  static const List<KeyboardShortcutOption> universalOptions = [
    KeyboardShortcutOption(id: 'F2', label: 'F2'),
    KeyboardShortcutOption(id: 'F3', label: 'F3'),
    KeyboardShortcutOption(id: 'Shift+F3', label: 'Shift + F3'),
    KeyboardShortcutOption(id: 'F4', label: 'F4'),
    KeyboardShortcutOption(id: 'Shift+F4', label: 'Shift + F4'),
    KeyboardShortcutOption(id: 'F5', label: 'F5'),
    KeyboardShortcutOption(id: 'F6', label: 'F6'),
    KeyboardShortcutOption(id: 'F7', label: 'F7'),
    KeyboardShortcutOption(id: 'F8', label: 'F8'),
    KeyboardShortcutOption(id: 'F9', label: 'F9'),
    KeyboardShortcutOption(id: 'F10', label: 'F10'),
    KeyboardShortcutOption(id: 'F12', label: 'F12'),
    KeyboardShortcutOption(id: 'Ctrl+S', label: 'Ctrl + S'),
    KeyboardShortcutOption(id: 'Ctrl+P', label: 'Ctrl + P'),
    KeyboardShortcutOption(id: 'Ctrl+C', label: 'Ctrl + C'),
    KeyboardShortcutOption(id: 'Ctrl+E', label: 'Ctrl + E'),
    KeyboardShortcutOption(id: 'Ctrl+Q', label: 'Ctrl + Q'),
    KeyboardShortcutOption(id: 'Enter', label: 'Enter'),
    KeyboardShortcutOption(id: 'Esc', label: 'Esc'),
  ];

  static final List<KeyboardShortcutDefinition> definitions = [
    KeyboardShortcutDefinition(
      actionId: moveUpAction,
      title: 'Move Up',
      description: 'Move to the previous menu item or keyboard target.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: moveDownAction,
      title: 'Move Down',
      description: 'Move to the next menu item or keyboard target.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: activateAction,
      title: 'Activate Selection',
      description: 'Open the selected action or confirm the highlighted target.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: goBackAction,
      title: 'Go Back',
      description: 'Close the current view, dialog, or go to the previous layer.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: openCompanyAction,
      title: 'Open Company',
      description: 'Open the company selection dialog from the home workspace.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: createCompanyAction,
      title: 'Create Company',
      description: 'Start a new company setup quickly from the keyboard.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: changeDirectoryAction,
      title: 'Change Data Directory',
      description: 'Open the storage directory chooser.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: saveVoucherAction,
      title: 'Save Voucher',
      description: 'Save the current voucher entry screen.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addSalesInvoiceAction,
      title: 'Sales Invoice',
      description: 'Shortcut to create a new Sales Invoice.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addSaleReturnAction,
      title: 'Sale Return / Credit Note',
      description: 'Shortcut to create a new Sale Return.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addPaymentInAction,
      title: 'Payment In',
      description: 'Shortcut to record a receipt.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addPurchaseBillAction,
      title: 'Purchase Bill',
      description: 'Shortcut to enter a Purchase Bill.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addPurchaseReturnAction,
      title: 'Purchase Return / Debit Note',
      description: 'Shortcut to enter a Purchase Return.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addPaymentOutAction,
      title: 'Payment Out',
      description: 'Shortcut to record a supplier payment.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addJournalVoucherAction,
      title: 'Journal Voucher',
      description: 'Shortcut to make an accounting adjustment.',
      options: universalOptions,
    ),
    KeyboardShortcutDefinition(
      actionId: addContraEntryAction,
      title: 'Contra Entry',
      description: 'Shortcut to transfer between cash & bank.',
      options: universalOptions,
    ),
  ];
}