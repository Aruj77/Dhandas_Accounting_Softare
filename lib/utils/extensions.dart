// desktop/lib/utils/extensions.dart
import 'package:intl/intl.dart';

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
}

extension CurrencyFormatExt on Object? {
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