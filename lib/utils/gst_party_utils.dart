class GstPartyUtils {
  static String extractPartyName(String rawText) {
    if (rawText.isEmpty) return '';
    final parenIdx = rawText.indexOf('(');
    if (parenIdx != -1) return rawText.substring(0, parenIdx).trim();
    final dashIdx = rawText.indexOf(' - ');
    if (dashIdx != -1) return rawText.substring(0, dashIdx).trim();
    return rawText.trim();
  }

  static String extractPartyGstin(String rawText) {
    if (rawText.isEmpty) return '';
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(rawText);
    if (parenMatch != null) return parenMatch.group(1)?.trim() ?? '';
    final dashMatch = RegExp(r' - ([A-Z0-9]{15})').firstMatch(rawText);
    if (dashMatch != null) return dashMatch.group(1)?.trim() ?? '';
    return '';
  }

  /// Formats party name and GSTIN into a unified display string
  static String formatPartyDisplay(String name, String gstin) {
    final cleanName = extractPartyName(name).trim();
    final cleanGstin = gstin.trim().isNotEmpty ? gstin.trim() : extractPartyGstin(name).trim();
    final targetName = cleanName.isNotEmpty ? cleanName : name.trim();
    return cleanGstin.isNotEmpty ? '$targetName ($cleanGstin)' : targetName;
  }

  /// Extracts the 2-digit state code from GSTIN or falls back to a provided code/matched party[cite: 1]
  static String extractStateCode(String partyText, {String fallbackStateCode = ''}) {
    final gstin = extractPartyGstin(partyText.trim());
    if (gstin.length >= 2 && int.tryParse(gstin.substring(0, 2)) != null) {
      return gstin.substring(0, 2);
    }
    return fallbackStateCode;
  }

  static double extractCessAmount(Map<String, dynamic> voucher) {
    final sundries = voucher['sundries'] as List? ?? const [];
    for (final s in sundries) {
      if (s is Map && (s['name'] ?? '').toString().toLowerCase().contains('cess')) {
        return double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
      }
    }
    return 0.0;
  }

  static String getPlaceOfSupply(String gstin, bool isInterState, {String? companyGstin}) {
    if (gstin.length >= 2) return gstin.substring(0, 2);
    if (companyGstin != null && companyGstin.length >= 2) return companyGstin.substring(0, 2);
    return isInterState ? 'Other' : 'Local';
  }
}