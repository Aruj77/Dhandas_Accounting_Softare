// =============================================================================
// DHANDAS — CENTRAL KEYBOARD SYSTEM (single source of truth)
//
// Every keyboard action, every default key, every user-remap option, the
// runtime matcher, focus helpers, the global key-listener widget, and the
// "Keyboard Shortcuts" help dialog live in THIS ONE FILE.
//
// Do not add keyboard logic to any other file. To add a new shortcut:
//   1. Add an id to `KeyboardAction`.
//   2. Add a row to `KeyboardActionCatalog.all` (for the help dialog).
//   3. Add its default key to `KeyboardShortcutService.defaultShortcuts`
//      (and to `_configurableActions` in `KeyboardRegistry` if the user
//      should be able to remap it from Settings).
//   4. Handle the action id in the screen's `onAction` callback.
// A screen decides what an action means; this file only decides *which key*
// fires it and *whether the user personally changed that*.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────
// 1. ACTIONS — abstract ids. Independent of any widget/screen.
// ─────────────────────────────────────────────────────────────────────────
abstract final class KeyboardAction {
  // Navigation
  static const String back = 'back';
  static const String up = 'up';
  static const String down = 'down';
  static const String left = 'left';
  static const String right = 'right';
  static const String activate = 'activate';
  static const String cancel = 'cancel';
  static const String focusSidebar = 'focusSidebar';
  static const String focusContent = 'focusContent';

  // Application
  static const String help = 'help';
  static const String search = 'search';
  static const String goTo = 'goTo';
  static const String newRecord = 'newRecord';
  static const String save = 'save';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String duplicate = 'duplicate';
  static const String print = 'print';
  static const String export = 'export';

  // Company
  static const String openCompany = 'openCompany';
  static const String createCompany = 'createCompany';
  static const String changeDirectory = 'changeDirectory';
  static const String switchWorkspace = 'switchWorkspace';
  static const String companyFeatures = 'companyFeatures';
  static const String configuration = 'configuration';

  // Vouchers (generic)
  static const String voucherDate = 'voucherDate';
  static const String saveVoucher = 'saveVoucher';
  static const String newVoucher = 'newVoucher';
  static const String voucherList = 'voucherList';

  // Tally/Busy-style voucher TYPE shortcuts (used from the transactions
  // dashboard / voucher list to jump straight into a voucher type).
  static const String contra = 'contra';
  static const String payment = 'payment';
  static const String receipt = 'receipt';
  static const String journal = 'journal';
  static const String sales = 'sales';
  static const String purchase = 'purchase';
  static const String creditNote = 'creditNote';
  static const String debitNote = 'debitNote';

  // Busy-style, voucher-entry-screen-only actions (scoped via
  // KeyboardScope.actionIds so they never collide with the app-level
  // F-keys above).
  static const String createLedger = 'createLedger'; // Alt+F1
  static const String createItem = 'createItem'; // Alt+F2
  static const String findMaster = 'findMaster'; // F3 (inside voucher)
  static const String repeatField = 'repeatField'; // F7 (inside voucher)
  static const String cancelVoucher = 'cancelVoucher'; // Ctrl+X
  static const String calculator = 'calculator'; // F10
  static const String hideRow = 'hideRow'; // F9 (inside voucher)
  static const String unhideRow = 'unhideRow'; // Alt+F9 (inside voucher)

  // Settings
  static const String settings = 'settings';
}

class KeyboardActionInfo {
  final String id;
  final String title;
  final String description;
  const KeyboardActionInfo({
    required this.id,
    required this.title,
    required this.description,
  });
}

