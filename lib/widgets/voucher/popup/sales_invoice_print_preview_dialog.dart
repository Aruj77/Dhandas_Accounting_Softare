import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../constants/app_colors.dart';
import '../../../services/storage_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/notification_service.dart';

class SalesInvoicePrintPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> company;
  final Map<String, dynamic> voucherData;

  const SalesInvoicePrintPreviewDialog({
    super.key,
    required this.company,
    required this.voucherData,
  });

  @override
  State<SalesInvoicePrintPreviewDialog> createState() =>
      _SalesInvoicePrintPreviewDialogState();
}

class _SalesInvoicePrintPreviewDialogState
    extends State<SalesInvoicePrintPreviewDialog> {
  bool _copyOriginal = true;
  bool _copyDuplicate = false;
  bool _copyTriplicate = false;
  bool _copyExtra = false;

  String _invoiceTheme = 'Modern';
  bool _isLandscape = false;
  bool _isLegalPaper = false;
  double _pageMargin = 18.0;
  double _fontScale = 9.0;
  bool _showHsnSummary = true;
  bool _showBankDetails = true;
  bool _showTransportDetails = true;
  bool _showTerms = true;
  bool _zebraStripes = true;
  bool _reverseCharge = false;

  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ifscCtrl;
  bool _isSavingBankDetails = false;

  late TextEditingController _grNoCtrl;
  late TextEditingController _transportCtrl;
  late TextEditingController _vehicleNoCtrl;
  late TextEditingController _stationCtrl;
  late TextEditingController _shippedToCtrl;

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController(
      text: (widget.company['bankName'] ?? '').toString().trim(),
    );
    _accountNoCtrl = TextEditingController(
      text: (widget.company['accountNo'] ?? widget.company['bankAccountNo'] ?? '')
          .toString()
          .trim(),
    );
    _ifscCtrl = TextEditingController(
      text: (widget.company['ifsc'] ?? widget.company['bankIfsc'] ?? '')
          .toString()
          .trim(),
    );

    _grNoCtrl = TextEditingController(
      text: (widget.voucherData['grNo'] ?? '').toString().trim(),
    );
    _transportCtrl = TextEditingController(
      text: (widget.voucherData['transport'] ?? '').toString().trim(),
    );
    _vehicleNoCtrl = TextEditingController(
      text: (widget.voucherData['vehicleNo'] ?? '').toString().trim(),
    );
    _stationCtrl = TextEditingController(
      text: (widget.voucherData['station'] ?? '').toString().trim(),
    );
    _shippedToCtrl = TextEditingController(
      text: (widget.voucherData['shippedTo'] ?? '').toString().trim(),
    );
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
    _grNoCtrl.dispose();
    _transportCtrl.dispose();
    _vehicleNoCtrl.dispose();
    _stationCtrl.dispose();
    _shippedToCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBankDetailsToCompany() async {
    await LoadingService.wrap(() async {
      setState(() => _isSavingBankDetails = true);
      try {
        final updatedCompany = Map<String, dynamic>.from(widget.company);
        updatedCompany['bankName'] = _bankNameCtrl.text.trim();
        updatedCompany['accountNo'] = _accountNoCtrl.text.trim();
        updatedCompany['ifsc'] = _ifscCtrl.text.trim();

        await StorageService.updateCompanyLocally(companyData: updatedCompany);

        widget.company['bankName'] = updatedCompany['bankName'];
        widget.company['accountNo'] = updatedCompany['accountNo'];
        widget.company['ifsc'] = updatedCompany['ifsc'];

        if (mounted) {
          NotificationService.show(
            context,
            message: 'Bank details saved to Company profile (company.json)',
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.show(
            context,
            message: 'Failed to save bank details: $e',
            type: NotificationType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSavingBankDetails = false);
        }
      }
    }, message: 'Saving Bank Details...');
  }

  PdfPageFormat _getActiveFormat() {
    final base = _isLegalPaper ? PdfPageFormat.legal : PdfPageFormat.a4;
    return _isLandscape ? base.landscape : base.portrait;
  }

  String _numberToWords(double amount) {
    if (amount <= 0) return 'Rupees Zero Only';
    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertChunk(int n) {
      String str = '';
      if (n >= 100) {
        str += '${units[n ~/ 100]} Hundred ';
        n %= 100;
      }
      if (n >= 20) {
        str += '${tens[n ~/ 10]} ';
        n %= 10;
      }
      if (n > 0) {
        str += '${units[n]} ';
      }
      return str.trim();
    }

    int intPart = amount.floor();
    int decPart = ((amount - intPart) * 100).round();

    String result = '';
    int crore = intPart ~/ 10000000;
    intPart %= 10000000;
    int lakh = intPart ~/ 100000;
    intPart %= 100000;
    int thousand = intPart ~/ 1000;
    intPart %= 1000;
    int hundred = intPart;

    if (crore > 0) result += '${convertChunk(crore)} Crore ';
    if (lakh > 0) result += '${convertChunk(lakh)} Lakh ';
    if (thousand > 0) result += '${convertChunk(thousand)} Thousand ';
    if (hundred > 0) result += '${convertChunk(hundred)} ';

    result = result.trim();
    if (result.isEmpty) result = 'Zero';
    result = 'Rupees $result';

    if (decPart > 0) {
      result += ' and ${convertChunk(decPart)} Paise';
    }
    result += ' Only';
    return result;
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();
    final fontBoldItalic = await PdfGoogleFonts.notoSansBoldItalic();

    final pdfTheme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
      boldItalic: fontBoldItalic,
    );

    final pdf = pw.Document(theme: pdfTheme);

    final company = widget.company;
    final voucherData = widget.voucherData;

    final companyName = (company['companyName'] ?? '').toString().trim();
    final companyAddress = (company['address'] ?? company['addr'] ?? '').toString().trim();
    final rawCompanyGst = (company['gstin'] ?? company['gstNumber'] ?? '').toString().trim();
    final companyGst = rawCompanyGst.isNotEmpty ? rawCompanyGst : 'Unregistered';
    final companyState = (company['state'] ?? '').toString().trim();
    final companyPhone = (company['phone'] ?? company['mobile'] ?? '').toString().trim();
    final companyEmail = (company['email'] ?? '').toString().trim();

    final currentBankName = _bankNameCtrl.text.trim();
    final currentAccountNo = _accountNoCtrl.text.trim();
    final currentIfsc = _ifscCtrl.text.trim();
    final hasAnyBankDetails = currentBankName.isNotEmpty ||
        currentAccountNo.isNotEmpty ||
        currentIfsc.isNotEmpty;

    final grNo = _grNoCtrl.text.trim();
    final transport = _transportCtrl.text.trim();
    final vehicleNo = _vehicleNoCtrl.text.trim();
    final station = _stationCtrl.text.trim();
    final hasTransport = grNo.isNotEmpty || transport.isNotEmpty || vehicleNo.isNotEmpty || station.isNotEmpty;

    final vchNo = (voucherData['voucherNumber'] ?? '').toString().trim();
    final vchDate = (voucherData['date'] ?? '').toString().trim();
    final partyFull = (voucherData['party'] ?? '').toString().trim();

    String partyName = partyFull;
    String rawPartyGst = '';
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(partyFull);
    if (match != null) {
      rawPartyGst = match.group(1)!.trim();
      final bracketIdx = partyFull.indexOf('[');
      if (bracketIdx != -1) {
        partyName = partyFull.substring(0, bracketIdx).trim();
      }
    }
    final partyGst = rawPartyGst.isNotEmpty ? rawPartyGst : 'Unregistered';
    final shippedTo = _shippedToCtrl.text.trim().isNotEmpty
        ? _shippedToCtrl.text.trim()
        : partyName;

    final isInterState = voucherData['isInterState'] == true;
    final items = (voucherData['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final sundries = (voucherData['sundries'] as List? ?? []).cast<Map<String, dynamic>>();

    final subTotal = double.tryParse(voucherData['subTotal']?.toString() ?? '0') ?? 0.0;
    final totalCgst = double.tryParse(voucherData['cgst']?.toString() ?? '0') ?? 0.0;
    final totalSgst = double.tryParse(voucherData['sgst']?.toString() ?? '0') ?? 0.0;
    final totalIgst = double.tryParse(voucherData['igst']?.toString() ?? '0') ?? 0.0;
    final roundOff = double.tryParse(voucherData['roundOff']?.toString() ?? '0') ?? 0.0;
    final grandTotal = double.tryParse(voucherData['grandTotal']?.toString() ?? '0') ?? 0.0;

    final Map<String, Map<String, dynamic>> hsnMap = {};
    double totalMainUnits = 0.0;
    double totalHsnTaxable = 0.0;
    double totalHsnCgst = 0.0;
    double totalHsnSgst = 0.0;
    double totalHsnIgst = 0.0;

    for (final it in items) {
      final hsn = (it['hsn'] ?? 'General').toString().trim();
      final rate = double.tryParse(it['gstRate']?.toString() ?? '0') ?? 0.0;
      final unit = (it['unit'] ?? 'Pcs').toString().trim();
      final key = '$hsn-$rate-$unit';

      final q = double.tryParse(it['qty']?.toString() ?? '0') ?? 0.0;
      final taxVal = double.tryParse(it['taxable']?.toString() ?? '0') ?? 0.0;
      final cgstVal = double.tryParse(it['cgst']?.toString() ?? '0') ?? 0.0;
      final sgstVal = double.tryParse(it['sgst']?.toString() ?? '0') ?? 0.0;
      final igstVal = double.tryParse(it['igst']?.toString() ?? '0') ?? 0.0;

      totalMainUnits += q;
      totalHsnTaxable += taxVal;
      totalHsnCgst += cgstVal;
      totalHsnSgst += sgstVal;
      totalHsnIgst += igstVal;

      if (!hsnMap.containsKey(key)) {
        hsnMap[key] = {
          'hsn': hsn,
          'rate': rate,
          'qty': 0.0,
          'unit': unit,
          'taxable': 0.0,
          'cgst': 0.0,
          'sgst': 0.0,
          'igst': 0.0,
        };
      }
      hsnMap[key]!['qty'] = (hsnMap[key]!['qty'] as double) + q;
      hsnMap[key]!['taxable'] = (hsnMap[key]!['taxable'] as double) + taxVal;
      hsnMap[key]!['cgst'] = (hsnMap[key]!['cgst'] as double) + cgstVal;
      hsnMap[key]!['sgst'] = (hsnMap[key]!['sgst'] as double) + sgstVal;
      hsnMap[key]!['igst'] = (hsnMap[key]!['igst'] as double) + igstVal;
    }

    final isClassic = _invoiceTheme == 'Classic';
    final primaryColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF0F172A);
    final accentColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF2563EB);
    final borderColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFFCBD5E1);
    final lightBg = isClassic ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);
    final mutedColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF475569);
    final tableRowAlt = isClassic ? PdfColors.white : const PdfColor.fromInt(0xFFFAFAFC);

    final List<String> copiesToGenerate = [];
    if (_copyOriginal) copiesToGenerate.add('ORIGINAL FOR RECIPIENT');
    if (_copyDuplicate) copiesToGenerate.add('DUPLICATE FOR TRANSPORTER');
    if (_copyTriplicate) copiesToGenerate.add('TRIPLICATE FOR SUPPLIER');
    if (_copyExtra) copiesToGenerate.add('EXTRA COPY');
    if (copiesToGenerate.isEmpty) copiesToGenerate.add('ORIGINAL FOR RECIPIENT');

    final tableColumnWidths = {
      0: const pw.FixedColumnWidth(26),
      1: const pw.FlexColumnWidth(3.8),
      2: const pw.FixedColumnWidth(48),
      3: const pw.FixedColumnWidth(46),
      4: const pw.FixedColumnWidth(46),
      5: const pw.FixedColumnWidth(40),
      6: const pw.FixedColumnWidth(48),
      7: const pw.FixedColumnWidth(40),
      8: const pw.FixedColumnWidth(48),
      9: const pw.FixedColumnWidth(64),
    };

    final tableHeaders = [
      'S.N.',
      'Description of Goods',
      'HSN/SAC',
      'Qty. Unit',
      'Price',
      isInterState ? 'IGST %' : 'CGST %',
      isInterState ? 'IGST Amt' : 'CGST Amt',
      isInterState ? '' : 'SGST %',
      isInterState ? '' : 'SGST Amt',
      'Amount (₹)',
    ];

    final tableData = List.generate(items.length, (idx) {
      final item = items[idx];
      final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0;
      final unit = (item['unit'] ?? 'Pcs').toString().trim();
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
      final rate = double.tryParse(item['gstRate']?.toString() ?? '0') ?? 0.0;
      final halfRate = rate / 2.0;

      final cgstAmt = double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0;
      final sgstAmt = double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0;
      final igstAmt = double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0;
      final isExempt = rate == 0.0 || (item['taxCategory'] ?? '').toString().toLowerCase().contains('exempt');

      return [
        '${idx + 1}.',
        (item['item'] ?? '').toString(),
        (item['hsn'] ?? '-').toString(),
        '${qty.toStringAsFixed(2)} $unit',
        price.toStringAsFixed(2),
        isInterState ? '$rate%' : (isExempt ? 'Exempt' : '${halfRate.toStringAsFixed(2)}%'),
        isInterState ? igstAmt.toStringAsFixed(2) : cgstAmt.toStringAsFixed(2),
        isInterState ? '' : (isExempt ? 'Exempt' : '${halfRate.toStringAsFixed(2)}%'),
        isInterState ? '' : sgstAmt.toStringAsFixed(2),
        amt.toStringAsFixed(2),
      ];
    });

    for (final currentCopy in copiesToGenerate) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: pw.EdgeInsets.all(_pageMargin),
          theme: pdfTheme,
          header: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: borderColor, width: 1.0),
                  left: pw.BorderSide(color: borderColor, width: 1.0),
                  right: pw.BorderSide(color: borderColor, width: 1.0),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: _fontScale * 1.5,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.Text(
                          currentCopy,
                          style: pw.TextStyle(
                            fontSize: _fontScale * 1.05,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 7,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                companyName.isNotEmpty ? companyName.toUpperCase() : 'BUSINESS FIRM',
                                style: pw.TextStyle(
                                  fontSize: _fontScale * 1.6,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              if (companyAddress.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  companyAddress,
                                  style: pw.TextStyle(fontSize: _fontScale * 0.95, color: mutedColor),
                                ),
                              ],
                              if (companyPhone.isNotEmpty || companyEmail.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  [
                                    if (companyPhone.isNotEmpty) 'Mob: $companyPhone',
                                    if (companyEmail.isNotEmpty) 'Email: $companyEmail',
                                  ].join(' | '),
                                  style: pw.TextStyle(fontSize: _fontScale * 0.9, color: mutedColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'GSTIN: $companyGst',
                                style: pw.TextStyle(
                                  fontSize: _fontScale * 1.05,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              if (companyState.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                pw.Text('State: $companyState',
                                    style: pw.TextStyle(fontSize: _fontScale * 0.95, color: mutedColor)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(color: borderColor, width: 1)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Billed to :',
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 0.95,
                                        fontWeight: pw.FontWeight.bold,
                                        color: accentColor)),
                                pw.SizedBox(height: 3),
                                pw.Text(partyName,
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 1.2,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.SizedBox(height: 2),
                                pw.Text('GSTIN/UIN: $partyGst',
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 1.0,
                                        fontWeight: partyGst != 'Unregistered' ? pw.FontWeight.bold : pw.FontWeight.normal,
                                        color: primaryColor)),
                                pw.SizedBox(height: 6),
                                pw.Text('Shipped to :',
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 0.95,
                                        fontWeight: pw.FontWeight.bold,
                                        color: accentColor)),
                                pw.SizedBox(height: 2),
                                pw.Text(shippedTo,
                                    style: pw.TextStyle(fontSize: _fontScale * 1.0, color: primaryColor)),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              children: [
                                _buildPdfMetaRow('Invoice No.', vchNo, _fontScale, isBold: true, isClassic: isClassic),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow('Dated', vchDate, _fontScale, isClassic: isClassic),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow(
                                  'Place of Supply',
                                  isInterState ? 'Inter-State' : (companyState.isNotEmpty ? companyState : 'Local'),
                                  _fontScale,
                                  isClassic: isClassic,
                                ),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow('Reverse Charge', _reverseCharge ? 'Y' : 'N', _fontScale, isClassic: isClassic),
                                if (_showTransportDetails && hasTransport) ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                    child: pw.Divider(color: borderColor, thickness: 0.5),
                                  ),
                                  _buildPdfMetaRow('GR/RR No.', grNo.isNotEmpty ? grNo : '-', _fontScale, isClassic: isClassic),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Transport', transport.isNotEmpty ? transport : '-', _fontScale, isClassic: isClassic),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Vehicle No.', vehicleNo.isNotEmpty ? vehicleNo : '-', _fontScale, isClassic: isClassic),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Station', station.isNotEmpty ? station : '-', _fontScale, isClassic: isClassic),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder(
                  left: pw.BorderSide(color: borderColor, width: 1.0),
                  right: pw.BorderSide(color: borderColor, width: 1.0),
                  top: pw.BorderSide(color: borderColor, width: 1.0),
                  bottom: pw.BorderSide(color: borderColor, width: 1.0),
                  horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                  verticalInside: pw.BorderSide(color: borderColor, width: 0.8),
                ),
                columnWidths: tableColumnWidths,
                headers: tableHeaders,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontSize: _fontScale * 0.9,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                headerDecoration: pw.BoxDecoration(color: lightBg),
                headerAlignment: pw.Alignment.center,
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
                cellStyle: pw.TextStyle(
                  fontSize: _fontScale * 0.85,
                  color: isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF1E293B),
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: (_zebraStripes && !isClassic)
                    ? pw.BoxDecoration(color: tableRowAlt)
                    : const pw.BoxDecoration(color: PdfColors.white),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.center,
                  8: pw.Alignment.centerRight,
                  9: pw.Alignment.centerRight,
                },
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 1.0),
                    right: pw.BorderSide(color: borderColor, width: 1.0),
                    bottom: pw.BorderSide(color: borderColor, width: 1.0),
                  ),
                ),
                child: pw.Table(
                  border: pw.TableBorder(
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.8),
                  ),
                  columnWidths: tableColumnWidths,
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightBg),
                      children: [
                        _buildPdfTableCell('', _fontScale, isClassic: isClassic),
                        _buildPdfTableCell('Total', _fontScale, isBold: true, isClassic: isClassic),
                        _buildPdfTableCell('', _fontScale, isClassic: isClassic),
                        _buildPdfTableCell('${totalMainUnits.toStringAsFixed(2)} Units', _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                        _buildPdfTableCell('', _fontScale, isClassic: isClassic),
                        _buildPdfTableCell('', _fontScale, isClassic: isClassic),
                        _buildPdfTableCell(isInterState ? totalIgst.toStringAsFixed(2) : totalCgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                        _buildPdfTableCell('', _fontScale, isClassic: isClassic),
                        _buildPdfTableCell(isInterState ? '' : totalSgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                        _buildPdfTableCell(grandTotal.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 1.0),
                    right: pw.BorderSide(color: borderColor, width: 1.0),
                    bottom: pw.BorderSide(color: borderColor, width: 1.0),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(color: borderColor, width: 1)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (_showHsnSummary && hsnMap.isNotEmpty) ...[
                              pw.Table(
                                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                                columnWidths: {
                                  0: const pw.FlexColumnWidth(1.2),
                                  1: const pw.FlexColumnWidth(1.0),
                                  2: const pw.FlexColumnWidth(1.4),
                                  3: const pw.FlexColumnWidth(1.4),
                                  4: const pw.FlexColumnWidth(1.1),
                                  5: const pw.FlexColumnWidth(1.1),
                                  6: const pw.FlexColumnWidth(1.2),
                                },
                                children: [
                                  pw.TableRow(
                                    decoration: pw.BoxDecoration(color: lightBg),
                                    children: [
                                      _buildMiniHsnHead('HSN/SAC', _fontScale, isClassic: isClassic),
                                      _buildMiniHsnHead('Tax Rate', _fontScale, align: pw.TextAlign.center, isClassic: isClassic),
                                      _buildMiniHsnHead('UQC Main Qty.', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                      _buildMiniHsnHead('Taxable Amt.', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                      if (!isInterState) ...[
                                        _buildMiniHsnHead('CGST Amt', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                        _buildMiniHsnHead('SGST Amt', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                      ] else
                                        _buildMiniHsnHead('IGST Amt', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                      _buildMiniHsnHead('Total Tax', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                    ],
                                  ),
                                  ...hsnMap.entries.map((e) {
                                    final data = e.value;
                                    final rate = data['rate'] as double;
                                    final isExempt = rate == 0.0;
                                    final taxSum = isInterState
                                        ? (data['igst'] as double)
                                        : ((data['cgst'] as double) + (data['sgst'] as double));

                                    return pw.TableRow(
                                      children: [
                                        _buildMiniHsnCell(data['hsn'].toString(), _fontScale, isClassic: isClassic),
                                        _buildMiniHsnCell(isExempt ? 'Exempt' : '$rate%', _fontScale, align: pw.TextAlign.center, isClassic: isClassic),
                                        _buildMiniHsnCell('${(data['qty'] as double).toStringAsFixed(2)} ${data['unit']}', _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                        _buildMiniHsnCell((data['taxable'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                        if (!isInterState) ...[
                                          _buildMiniHsnCell((data['cgst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                          _buildMiniHsnCell((data['sgst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                        ] else
                                          _buildMiniHsnCell((data['igst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isClassic: isClassic),
                                        _buildMiniHsnCell(taxSum.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                      ],
                                    );
                                  }),
                                  pw.TableRow(
                                    decoration: pw.BoxDecoration(color: lightBg),
                                    children: [
                                      _buildMiniHsnCell('Total', _fontScale, isBold: true, isClassic: isClassic),
                                      _buildMiniHsnCell('', _fontScale, isClassic: isClassic),
                                      _buildMiniHsnCell('${totalMainUnits.toStringAsFixed(2)} Units', _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                      _buildMiniHsnCell(totalHsnTaxable.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                      if (!isInterState) ...[
                                        _buildMiniHsnCell(totalHsnCgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                        _buildMiniHsnCell(totalHsnSgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                      ] else
                                        _buildMiniHsnCell(totalHsnIgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true, isClassic: isClassic),
                                      _buildMiniHsnCell(
                                        isInterState
                                            ? totalHsnIgst.toStringAsFixed(2)
                                            : (totalHsnCgst + totalHsnSgst).toStringAsFixed(2),
                                        _fontScale,
                                        align: pw.TextAlign.right,
                                        isBold: true,
                                        isClassic: isClassic,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 6),
                            ],

                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Amount in Words : ',
                                    style: pw.TextStyle(
                                      fontSize: _fontScale * 0.9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      _numberToWords(grandTotal),
                                      style: pw.TextStyle(
                                        fontSize: _fontScale * 0.9,
                                        fontWeight: pw.FontWeight.bold,
                                        fontStyle: pw.FontStyle.italic,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 6),

                            if (_showBankDetails && hasAnyBankDetails) ...[
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(6),
                                decoration: pw.BoxDecoration(
                                  color: lightBg,
                                  borderRadius: pw.BorderRadius.circular(4),
                                  border: pw.Border.all(color: borderColor, width: 0.8),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'BANK & PAYMENT DETAILS',
                                      style: pw.TextStyle(
                                        fontSize: _fontScale * 0.8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    if (currentBankName.isNotEmpty)
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(bottom: 2),
                                        child: pw.Text(
                                          'Bank Name : $currentBankName',
                                          style: pw.TextStyle(
                                            fontSize: _fontScale * 0.85,
                                            fontWeight: pw.FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    if (currentAccountNo.isNotEmpty)
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(bottom: 2),
                                        child: pw.Text(
                                          'Account No : $currentAccountNo',
                                          style: pw.TextStyle(
                                            fontSize: _fontScale * 0.85,
                                            fontWeight: pw.FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    if (currentIfsc.isNotEmpty)
                                      pw.Text(
                                        'IFSC Code : $currentIfsc',
                                        style: pw.TextStyle(
                                          fontSize: _fontScale * 0.85,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(height: 6),
                            ],

                            if (_showTerms) ...[
                              pw.Text(
                                'Terms & Conditions:',
                                style: pw.TextStyle(
                                  fontSize: _fontScale * 0.9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              pw.Text(
                                'E.& O.E.',
                                style: pw.TextStyle(
                                  fontSize: _fontScale * 0.8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: mutedColor,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '1. Goods once sold will not be taken back.\n'
                                '2. Interest @ 18% p.a. will be charged if the payment is not made with in the stipulated time.\n'
                                '3. Subject to \'${companyState.isNotEmpty ? companyState : "Uttar Pradesh"}\' Jurisdiction only.',
                                style: pw.TextStyle(
                                  fontSize: _fontScale * 0.8,
                                  color: primaryColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(
                          children: [
                            _buildPdfSummaryRow('Taxable Amount', '₹ ${subTotal.toStringAsFixed(2)}', _fontScale, isClassic: isClassic),
                            pw.SizedBox(height: 4),
                            if (!isInterState) ...[
                              _buildPdfSummaryRow('CGST Amount', '₹ ${totalCgst.toStringAsFixed(2)}', _fontScale, isClassic: isClassic),
                              pw.SizedBox(height: 4),
                              _buildPdfSummaryRow('SGST Amount', '₹ ${totalSgst.toStringAsFixed(2)}', _fontScale, isClassic: isClassic),
                            ] else ...[
                              _buildPdfSummaryRow('IGST Amount', '₹ ${totalIgst.toStringAsFixed(2)}', _fontScale, isClassic: isClassic),
                            ],
                            if (sundries.isNotEmpty)
                              ...sundries.map((s) => pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 4),
                                    child: _buildPdfSummaryRow(
                                      (s['name'] ?? 'Sundry').toString(),
                                      '₹ ${(double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                      _fontScale,
                                      isClassic: isClassic,
                                    ),
                                  )),
                            if (roundOff != 0.0) ...[
                              pw.SizedBox(height: 4),
                              _buildPdfSummaryRow('Round Off', '₹ ${roundOff.toStringAsFixed(2)}', _fontScale, isClassic: isClassic),
                            ],
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6),
                              child: pw.Divider(color: borderColor, thickness: 0.8),
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Grand Total',
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 1.25,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text('₹ ${grandTotal.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                        fontSize: _fontScale * 1.45,
                                        fontWeight: pw.FontWeight.bold,
                                        color: accentColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 1.0),
                    right: pw.BorderSide(color: borderColor, width: 1.0),
                    bottom: pw.BorderSide(color: borderColor, width: 1.0),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Receiver\'s Signature:',
                        style: pw.TextStyle(fontSize: _fontScale * 0.85, color: mutedColor)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('for ${companyName.isNotEmpty ? companyName.toUpperCase() : "SELLER"}',
                            style: pw.TextStyle(
                                fontSize: _fontScale * 0.9,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.SizedBox(height: 28),
                        pw.Text('Authorised Signatory',
                            style: pw.TextStyle(fontSize: _fontScale * 0.85, color: mutedColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildPdfMetaRow(String label, String val, double scale, {bool isBold = false, bool isClassic = false}) {
    final labelColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF475569);
    final valColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF0F172A);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$label:', style: pw.TextStyle(fontSize: scale * 0.9, color: labelColor)),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: scale * 0.95,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCellText(String text, double scale,
      {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false, bool isBold = false, bool isMuted = false, bool isClassic = false}) {
    final textColor = isClassic
        ? PdfColors.black
        : (isMuted
            ? const PdfColor.fromInt(0xFF94A3B8)
            : (isHeader ? const PdfColor.fromInt(0xFF0F172A) : const PdfColor.fromInt(0xFF1E293B)));
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? scale * 0.9 : scale * 0.85,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableCell(String text, double scale,
      {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false, bool isBold = false, bool isMuted = false, bool isClassic = false}) {
    return _buildTableCellText(text, scale, align: align, isHeader: isHeader, isBold: isBold, isMuted: isMuted, isClassic: isClassic);
  }

  static pw.Widget _buildPdfSummaryRow(String label, String val, double scale, {bool isClassic = false}) {
    final labelColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF334155);
    final valColor = isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF0F172A);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: scale * 0.95, color: labelColor)),
        pw.Text(val, style: pw.TextStyle(fontSize: scale * 0.95, fontWeight: pw.FontWeight.bold, color: valColor)),
      ],
    );
  }

  static pw.Widget _buildMiniHsnHead(String title, double scale, {pw.TextAlign align = pw.TextAlign.left, bool isClassic = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(title,
          textAlign: align,
          style: pw.TextStyle(fontSize: scale * 0.75, fontWeight: pw.FontWeight.bold, color: isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF0F172A))),
    );
  }

  static pw.Widget _buildMiniHsnCell(String val, double scale, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false, bool isClassic = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(val,
          textAlign: align,
          style: pw.TextStyle(fontSize: scale * 0.75, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isClassic ? PdfColors.black : const PdfColor.fromInt(0xFF334155))),
    );
  }

  Widget _buildSidebarCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMiniTextField({required TextEditingController controller, required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildToggleTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Transform.scale(
            scale: 0.75,
            child: Switch(value: value, activeThumbColor: AppColors.primary, activeTrackColor: AppColors.primaryLight, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: math.min(MediaQuery.of(context).size.width * 0.95, 1340),
        height: math.min(MediaQuery.of(context).size.height * 0.94, 900),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Invoice Studio — #${widget.voucherData['voucherNumber'] ?? ''}',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border(right: BorderSide(color: AppColors.border, width: 1.2)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        _buildSidebarCard(
                          title: 'PRINT COPIES (BATCH PRINT)',
                          icon: Icons.copy_all_rounded,
                          children: [
                            _buildCopyCheckbox('Original for Recipient', _copyOriginal, (val) {
                              setState(() => _copyOriginal = val ?? false);
                            }),
                            _buildCopyCheckbox('Duplicate for Transporter', _copyDuplicate, (val) {
                              setState(() => _copyDuplicate = val ?? false);
                            }),
                            _buildCopyCheckbox('Triplicate for Supplier', _copyTriplicate, (val) {
                              setState(() => _copyTriplicate = val ?? false);
                            }),
                            _buildCopyCheckbox('Extra Copy', _copyExtra, (val) {
                              setState(() => _copyExtra = val ?? false);
                            }),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'PRINT THEME (COLOR / B&W)',
                          icon: Icons.palette_outlined,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'Modern',
                                  label: Text('Modern Theme', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  icon: Icon(Icons.auto_awesome, size: 14),
                                ),
                                ButtonSegment(
                                  value: 'Classic',
                                  label: Text('Classic B&W', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  icon: Icon(Icons.print_outlined, size: 14),
                                ),
                              ],
                              selected: {_invoiceTheme},
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                selectedBackgroundColor: AppColors.primary,
                                selectedForegroundColor: AppColors.surface,
                              ),
                              onSelectionChanged: (val) => setState(() => _invoiceTheme = val.first),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'DISPATCH & TRANSPORT DETAILS',
                          icon: Icons.local_shipping_rounded,
                          children: [
                            _buildMiniTextField(controller: _grNoCtrl, label: 'GR/RR No.', hint: 'e.g. 1029'),
                            _buildMiniTextField(controller: _transportCtrl, label: 'Transport', hint: 'e.g. Roadlines'),
                            _buildMiniTextField(controller: _vehicleNoCtrl, label: 'Vehicle No.', hint: 'e.g. UP20AT1234'),
                            _buildMiniTextField(controller: _stationCtrl, label: 'Station', hint: 'e.g. Bijnor'),
                            _buildMiniTextField(controller: _shippedToCtrl, label: 'Shipped to Address', hint: 'Default: Same as Billed to'),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'BANK & PAYMENT DETAILS',
                          icon: Icons.account_balance_rounded,
                          children: [
                            _buildMiniTextField(controller: _bankNameCtrl, label: 'Bank Name', hint: 'e.g., State Bank of India'),
                            _buildMiniTextField(controller: _accountNoCtrl, label: 'Account Number', hint: 'e.g., 1029384756'),
                            _buildMiniTextField(controller: _ifscCtrl, label: 'IFSC Code', hint: 'e.g., SBIN0001234'),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: _isSavingBankDetails ? null : _saveBankDetailsToCompany,
                                icon: _isSavingBankDetails
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
                                    : const Icon(Icons.save_rounded, size: 14, color: AppColors.surface),
                                label: const Text('Save to Company Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.surface)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                              ),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'PAGE SIZE & MARGINS',
                          icon: Icons.aspect_ratio_rounded,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isLandscape = !_isLandscape),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _isLandscape ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                                      side: BorderSide(color: _isLandscape ? AppColors.primary : AppColors.borderMedium),
                                    ),
                                    child: Text(_isLandscape ? 'Landscape' : 'Portrait', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isLegalPaper = !_isLegalPaper),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _isLegalPaper ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                                      side: BorderSide(color: _isLegalPaper ? AppColors.primary : AppColors.borderMedium),
                                    ),
                                    child: Text(_isLegalPaper ? 'Legal' : 'A4 Size', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Margin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('${_pageMargin.toInt()} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            Slider(
                              value: _pageMargin,
                              min: 8.0,
                              max: 30.0,
                              divisions: 11,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _pageMargin = val),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Font Scale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('${_fontScale.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            Slider(
                              value: _fontScale,
                              min: 7.0,
                              max: 11.5,
                              divisions: 9,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _fontScale = val),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'CONTENT TOGGLES',
                          icon: Icons.visibility_rounded,
                          children: [
                            _buildToggleTile(title: 'Reverse Charge (RCM)', value: _reverseCharge, onChanged: (v) => setState(() => _reverseCharge = v)),
                            _buildToggleTile(title: 'Show Transport Details', value: _showTransportDetails, onChanged: (v) => setState(() => _showTransportDetails = v)),
                            _buildToggleTile(title: 'Show Bank Details', value: _showBankDetails, onChanged: (v) => setState(() => _showBankDetails = v)),
                            _buildToggleTile(title: 'Show HSN/Tax Matrix', value: _showHsnSummary, onChanged: (v) => setState(() => _showHsnSummary = v)),
                            _buildToggleTile(title: 'Show Terms & Notes', value: _showTerms, onChanged: (v) => setState(() => _showTerms = v)),
                            if (_invoiceTheme == 'Modern')
                              _buildToggleTile(title: 'Zebra Striping', value: _zebraStripes, onChanged: (v) => setState(() => _zebraStripes = v)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        primaryColor: AppColors.primary,
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.surface,
                          onPrimary: AppColors.primary,
                          surface: AppColors.background,
                        ),
                        iconTheme: const IconThemeData(color: AppColors.primary),
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.all(AppColors.primary),
                          trackColor: WidgetStateProperty.all(AppColors.borderFocus),
                        ),
                      ),
                      child: PdfPreview(
                        build: (format) => _generatePdf(_getActiveFormat()),
                        initialPageFormat: _getActiveFormat(),
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        allowSharing: true,
                        allowPrinting: true,
                        previewPageMargin: const EdgeInsets.all(16),
                        pdfFileName: 'Tax_Invoice_${widget.voucherData['voucherNumber'] ?? 'Bill'}.pdf',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}