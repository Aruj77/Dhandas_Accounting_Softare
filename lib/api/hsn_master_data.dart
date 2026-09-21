// lib/api/hsn_master_data.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HsnService {
  static Map<String, String>? _cachedRecords;

  /// Loads HSN records from the local JSON asset file into memory.
  static Future<Map<String, String>> loadRecords() async {
    if (_cachedRecords != null && _cachedRecords!.isNotEmpty) {
      return _cachedRecords!;
    }

    try {
      final jsonString = await rootBundle.loadString('lib/api/helpers/hsn.json');
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is Map) {
        _cachedRecords = decoded.map(
          (key, value) => MapEntry(key.toString().trim(), value.toString().trim()),
        );
      } else if (decoded is List) {
        // Fallback in case JSON is an array of objects: [{"hsn": "...", "description": "..."}]
        final map = <String, String>{};
        for (final item in decoded) {
          if (item is Map) {
            final code = (item['hsn'] ?? item['code'] ?? item['hsn_code'])?.toString().trim();
            final desc = (item['description'] ?? item['desc'])?.toString().trim();
            if (code != null && desc != null) {
              map[code] = desc;
            }
          }
        }
        _cachedRecords = map;
      }
      return _cachedRecords ?? {};
    } catch (e) {
      debugPrint('Error loading lib/api/helpers/hsn.json: $e');
      return {};
    }
  }

  /// Searches for an exact code match, falling back to prefix matching (8 -> 6 -> 4 -> 2 digits).
  /// Returns the description if present in the file, otherwise returns null.
  static Future<String?> findDescription(String hsnCode) async {
    final clean = hsnCode.trim();
    if (clean.isEmpty) return null;

    final records = await loadRecords();
    if (records.isEmpty) return null;

    // 1. Direct match
    if (records.containsKey(clean) && records[clean]!.isNotEmpty) {
      return records[clean];
    }

    // 2. Prefix fallback for subheadings (e.g. 33049900 -> 330499 -> 3304 -> 33)
    for (int length = clean.length - 1; length >= 2; length--) {
      final prefix = clean.substring(0, length);
      if (records.containsKey(prefix) && records[prefix]!.isNotEmpty) {
        return records[prefix];
      }
    }

    return null;
  }
}