abstract final class KeyboardActionCatalog {
  static const List<KeyboardActionInfo> all = [
    KeyboardActionInfo(id: KeyboardAction.back, title: 'Back', description: 'Go back or close the current layer.'),
    KeyboardActionInfo(id: KeyboardAction.up, title: 'Move Up', description: 'Move to the previous keyboard target.'),
    KeyboardActionInfo(id: KeyboardAction.down, title: 'Move Down', description: 'Move to the next keyboard target.'),
    KeyboardActionInfo(id: KeyboardAction.left, title: 'Move Left', description: 'Move to the previous column or target.'),
    KeyboardActionInfo(id: KeyboardAction.right, title: 'Move Right', description: 'Move to the next column or target.'),
    KeyboardActionInfo(id: KeyboardAction.activate, title: 'Accept / Select', description: 'Activate the current selection.'),
    KeyboardActionInfo(id: KeyboardAction.cancel, title: 'Cancel', description: 'Cancel the current operation.'),
    KeyboardActionInfo(id: KeyboardAction.help, title: 'Help', description: 'Show keyboard shortcut help.'),
    KeyboardActionInfo(id: KeyboardAction.search, title: 'Search', description: 'Open search.'),
    KeyboardActionInfo(id: KeyboardAction.goTo, title: 'Go To', description: 'Open the Go To navigation.'),
    KeyboardActionInfo(id: KeyboardAction.newRecord, title: 'New', description: 'Create a new record.'),
    KeyboardActionInfo(id: KeyboardAction.save, title: 'Save', description: 'Save the current record.'),
    KeyboardActionInfo(id: KeyboardAction.edit, title: 'Edit', description: 'Edit the selected record.'),
    KeyboardActionInfo(id: KeyboardAction.delete, title: 'Delete', description: 'Delete the selected record.'),
    KeyboardActionInfo(id: KeyboardAction.duplicate, title: 'Duplicate', description: 'Duplicate the selected record.'),
    KeyboardActionInfo(id: KeyboardAction.print, title: 'Print', description: 'Print the current document/report.'),
    KeyboardActionInfo(id: KeyboardAction.export, title: 'Export', description: 'Export the current data.'),
    KeyboardActionInfo(id: KeyboardAction.openCompany, title: 'Open Company', description: 'Open a company.'),
    KeyboardActionInfo(id: KeyboardAction.createCompany, title: 'Create Company', description: 'Create a new company.'),
    KeyboardActionInfo(id: KeyboardAction.changeDirectory, title: 'Change Data Directory', description: 'Change the local company data directory.'),
    KeyboardActionInfo(id: KeyboardAction.switchWorkspace, title: 'Switch Workspace', description: 'Return from a company to the workspace.'),
    KeyboardActionInfo(id: KeyboardAction.configuration, title: 'Configuration', description: 'Open configuration/settings.'),
    KeyboardActionInfo(id: KeyboardAction.saveVoucher, title: 'Save Voucher', description: 'Save the current voucher.'),
    KeyboardActionInfo(id: KeyboardAction.newVoucher, title: 'New Voucher', description: 'Create a new voucher of the current type.'),
    KeyboardActionInfo(id: KeyboardAction.voucherList, title: 'Voucher List', description: 'Open the voucher list.'),
    KeyboardActionInfo(id: KeyboardAction.contra, title: 'Contra Voucher', description: 'Create a Contra voucher.'),
    KeyboardActionInfo(id: KeyboardAction.payment, title: 'Payment Voucher', description: 'Create a Payment voucher.'),
    KeyboardActionInfo(id: KeyboardAction.receipt, title: 'Receipt Voucher', description: 'Create a Receipt voucher.'),
    KeyboardActionInfo(id: KeyboardAction.journal, title: 'Journal Voucher', description: 'Create a Journal voucher.'),
    KeyboardActionInfo(id: KeyboardAction.sales, title: 'Sales Voucher', description: 'Create a Sales voucher.'),
    KeyboardActionInfo(id: KeyboardAction.purchase, title: 'Purchase Voucher', description: 'Create a Purchase voucher.'),
    KeyboardActionInfo(id: KeyboardAction.creditNote, title: 'Credit Note', description: 'Create a Credit Note.'),
    KeyboardActionInfo(id: KeyboardAction.debitNote, title: 'Debit Note', description: 'Create a Debit Note.'),
    KeyboardActionInfo(id: KeyboardAction.createLedger, title: 'Create Ledger', description: 'Create a new account ledger on-the-fly.'),
    KeyboardActionInfo(id: KeyboardAction.createItem, title: 'Create Item', description: 'Create a new stock item on-the-fly.'),
    KeyboardActionInfo(id: KeyboardAction.findMaster, title: 'Find/Add Master', description: 'Search or add a master while typing.'),
    KeyboardActionInfo(id: KeyboardAction.repeatField, title: 'Repeat Field', description: 'Copy the value from the same field in the previous row.'),
    KeyboardActionInfo(id: KeyboardAction.cancelVoucher, title: 'Cancel Voucher', description: 'Cancel the current voucher.'),
    KeyboardActionInfo(id: KeyboardAction.calculator, title: 'Calculator', description: 'Open the built-in calculator.'),
    KeyboardActionInfo(id: KeyboardAction.hideRow, title: 'Hide Row', description: 'Hide the selected row.'),
    KeyboardActionInfo(id: KeyboardAction.unhideRow, title: 'Unhide Row', description: 'Unhide a previously hidden row.'),
  ];

