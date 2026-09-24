class MathExpressionEvaluator {
  static double? tryEvaluate(String input) {
    final sanitized = input.replaceAll(' ', '').trim();
    if (sanitized.isEmpty) return null;

    // Fast check: if it's already a clean number, just parse it
    final simpleNum = double.tryParse(sanitized);
    if (simpleNum != null) return simpleNum;

    // Only attempt if it contains basic math operators
    if (!sanitized.contains(RegExp(r'[+\-*/()]'))) return null;

    try {
      final parser = _Parser(sanitized);
      final val = parser.parse();
      if (val.isNaN || val.isInfinite) return null;
      return val;
    } catch (_) {
      return null;
    }
  }

  static String formatResult(double value, {bool isQty = false, int decimals = 2}) {
    if (isQty && value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(decimals);
  }
}

class _Parser {
  final String text;
  int _pos = 0;

  _Parser(this.text);

  double parse() {
    final value = _parseExpression();
    if (_pos < text.length) {
      throw FormatException('Unexpected character at $_pos');
    }
    return value;
  }

  // Handles + and -
  double _parseExpression() {
    double value = _parseTerm();
    while (_pos < text.length) {
      final char = text[_pos];
      if (char == '+') {
        _pos++;
        value += _parseTerm();
      } else if (char == '-') {
        _pos++;
        value -= _parseTerm();
      } else {
        break;
      }
    }
    return value;
  }

  // Handles * and /
  double _parseTerm() {
    double value = _parseFactor();
    while (_pos < text.length) {
      final char = text[_pos];
      if (char == '*') {
        _pos++;
        value *= _parseFactor();
      } else if (char == '/') {
        _pos++;
        final divisor = _parseFactor();
        if (divisor == 0) throw const IntegerDivisionByZeroException();
        value /= divisor;
      } else {
        break;
      }
    }
    return value;
  }

  // Handles numbers, unary signs (+, -), and parentheses ( )
  double _parseFactor() {
    if (_pos < text.length && text[_pos] == '+') {
      _pos++;
      return _parseFactor();
    }
    if (_pos < text.length && text[_pos] == '-') {
      _pos++;
      return -_parseFactor();
    }
    if (_pos < text.length && text[_pos] == '(') {
      _pos++;
      final value = _parseExpression();
      if (_pos < text.length && text[_pos] == ')') {
        _pos++;
        return value;
      }
      throw const FormatException('Missing closing parenthesis');
    }

    final start = _pos;
    while (_pos < text.length &&
        ((text.codeUnitAt(_pos) >= 48 && text.codeUnitAt(_pos) <= 57) ||
            text[_pos] == '.')) {
      _pos++;
    }
    if (start == _pos) {
      throw FormatException('Expected number at position $_pos');
    }

    final numStr = text.substring(start, _pos);
    return double.parse(numStr);
  }
}