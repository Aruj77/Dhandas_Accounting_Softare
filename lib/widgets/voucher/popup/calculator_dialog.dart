import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

      // Handle percentage conversion inline if present (e.g., "50%")
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

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final result = _evaluateExpression(_displayCtrl.text);
      final finalVal = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
      widget.onSubmitted(finalVal);
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onKeyTapped('⌫');
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character != null && '0123456789+-*/.%×÷'.contains(character)) {
      _onKeyTapped(character);
      return KeyEventResult.handled;
    }

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

    if (numpadMap.containsKey(event.logicalKey)) {
      _onKeyTapped(numpadMap[event.logicalKey]!);
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
                    color: const Color(0xFF101B3A).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33092B60), blurRadius: 24, offset: Offset(0, 10)),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Draggable Titlebar
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F62FE).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.calculate_rounded, color: Color(0xFF0F62FE), size: 15),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Calc (F4)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Display Screen
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: TextField(
                          controller: _displayCtrl,
                          readOnly: true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Keypad Grid
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

                          Color bg = const Color(0xFF1E293B);
                          Color fg = Colors.white;

                          if (btn == '=') {
                            bg = const Color(0xFF0F62FE);
                          } else if (isAction) {
                            bg = const Color(0xFF27354F);
                            fg = const Color(0xFF94A3B8);
                          } else if (isOperator) {
                            bg = const Color(0xFF2C3E5D);
                            fg = const Color(0xFF60A5FA);
                          }

                          // Clean up button label representation
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