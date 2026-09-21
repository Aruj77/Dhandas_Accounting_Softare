import '../constants/gst_constants.dart';

class GstinService {
  static const Map<String, String> stateCodes = GstConstants.stateCodes;

  static bool isValid(String? gstin) {
    if (gstin == null) return false;
    final sanitized = gstin.trim().toUpperCase();
    if (!GstConstants.gstinRegex.hasMatch(sanitized)) return false;

    final stateCode = sanitized.substring(0, 2);
    return stateCodes.containsKey(stateCode);
  }

  static String getStateName(String? gstin) {
    if (gstin == null) return 'Unknown';
    final sanitized = gstin.trim().toUpperCase();
    if (sanitized.length < 2) return 'Unknown';

    final stateCode = sanitized.substring(0, 2);
    return GstConstants.getStateName(stateCode);
  }

  static String? extractPan(String? gstin) {
    if (gstin == null) return null;
    final sanitized = gstin.trim().toUpperCase();
    if (sanitized.length >= 12) {
      final pan = sanitized.substring(2, 12);
      if (GstConstants.panRegex.hasMatch(pan)) {
        return pan;
      }
    }
    return null;
  }
}
