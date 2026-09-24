// lib/utils/extensions.dart
import 'package:intl/intl.dart';
import 'math_expression_evaluator.dart';

final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Top-level parser that safely handles `dynamic` JSON types
double parseDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  final clean = value.toString().replaceAll(',', '').trim();
  return double.tryParse(clean) ?? fallback;
}

int parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  final clean = value.toString().replaceAll(',', '').trim();
  return int.tryParse(clean) ?? fallback;
}

extension NumericParseExt on Object? {
  double toCleanDouble([double fallback = 0.0]) => parseDouble(this, fallback);
  int toCleanInt([int fallback = 0]) => parseInt(this, fallback);
  
  double evalMath([double fallback = 0.0]) {
    if (this == null) return fallback;
    final str = toString().trim();
    if (str.isEmpty) return fallback;
    return MathExpressionEvaluator.tryEvaluate(str) ?? fallback;
  }
}

extension CurrencyFormatExt on Object? {
  /// Formats numbers into standard 2-decimal string format (e.g. "1500.00")
  String toCurrency() {
    if (this is num) return (this as num).toStringAsFixed(2);
    final parsed = double.tryParse(toString().replaceAll(',', '').trim()) ?? 0.0;
    return parsed.toStringAsFixed(2);
  }

  /// Formats numbers into Indian Rupee currency string (e.g. "₹1,500.00")
  String toINR() {
    if (this == null) return '₹0.00';
    if (this is num) {
      return _inrCurrencyFormat.format(this);
    }
    final parsed = double.tryParse(toString().replaceAll(',', '').trim()) ?? 0.0;
    return _inrCurrencyFormat.format(parsed);
  }

  String toFixedDecimals([int places = 2]) {
    if (this is num) return (this as num).toStringAsFixed(places);
    final parsed = double.tryParse(toString().replaceAll(',', '').trim()) ?? 0.0;
    return parsed.toStringAsFixed(places);
  }
}

extension StringSafeCaseExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase().trim() == other.toLowerCase().trim();
}