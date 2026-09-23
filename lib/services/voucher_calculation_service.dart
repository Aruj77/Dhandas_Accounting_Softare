import '../widgets/voucher/voucher_item_row.dart';
import '../widgets/voucher/voucher_sundry_row.dart';

class VoucherTotalsResult {
  final double totalQty;
  final double subTotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTax;
  final double sundryTotal;
  final double roundOff;
  final double grandTotal;
  final double totalItemAmount;

  const VoucherTotalsResult({
    this.totalQty = 0.0,
    this.subTotal = 0.0,
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.totalTax = 0.0,
    this.sundryTotal = 0.0,
    this.roundOff = 0.0,
    this.grandTotal = 0.0,
    this.totalItemAmount = 0.0,
  });

  static const zero = VoucherTotalsResult();
}

class VoucherCalculationService {
  static void recalculateTaxableAndTaxes(VoucherItemRow row, bool isInterState) {
    final q = double.tryParse(row.qty.text) ?? 0.0;
    final p = double.tryParse(row.price.text) ?? 0.0;
    final taxVal = q * p;
    row.taxable.text = taxVal > 0 ? taxVal.toStringAsFixed(2) : '';
    recalculateTaxesFromTaxable(row, isInterState);
  }

  static void recalculateTaxesFromTaxable(VoucherItemRow row, bool isInterState) {
    final taxVal = double.tryParse(row.taxable.text) ?? 0.0;
    final rate = row.gstRate;
    double taxTotal = 0.0;

    if (isInterState) {
      final igstVal = (taxVal * rate) / 100.0;
      row.igst.text = igstVal == 0 ? '' : igstVal.toStringAsFixed(2);
      row.cgst.text = '';
      row.sgst.text = '';
      taxTotal = igstVal;
    } else {
      final halfRate = rate / 2.0;
      final cVal = (taxVal * halfRate) / 100.0;
      row.cgst.text = cVal == 0 ? '' : cVal.toStringAsFixed(2);
      row.sgst.text = cVal == 0 ? '' : cVal.toStringAsFixed(2);
      row.igst.text = '';
      taxTotal = cVal * 2.0;
    }

    final gross = taxVal + taxTotal;
    row.amount.text = gross == 0 ? '' : gross.toStringAsFixed(2);
  }

  static void recalculateFromInvoiceAmount(VoucherItemRow row, bool isInterState) {
    final invoiceAmt = double.tryParse(row.amount.text) ?? 0.0;
    if (invoiceAmt <= 0) return;

    final rate = row.gstRate;
    final taxableVal = invoiceAmt / (1.0 + (rate / 100.0));
    final totalTaxVal = invoiceAmt - taxableVal;

    row.taxable.text = taxableVal.toStringAsFixed(2);

    if (isInterState) {
      row.igst.text = totalTaxVal.toStringAsFixed(2);
      row.cgst.text = '';
      row.sgst.text = '';
    } else {
      final halfTax = totalTaxVal / 2.0;
      row.cgst.text = halfTax.toStringAsFixed(2);
      row.sgst.text = halfTax.toStringAsFixed(2);
      row.igst.text = '';
    }

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0) {
      row.price.text = (taxableVal / q).toStringAsFixed(2);
    }
  }

  /// Calculates sundry amount from percentage against the taxable subtotal
  static void recalculateSundryFromPercent(VoucherSundryRow sundry, double baseTaxable) {
    final pct = double.tryParse(sundry.percent.text) ?? 0.0;
    if (pct > 0 && baseTaxable > 0) {
      final calculated = (baseTaxable * pct) / 100.0;
      sundry.amount.text = calculated.toStringAsFixed(2);
    }
  }

  /// Calculates sundry percentage from amount against the taxable subtotal
  static void recalculateSundryFromAmount(VoucherSundryRow sundry, double baseTaxable) {
    final amt = double.tryParse(sundry.amount.text) ?? 0.0;
    if (amt > 0 && baseTaxable > 0) {
      final calculatedPct = (amt / baseTaxable) * 100.0;
      sundry.percent.text = calculatedPct.toStringAsFixed(2);
    }
  }

  static VoucherTotalsResult calculateTotals({
    required List<VoucherItemRow> items,
    required List<VoucherSundryRow> sundries,
    required bool isInterState,
    required bool autoRoundOff,
  }) {
    double totalTaxable = 0.0;
    double accumQty = 0.0;
    double cgstAccum = 0.0;
    double sgstAccum = 0.0;
    double igstAccum = 0.0;
    double accumAmount = 0.0;

    for (final row in items) {
      final q = double.tryParse(row.qty.text) ?? 0.0;
      final t = double.tryParse(row.taxable.text) ?? 0.0;
      final c = double.tryParse(row.cgst.text) ?? 0.0;
      final s = double.tryParse(row.sgst.text) ?? 0.0;
      final i = double.tryParse(row.igst.text) ?? 0.0;
      final amt = double.tryParse(row.amount.text) ?? 0.0;

      accumQty += q;
      totalTaxable += t;
      accumAmount += amt;

      if (isInterState) {
        igstAccum += i;
      } else {
        cgstAccum += c;
        sgstAccum += s;
      }
    }

    double sundrySum = 0.0;
    for (final s in sundries) {
      final amt = double.tryParse(s.amount.text) ?? 0.0;
      if (s.name.text == 'Round off+' || s.name.text == 'Round Off+') {
        sundrySum += amt;
      } else if (s.name.text == 'Round Off-' || s.name.text == 'Rnd off -' || s.isNegative) {
        sundrySum -= amt.abs();
      } else {
        sundrySum += amt.abs();
      }
    }

    final totalTaxCalculated = isInterState ? igstAccum : (cgstAccum + sgstAccum);
    final preFinal = totalTaxable + totalTaxCalculated + sundrySum;
    double rOff = 0.0;
    double gTotal = preFinal;

    if (autoRoundOff) {
      gTotal = preFinal.roundToDouble();
      rOff = gTotal - preFinal;
    }

    return VoucherTotalsResult(
      totalQty: accumQty,
      subTotal: totalTaxable,
      totalCgst: cgstAccum,
      totalSgst: sgstAccum,
      totalIgst: igstAccum,
      totalTax: totalTaxCalculated,
      sundryTotal: sundrySum,
      roundOff: rOff,
      grandTotal: gTotal,
      totalItemAmount: accumAmount,
    );
  }
}