import '../utils/app_date_utils.dart';
import 'storage_service.dart';

class VoucherNumberingService {
  static Future<String?> autogenerate({
    required Map<String, dynamic> company,
    required String voucherType,
    required String seriesName,
    required Map<String, dynamic> seriesSettings,
  }) async {
    if (seriesName.toLowerCase() == 'main') return null;

    if (seriesSettings['numberingType']?.toString() == 'Manual') {
      return null;
    }

    final folderPath = company['folderPath'];
    final fy = company['activeFinancialYear']?.toString() ?? AppDateUtils.defaultFinancialYear;
    if (folderPath == null) return null;

    final vouchers = await StorageService.loadVouchers(
      folderPath: folderPath,
      financialYear: fy,
      voucherType: voucherType,
      seriesName: seriesName,
    );

    final yearPosition = seriesSettings['yearPosition']?.toString() ?? 'As Prefix';
    final searchFirst = (yearPosition == 'As Suffix');

    if (vouchers.isNotEmpty) {
      final lastVchNo = vouchers.last['voucherNumber']?.toString() ?? '';
      if (lastVchNo.isNotEmpty) {
        final regex = searchFirst ? RegExp(r'^[^0-9]*(\d+)') : RegExp(r'(\d+)(?!.*\d)');
        final match = regex.firstMatch(lastVchNo);
        if (match != null) {
          final numStr = match.group(1)!;
          final number = int.tryParse(numStr) ?? 0;
          final nextNum = number + 1;
          return lastVchNo.replaceRange(match.start, match.end, nextNum.toString());
        }
      }
    }

    final sep = seriesSettings['separator']?.toString() ?? '';
    final startNum = seriesSettings['startNumber']?.toString() ?? '1';
    final prefix = seriesSettings['prefix']?.toString() ?? '';
    final suffix = seriesSettings['suffix']?.toString() ?? '';
    final renumberingFreq = seriesSettings['renumberingFreq']?.toString() ?? 'None';
    final yearFormat = seriesSettings['yearFormat']?.toString() ?? 'YYYY-YY';
    final monthFormat = seriesSettings['monthFormat']?.toString() ?? 'MMM';
    final dateFormat = seriesSettings['dateFormat']?.toString() ?? 'DD-MM-YYYY';

    List<String> parts = [];
    String dateComponent = '';

    if (renumberingFreq == 'Yearly') {
      dateComponent = (yearFormat == 'YY-YY') ? '26-27' : '2026-27';
    } else if (renumberingFreq == 'Monthly') {
      if (monthFormat == 'MMM') dateComponent = 'Sep';
      if (monthFormat == 'M-full') dateComponent = 'September';
      if (monthFormat == 'M-digit') dateComponent = '09';
    } else if (renumberingFreq == 'Daily') {
      if (dateFormat == 'DD-MM-YYYY') dateComponent = '19-09-2026';
      if (dateFormat == 'DD/MM/YY') dateComponent = '19/09/26';
    }

    if (prefix.isNotEmpty) parts.add(prefix);
    if (renumberingFreq != 'None' && yearPosition == 'As Prefix' && dateComponent.isNotEmpty) {
      parts.add(dateComponent);
    }

    parts.add(startNum);

    if (renumberingFreq != 'None' && yearPosition == 'As Suffix' && dateComponent.isNotEmpty) {
      parts.add(dateComponent);
    }

    if (suffix.isNotEmpty) parts.add(suffix);

    return parts.join(sep);
  }
}