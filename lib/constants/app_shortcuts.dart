import 'package:flutter/services.dart';

class AppShortcuts {
  // Action identifiers
  static const String quickAddMaster = 'quick_add_master'; // Alt + C
  static const String openTaxDetails = 'open_tax_details'; // Alt + E
  static const String saveVoucher = 'save_voucher';       // F2 or Ctrl+S
  static const String quitOrClose = 'quit_or_close';       // Esc

  /// Returns true if Alt + C is pressed
  static bool isQuickAdd(KeyEvent event) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC;
  }

  /// Returns true if Alt + E is pressed
  static bool isTaxDetails(KeyEvent event) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.keyE;
  }

  /// General Alt key checker
  static bool isAltKey(KeyEvent event, LogicalKeyboardKey key) {
    return event is KeyDownEvent &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == key;
  }
}