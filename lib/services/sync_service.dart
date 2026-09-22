import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

class SyncService {
  static const String backendUrl = 'http://localhost:8000/sync/';

  static Future<void> syncCompanyData(String companyId, String folderPath) async {
    final db = AppDatabase.forCompany(folderPath);
    try {
      final unsynced = await db.getUnsyncedVouchers();
      if (unsynced.isEmpty) return;

      final vouchersPayload = unsynced.map((row) => jsonDecode(row.payloadJson)).toList();

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'company_id': companyId,
          'vouchers': vouchersPayload,
        }),
      );

      if (response.statusCode == 200) {
        final ids = unsynced.map((r) => r.id).toList();
        await db.markAsSynced(ids);
      }
    } catch (e) {
      // Handle offline conditions silently; retry on next lifecycle trigger
    } finally {
      await db.close();
    }
  }
}