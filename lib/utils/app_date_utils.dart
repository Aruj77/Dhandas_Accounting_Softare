class FinancialYearBounds {
  final DateTime startDate;
  final DateTime endDate;

  const FinancialYearBounds({
    required this.startDate,
    required this.endDate,
  });
}

class AppDateUtils {
  static const String defaultFinancialYear = '2026-27';
  static const List<String> defaultFinancialYears = [
    '2024-25',
    '2025-26',
    '2026-27',
  ];

  static String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  static DateTime? parseDate(String? raw) {
    if (raw == null) return null;
    final sanitized = raw.trim().replaceAll('/', '-').replaceAll('.', '-');
    final parts = sanitized.split('-').where((p) => p.isNotEmpty).toList();

    int? day;
    int? month;
    int? year;

    if (parts.length == 1 && parts[0].length == 4) {
      day = int.tryParse(parts[0].substring(0, 2));
      month = int.tryParse(parts[0].substring(2, 4));
    } else if (parts.length >= 2) {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      if (parts.length == 3) {
        var y = int.tryParse(parts[2]);
        if (y != null && y < 100) y += 2000;
        year = y;
      }
    }

    if (day == null || month == null || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    year ??= DateTime.now().year;

    try {
      final dt = DateTime(year, month, day);
      if (dt.day == day && dt.month == month) return dt;
    } catch (_) {}
    return null;
  }

  static FinancialYearBounds parseFinancialYearBounds(String fyStr) {
    try {
      final parts = fyStr.trim().split(RegExp(r'[-/]'));
      var startY = int.parse(parts[0].trim());
      if (startY < 100) startY += 2000;

      var endY = startY + 1;
      if (parts.length > 1) {
        final parsedEnd = int.tryParse(parts[1].trim());
        if (parsedEnd != null) {
          endY = parsedEnd < 100 ? 2000 + parsedEnd : parsedEnd;
        }
      }

      return FinancialYearBounds(
        startDate: DateTime(startY, 4, 1),
        endDate: DateTime(endY, 3, 31, 23, 59, 59),
      );
    } catch (_) {
      return FinancialYearBounds(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2027, 3, 31, 23, 59, 59),
      );
    }
  }
}