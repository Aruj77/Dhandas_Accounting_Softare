import 'math_expression_evaluator.dart';

class NumberParsing {
  const NumberParsing._();

  /// Safely parses any dynamic value into a double, falling back to [fallback].
  static double toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().trim()) ?? fallback;
  }

  /// Evaluates arithmetic expressions first (e.g. "12*5"), falling back to standard double parsing.
  static double evalOrParse(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    final text = val.toString().trim();
    if (text.isEmpty) return fallback;
    return MathExpressionEvaluator.tryEvaluate(text) ??
        double.tryParse(text) ??
        fallback;
  }

  /// Formats a double to standard currency format without scientific notation.
  static String formatCurrency(double val, [int decimals = 2]) {
    return val.toStringAsFixed(decimals);
  }
}

extension NumberParsingDynamicExt on dynamic {
  double toCleanDouble([double fallback = 0.0]) =>
      NumberParsing.toDouble(this, fallback);

  double evalMath([double fallback = 0.0]) =>
      NumberParsing.evalOrParse(this, fallback);
}

extension NumberParsingDoubleExt on double {
  String toCurrency([int decimals = 2]) =>
      NumberParsing.formatCurrency(this, decimals);
}