import '../utils/gst_party_utils.dart';

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
      invVal += double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;
      taxable += double.tryParse(v['subTotal']?.toString() ?? '0') ?? 0.0;
      igst += double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0;
      cgst += double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0;
      sgst += double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0;
      cess += GstPartyUtils.extractCessAmount(v);

      final items = v['items'] as List? ?? [];
      for (final i in items) {
        qty += double.tryParse(i['qty']?.toString() ?? '0') ?? 0.0;
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