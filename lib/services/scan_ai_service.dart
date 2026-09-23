// desktop/lib/services/scan_ai_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ScanAiException implements Exception {
  final String message;
  ScanAiException(this.message);
  @override
  String toString() => message;
}

class ScannedItem {
  String name;
  String hsn;
  double qty;
  String unit;
  double rate;
  double taxRatePercent;

  ScannedItem({
    required this.name,
    this.hsn = '',
    this.qty = 1,
    this.unit = 'PCS',
    this.rate = 0,
    this.taxRatePercent = 0,
  });

  factory ScannedItem.fromJson(Map<String, dynamic> j) => ScannedItem(
        name: (j['name'] ?? '').toString().trim(),
        hsn: (j['hsn'] ?? '').toString().trim(),
        qty: double.tryParse('${j['qty'] ?? 1}') ?? 1,
        unit: (j['unit'] ?? 'PCS').toString().trim().toUpperCase(),
        rate: double.tryParse('${j['rate'] ?? 0}') ?? 0,
        taxRatePercent: double.tryParse('${j['taxRatePercent'] ?? 0}') ?? 0,
      );
}

class ScannedSundry {
  final String name;
  final double amount;
  final bool isNegative;

  ScannedSundry({
    required this.name,
    required this.amount,
    this.isNegative = false,
  });

  factory ScannedSundry.fromJson(Map<String, dynamic> j) => ScannedSundry(
        name: (j['name'] ?? '').toString().trim(),
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0.0,
        isNegative: j['isNegative'] == true,
      );
}

class ScannedVoucherData {
  final String voucherType;
  final String partyName;
  final String partyGstin;
  final String invoiceNo;
  final String invoiceDate;
  final List<ScannedItem> items;
  final List<ScannedSundry> sundries;
  final double? totalAmount;
  final double confidence;
  final String rawModelText;

  ScannedVoucherData({
    required this.voucherType,
    required this.partyName,
    required this.partyGstin,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.items,
    this.sundries = const [],
    required this.totalAmount,
    required this.confidence,
    required this.rawModelText,
  });

  factory ScannedVoucherData.fromJson(Map<String, dynamic> j) {
    return ScannedVoucherData(
      voucherType: (j['voucherType'] ?? 'Unknown').toString(),
      partyName: (j['partyName'] ?? '').toString().trim(),
      partyGstin: (j['partyGstin'] ?? '').toString().trim().toUpperCase(),
      invoiceNo: (j['invoiceNo'] ?? '').toString().trim(),
      invoiceDate: (j['invoiceDate'] ?? '').toString().trim(),
      items: ((j['items'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => ScannedItem.fromJson(Map<String, dynamic>.from(e)))
          .where((i) => i.name.isNotEmpty)
          .toList(),
      sundries: ((j['sundries'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => ScannedSundry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalAmount: j['totalAmount'] == null
          ? null
          : double.tryParse('${j['totalAmount']}'),
      confidence:
          (double.tryParse('${j['confidence'] ?? 0.5}') ?? 0.5).clamp(0, 1),
      rawModelText: (j['rawText'] ?? '').toString(),
    );
  }
}

class ScanAiService {
  static const String _baseUrl = String.fromEnvironment(
    'OCR_SERVER_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const int _maxBytes = 15 * 1024 * 1024;

  static Future<ScannedVoucherData> extractFromFile(
    Uint8List bytes, {
    required String fileName,
    String mediaType = 'application/pdf',
  }) async {
    if (bytes.isEmpty) throw ScanAiException('Empty file provided.');
    if (bytes.lengthInBytes > _maxBytes) {
      throw ScanAiException(
          'File too large (${(bytes.lengthInBytes / 1e6).toStringAsFixed(1)} MB).');
    }

    final uri = Uri.parse('$_baseUrl/scan');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 40));
    } catch (e) {
      throw ScanAiException(
          'Could not reach the OCR server at $_baseUrl. Ensure the Python server is running ($e).');
    }

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw ScanAiException('Server error (${streamed.statusCode}): $body');
    }

    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return ScannedVoucherData.fromJson(j);
    } catch (e) {
      throw ScanAiException('Failed to parse scan response: $e');
    }
  }
}