import 'package:intl/intl.dart';

final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

extension NumericParseExt on String? {
  double toCleanDouble([double fallback = 0.0]) {
    if (this == null) return fallback;
    final clean = this!.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? fallback;
  }

  int toCleanInt([int fallback = 0]) {
    if (this == null) return fallback;
    final clean = this!.replaceAll(',', '').trim();
    return int.tryParse(clean) ?? fallback;
  }
}

extension CurrencyFormatExt on num {
  String toINR() => _inrCurrencyFormat.format(this);
  
  String toFixedDecimals([int places = 2]) => toStringAsFixed(places);
}

extension StringSafeCaseExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase().trim() == other.toLowerCase().trim();
}