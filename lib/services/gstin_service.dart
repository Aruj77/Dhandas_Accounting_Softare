import 'dart:convert';

import 'package:http/http.dart' as http;

class GstinData {
  final String gstin;
  final String tradeName;
  final String legalName;
  final String address;
  final String city;
  final String pincode;
  final String status;

  GstinData({
    required this.gstin,
    required this.tradeName,
    required this.legalName,
    required this.address,
    required this.city,
    required this.pincode,
    required this.status,
  });

  // Parses our own backend's normalized `data` object (see backend/app/schemas/gstin.py).
  // The backend hides which 3rd-party/official provider is behind it.
  factory GstinData.fromJson(Map<String, dynamic> json) {
    return GstinData(
      gstin: json['gstin']?.toString() ?? '',
      tradeName: json['trade_name']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Talks to our own FastAPI backend (backend/), which in turn talks to the
/// 3rd-party/official GST provider. The app never calls the provider directly
/// or holds its API key.
class GstinService {
  static const String _backendBaseUrl = 'http://localhost:8000';

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

  /// Validates format and state code.
  static bool isValid(String? gstin) {
    if (gstin == null) return false;
    final sanitized = gstin.trim().toUpperCase();
    if (!_gstinRegex.hasMatch(sanitized)) return false;

    final stateCode = sanitized.substring(0, 2);
    return stateCodes.containsKey(stateCode);
  }

  /// Returns state name corresponding to GSTIN code.
  static String getStateName(String? gstin) {
    if (gstin == null) return 'Unknown';
    final sanitized = gstin.trim().toUpperCase();
    if (sanitized.length < 2) return 'Unknown';

    final stateCode = sanitized.substring(0, 2);
    return stateCodes[stateCode] ?? 'Unknown';
  }

  /// Extracts PAN number from a 15-digit GSTIN.
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

  /// Throws [FormatException] for a malformed GSTIN (no network call made),
  /// or [Exception] with a user-facing message for any backend/API failure.
  static Future<GstinData> validateAndFetch(String rawGstin) async {
    final gstin = rawGstin.trim().toUpperCase();

    if (gstin.isEmpty) {
      throw const FormatException('Enter a GSTIN to validate');
    }
    if (!isValid(gstin)) {
      throw const FormatException(
        'Invalid GSTIN format (e.g. 09AAECB1234F1Z5)',
      );
    }

    final uri = Uri.parse('$_backendBaseUrl/api/v1/gstin/$gstin');
    final response = await http.get(uri);
    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['valid'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Failed to fetch GSTIN details',
      );
    }

    return GstinData.fromJson(body['data'] as Map<String, dynamic>);
  }
}
