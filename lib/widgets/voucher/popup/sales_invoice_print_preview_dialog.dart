import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../constants/app_colors.dart';
import '../../../services/storage_service.dart';

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
  // Multiple Copies Selection
  bool _copyOriginal = true;
  bool _copyDuplicate = false;
  bool _copyTriplicate = false;
  bool _copyExtra = false;

  // Customization Options ('Modern' or 'Classic')
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

  // Editable Bank Controllers
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ifscCtrl;
  bool _isSavingBankDetails = false;

  // Editable Transport / Dispatch Controllers
  late TextEditingController _grNoCtrl;
  late TextEditingController _transportCtrl;
  late TextEditingController _vehicleNoCtrl;
  late TextEditingController _stationCtrl;
  late TextEditingController _shippedToCtrl;

  @override
  void initState() {
    super.initState();
    // Initialize Bank Controllers
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

    // Initialize Dispatch & Transport Controllers
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details saved to Company profile (company.json)'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bank details: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBankDetails = false);
      }
    }
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
    // 1. Load full Unicode font variants (Regular, Bold, Italic, BoldItalic)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();
    final fontBoldItalic = await PdfGoogleFonts.notoSansBoldItalic();

    // 2. Build font theme ensuring bold-italic has full Unicode support
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

    // Build HSN/SAC Unit-wise, Rate-wise Matrix
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

    for (final currentCopy in copiesToGenerate) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(_pageMargin),
          theme: pdfTheme,
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 1.0),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Header Banner
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

                  // 2. Organization Header
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

                  // 3. Buyer Details & Invoice Meta Details Grid
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left: Buyer & Consignee
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

                        // Right: Invoice & Dispatch Meta
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              children: [
                                _buildPdfMetaRow('Invoice No.', vchNo, _fontScale, isBold: true),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow('Dated', vchDate, _fontScale),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow(
                                  'Place of Supply',
                                  isInterState ? 'Inter-State' : (companyState.isNotEmpty ? companyState : 'Local'),
                                  _fontScale,
                                ),
                                pw.SizedBox(height: 3.5),
                                _buildPdfMetaRow('Reverse Charge', _reverseCharge ? 'Y' : 'N', _fontScale),
                                if (_showTransportDetails && hasTransport) ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                    child: pw.Divider(color: borderColor, thickness: 0.5),
                                  ),
                                  _buildPdfMetaRow('GR/RR No.', grNo.isNotEmpty ? grNo : '-', _fontScale),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Transport', transport.isNotEmpty ? transport : '-', _fontScale),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Vehicle No.', vehicleNo.isNotEmpty ? vehicleNo : '-', _fontScale),
                                  pw.SizedBox(height: 2.5),
                                  _buildPdfMetaRow('Station', station.isNotEmpty ? station : '-', _fontScale),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Main Line Items Table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder(
                        horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                        verticalInside: pw.BorderSide(color: borderColor, width: 0.8),
                        bottom: pw.BorderSide(color: borderColor, width: 1.0),
                      ),
                      columnWidths: {
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
                      },
                      children: [
                        // Header
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: lightBg),
                          children: [
                            _buildPdfTableCell('S.N.', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell('Description of Goods', _fontScale, isHeader: true),
                            _buildPdfTableCell('HSN/SAC', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell('Qty. Unit', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell('Price', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell(isInterState ? 'IGST %' : 'CGST %', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell(isInterState ? 'IGST Amt' : 'CGST Amt', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell(isInterState ? '' : 'SGST %', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell(isInterState ? '' : 'SGST Amt', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell('Amount (₹)', _fontScale, align: pw.TextAlign.right, isHeader: true),
                          ],
                        ),
                        // Data rows
                        ...List.generate(items.length, (idx) {
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
                          final isEven = idx % 2 == 0;
                          final isExempt = rate == 0.0 || (item['taxCategory'] ?? '').toString().toLowerCase().contains('exempt');

                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: (_zebraStripes && !isClassic && isEven)
                                  ? tableRowAlt
                                  : PdfColors.white,
                            ),
                            children: [
                              _buildPdfTableCell('${idx + 1}.', _fontScale, align: pw.TextAlign.center),
                              _buildPdfTableCell((item['item'] ?? '').toString(), _fontScale, isBold: true),
                              _buildPdfTableCell((item['hsn'] ?? '-').toString(), _fontScale, align: pw.TextAlign.center),
                              _buildPdfTableCell('${qty.toStringAsFixed(2)} $unit', _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(price.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(isInterState ? '$rate%' : (isExempt ? 'Exempt' : '${halfRate.toStringAsFixed(2)}%'), _fontScale, align: pw.TextAlign.center),
                              _buildPdfTableCell(isInterState ? igstAmt.toStringAsFixed(2) : cgstAmt.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(isInterState ? '' : (isExempt ? 'Exempt' : '${halfRate.toStringAsFixed(2)}%'), _fontScale, align: pw.TextAlign.center),
                              _buildPdfTableCell(isInterState ? '' : sgstAmt.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(amt.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                            ],
                          );
                        }),
                        // Main Table Summary Total Line
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: lightBg),
                          children: [
                            _buildPdfTableCell('', _fontScale),
                            _buildPdfTableCell('Total', _fontScale, isBold: true),
                            _buildPdfTableCell('', _fontScale),
                            _buildPdfTableCell('${totalMainUnits.toStringAsFixed(2)} Units', _fontScale, align: pw.TextAlign.right, isBold: true),
                            _buildPdfTableCell('', _fontScale),
                            _buildPdfTableCell('', _fontScale),
                            _buildPdfTableCell(isInterState ? totalIgst.toStringAsFixed(2) : totalCgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                            _buildPdfTableCell('', _fontScale),
                            _buildPdfTableCell(isInterState ? '' : totalSgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                            _buildPdfTableCell(grandTotal.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 5. Lower HSN Matrix, Calculations, Bank, and Unboxed Terms
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Side: HSN Matrix + Amount in Words + Bank Details + Unboxed Terms
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
                                // Detailed HSN Summary Matrix Table
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
                                          _buildMiniHsnHead('HSN/SAC', _fontScale),
                                          _buildMiniHsnHead('Tax Rate', _fontScale, align: pw.TextAlign.center),
                                          _buildMiniHsnHead('UQC Main Qty.', _fontScale, align: pw.TextAlign.right),
                                          _buildMiniHsnHead('Taxable Amt.', _fontScale, align: pw.TextAlign.right),
                                          if (!isInterState) ...[
                                            _buildMiniHsnHead('CGST Amt', _fontScale, align: pw.TextAlign.right),
                                            _buildMiniHsnHead('SGST Amt', _fontScale, align: pw.TextAlign.right),
                                          ] else
                                            _buildMiniHsnHead('IGST Amt', _fontScale, align: pw.TextAlign.right),
                                          _buildMiniHsnHead('Total Tax', _fontScale, align: pw.TextAlign.right),
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
                                            _buildMiniHsnCell(data['hsn'].toString(), _fontScale),
                                            _buildMiniHsnCell(isExempt ? 'Exempt' : '$rate%', _fontScale, align: pw.TextAlign.center),
                                            _buildMiniHsnCell('${(data['qty'] as double).toStringAsFixed(2)} ${data['unit']}', _fontScale, align: pw.TextAlign.right),
                                            _buildMiniHsnCell((data['taxable'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                            if (!isInterState) ...[
                                              _buildMiniHsnCell((data['cgst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                              _buildMiniHsnCell((data['sgst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                            ] else
                                              _buildMiniHsnCell((data['igst'] as double).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                            _buildMiniHsnCell(taxSum.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                                          ],
                                        );
                                      }),
                                      // Cumulative Total Footer Row
                                      pw.TableRow(
                                        decoration: pw.BoxDecoration(color: lightBg),
                                        children: [
                                          _buildMiniHsnCell('Total', _fontScale, isBold: true),
                                          _buildMiniHsnCell('', _fontScale),
                                          _buildMiniHsnCell('${totalMainUnits.toStringAsFixed(2)} Units', _fontScale, align: pw.TextAlign.right, isBold: true),
                                          _buildMiniHsnCell(totalHsnTaxable.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                                          if (!isInterState) ...[
                                            _buildMiniHsnCell(totalHsnCgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                                            _buildMiniHsnCell(totalHsnSgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                                          ] else
                                            _buildMiniHsnCell(totalHsnIgst.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                                          _buildMiniHsnCell(
                                            isInterState
                                                ? totalHsnIgst.toStringAsFixed(2)
                                                : (totalHsnCgst + totalHsnSgst).toStringAsFixed(2),
                                            _fontScale,
                                            align: pw.TextAlign.right,
                                            isBold: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 6),
                                ],

                                // Amount in Words
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

                                // Bank Details Block (Vertical Rows)
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
                                            color: isClassic ? PdfColors.black : accentColor,
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

                                // Terms & Conditions (Unboxed)
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

                        // Right Side: Grand Total & Taxes Calculation Box
                        pw.Expanded(
                          flex: 4,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Column(
                              children: [
                                _buildPdfSummaryRow('Taxable Amount', '₹ ${subTotal.toStringAsFixed(2)}', _fontScale),
                                pw.SizedBox(height: 4),
                                if (!isInterState) ...[
                                  _buildPdfSummaryRow('CGST Amount', '₹ ${totalCgst.toStringAsFixed(2)}', _fontScale),
                                  pw.SizedBox(height: 4),
                                  _buildPdfSummaryRow('SGST Amount', '₹ ${totalSgst.toStringAsFixed(2)}', _fontScale),
                                ] else ...[
                                  _buildPdfSummaryRow('IGST Amount', '₹ ${totalIgst.toStringAsFixed(2)}', _fontScale),
                                ],
                                if (sundries.isNotEmpty)
                                  ...sundries.map((s) => pw.Padding(
                                        padding: const pw.EdgeInsets.only(top: 4),
                                        child: _buildPdfSummaryRow(
                                          (s['name'] ?? 'Sundry').toString(),
                                          '₹ ${(double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                          _fontScale,
                                        ),
                                      )),
                                if (roundOff != 0.0) ...[
                                  pw.SizedBox(height: 4),
                                  _buildPdfSummaryRow('Round Off', '₹ ${roundOff.toStringAsFixed(2)}', _fontScale),
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

                  // 6. Signatures Bottom Strip
                  pw.Container(
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
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildPdfMetaRow(String label, String val, double scale, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$label:', style: pw.TextStyle(fontSize: scale * 0.9, color: const PdfColor.fromInt(0xFF475569))),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: scale * 0.95,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: const PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCellText(String text, double scale,
      {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false, bool isBold = false, bool isMuted = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? scale * 0.9 : scale * 0.85,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isMuted
              ? const PdfColor.fromInt(0xFF94A3B8)
              : (isHeader ? const PdfColor.fromInt(0xFF0F172A) : const PdfColor.fromInt(0xFF1E293B)),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableCell(String text, double scale,
      {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false, bool isBold = false, bool isMuted = false}) {
    return _buildTableCellText(text, scale, align: align, isHeader: isHeader, isBold: isBold, isMuted: isMuted);
  }

  static pw.Widget _buildPdfSummaryRow(String label, String val, double scale) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: scale * 0.95, color: const PdfColor.fromInt(0xFF334155))),
        pw.Text(val, style: pw.TextStyle(fontSize: scale * 0.95, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
      ],
    );
  }

  static pw.Widget _buildMiniHsnHead(String title, double scale, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(title,
          textAlign: align,
          style: pw.TextStyle(fontSize: scale * 0.75, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
    );
  }

  static pw.Widget _buildMiniHsnCell(String val, double scale, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(val,
          textAlign: align,
          style: pw.TextStyle(fontSize: scale * 0.75, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: const PdfColor.fromInt(0xFF334155))),
    );
  }

  Widget _buildSidebarCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2EAF5)),
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
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
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
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 3),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
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
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Transform.scale(
            scale: 0.75,
            child: Switch(value: value, activeThumbColor: AppColors.primary, onChanged: onChanged),
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
        title: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: math.min(MediaQuery.of(context).size.width * 0.95, 1340),
        height: math.min(MediaQuery.of(context).size.height * 0.94, 900),
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
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
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Studio Layout: Sidebar Controls + Live Preview
            Expanded(
              child: Row(
                children: [
                  // Sidebar Controls
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFD),
                      border: Border(right: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        // Multiple Copies Selection
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

                        // Theme Selection (Modern vs Classic B&W)
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
                                selectedForegroundColor: Colors.white,
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
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_rounded, size: 14, color: Colors.white),
                                label: const Text('Save to Company Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
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
                                      backgroundColor: _isLandscape ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                      side: BorderSide(color: _isLandscape ? AppColors.primary : const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(_isLandscape ? 'Landscape' : 'Portrait', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isLegalPaper = !_isLegalPaper),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _isLegalPaper ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                      side: BorderSide(color: _isLegalPaper ? AppColors.primary : const Color(0xFFCBD5E1)),
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
                          primary: Colors.white,
                          onPrimary: AppColors.primary,
                          surface: const Color(0xFFF1F5FB),
                        ),
                        iconTheme: const IconThemeData(color: AppColors.primary),
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.all(AppColors.primary),
                          trackColor: WidgetStateProperty.all(const Color(0xFFD6E3F4)),
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