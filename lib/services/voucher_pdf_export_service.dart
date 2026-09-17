import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'voucher_excel_export_service.dart';

class VoucherPdfExportService {
  static Future<Uint8List> generateRegisterPdf({
    required PdfPageFormat format,
    required Map<String, dynamic> company,
    required String voucherType,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Map<String, dynamic>> filteredVouchers,
    required List<String> activeKeys,
    required Map<String, String> columnLabels,
    required String Function(String) extractPartyName,
    required String Function(String) extractPartyGstin,
    required String Function(String, bool) getPlaceOfSupply,
    required double Function(Map<String, dynamic>) extractCessAmount,
    required String Function(DateTime) formatDate,
    required double totalQuantity,
    required double totalInvoiceValue,
    required double totalTaxable,
    required double totalIgst,
    required double totalCgst,
    required double totalSgst,
    required double totalCess,
    double pageMargin = 20.0,
    double columnScale = 1.0,
    double tableFontSize = 8.0,
    double borderWidth = 0.5,
    bool showAddress = true,
    bool showDateRange = true,
    bool showSubtitle = true,
    bool alternateRowColors = false,
  }) async {
    // 1. Load full Unicode-compliant fonts from printing package
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();
    final fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();

    // 2. Attach Unicode font theme to pw.Document
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
        boldItalic: fontBoldItalic,
      ),
    );

    final companyName = (company['name'] ?? company['companyName'] ?? 'Business Firm').toString().trim();
    final companyAddress = (company['address'] ?? '').toString().trim();
    final dateRangeStr = 'F.Y. ${company['activeFinancialYear'] ?? '2026-27'} (${formatDate(fromDate)} to ${formatDate(toDate)})';
    final registerSubtitle = VoucherExcelExportService.resolveRegisterTitle(voucherType);

    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < activeKeys.length; i++) {
      double baseFlex = 1.0;
      switch (activeKeys[i]) {
        case 'sno':
          baseFlex = 0.5;
          break;
        case 'party':
          baseFlex = 2.4 * columnScale;
          break;
        case 'gstin':
          baseFlex = 1.6;
          break;
        case 'pos':
          baseFlex = 1.4;
          break;
        case 'vchNo':
          baseFlex = 1.1;
          break;
        case 'date':
          baseFlex = 1.1;
          break;
        case 'qty':
          baseFlex = 0.8;
          break;
        case 'unit':
          baseFlex = 0.6;
          break;
        case 'hsn':
          baseFlex = 1.0;
          break;
        case 'invoiceVal':
          baseFlex = 1.4;
          break;
        case 'taxable':
          baseFlex = 1.2;
          break;
        case 'taxRate':
          baseFlex = 0.7;
          break;
        case 'igst':
          baseFlex = 1.0;
          break;
        case 'cgst':
          baseFlex = 1.0;
          break;
        case 'sgst':
          baseFlex = 1.0;
          break;
        case 'cess':
          baseFlex = 0.9;
          break;
        default:
          baseFlex = 1.0;
      }
      columnWidths[i] = pw.FlexColumnWidth(baseFlex);
    }

    final List<pw.TableRow> tableRows = [];

    // Header row
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        children: activeKeys.map((k) {
          final isNumeric = ['qty', 'invoiceVal', 'taxable', 'taxRate', 'igst', 'cgst', 'sgst', 'cess'].contains(k);
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: isNumeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Text(
              columnLabels[k]!,
              style: pw.TextStyle(fontSize: tableFontSize + 0.5, fontWeight: pw.FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );

    // Data rows
    int sno = 0;
    int renderedRowCount = 0;
    for (final v in filteredVouchers) {
      final vchNo = (v['voucherNumber'] ?? '').toString();
      final date = (v['date'] ?? '').toString();
      final fullParty = (v['party'] ?? '').toString();
      final partyName = extractPartyName(fullParty);
      final gstin = extractPartyGstin(fullParty);
      final isInterState = v['isInterState'] == true;
      final pos = getPlaceOfSupply(gstin, isInterState);
      final invoiceTotal = (double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
      final cessTotal = extractCessAmount(v);
      final items = v['items'] as List? ?? [];

      if (items.isEmpty) {
        sno++;
        renderedRowCount++;
        final isEven = renderedRowCount % 2 == 0;
        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: (alternateRowColors && isEven) ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
            ),
            children: activeKeys.map((k) {
              String val = '';
              bool right = false;
              switch (k) {
                case 'sno':
                  val = '$sno';
                  break;
                case 'party':
                  val = partyName;
                  break;
                case 'gstin':
                  val = gstin;
                  break;
                case 'pos':
                  val = pos;
                  break;
                case 'vchNo':
                  val = vchNo;
                  break;
                case 'date':
                  val = date;
                  break;
                case 'qty':
                  val = '0.00';
                  right = true;
                  break;
                case 'unit':
                  val = 'Pcs';
                  break;
                case 'hsn':
                  val = '';
                  break;
                case 'invoiceVal':
                  val = invoiceTotal;
                  right = true;
                  break;
                case 'taxable':
                  val = '0.00';
                  right = true;
                  break;
                case 'taxRate':
                  val = '0%';
                  right = true;
                  break;
                case 'igst':
                  val = (double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                  right = true;
                  break;
                case 'cgst':
                  val = (double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                  right = true;
                  break;
                case 'sgst':
                  val = (double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                  right = true;
                  break;
                case 'cess':
                  val = cessTotal.toStringAsFixed(2);
                  right = true;
                  break;
              }
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                child: pw.Text(val, style: pw.TextStyle(fontSize: tableFontSize)),
              );
            }).toList(),
          ),
        );
      } else {
        for (int i = 0; i < items.length; i++) {
          if (i == 0) sno++;
          renderedRowCount++;
          final isEven = renderedRowCount % 2 == 0;
          final item = items[i];
          final qty = (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
          final unit = (item['unit'] ?? 'Pcs').toString();
          final hsn = (item['hsn'] ?? '').toString();
          final taxable = (double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
          final taxRate = '${item['gstRate'] ?? 0}%';
          final igstVal = (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
          final cgstVal = (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
          final sgstVal = (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);

          tableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: (alternateRowColors && isEven) ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
              ),
              children: activeKeys.map((k) {
                String val = '';
                bool right = false;
                switch (k) {
                  case 'sno':
                    val = i == 0 ? '$sno' : '';
                    break;
                  case 'party':
                    val = i == 0 ? partyName : '';
                    break;
                  case 'gstin':
                    val = i == 0 ? gstin : '';
                    break;
                  case 'pos':
                    val = i == 0 ? pos : '';
                    break;
                  case 'vchNo':
                    val = i == 0 ? vchNo : '';
                    break;
                  case 'date':
                    val = i == 0 ? date : '';
                    break;
                  case 'qty':
                    val = qty;
                    right = true;
                    break;
                  case 'unit':
                    val = unit;
                    break;
                  case 'hsn':
                    val = hsn;
                    break;
                  case 'invoiceVal':
                    val = i == 0 ? invoiceTotal : '';
                    right = true;
                    break;
                  case 'taxable':
                    val = taxable;
                    right = true;
                    break;
                  case 'taxRate':
                    val = taxRate;
                    right = true;
                    break;
                  case 'igst':
                    val = igstVal;
                    right = true;
                    break;
                  case 'cgst':
                    val = cgstVal;
                    right = true;
                    break;
                  case 'sgst':
                    val = sgstVal;
                    right = true;
                    break;
                  case 'cess':
                    val = i == 0 ? cessTotal.toStringAsFixed(2) : '';
                    right = true;
                    break;
                }
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  child: pw.Text(val, style: pw.TextStyle(fontSize: tableFontSize)),
                );
              }).toList(),
            ),
          );
        }
      }
    }

    // Cumulative footer total row
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        children: activeKeys.map((k) {
          String val = '';
          bool right = false;
          switch (k) {
            case 'sno':
              val = '';
              break;
            case 'party':
              val = 'TOTAL';
              break;
            case 'qty':
              val = totalQuantity.toStringAsFixed(2);
              right = true;
              break;
            case 'invoiceVal':
              val = totalInvoiceValue.toStringAsFixed(2);
              right = true;
              break;
            case 'taxable':
              val = totalTaxable.toStringAsFixed(2);
              right = true;
              break;
            case 'igst':
              val = totalIgst.toStringAsFixed(2);
              right = true;
              break;
            case 'cgst':
              val = totalCgst.toStringAsFixed(2);
              right = true;
              break;
            case 'sgst':
              val = totalSgst.toStringAsFixed(2);
              right = true;
              break;
            case 'cess':
              val = totalCess.toStringAsFixed(2);
              right = true;
              break;
          }
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Text(
              val,
              style: pw.TextStyle(fontSize: tableFontSize + 0.5, fontWeight: pw.FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );

    // MultiPage Document with perfectly centered titles
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.all(pageMargin),
        header: (context) => pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Center(
                child: pw.Text(
                  companyName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              if (showAddress && companyAddress.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    companyAddress,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
              if (showDateRange) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    dateRangeStr,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
              if (showSubtitle) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    registerSubtitle,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: borderWidth),
            columnWidths: columnWidths,
            children: tableRows,
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ),
      ),
    );

    return pdf.save();
  }
}