  static KeyboardActionInfo? find(String id) {
    for (final action in all) {
      if (action.id == id) return action;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. COMMAND — one physical-key binding for one action.
// ─────────────────────────────────────────────────────────────────────────
class KeyboardCommand {
  final String actionId;
  final LogicalKeyboardKey key;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;
  final String label;

  const KeyboardCommand({
    required this.actionId,
    required this.key,
    required this.label,
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  bool matches(KeyEvent event) {
    if (event.logicalKey != key) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasControl = pressed.contains(LogicalKeyboardKey.controlLeft) || pressed.contains(LogicalKeyboardKey.controlRight);
    final hasAlt = pressed.contains(LogicalKeyboardKey.altLeft) || pressed.contains(LogicalKeyboardKey.altRight);
    final hasShift = pressed.contains(LogicalKeyboardKey.shiftLeft) || pressed.contains(LogicalKeyboardKey.shiftRight);
    final hasMeta = pressed.contains(LogicalKeyboardKey.metaLeft) || pressed.contains(LogicalKeyboardKey.metaRight);
    return hasControl == control && hasAlt == alt && hasShift == shift && hasMeta == meta;
  }

  @override
  String toString() => label;
}

// ─────────────────────────────────────────────────────────────────────────
// 3. FOCUS helpers
// ─────────────────────────────────────────────────────────────────────────
class KeyboardFocus {
  const KeyboardFocus._();
  static void request(FocusNode? node) => node?.requestFocus();
  static void unfocus(BuildContext context) => FocusScope.of(context).unfocus();
  static void next(BuildContext context) => FocusScope.of(context).nextFocus();
  static void previous(BuildContext context) => FocusScope.of(context).previousFocus();
  static bool isFocused(FocusNode? node) => node?.hasFocus ?? false;
}

// ─────────────────────────────────────────────────────────────────────────
// 4. SETTINGS — persistence for user remaps (personal, per device/user).
// ─────────────────────────────────────────────────────────────────────────
class KeyboardShortcutSettings {
  final bool keyboardIntensiveMode;
  final bool useNumpadNavigation;
  final Map<String, String> shortcuts;

  const KeyboardShortcutSettings({
    required this.keyboardIntensiveMode,
    required this.useNumpadNavigation,
    required this.shortcuts,
  });

  factory KeyboardShortcutSettings.defaults() => KeyboardShortcutSettings(
        keyboardIntensiveMode: true,
        useNumpadNavigation: true,
        shortcuts: Map<String, String>.from(KeyboardShortcutService.defaultShortcuts),
      );

  KeyboardShortcutSettings copyWith({
    bool? keyboardIntensiveMode,
    bool? useNumpadNavigation,
    Map<String, String>? shortcuts,
  }) =>
      KeyboardShortcutSettings(
        keyboardIntensiveMode: keyboardIntensiveMode ?? this.keyboardIntensiveMode,
        useNumpadNavigation: useNumpadNavigation ?? this.useNumpadNavigation,
        shortcuts: shortcuts ?? this.shortcuts,
      );

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
      if (rawShortcuts is Map) ...rawShortcuts.map((k, v) => MapEntry(k.toString(), v.toString())),
    };
    return KeyboardShortcutSettings(
      keyboardIntensiveMode: json['keyboardIntensiveMode'] is bool ? json['keyboardIntensiveMode'] as bool : defaults.keyboardIntensiveMode,
      useNumpadNavigation: json['useNumpadNavigation'] is bool ? json['useNumpadNavigation'] as bool : defaults.useNumpadNavigation,
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

/// Persistence + keymap for user-configurable shortcuts. Action ids are
/// always [KeyboardAction] ids — never redefined here.
class KeyboardShortcutService {
  static const String _prefsKey = 'dhandas_keyboard_shortcut_settings';

  // Back-compat aliases so older call sites keep reading naturally.
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

  // Key ids (physical keys a user can bind an action to).
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
  static const String keyCtrlN = 'ctrlN';
  static const String keyCtrlS = 'ctrlS';
  static const String keyCtrlD = 'ctrlD';
  static const String keyCtrlP = 'ctrlP';
  static const String keyCtrlE = 'ctrlE';
  static const String keyCtrlF8 = 'ctrlF8';
  static const String keyCtrlF9 = 'ctrlF9';
  static const String keyF10Alt = 'altF10';
  static const String keyAltF1 = 'altF1';
  static const String keyAltF2 = 'altF2';
  static const String keyAltF9 = 'altF9';
  static const String keyCtrlX = 'ctrlX';

  /// Global defaults — Tally/Busy-style keymap so the whole app is usable
  /// without a mouse out of the box. Users may override any of these from
  /// Settings; overrides are stored personally (SharedPreferences).
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

    // Tally-style voucher type shortcuts — only active on screens that
    // register them (transactions dashboard / voucher list).
    KeyboardAction.contra: keyF4,
    KeyboardAction.payment: keyF5,
    KeyboardAction.receipt: keyF6,
    KeyboardAction.journal: keyF7,
    KeyboardAction.sales: keyF8,
    KeyboardAction.purchase: keyF9,
    KeyboardAction.creditNote: keyCtrlF8,
    KeyboardAction.debitNote: keyCtrlF9,
    KeyboardAction.voucherList: keyF10Alt,

    // Busy-style voucher-entry-only keys (see KeyboardAction for the list).
    KeyboardAction.createLedger: keyAltF1,
    KeyboardAction.createItem: keyAltF2,
    KeyboardAction.findMaster: keyF3,
    KeyboardAction.repeatField: keyF7,
    KeyboardAction.cancelVoucher: keyCtrlX,
    KeyboardAction.calculator: keyF10,
    KeyboardAction.hideRow: keyF9,
    KeyboardAction.unhideRow: keyAltF9,
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
    KeyboardShortcutOption(id: keyCtrlF8, label: 'Ctrl+F8'),
    KeyboardShortcutOption(id: keyCtrlF9, label: 'Ctrl+F9'),
    KeyboardShortcutOption(id: keyF10Alt, label: 'Alt+F10'),
    KeyboardShortcutOption(id: keyAltF1, label: 'Alt+F1'),
    KeyboardShortcutOption(id: keyAltF2, label: 'Alt+F2'),
    KeyboardShortcutOption(id: keyAltF9, label: 'Alt+F9'),
    KeyboardShortcutOption(id: keyCtrlX, label: 'Ctrl+X'),
  ];

  /// Every user-remappable shortcut, shown as-is on the Settings screen.
  static final List<KeyboardShortcutDefinition> definitions = [
    for (final a in [
      moveUpAction, moveDownAction, moveLeftAction, moveRightAction, activateAction, goBackAction,
      KeyboardAction.help, KeyboardAction.search, KeyboardAction.goTo, KeyboardAction.newRecord,
      KeyboardAction.save, KeyboardAction.edit, KeyboardAction.delete, KeyboardAction.duplicate,
      KeyboardAction.print, KeyboardAction.export, openCompanyAction, createCompanyAction,
      changeDirectoryAction, openSettingsAction, switchWorkspaceAction, saveVoucherAction,
      KeyboardAction.contra, KeyboardAction.payment, KeyboardAction.receipt, KeyboardAction.journal,
      KeyboardAction.sales, KeyboardAction.purchase, KeyboardAction.creditNote, KeyboardAction.debitNote,
      KeyboardAction.voucherList, KeyboardAction.createLedger, KeyboardAction.createItem,
      KeyboardAction.findMaster, KeyboardAction.repeatField, KeyboardAction.cancelVoucher,
      KeyboardAction.calculator, KeyboardAction.hideRow, KeyboardAction.unhideRow,
    ])
      KeyboardShortcutDefinition(
        actionId: a,
        title: KeyboardActionCatalog.find(a)?.title ?? a,
        description: KeyboardActionCatalog.find(a)?.description ?? '',
        options: _options,
      ),
  ];

  // Persistence
  static Future<KeyboardShortcutSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return KeyboardShortcutSettings.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return KeyboardShortcutSettings.fromJson(decoded);
      if (decoded is Map) return KeyboardShortcutSettings.fromJson(decoded.map((k, v) => MapEntry(k.toString(), v)));
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

  // Lookup helpers
  static String shortcutFor(KeyboardShortcutSettings settings, String actionId) =>
      settings.shortcuts[actionId] ?? defaultShortcuts[actionId] ?? keyEnter;

  static String labelForKey(String keyId) {
    for (final option in _options) {
      if (option.id == keyId) return option.label;
    }
    return keyId;
  }

  static String labelForAction(KeyboardShortcutSettings settings, String actionId) => labelForKey(shortcutFor(settings, actionId));

  static bool get _controlPressed {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.controlLeft) || pressed.contains(LogicalKeyboardKey.controlRight);
  }

  static bool get _altPressed {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.altLeft) || pressed.contains(LogicalKeyboardKey.altRight);
  }

  static String? keyIdFromEvent(KeyEvent event) {
    final key = event.logicalKey;

    if (_controlPressed) {
      if (key == LogicalKeyboardKey.keyN) return keyCtrlN;
      if (key == LogicalKeyboardKey.keyS) return keyCtrlS;
      if (key == LogicalKeyboardKey.keyD) return keyCtrlD;
      if (key == LogicalKeyboardKey.keyP) return keyCtrlP;
      if (key == LogicalKeyboardKey.keyE) return keyCtrlE;
      if (key == LogicalKeyboardKey.f8) return keyCtrlF8;
      if (key == LogicalKeyboardKey.f9) return keyCtrlF9;
      if (key == LogicalKeyboardKey.keyX) return keyCtrlX;
    }
    if (_altPressed) {
      if (key == LogicalKeyboardKey.f10) return keyF10Alt;
      if (key == LogicalKeyboardKey.f1) return keyAltF1;
      if (key == LogicalKeyboardKey.f2) return keyAltF2;
      if (key == LogicalKeyboardKey.f9) return keyAltF9;
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

  static bool matchesAction(KeyboardShortcutSettings settings, String actionId, KeyEvent event) {
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

// ─────────────────────────────────────────────────────────────────────────
// 5. REGISTRY — turns settings into concrete KeyboardCommands at runtime.
// ─────────────────────────────────────────────────────────────────────────
class KeyboardRegistry {
  KeyboardRegistry._();
  static final KeyboardRegistry instance = KeyboardRegistry._();

  // Fixed commands: always active, never remapped by the user.
  // Context-specific voucher-type shortcuts (F4..F9, Ctrl+F8/F9) are
  // configurable instead, so a screen can opt in via `commandsFor`.
  final List<KeyboardCommand> _fixedCommands = [
    KeyboardCommand(actionId: KeyboardAction.back, key: LogicalKeyboardKey.escape, label: 'Esc'),
    KeyboardCommand(actionId: KeyboardAction.up, key: LogicalKeyboardKey.arrowUp, label: '↑'),
    KeyboardCommand(actionId: KeyboardAction.down, key: LogicalKeyboardKey.arrowDown, label: '↓'),
    KeyboardCommand(actionId: KeyboardAction.left, key: LogicalKeyboardKey.arrowLeft, label: '←'),
    KeyboardCommand(actionId: KeyboardAction.right, key: LogicalKeyboardKey.arrowRight, label: '→'),
    KeyboardCommand(actionId: KeyboardAction.activate, key: LogicalKeyboardKey.enter, label: 'Enter'),
    KeyboardCommand(actionId: KeyboardAction.focusSidebar, key: LogicalKeyboardKey.tab, shift: true, label: 'Shift+Tab'),
    KeyboardCommand(actionId: KeyboardAction.focusContent, key: LogicalKeyboardKey.tab, label: 'Tab'),
  ];

  // User-configurable actions (remappable from Settings screen).
  static const List<String> _configurableActions = [
    KeyboardAction.help,
    KeyboardAction.openCompany,
    KeyboardAction.createCompany,
    KeyboardAction.changeDirectory,
    KeyboardAction.settings,
    KeyboardAction.switchWorkspace,
    KeyboardAction.search,
    KeyboardAction.goTo,
    KeyboardAction.newRecord,
    KeyboardAction.save,
    KeyboardAction.edit,
    KeyboardAction.delete,
    KeyboardAction.duplicate,
    KeyboardAction.print,
    KeyboardAction.export,
    KeyboardAction.saveVoucher,
    // Tally-style voucher type keys — screens that don't need them simply
    // never see these action ids fire (they're not in `_fixedCommands`,
    // and a screen's own KeyboardScope only reacts to ids it handles).
    KeyboardAction.contra,
    KeyboardAction.payment,
    KeyboardAction.receipt,
    KeyboardAction.journal,
    KeyboardAction.sales,
    KeyboardAction.purchase,
    KeyboardAction.creditNote,
    KeyboardAction.debitNote,
    KeyboardAction.voucherList,
    KeyboardAction.createLedger,
    KeyboardAction.createItem,
    KeyboardAction.findMaster,
    KeyboardAction.repeatField,
    KeyboardAction.cancelVoucher,
    KeyboardAction.calculator,
    KeyboardAction.hideRow,
    KeyboardAction.unhideRow,
  ];

  KeyboardShortcutSettings? _settings;
  KeyboardShortcutSettings get settings => _settings ?? KeyboardShortcutSettings.defaults();

  void updateSettings(KeyboardShortcutSettings settings) => _settings = settings;
  void clearSettings() => _settings = null;

  List<KeyboardCommand> get commands {
    final s = settings;
    final result = <KeyboardCommand>[..._fixedCommands];
    for (final actionId in _configurableActions) {
      final keyId = KeyboardShortcutService.shortcutFor(s, actionId);
      final command = _commandFromKeyId(actionId, keyId);
      if (command != null) result.add(command);
    }
    return List.unmodifiable(result);
  }

  List<KeyboardCommand> commandsFor(String actionId) =>
      commands.where((c) => c.actionId == actionId).toList(growable: false);

  /// Resolve a raw key event to a command among the *fixed* set plus a
  /// given subset of configurable action ids that the calling screen cares
  /// about (defaults to all — pass a narrower list to avoid, e.g., a
  /// voucher-entry screen's Save (F2) colliding with a dashboard's F-keys).
  KeyboardCommand? commandFor(KeyEvent event, {List<String>? only}) {
    final s = settings;

    for (final command in _fixedCommands) {
      if (command.matches(event)) return command;
    }

    final actionIds = only ?? _configurableActions;
    for (final actionId in actionIds) {
      if (!_configurableActions.contains(actionId)) continue;
      if (KeyboardShortcutService.matchesAction(s, actionId, event)) {
        final keyId = KeyboardShortcutService.shortcutFor(s, actionId);
        return _commandFromKeyId(actionId, keyId);
      }
    }
    return null;
  }

  KeyboardCommand? _commandFromKeyId(String actionId, String keyId) {
    final key = _logicalKeyFromId(keyId);
    if (key == null) return null;
    return KeyboardCommand(
      actionId: actionId,
      key: key,
      control: keyId.startsWith('ctrl'),
      alt: keyId.startsWith('alt'),
      label: KeyboardShortcutService.labelForKey(keyId),
    );
  }

  LogicalKeyboardKey? _logicalKeyFromId(String keyId) {
    switch (keyId) {
      case KeyboardShortcutService.keyEscape:
        return LogicalKeyboardKey.escape;
      case KeyboardShortcutService.keyArrowUp:
        return LogicalKeyboardKey.arrowUp;
      case KeyboardShortcutService.keyArrowDown:
        return LogicalKeyboardKey.arrowDown;
      case KeyboardShortcutService.keyArrowLeft:
        return LogicalKeyboardKey.arrowLeft;
      case KeyboardShortcutService.keyArrowRight:
        return LogicalKeyboardKey.arrowRight;
      case KeyboardShortcutService.keyEnter:
        return LogicalKeyboardKey.enter;
      case KeyboardShortcutService.keyNumpadEnter:
        return LogicalKeyboardKey.numpadEnter;
      case KeyboardShortcutService.keyNumpad8:
        return LogicalKeyboardKey.numpad8;
      case KeyboardShortcutService.keyNumpad2:
        return LogicalKeyboardKey.numpad2;
      case KeyboardShortcutService.keyNumpad4:
        return LogicalKeyboardKey.numpad4;
      case KeyboardShortcutService.keyNumpad6:
        return LogicalKeyboardKey.numpad6;
      case KeyboardShortcutService.keySpace:
        return LogicalKeyboardKey.space;
      case KeyboardShortcutService.keyTab:
        return LogicalKeyboardKey.tab;
      case KeyboardShortcutService.keyF1:
        return LogicalKeyboardKey.f1;
      case KeyboardShortcutService.keyF2:
        return LogicalKeyboardKey.f2;
      case KeyboardShortcutService.keyF3:
        return LogicalKeyboardKey.f3;
      case KeyboardShortcutService.keyF4:
        return LogicalKeyboardKey.f4;
      case KeyboardShortcutService.keyF5:
        return LogicalKeyboardKey.f5;
      case KeyboardShortcutService.keyF6:
        return LogicalKeyboardKey.f6;
      case KeyboardShortcutService.keyF7:
        return LogicalKeyboardKey.f7;
      case KeyboardShortcutService.keyF8:
        return LogicalKeyboardKey.f8;
      case KeyboardShortcutService.keyF9:
        return LogicalKeyboardKey.f9;
      case KeyboardShortcutService.keyF10:
        return LogicalKeyboardKey.f10;
      case KeyboardShortcutService.keyF11:
        return LogicalKeyboardKey.f11;
      case KeyboardShortcutService.keyF12:
        return LogicalKeyboardKey.f12;
      case KeyboardShortcutService.keyDelete:
        return LogicalKeyboardKey.delete;
      case KeyboardShortcutService.keyCtrlN:
        return LogicalKeyboardKey.keyN;
      case KeyboardShortcutService.keyCtrlS:
        return LogicalKeyboardKey.keyS;
      case KeyboardShortcutService.keyCtrlD:
        return LogicalKeyboardKey.keyD;
      case KeyboardShortcutService.keyCtrlP:
        return LogicalKeyboardKey.keyP;
      case KeyboardShortcutService.keyCtrlE:
        return LogicalKeyboardKey.keyE;
      case KeyboardShortcutService.keyCtrlF8:
        return LogicalKeyboardKey.f8;
      case KeyboardShortcutService.keyCtrlF9:
        return LogicalKeyboardKey.f9;
      case KeyboardShortcutService.keyF10Alt:
        return LogicalKeyboardKey.f10;
      case KeyboardShortcutService.keyAltF1:
        return LogicalKeyboardKey.f1;
      case KeyboardShortcutService.keyAltF2:
        return LogicalKeyboardKey.f2;
      case KeyboardShortcutService.keyAltF9:
        return LogicalKeyboardKey.f9;
      case KeyboardShortcutService.keyCtrlX:
        return LogicalKeyboardKey.keyX;
      default:
        return null;
    }
  }

  String labelForAction(String actionId) => KeyboardShortcutService.labelForAction(settings, actionId);
}

// ─────────────────────────────────────────────────────────────────────────
// 6. SCOPE — the one widget every screen wraps itself in to get keys.
// ─────────────────────────────────────────────────────────────────────────
typedef KeyboardActionHandler = KeyEventResult Function(String actionId, KeyEvent event);

class KeyboardScope extends StatefulWidget {
  const KeyboardScope({
    super.key,
    required this.child,
    required this.onAction,
    this.enabled = true,
    this.autofocus = true,
    this.actionIds,
  });

  final Widget child;
  final KeyboardActionHandler onAction;
  final bool enabled;
  final bool autofocus;

  /// Restrict which *configurable* action ids this scope reacts to (e.g. a
  /// dashboard passes the Tally voucher-type ids; a voucher-entry screen
  /// leaves this null to get the normal app-wide set). Fixed navigation
  /// commands always work regardless of this list.
  final List<String>? actionIds;

  @override
  State<KeyboardScope> createState() => _KeyboardScopeState();
}

class _KeyboardScopeState extends State<KeyboardScope> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'GlobalKeyboardScope');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final command = KeyboardRegistry.instance.commandFor(
      event,
      only: widget.actionIds,
    );

    // Consume ALL Alt key combinations to prevent Windows beep.
    if (HardwareKeyboard.instance.isAltPressed) {
      if (command != null) {
        final result = widget.onAction(command.actionId, event);

        return result == KeyEventResult.ignored
            ? KeyEventResult.handled
            : result;
      }

      return KeyEventResult.handled;
    }

    if (command == null) {
      return KeyEventResult.ignored;
    }

    return widget.onAction(command.actionId, event);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 7. HELP DIALOG — press the Help key (F1 by default) anywhere.
// ─────────────────────────────────────────────────────────────────────────
class KeyboardHelpDialog extends StatelessWidget {
  const KeyboardHelpDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(context: context, builder: (_) => const KeyboardHelpDialog());
  }

  @override
  Widget build(BuildContext context) {
    final commands = KeyboardRegistry.instance.commands;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard_alt_outlined),
          SizedBox(width: 12),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 560,
        child: ListView(
          children: [
            const Text(
              'Dhandas is designed to work without depending on the mouse.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...KeyboardActionCatalog.all.map((action) {
              final actionCommands = commands.where((c) => c.actionId == action.id).toList();
              if (actionCommands.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: actionCommands
                            .map((c) => Chip(label: Text(c.label), visualDensity: VisualDensity.compact))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
