import 'dart:convert';

import 'package:http/http.dart' as http;

class HsnData {
  final String code;
  final String description;
  final String chapter;
  final String source; // always "offline" (bundled official master data)

  HsnData({
    required this.code,
    required this.description,
    required this.chapter,
    required this.source,
  });

  // Parses our own backend's normalized `data` object (see backend/app/schemas/hsn.py).
  factory HsnData.fromJson(Map<String, dynamic> json) {
    return HsnData(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      chapter: json['chapter']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

/// Talks to our own FastAPI backend (backend/), which looks up the HSN/SAC
/// code in a bundled offline master list (backend/app/data/hsn_codes.json).
/// Fast, no external network dependency for the backend itself.
class HsnService {
  static const String _backendBaseUrl = 'http://localhost:8000';

  static final RegExp _hsnRegex = RegExp(r'^[0-9]{2}([0-9]{2}([0-9]{2}([0-9]{2})?)?)?$');

  /// Format-only check (no network call) — used for instant UI feedback
  /// while the user is still typing.
  static bool isValidFormat(String? code) {
    if (code == null) return false;
    return _hsnRegex.hasMatch(code.trim());
  }

  /// Throws [FormatException] for a malformed code (no network call made),
  /// or [Exception] with a user-facing message if no provider recognizes it.
  static Future<HsnData> validateAndFetch(String rawCode) async {
    final code = rawCode.trim();

    if (code.isEmpty) {
      throw const FormatException('Enter an HSN/SAC code to validate');
    }
    if (!isValidFormat(code)) {
      throw const FormatException('HSN/SAC must be numeric: 2, 4, 6 or 8 digits');
    }

    final uri = Uri.parse('$_backendBaseUrl/api/v1/hsn/$code');
    final response = await http.get(uri);
    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['valid'] != true) {
      throw Exception(body['message']?.toString() ?? 'Failed to validate HSN/SAC code');
    }

    return HsnData.fromJson(body['data'] as Map<String, dynamic>);
  }
}
