import '../utils/gst_party_utils.dart';
import '../utils/number_parsing_utils.dart';

class RegisterSummary {
  final int totalInvoices;
  final double totalQuantity;
  final double totalInvoiceValue;
  final double totalTaxable;
  final double totalIgst;
  final double totalCgst;
  final double totalSgst;
  final double totalCess;

  const RegisterSummary({
    required this.totalInvoices,
    required this.totalQuantity,
    required this.totalInvoiceValue,
    required this.totalTaxable,
    required this.totalIgst,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalCess,
  });

  factory RegisterSummary.fromVouchers(List<Map<String, dynamic>> vouchers) {
    double qty = 0.0;
    double invVal = 0.0;
    double taxable = 0.0;
    double igst = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double cess = 0.0;

    for (final v in vouchers) {
      invVal += NumberParsing.toDouble(v['grandTotal']);
      taxable += NumberParsing.toDouble(v['subTotal']);
      igst += NumberParsing.toDouble(v['igst']);
      cgst += NumberParsing.toDouble(v['cgst']);
      sgst += NumberParsing.toDouble(v['sgst']);
      cess += GstPartyUtils.extractCessAmount(v);

      final items = v['items'] as List? ?? const [];
      for (final i in items) {
        if (i is Map) {
          qty += NumberParsing.toDouble(i['qty']);
        }
      }
    }

    return RegisterSummary(
      totalInvoices: vouchers.length,
      totalQuantity: qty,
      totalInvoiceValue: invVal,
      totalTaxable: taxable,
      totalIgst: igst,
      totalCgst: cgst,
      totalSgst: sgst,
      totalCess: cess,
    );
  }
}