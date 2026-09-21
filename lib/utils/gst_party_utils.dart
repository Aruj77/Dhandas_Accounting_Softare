import '../constants/gst_constants.dart';

class GstPartyUtils {
  static String extractPartyName(String fullParty) {
    final bracketIndex = fullParty.indexOf('[');
    if (bracketIndex != -1) {
      return fullParty.substring(0, bracketIndex).trim();
    }
    return fullParty.trim();
  }

  static String extractPartyGstin(String fullParty) {
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(fullParty);
    if (match != null) {
      return match.group(1)!.trim();
    }
    if (fullParty.trim().length == 15) {
      return fullParty.trim();
    }
    return '';
  }

  static String getPlaceOfSupply(
    String gstin,
    bool isInterState, {
    String companyGstin = '',
  }) {
    if (gstin.length >= 2) {
      final code = gstin.substring(0, 2);
      final state = GstConstants.stateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    final compGst = companyGstin.trim();
    if (!isInterState && compGst.length >= 2) {
      final code = compGst.substring(0, 2);
      final state = GstConstants.stateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    return isInterState ? 'Inter-State' : 'Local';
  }

  static double extractCessAmount(Map<String, dynamic> voucher) {
    final sundries = voucher['sundries'] as List? ?? [];
    double cessTotal = 0.0;
    for (final s in sundries) {
      if (s is Map<String, dynamic>) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        if (name.contains('cess')) {
          final amt = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
          cessTotal += amt;
        }
      }
    }
    return cessTotal;
  }
}