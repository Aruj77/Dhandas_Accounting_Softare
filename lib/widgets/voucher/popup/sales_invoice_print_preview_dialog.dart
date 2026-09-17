import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  // Customization Options
  String _invoiceCopy = 'ORIGINAL FOR RECIPIENT';
  String _invoiceTheme = 'Modern'; // 'Modern' or 'Classic'
  bool _isLandscape = false;
  bool _isLegalPaper = false;
  double _pageMargin = 22.0;
  double _fontScale = 8.5;
  bool _showHsnSummary = true;
  bool _showBankDetails = true;
  bool _showTerms = true;
  bool _zebraStripes = true;

  // Editable Bank Controllers
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ifscCtrl;
  bool _isSavingBankDetails = false;

  @override
  void initState() {
    super.initState();
    // Default to company.json values, otherwise completely empty (no fallback dummy data)
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
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
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

      // Update in-memory reference
      widget.company['bankName'] = updatedCompany['bankName'];
      widget.company['accountNo'] = updatedCompany['accountNo'];
      widget.company['ifsc'] = updatedCompany['ifsc'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details saved to Company profile (company.json)'),
            backgroundColor: Color(0xFF10A35B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bank details: $e'),
            backgroundColor: const Color(0xFFEE4343),
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

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final company = widget.company;
    final voucherData = widget.voucherData;

    final companyName = (company['companyName'] ?? '').toString().trim();
    final companyAddress = (company['address'] ?? company['addr'] ?? '').toString().trim();
    final companyGst = (company['gstin'] ?? company['gstNumber'] ?? '').toString().trim();
    final companyState = (company['state'] ?? '').toString().trim();
    final companyPhone = (company['phone'] ?? company['mobile'] ?? '').toString().trim();
    final companyEmail = (company['email'] ?? '').toString().trim();

    // Bank Details from live editing controllers
    final currentBankName = _bankNameCtrl.text.trim();
    final currentAccountNo = _accountNoCtrl.text.trim();
    final currentIfsc = _ifscCtrl.text.trim();
    final hasAnyBankDetails = currentBankName.isNotEmpty ||
        currentAccountNo.isNotEmpty ||
        currentIfsc.isNotEmpty;

    final vchNo = (voucherData['voucherNumber'] ?? '').toString().trim();
    final vchDate = (voucherData['date'] ?? '').toString().trim();
    final partyFull = (voucherData['party'] ?? '').toString().trim();

    String partyName = partyFull;
    String partyGst = '';
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(partyFull);
    if (match != null) {
      partyGst = match.group(1)!.trim();
      final bracketIdx = partyFull.indexOf('[');
      if (bracketIdx != -1) {
        partyName = partyFull.substring(0, bracketIdx).trim();
      }
    }

    final isInterState = voucherData['isInterState'] == true;
    final items = (voucherData['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final sundries = (voucherData['sundries'] as List? ?? []).cast<Map<String, dynamic>>();

    final subTotal = double.tryParse(voucherData['subTotal']?.toString() ?? '0') ?? 0.0;
    final totalCgst = double.tryParse(voucherData['cgst']?.toString() ?? '0') ?? 0.0;
    final totalSgst = double.tryParse(voucherData['sgst']?.toString() ?? '0') ?? 0.0;
    final totalIgst = double.tryParse(voucherData['igst']?.toString() ?? '0') ?? 0.0;
    final roundOff = double.tryParse(voucherData['roundOff']?.toString() ?? '0') ?? 0.0;
    final grandTotal = double.tryParse(voucherData['grandTotal']?.toString() ?? '0') ?? 0.0;

    // Build HSN Summary Matrix
    final Map<String, Map<String, double>> hsnMap = {};
    for (final it in items) {
      final hsn = (it['hsn'] ?? 'General').toString().trim();
      final rate = double.tryParse(it['gstRate']?.toString() ?? '18') ?? 18.0;
      final key = '$hsn-$rate';
      final taxVal = double.tryParse(it['taxable']?.toString() ?? '0') ?? 0.0;
      final cgstVal = double.tryParse(it['cgst']?.toString() ?? '0') ?? 0.0;
      final sgstVal = double.tryParse(it['sgst']?.toString() ?? '0') ?? 0.0;
      final igstVal = double.tryParse(it['igst']?.toString() ?? '0') ?? 0.0;

      if (!hsnMap.containsKey(key)) {
        hsnMap[key] = {
          'rate': rate,
          'taxable': 0.0,
          'cgst': 0.0,
          'sgst': 0.0,
          'igst': 0.0,
        };
      }
      hsnMap[key]!['taxable'] = hsnMap[key]!['taxable']! + taxVal;
      hsnMap[key]!['cgst'] = hsnMap[key]!['cgst']! + cgstVal;
      hsnMap[key]!['sgst'] = hsnMap[key]!['sgst']! + sgstVal;
      hsnMap[key]!['igst'] = hsnMap[key]!['igst']! + igstVal;
    }

    final isModern = _invoiceTheme == 'Modern';
    final primaryColor = isModern ? const PdfColor.fromInt(0xFF0F172A) : PdfColors.black;
    final accentColor = isModern ? const PdfColor.fromInt(0xFF2563EB) : PdfColors.black;
    final borderColor = isModern ? const PdfColor.fromInt(0xFFE2E8F0) : PdfColors.grey700;
    final lightBg = isModern ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.grey100;
    const mutedColor = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(_pageMargin),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName.isNotEmpty ? companyName.toUpperCase() : 'BUSINESS ENTITY',
                          style: pw.TextStyle(
                            fontSize: _fontScale * 1.8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (companyAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            companyAddress,
                            style: pw.TextStyle(
                              fontSize: _fontScale * 0.95,
                              color: mutedColor,
                            ),
                          ),
                        ],
                        if (companyPhone.isNotEmpty || companyEmail.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              if (companyPhone.isNotEmpty) 'Phone: $companyPhone',
                              if (companyEmail.isNotEmpty) 'Email: $companyEmail',
                            ].join(' | '),
                            style: pw.TextStyle(
                              fontSize: _fontScale * 0.9,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: isModern ? accentColor : PdfColors.grey300,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'TAX INVOICE',
                            style: pw.TextStyle(
                              fontSize: _fontScale * 1.25,
                              fontWeight: pw.FontWeight.bold,
                              color: isModern ? PdfColors.white : PdfColors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _invoiceCopy,
                          style: pw.TextStyle(
                            fontSize: _fontScale * 0.85,
                            fontWeight: pw.FontWeight.bold,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Billed To & Meta Grid Card
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, width: 1),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BUYER / RECEIVER DETAILS',
                            style: pw.TextStyle(
                              fontSize: _fontScale * 0.8,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            partyName,
                            style: pw.TextStyle(
                              fontSize: _fontScale * 1.2,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          if (partyGst.isNotEmpty)
                            pw.Text('GSTIN: $partyGst',
                                style: pw.TextStyle(
                                    fontSize: _fontScale * 0.95,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor))
                          else
                            pw.Text('Status: Consumer / Unregistered',
                                style: pw.TextStyle(
                                    fontSize: _fontScale * 0.9,
                                    color: mutedColor)),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 46, color: borderColor),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfMetaRow('Invoice No', vchNo, _fontScale, isBold: true),
                          pw.SizedBox(height: 2),
                          _buildPdfMetaRow('Invoice Date', vchDate, _fontScale),
                          pw.SizedBox(height: 2),
                          _buildPdfMetaRow(
                            'Place of Supply',
                            isInterState
                                ? 'Inter-State'
                                : (companyState.isNotEmpty ? 'Intra-State ($companyState)' : 'Local'),
                            _fontScale,
                          ),
                          pw.SizedBox(height: 2),
                          _buildPdfMetaRow(
                            'Supplier GSTIN',
                            companyGst.isNotEmpty ? companyGst : 'Not Provided',
                            _fontScale,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Items Table
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Table(
                      columnWidths: {
                        0: const pw.FixedColumnWidth(26),
                        1: const pw.FlexColumnWidth(4),
                        2: const pw.FixedColumnWidth(55),
                        3: const pw.FixedColumnWidth(40),
                        4: const pw.FixedColumnWidth(34),
                        5: const pw.FixedColumnWidth(55),
                        6: const pw.FixedColumnWidth(60),
                        7: const pw.FixedColumnWidth(65),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: lightBg),
                          children: [
                            _buildPdfTableCell('#', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell('Item Description', _fontScale, isHeader: true),
                            _buildPdfTableCell('HSN/SAC', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell('Qty', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell('Unit', _fontScale, align: pw.TextAlign.center, isHeader: true),
                            _buildPdfTableCell('Rate (INR)', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell('Taxable (INR)', _fontScale, align: pw.TextAlign.right, isHeader: true),
                            _buildPdfTableCell('Amount (INR)', _fontScale, align: pw.TextAlign.right, isHeader: true),
                          ],
                        ),
                        ...List.generate(items.length, (idx) {
                          final item = items[idx];
                          final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0;
                          final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                          final taxable = double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0;
                          final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                          final isEven = idx % 2 == 0;

                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: (_zebraStripes && isEven)
                                  ? const PdfColor.fromInt(0xFFFAFAFC)
                                  : PdfColors.white,
                              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
                            ),
                            children: [
                              _buildPdfTableCell('${idx + 1}', _fontScale, align: pw.TextAlign.center, isMuted: true),
                              _buildPdfTableCell((item['item'] ?? '').toString(), _fontScale, isBold: true),
                              _buildPdfTableCell((item['hsn'] ?? '-').toString(), _fontScale, align: pw.TextAlign.center),
                              _buildPdfTableCell(qty.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell((item['unit'] ?? 'Pcs').toString(), _fontScale, align: pw.TextAlign.center, isMuted: true),
                              _buildPdfTableCell(price.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(taxable.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                              _buildPdfTableCell(amt.toStringAsFixed(2), _fontScale, align: pw.TextAlign.right, isBold: true),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              // Bottom Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // HSN Summary Matrix
                        if (_showHsnSummary && hsnMap.isNotEmpty) ...[
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: borderColor),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Table(
                              children: [
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(color: lightBg),
                                  children: [
                                    _buildMiniHsnHead('HSN/SAC', _fontScale),
                                    _buildMiniHsnHead('Taxable', _fontScale, align: pw.TextAlign.right),
                                    if (!isInterState) ...[
                                      _buildMiniHsnHead('CGST', _fontScale, align: pw.TextAlign.right),
                                      _buildMiniHsnHead('SGST', _fontScale, align: pw.TextAlign.right),
                                    ] else
                                      _buildMiniHsnHead('IGST', _fontScale, align: pw.TextAlign.right),
                                  ],
                                ),
                                ...hsnMap.entries.map((e) {
                                  final hsn = e.key.split('-')[0];
                                  final data = e.value;
                                  return pw.TableRow(
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
                                    ),
                                    children: [
                                      _buildMiniHsnCell(hsn, _fontScale),
                                      _buildMiniHsnCell((data['taxable'] ?? 0).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                      if (!isInterState) ...[
                                        _buildMiniHsnCell((data['cgst'] ?? 0).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                        _buildMiniHsnCell((data['sgst'] ?? 0).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                      ] else
                                        _buildMiniHsnCell((data['igst'] ?? 0).toStringAsFixed(2), _fontScale, align: pw.TextAlign.right),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 6),
                        ],

                        // Bank Account Info (Only if enabled AND details present)
                        if (_showBankDetails && hasAnyBankDetails) ...[
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: lightBg,
                              border: pw.Border.all(color: borderColor),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'BANK & PAYMENT DETAILS',
                                  style: pw.TextStyle(
                                    fontSize: _fontScale * 0.75,
                                    fontWeight: pw.FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                if (currentBankName.isNotEmpty)
                                  pw.Text('Bank Name: $currentBankName',
                                      style: pw.TextStyle(fontSize: _fontScale * 0.85, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                if (currentAccountNo.isNotEmpty)
                                  pw.Text('Account No: $currentAccountNo',
                                      style: pw.TextStyle(fontSize: _fontScale * 0.85, color: primaryColor)),
                                if (currentIfsc.isNotEmpty)
                                  pw.Text('IFSC Code: $currentIfsc',
                                      style: pw.TextStyle(fontSize: _fontScale * 0.8, color: mutedColor)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 6),
                        ],

                        if (_showTerms)
                          pw.Text(
                            'Terms: 1. Goods once sold will not be accepted back. 2. Subject to local jurisdiction.',
                            style: pw.TextStyle(fontSize: _fontScale * 0.75, color: mutedColor),
                          ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 12),

                  // Grand Total Summary Box
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        border: pw.Border.all(color: borderColor),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        children: [
                          _buildPdfSummaryRow('Sub Total', 'Rs. ${subTotal.toStringAsFixed(2)}', _fontScale),
                          if (!isInterState) ...[
                            _buildPdfSummaryRow('CGST', 'Rs. ${totalCgst.toStringAsFixed(2)}', _fontScale),
                            _buildPdfSummaryRow('SGST', 'Rs. ${totalSgst.toStringAsFixed(2)}', _fontScale),
                          ] else
                            _buildPdfSummaryRow('IGST', 'Rs. ${totalIgst.toStringAsFixed(2)}', _fontScale),
                          if (sundries.isNotEmpty)
                            ...sundries.map((s) => _buildPdfSummaryRow(
                                  (s['name'] ?? 'Sundry').toString(),
                                  'Rs. ${(double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                  _fontScale,
                                )),
                          if (roundOff != 0.0)
                            _buildPdfSummaryRow('Round Off', 'Rs. ${roundOff.toStringAsFixed(2)}', _fontScale),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Divider(color: borderColor, thickness: 1),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Due',
                                  style: pw.TextStyle(
                                      fontSize: _fontScale * 1.15,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor)),
                              pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                      fontSize: _fontScale * 1.35,
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

              pw.SizedBox(height: 10),

              // Signature Bar
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: borderColor, width: 1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Receiver Signature',
                        style: pw.TextStyle(fontSize: _fontScale * 0.8, color: mutedColor)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('For ${companyName.isNotEmpty ? companyName : "Seller"}',
                            style: pw.TextStyle(
                                fontSize: _fontScale * 0.85,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.SizedBox(height: 20),
                        pw.Text('Authorized Signatory',
                            style: pw.TextStyle(fontSize: _fontScale * 0.8, color: mutedColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfMetaRow(String label, String val, double scale, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$label:', style: pw.TextStyle(fontSize: scale * 0.85, color: const PdfColor.fromInt(0xFF64748B))),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: scale * 0.9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: const PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfTableCell(String text, double scale,
      {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false, bool isBold = false, bool isMuted = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
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

  static pw.Widget _buildPdfSummaryRow(String label, String val, double scale) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: scale * 0.85, color: const PdfColor.fromInt(0xFF475569))),
          pw.Text(val, style: pw.TextStyle(fontSize: scale * 0.85, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
        ],
      ),
    );
  }

  static pw.Widget _buildMiniHsnHead(String title, double scale, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(title,
          textAlign: align,
          style: pw.TextStyle(fontSize: scale * 0.75, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
    );
  }

  static pw.Widget _buildMiniHsnCell(String val, double scale, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(val, textAlign: align, style: pw.TextStyle(fontSize: scale * 0.75, color: const PdfColor.fromInt(0xFF334155))),
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
              Icon(icon, size: 14, color: const Color(0xFF0F62FE)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMiniTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
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
            child: Switch(
              value: value,
              activeThumbColor: const Color(0xFF0F62FE),
              onChanged: onChanged,
            ),
          ),
        ],
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
                      color: const Color(0xFF0F62FE).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print_rounded, color: Color(0xFF0F62FE), size: 18),
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
                    width: 310,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFD),
                      border: Border(right: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        _buildSidebarCard(
                          title: 'BANK & PAYMENT DETAILS',
                          icon: Icons.account_balance_rounded,
                          children: [
                            _buildMiniTextField(
                              controller: _bankNameCtrl,
                              label: 'Bank Name',
                              hint: 'e.g., State Bank of India',
                            ),
                            _buildMiniTextField(
                              controller: _accountNoCtrl,
                              label: 'Account Number',
                              hint: 'e.g., 1029384756',
                            ),
                            _buildMiniTextField(
                              controller: _ifscCtrl,
                              label: 'IFSC Code',
                              hint: 'e.g., SBIN0001234',
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: _isSavingBankDetails ? null : _saveBankDetailsToCompany,
                                icon: _isSavingBankDetails
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save_rounded, size: 14, color: Colors.white),
                                label: const Text(
                                  'Save to Company Profile',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'COPY & PRESET',
                          icon: Icons.copy_all_rounded,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _invoiceCopy,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              items: const [
                                DropdownMenuItem(value: 'ORIGINAL FOR RECIPIENT', child: Text('Original for Recipient')),
                                DropdownMenuItem(value: 'DUPLICATE FOR TRANSPORTER', child: Text('Duplicate (Transporter)')),
                                DropdownMenuItem(value: 'TRIPLICATE FOR SUPPLIER', child: Text('Triplicate (Supplier)')),
                                DropdownMenuItem(value: 'EXTRA COPY', child: Text('Extra Copy')),
                              ],
                              onChanged: (val) => setState(() => _invoiceCopy = val ?? _invoiceCopy),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'PAGE & STYLING',
                          icon: Icons.auto_awesome_mosaic_rounded,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'Modern', label: Text('Modern', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                ButtonSegment(value: 'Classic', label: Text('Classic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                              selected: {_invoiceTheme},
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                selectedBackgroundColor: const Color(0xFF0F62FE),
                                selectedForegroundColor: Colors.white,
                              ),
                              onSelectionChanged: (val) => setState(() => _invoiceTheme = val.first),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isLandscape = !_isLandscape),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _isLandscape ? const Color(0xFF0F62FE).withValues(alpha: 0.1) : Colors.white,
                                      side: BorderSide(color: _isLandscape ? const Color(0xFF0F62FE) : const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(_isLandscape ? 'Landscape' : 'Portrait', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isLegalPaper = !_isLegalPaper),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _isLegalPaper ? const Color(0xFF0F62FE).withValues(alpha: 0.1) : Colors.white,
                                      side: BorderSide(color: _isLegalPaper ? const Color(0xFF0F62FE) : const Color(0xFFCBD5E1)),
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
                                Text('${_pageMargin.toInt()} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
                              ],
                            ),
                            Slider(
                              value: _pageMargin,
                              min: 10.0,
                              max: 36.0,
                              divisions: 13,
                              activeColor: const Color(0xFF0F62FE),
                              onChanged: (val) => setState(() => _pageMargin = val),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Font Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('${_fontScale.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
                              ],
                            ),
                            Slider(
                              value: _fontScale,
                              min: 7.5,
                              max: 10.5,
                              divisions: 6,
                              activeColor: const Color(0xFF0F62FE),
                              onChanged: (val) => setState(() => _fontScale = val),
                            ),
                          ],
                        ),

                        _buildSidebarCard(
                          title: 'CONTENT TOGGLES',
                          icon: Icons.visibility_rounded,
                          children: [
                            _buildToggleTile(
                              title: 'Show Bank Details',
                              value: _showBankDetails,
                              onChanged: (v) => setState(() => _showBankDetails = v),
                            ),
                            _buildToggleTile(
                              title: 'Show HSN/Tax Matrix',
                              value: _showHsnSummary,
                              onChanged: (v) => setState(() => _showHsnSummary = v),
                            ),
                            _buildToggleTile(
                              title: 'Show Terms & Notes',
                              value: _showTerms,
                              onChanged: (v) => setState(() => _showTerms = v),
                            ),
                            _buildToggleTile(
                              title: 'Zebra Striping',
                              value: _zebraStripes,
                              onChanged: (v) => setState(() => _zebraStripes = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        // 1. Controls that exact blue bar strip behind printer, share & switch icons
                        primaryColor: const Color(0xFF0F62FE), // <-- Change this to any color you want (e.g. const Color(0xFF0F172A), Colors.white, etc.)
                        
                        // 2. Material 3 surface & primary fallback
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: Colors.white, // Matches the bar background
                          onPrimary: const Color(0xFF0F62FE), // Color of the icons (printer, share)
                          surface: const Color(0xFFF1F5FB), // Background of the canvas area around the page
                        ),
                        
                        // 3. Icon and Switch controls styling
                        iconTheme: const IconThemeData(
                          color: Color(0xFF0F62FE), // Icon tint inside the bar
                        ),
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.all(const Color(0xFF0F62FE)),
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