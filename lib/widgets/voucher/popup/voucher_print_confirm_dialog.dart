import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoucherPrintConfirmDialog extends StatefulWidget {
  final String voucherType;

  const VoucherPrintConfirmDialog({
    super.key,
    required this.voucherType,
  });

  static Future<bool> show(
    BuildContext context, {
    String voucherType = '',
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => VoucherPrintConfirmDialog(
            voucherType: voucherType,
          ),
        ) ??
        false;
  }

  @override
  State<VoucherPrintConfirmDialog> createState() =>
      _VoucherPrintConfirmDialogState();
}

class _VoucherPrintConfirmDialogState
    extends State<VoucherPrintConfirmDialog> {
  final FocusNode _focusNode = FocusNode();

  bool _yesSelected = true;

  static const blue = Color(0xFF0F62FE);
  static const text = Color(0xFF172033);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _close(bool value) {
    Navigator.of(context).pop(value);
  }

  void _toggle() {
    setState(() {
      _yesSelected = !_yesSelected;
    });
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Left / Right / Tab
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.tab) {
      _toggle();
      return KeyEventResult.handled;
    }

    // Direct selection
    if (key == LogicalKeyboardKey.keyY) {
      _close(true);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyN ||
        key == LogicalKeyboardKey.escape) {
      _close(false);
      return KeyEventResult.handled;
    }

    // Confirm selected option
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _close(_yesSelected);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _button({
    required String label,
    required String shortcut,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? blue : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? blue : const Color(0xFFD1D9E6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortcut,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: 320,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Small success icon
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
              ),

              const SizedBox(width: 9),

              // Message
              const Expanded(
                child: Text(
                  'Print voucher?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
              ),

              // No
              _button(
                label: 'No',
                shortcut: 'N',
                selected: !_yesSelected,
                onTap: () => _close(false),
              ),

              const SizedBox(width: 5),

              // Yes
              _button(
                label: 'Yes',
                shortcut: 'Y',
                selected: _yesSelected,
                onTap: () => _close(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}