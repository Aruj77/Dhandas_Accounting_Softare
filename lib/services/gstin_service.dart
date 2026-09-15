class GstinService {
  static final RegExp _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  static const Map<String, String> stateCodes = {
    '01': 'Jammu and Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra and Nagar Haveli and Daman and Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman and Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  /// Validates format and state code
  static bool isValid(String? gstin) {
    if (gstin == null) return false;
    final sanitized = gstin.trim().toUpperCase();
    if (!_gstinRegex.hasMatch(sanitized)) return false;

    final stateCode = sanitized.substring(0, 2);
    return stateCodes.containsKey(stateCode);
  }

  /// Returns state name corresponding to GSTIN code
  static String getStateName(String? gstin) {
    if (gstin == null) return 'Unknown';
    final sanitized = gstin.trim().toUpperCase();
    if (sanitized.length < 2) return 'Unknown';

    final stateCode = sanitized.substring(0, 2);
    return stateCodes[stateCode] ?? 'Unknown';
  }

  /// Extracts PAN number from a 15-digit GSTIN
  static String? extractPan(String? gstin) {
    if (gstin == null) return null;
    final sanitized = gstin.trim().toUpperCase();
    if (sanitized.length >= 12) {
      final pan = sanitized.substring(2, 12);
      if (RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
        return pan;
      }
    }
    return null;
  }
}