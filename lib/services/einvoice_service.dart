// desktop/lib/services/einvoice_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EInvoiceService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>?> generateInv01({
    required Map<String, dynamic> voucher,
    required Map<String, dynamic> company,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/einvoice/serialize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voucher': voucher,
          'company': company,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('E-Invoice Generation Error: $e');
      return null;
    }
  }
}