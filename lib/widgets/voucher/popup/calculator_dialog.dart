// desktop/lib/widgets/voucher/popup/calculator_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constants/app_colors.dart';
import '../../../../services/keyboard_shortcut_service.dart';

class CalculatorDialog extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSubmitted;

  const CalculatorDialog({
    super.key,
    required this.initialValue,
    required this.onSubmitted,
  });

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  late TextEditingController _displayCtrl;
  final FocusNode _keyboardFocusNode = FocusNode();
  Offset _position = const Offset(120, 120);

  @override
  void initState() {
    super.initState();
    _displayCtrl = TextEditingController(text: widget.initialValue);
    _displayCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _displayCtrl.text.length);
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  double _evaluateExpression(String input) {
    try {
      String sanitized = input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      if (sanitized.isEmpty) return 0.0;

      if (sanitized.endsWith('%')) {
        sanitized = sanitized.substring(0, sanitized.length - 1);
        final base = double.tryParse(sanitized) ?? 0.0;
        return base / 100.0;
      }

      final tokens = <String>[];
      String currentNumber = '';
      for (int i = 0; i < sanitized.length; i++) {
        final char = sanitized[i];
        if ('+-*/'.contains(char)) {
          if (currentNumber.isNotEmpty) {
            tokens.add(currentNumber);
            currentNumber = '';
          }
          tokens.add(char);
        } else {
          currentNumber += char;
        }
      }
      if (currentNumber.isNotEmpty) {
        tokens.add(currentNumber);
      }

      if (tokens.isEmpty) return 0.0;

      List<String> intermediate = [];
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          if (intermediate.isEmpty) return 0.0;
          final prev = double.parse(intermediate.removeLast());
          if (i + 1 >= tokens.length) return prev;
          final next = double.parse(tokens[++i]);
          final res = tokens[i - 1] == '*' ? prev * next : (next != 0 ? prev / next : 0.0);
          intermediate.add(res.toString());
        } else {
          intermediate.add(tokens[i]);
        }
      }

      if (intermediate.isEmpty) return 0.0;
      double result = double.parse(intermediate[0]);
      for (int i = 1; i < intermediate.length; i += 2) {
        if (i + 1 < intermediate.length) {
          final op = intermediate[i];
          final val = double.parse(intermediate[i + 1]);
          if (op == '+') result += val;
          if (op == '-') result -= val;
        }
      }

      return result;
    } catch (_) {
      return double.tryParse(input) ?? 0.0;
    }
  }

  void _onKeyTapped(String val) {
    setState(() {
      if (val == 'C') {
        _displayCtrl.text = '';
      } else if (val == '⌫') {
        if (_displayCtrl.text.isNotEmpty) {
          _displayCtrl.text = _displayCtrl.text.substring(0, _displayCtrl.text.length - 1);
        }
      } else if (val == '%') {
        final currentVal = double.tryParse(_displayCtrl.text) ?? 0.0;
        final res = currentVal / 100.0;
        _displayCtrl.text = res == res.toInt() ? res.toInt().toString() : res.toStringAsFixed(4);
      } else if (val == '=') {
        final result = _evaluateExpression(_displayCtrl.text);
        final finalVal = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
        widget.onSubmitted(finalVal);
        Navigator.pop(context);
      } else {
        _displayCtrl.text += val;
      }
      _displayCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _displayCtrl.text.length));
    });
  }

  KeyEventResult _handleKeyboardInput(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (KeyboardShortcutService.isConfirm(event)) {
      final result = _evaluateExpression(_displayCtrl.text);
      final finalVal = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
      widget.onSubmitted(finalVal);
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isBackspace(event)) {
      _onKeyTapped('⌫');
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isExit(event)) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    final character = KeyboardShortcutService.extractCharOrNumpad(event);
    if (character != null && '0123456789+-*/.%×÷'.contains(character)) {
      _onKeyTapped(character);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            child: Material(
              color: Colors.transparent,
              child: Focus(
                focusNode: _keyboardFocusNode,
                autofocus: true,
                onKeyEvent: _handleKeyboardInput,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.calcKeypadBg.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: AppColors.dialogShadowLight, blurRadius: 24, offset: Offset(0, 10)),
                    ],
                    border: Border.all(color: AppColors.surface.withValues(alpha: 0.12), width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 15),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Calc (F4)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.surface),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.calcDisplayBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surface.withValues(alpha: 0.06)),
                        ),
                        child: TextField(
                          controller: _displayCtrl,
                          readOnly: true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.surface),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.15,
                        children: [
                          'C', '(%', '÷', '⌫',
                          '7', '8', '9', '×',
                          '4', '5', '6', '-',
                          '1', '2', '3', '+',
                          '%', '0', '.', '=',
                        ].map((btn) {
                          final isOperator = ['÷', '×', '-', '+', '='].contains(btn);
                          final isAction = ['C', '⌫', '%', '(%'].contains(btn);

                          Color bg = AppColors.calcKeyNumBg;
                          Color fg = AppColors.surface;

                          if (btn == '=') {
                            bg = AppColors.primary;
                          } else if (isAction) {
                            bg = AppColors.calcKeyActionBg;
                            fg = AppColors.textMuted;
                          } else if (isOperator) {
                            bg = AppColors.calcKeyOpBg;
                            fg = AppColors.calcKeyOpFg;
                          }

                          final label = btn == '(%' ? '%' : btn;

                          return ElevatedButton(
                            onPressed: () => _onKeyTapped(label),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bg,
                              foregroundColor: fg,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(fontSize: btn == '=' ? 18 : 15, fontWeight: FontWeight.w800),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}