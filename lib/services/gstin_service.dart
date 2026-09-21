import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/gst_constants.dart';

class GstinData {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String status;
  final String state;
  final String address;
  final String city;
  final String pincode;

  const GstinData({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.status,
    required this.state,
    required this.address,
    required this.city,
    required this.pincode,
  });

  factory GstinData.fromJson(Map<String, dynamic> json) {
    return GstinData(
      gstin: json['gstin']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
      tradeName: json['trade_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }
}

class GstinService {
  static const String _backendBaseUrl = 'http://localhost:8000';
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

  static Future<GstinData> validateAndFetch(String rawGstin) async {
    final gstin = rawGstin.trim().toUpperCase();

    if (gstin.isEmpty) {
      throw const FormatException('Enter a GSTIN to validate');
    }
    if (!isValid(gstin)) {
      throw const FormatException('Invalid GSTIN format or state code');
    }

    final uri = Uri.parse('$_backendBaseUrl/api/v1/gstin/$gstin');
    final response = await http.get(uri);
    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['valid'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Failed to validate GSTIN',
      );
    }

    return GstinData.fromJson(body['data'] as Map<String, dynamic>);
  }
}
