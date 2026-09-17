import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_excel_export_service.dart';
import '../../../services/voucher_pdf_export_service.dart';

class VoucherListScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onClose;

  const VoucherListScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.fromDate,
    required this.toDate,
    required this.onClose,
  });

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  static const Map<String, String> _gstStateCodes = {
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra & Nagar Haveli and Daman & Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalHeaderCtrl = ScrollController();
  final ScrollController _horizontalBodyCtrl = ScrollController();
  final ScrollController _horizontalFooterCtrl = ScrollController();

  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  final Map<String, String> _columnLabels = {
    'sno': 'S.No.',
    'party': 'Party',
    'gstin': 'GSTIN',
    'pos': 'Place of Supply',
    'vchNo': 'Voc. No.',
    'date': 'Voc. Date',
    'qty': 'Qty.',
    'unit': 'Unit',
    'hsn': 'HSN',
    'invoiceVal': 'Invoice Value',
    'taxable': 'Taxable',
    'taxRate': 'Rate',
    'igst': 'IGST',
    'cgst': 'CGST',
    'sgst': 'SGST',
    'cess': 'Cess',
  };

  final Map<String, bool> _userSelectedColumns = {
    'sno': true,
    'party': true,
    'gstin': true,
    'pos': true,
    'vchNo': true,
    'date': true,
    'qty': true,
    'unit': true,
    'hsn': true,
    'invoiceVal': true,
    'taxable': true,
    'taxRate': true,
    'igst': true,
    'cgst': true,
    'sgst': true,
    'cess': true,
  };

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);

    _horizontalBodyCtrl.addListener(() {
      if (_horizontalHeaderCtrl.hasClients &&
          _horizontalHeaderCtrl.offset != _horizontalBodyCtrl.offset) {
        _horizontalHeaderCtrl.jumpTo(_horizontalBodyCtrl.offset);
      }
      if (_horizontalFooterCtrl.hasClients &&
          _horizontalFooterCtrl.offset != _horizontalBodyCtrl.offset) {
        _horizontalFooterCtrl.jumpTo(_horizontalBodyCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _horizontalHeaderCtrl.dispose();
    _horizontalBodyCtrl.dispose();
    _horizontalFooterCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseVchDate(String? raw) {
    if (raw == null) return null;
    final sanitized = raw.trim().replaceAll('/', '-').replaceAll('.', '-');
    final parts = sanitized.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _loadVouchers() async {
    final folderPath = widget.company['folderPath']?.toString();
    final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

    if (folderPath != null) {
      final allVouchers = await StorageService.loadVouchers(
        folderPath: folderPath,
        financialYear: fy,
        voucherType: widget.voucherType,
      );

      final matching = allVouchers.where((v) {
        final type = (v['voucherType'] ?? '').toString().toLowerCase();
        if (type != widget.voucherType.toLowerCase()) return false;

        final dt = _parseVchDate(v['date']?.toString());
        if (dt == null) return true;

        final afterStart = dt.isAfter(widget.fromDate.subtract(const Duration(seconds: 1)));
        final beforeEnd = dt.isBefore(widget.toDate.add(const Duration(days: 1)));
        return afterStart && beforeEnd;
      }).toList();

      if (mounted) {
        setState(() {
          _vouchers = matching;
          _filtered = matching;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _vouchers;
      } else {
        _filtered = _vouchers.where((v) {
          final vchNo = (v['voucherNumber'] ?? '').toString().toLowerCase();
          final party = (v['party'] ?? '').toString().toLowerCase();
          final date = (v['date'] ?? '').toString().toLowerCase();
          final gstin = _extractPartyGstin((v['party'] ?? '').toString()).toLowerCase();
          final items = v['items'] as List? ?? [];
          final hasItemMatch = items.any((it) {
            final hsn = (it['hsn'] ?? '').toString().toLowerCase();
            final name = (it['item'] ?? '').toString().toLowerCase();
            return hsn.contains(q) || name.contains(q);
          });
          return vchNo.contains(q) || party.contains(q) || date.contains(q) || gstin.contains(q) || hasItemMatch;
        }).toList();
      }
    });
  }

  String _extractPartyName(String fullParty) {
    final bracketIndex = fullParty.indexOf('[');
    if (bracketIndex != -1) {
      return fullParty.substring(0, bracketIndex).trim();
    }
    return fullParty.trim();
  }

  String _extractPartyGstin(String fullParty) {
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(fullParty);
    if (match != null) {
      return match.group(1)!.trim();
    }
    if (fullParty.trim().length == 15) {
      return fullParty.trim();
    }
    return '';
  }

  String _getPlaceOfSupply(String gstin, bool isInterState) {
    if (gstin.length >= 2) {
      final code = gstin.substring(0, 2);
      final state = _gstStateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    final compGst = (widget.company['gstin'] ?? '').toString().trim();
    if (!isInterState && compGst.length >= 2) {
      final code = compGst.substring(0, 2);
      final state = _gstStateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    return isInterState ? 'Inter-State' : 'Local';
  }

  double _extractCessAmount(Map<String, dynamic> voucher) {
    final sundries = voucher['sundries'] as List? ?? [];
    double cessTotal = 0.0;
    for (final s in sundries) {
      if (s is Map<String, dynamic>) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        if (name.contains('cess')) {
          final amt = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
          cessTotal += amt;
        }
      }
    }
    return cessTotal;
  }

  bool _hasEntries(String colKey) {
    if (_filtered.isEmpty) return true;

    switch (colKey) {
      case 'gstin':
        return _filtered.any((v) => _extractPartyGstin(v['party']?.toString() ?? '').isNotEmpty);
      case 'pos':
        return _filtered.any((v) => _getPlaceOfSupply(_extractPartyGstin(v['party']?.toString() ?? ''), v['isInterState'] == true).isNotEmpty);
      case 'hsn':
        return _filtered.any((v) {
          final items = v['items'] as List? ?? [];
          return items.any((i) => (i['hsn']?.toString() ?? '').trim().isNotEmpty);
        });
      case 'igst':
        return _filtered.any((v) {
          final val = double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0;
          return val > 0;
        });
      case 'cgst':
        return _filtered.any((v) {
          final val = double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0;
          return val > 0;
        });
      case 'sgst':
        return _filtered.any((v) {
          final val = double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0;
          return val > 0;
        });
      case 'cess':
        return _filtered.any((v) => _extractCessAmount(v) > 0);
      default:
        return true;
    }
  }

  bool _isColVisible(String colKey) {
    return (_userSelectedColumns[colKey] ?? true) && _hasEntries(colKey);
  }

  double get _totalQuantity {
    return _filtered.fold(0.0, (acc, v) {
      final items = v['items'] as List? ?? [];
      final itemSum = items.fold(0.0, (sum, i) => sum + (double.tryParse(i['qty']?.toString() ?? '0') ?? 0.0));
      return acc + itemSum;
    });
  }

  double get _totalInvoiceValue {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['grandTotal']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalTaxable {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['subTotal']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalIgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalCgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalSgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalCess {
    return _filtered.fold(0.0, (acc, item) => acc + _extractCessAmount(item));
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  double _calculateActiveMinWidth() {
    double w = 0;
    if (_isColVisible('sno')) w += 45;
    if (_isColVisible('party')) w += 160;
    if (_isColVisible('gstin')) w += 130;
    if (_isColVisible('pos')) w += 140;
    if (_isColVisible('vchNo')) w += 95;
    if (_isColVisible('date')) w += 85;
    if (_isColVisible('qty')) w += 65;
    if (_isColVisible('unit')) w += 50;
    if (_isColVisible('hsn')) w += 75;
    if (_isColVisible('invoiceVal')) w += 105;
    if (_isColVisible('taxable')) w += 95;
    if (_isColVisible('taxRate')) w += 55;
    if (_isColVisible('igst')) w += 80;
    if (_isColVisible('cgst')) w += 80;
    if (_isColVisible('sgst')) w += 80;
    if (_isColVisible('cess')) w += 75;
    return w;
  }

  void _openFileDirectly(String filePath) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [filePath]);
    }
  }

  Future<bool> _confirmOverwrite(String filePath) async {
    if (!await File(filePath).exists()) return true;

    final fileName = filePath.split(Platform.pathSeparator).last;
    final shouldOverwrite = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Text('File Already Exists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'A file named "$fileName" already exists in this folder.\n\nDo you want to overwrite it?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            child: const Text('Overwrite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return shouldOverwrite ?? false;
  }

  void _showExportSuccessDialog(String filePath, String fileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10A35B), size: 24),
            SizedBox(width: 8),
            Text('Export Successful', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fileType saved successfully:',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2EAF5)),
              ),
              child: SelectableText(
                filePath,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Do you want to open this file now?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openFileDirectly(filePath);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
            label: const Text('Open File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE)),
          ),
        ],
      ),
    );
  }

  void _openColumnSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.view_column_rounded, color: Color(0xFF0F62FE), size: 22),
                  SizedBox(width: 8),
                  Text('Customize Columns', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _columnLabels.keys.map((key) {
                      final hasData = _hasEntries(key);
                      final isChecked = _userSelectedColumns[key] ?? true;

                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: const Color(0xFF0F62FE),
                        dense: true,
                        title: Row(
                          children: [
                            Text(
                              _columnLabels[key]!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: hasData ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            if (!hasData) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5FB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'No entries',
                                  style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            _userSelectedColumns[key] = val ?? false;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      for (final k in _userSelectedColumns.keys) {
                        _userSelectedColumns[k] = true;
                      }
                    });
                    setState(() {});
                  },
                  child: const Text('Check All'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE)),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleExcelExport() async {
    try {
      final activeKeys = _columnLabels.keys.where((k) => _isColVisible(k)).toList();

      final savedPath = await VoucherExcelExportService.exportToExcel(
        company: widget.company,
        voucherType: widget.voucherType,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        filteredVouchers: _filtered,
        activeKeys: activeKeys,
        columnLabels: _columnLabels,
        extractPartyName: _extractPartyName,
        extractPartyGstin: _extractPartyGstin,
        getPlaceOfSupply: _getPlaceOfSupply,
        extractCessAmount: _extractCessAmount,
        formatDate: _formatDate,
        totalQuantity: _totalQuantity,
        totalInvoiceValue: _totalInvoiceValue,
        totalTaxable: _totalTaxable,
        totalIgst: _totalIgst,
        totalCgst: _totalCgst,
        totalSgst: _totalSgst,
        totalCess: _totalCess,
        onConfirmOverwrite: _confirmOverwrite,
      );

      if (savedPath != null && mounted) {
        _showExportSuccessDialog(savedPath, 'Excel Workbook (.xlsx)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFEE4343)),
        );
      }
    }
  }

  Future<void> _exportToJson() async {
    try {
      final exportDir = await VoucherExcelExportService.getOrChooseExportDirectory();
      if (exportDir == null) return;

      final fileName = '${widget.voucherType.replaceAll(' ', '_').toLowerCase()}_register.json';
      final filePath = '$exportDir${Platform.pathSeparator}$fileName';

      if (!await _confirmOverwrite(filePath)) return;

      final List<Map<String, dynamic>> exportedJson = _filtered.map((v) {
        final Map<String, dynamic> row = {};
        final fullParty = (v['party'] ?? '').toString();
        final gstin = _extractPartyGstin(fullParty);
        final isInterState = v['isInterState'] == true;

        if (_isColVisible('vchNo')) row['voucherNumber'] = v['voucherNumber'];
        if (_isColVisible('date')) row['date'] = v['date'];
        if (_isColVisible('party')) row['party'] = _extractPartyName(fullParty);
        if (_isColVisible('gstin')) row['gstin'] = gstin;
        if (_isColVisible('pos')) row['placeOfSupply'] = _getPlaceOfSupply(gstin, isInterState);
        if (_isColVisible('invoiceVal')) row['grandTotal'] = v['grandTotal'];
        if (_isColVisible('taxable')) row['subTotal'] = v['subTotal'];
        if (_isColVisible('igst')) row['igst'] = v['igst'];
        if (_isColVisible('cgst')) row['cgst'] = v['cgst'];
        if (_isColVisible('sgst')) row['sgst'] = v['sgst'];
        if (_isColVisible('cess')) row['cess'] = _extractCessAmount(v);

        final items = v['items'] as List? ?? [];
        row['items'] = items.map((i) {
          final Map<String, dynamic> itemMap = {};
          if (_isColVisible('qty')) itemMap['qty'] = i['qty'];
          if (_isColVisible('unit')) itemMap['unit'] = i['unit'];
          if (_isColVisible('hsn')) itemMap['hsn'] = i['hsn'];
          if (_isColVisible('taxable')) itemMap['taxable'] = i['taxable'];
          if (_isColVisible('taxRate')) itemMap['gstRate'] = i['gstRate'];
          if (_isColVisible('igst')) itemMap['igst'] = i['igst'];
          if (_isColVisible('cgst')) itemMap['cgst'] = i['cgst'];
          if (_isColVisible('sgst')) itemMap['sgst'] = i['sgst'];
          return itemMap;
        }).toList();

        return row;
      }).toList();

      final file = File(filePath);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportedJson));

      if (mounted) {
        _showExportSuccessDialog(filePath, 'JSON');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFEE4343)),
        );
      }
    }
  }

  // --- COMPREHENSIVE TWO-PANE PRINT STUDIO WITH STYLED TOOLBAR & CLIPPED RADIUS ---
  void _triggerPrint() {
    final activeKeys = _columnLabels.keys.where((k) => _isColVisible(k)).toList();

    double selectedMargin = 20.0;
    double columnScale = 1.0;
    double tableFontSize = 8.0;
    double borderWidth = 0.5;
    bool isLandscape = true;
    bool isLegal = false;
    bool showAddress = true;
    bool showDateRange = true;
    bool showSubtitle = true;
    bool alternateRowColors = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPrintDialogState) {
          PdfPageFormat getActiveFormat() {
            final base = isLegal ? PdfPageFormat.legal : PdfPageFormat.a4;
            return isLandscape ? base.landscape : base.portrait;
          }

          return Dialog(
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: math.min(MediaQuery.of(context).size.width * 0.96, 1380),
              height: math.min(MediaQuery.of(context).size.height * 0.94, 900),
              child: Column(
                children: [
                  // Top Suite Title Header
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F62FE).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF0F62FE)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Print Studio — ${widget.voucherType} Register',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF101C38)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5FB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isLegal ? 'Legal' : 'A4'} • ${isLandscape ? 'Landscape' : 'Portrait'}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE)),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setPrintDialogState(() {
                              selectedMargin = 20.0;
                              columnScale = 1.0;
                              tableFontSize = 8.0;
                              borderWidth = 0.5;
                              isLandscape = true;
                              isLegal = false;
                              showAddress = true;
                              showDateRange = true;
                              showSubtitle = true;
                              alternateRowColors = false;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF64748B)),
                          label: const Text('Reset Defaults', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7B9B)),
                          onPressed: () => Navigator.pop(ctx),
                          style: IconButton.styleFrom(hoverColor: const Color(0xFFFFECEC)),
                        ),
                      ],
                    ),
                  ),

                  // Studio Two-Pane Body
                  Expanded(
                    child: Row(
                      children: [
                        // LEFT SIDEBAR CONTROLS
                        Container(
                          width: 320,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFD),
                            border: Border(right: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                          ),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSidebarCard(
                                title: 'PAGE LAYOUT',
                                icon: Icons.description_rounded,
                                children: [
                                  _buildSidebarLabel('Orientation'),
                                  const SizedBox(height: 6),
                                  SegmentedButton<bool>(
                                    segments: const [
                                      ButtonSegment(value: true, label: Text('Landscape', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      ButtonSegment(value: false, label: Text('Portrait', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                    selected: {isLandscape},
                                    showSelectedIcon: false,
                                    style: SegmentedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      selectedBackgroundColor: const Color(0xFF0F62FE),
                                      selectedForegroundColor: Colors.white,
                                    ),
                                    onSelectionChanged: (val) => setPrintDialogState(() => isLandscape = val.first),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSidebarLabel('Paper Size'),
                                  const SizedBox(height: 6),
                                  SegmentedButton<bool>(
                                    segments: const [
                                      ButtonSegment(value: false, label: Text('A4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      ButtonSegment(value: true, label: Text('Legal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                    selected: {isLegal},
                                    showSelectedIcon: false,
                                    style: SegmentedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      selectedBackgroundColor: const Color(0xFF0F62FE),
                                      selectedForegroundColor: Colors.white,
                                    ),
                                    onSelectionChanged: (val) => setPrintDialogState(() => isLegal = val.first),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildSidebarCard(
                                title: 'PAGE MARGINS',
                                icon: Icons.border_outer_rounded,
                                children: [
                                  Row(
                                    children: [
                                      _buildSidebarLabel('Margin: ${selectedMargin.toInt()} pt'),
                                      const Spacer(),
                                      _buildPresetChip(
                                        label: 'Tight',
                                        isSelected: selectedMargin == 12.0,
                                        onTap: () => setPrintDialogState(() => selectedMargin = 12.0),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildPresetChip(
                                        label: 'Normal',
                                        isSelected: selectedMargin == 20.0,
                                        onTap: () => setPrintDialogState(() => selectedMargin = 20.0),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildPresetChip(
                                        label: 'Wide',
                                        isSelected: selectedMargin == 32.0,
                                        onTap: () => setPrintDialogState(() => selectedMargin = 32.0),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: selectedMargin,
                                    min: 8.0,
                                    max: 45.0,
                                    divisions: 37,
                                    activeColor: const Color(0xFF0F62FE),
                                    onChanged: (val) => setPrintDialogState(() => selectedMargin = val),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildSidebarCard(
                                title: 'TABLE SCALING',
                                icon: Icons.tune_rounded,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSidebarLabel('Party Width Flex'),
                                      Text('${(columnScale * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE))),
                                    ],
                                  ),
                                  Slider(
                                    value: columnScale,
                                    min: 0.8,
                                    max: 1.6,
                                    divisions: 8,
                                    activeColor: const Color(0xFF0F62FE),
                                    onChanged: (val) => setPrintDialogState(() => columnScale = val),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSidebarLabel('Font Size'),
                                      Text('${tableFontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE))),
                                    ],
                                  ),
                                  Slider(
                                    value: tableFontSize,
                                    min: 7.0,
                                    max: 10.5,
                                    divisions: 7,
                                    activeColor: const Color(0xFF0F62FE),
                                    onChanged: (val) => setPrintDialogState(() => tableFontSize = val),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildSidebarLabel('Grid Border'),
                                  const SizedBox(height: 6),
                                  SegmentedButton<double>(
                                    segments: const [
                                      ButtonSegment(value: 0.3, label: Text('Hairline', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      ButtonSegment(value: 0.5, label: Text('Normal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      ButtonSegment(value: 1.0, label: Text('Bold', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                    ],
                                    selected: {borderWidth},
                                    showSelectedIcon: false,
                                    style: SegmentedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      selectedBackgroundColor: const Color(0xFF0F62FE),
                                      selectedForegroundColor: Colors.white,
                                    ),
                                    onSelectionChanged: (val) => setPrintDialogState(() => borderWidth = val.first),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildSidebarCard(
                                title: 'DOCUMENT HEADERS',
                                icon: Icons.visibility_rounded,
                                children: [
                                  _buildToggleTile(
                                    title: 'Show Address',
                                    value: showAddress,
                                    onChanged: (v) => setPrintDialogState(() => showAddress = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Show Date Range',
                                    value: showDateRange,
                                    onChanged: (v) => setPrintDialogState(() => showDateRange = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Show Register Subtitle',
                                    value: showSubtitle,
                                    onChanged: (v) => setPrintDialogState(() => showSubtitle = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Zebra Row Fills',
                                    value: alternateRowColors,
                                    onChanged: (v) => setPrintDialogState(() => alternateRowColors = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // RIGHT PREVIEW CANVAS (Full Styled Toolbar & Rounded Corners)
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF1F5FB),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                appBarTheme: const AppBarTheme(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  iconTheme: IconThemeData(color: Color(0xFF0F62FE)),
                                ),
                                primaryColor: const Color(0xFF0F62FE),
                                scaffoldBackgroundColor: const Color(0xFFF1F5FB),
                              ),
                              child: PdfPreview(
                                build: (format) => VoucherPdfExportService.generateRegisterPdf(
                                  format: getActiveFormat(),
                                  company: widget.company,
                                  voucherType: widget.voucherType,
                                  fromDate: widget.fromDate,
                                  toDate: widget.toDate,
                                  filteredVouchers: _filtered,
                                  activeKeys: activeKeys,
                                  columnLabels: _columnLabels,
                                  extractPartyName: _extractPartyName,
                                  extractPartyGstin: _extractPartyGstin,
                                  getPlaceOfSupply: _getPlaceOfSupply,
                                  extractCessAmount: _extractCessAmount,
                                  formatDate: _formatDate,
                                  totalQuantity: _totalQuantity,
                                  totalInvoiceValue: _totalInvoiceValue,
                                  totalTaxable: _totalTaxable,
                                  totalIgst: _totalIgst,
                                  totalCgst: _totalCgst,
                                  totalSgst: _totalSgst,
                                  totalCess: _totalCess,
                                  pageMargin: selectedMargin,
                                  columnScale: columnScale,
                                  tableFontSize: tableFontSize,
                                  borderWidth: borderWidth,
                                  showAddress: showAddress,
                                  showDateRange: showDateRange,
                                  showSubtitle: showSubtitle,
                                  alternateRowColors: alternateRowColors,
                                ),
                                initialPageFormat: getActiveFormat(),
                                canChangePageFormat: false,
                                canChangeOrientation: false,
                                shouldRepaint: true,
                                allowPrinting: true,
                                allowSharing: true,
                                canDebug: false,
                                previewPageMargin: const EdgeInsets.all(20),
                                pdfFileName: '${widget.voucherType.replaceAll(' ', '_').toLowerCase()}_register.pdf',
                              ),
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
        },
      ),
    );
  }

  Widget _buildSidebarCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
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

  Widget _buildSidebarLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
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
              activeColor: const Color(0xFF0F62FE),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterRow({
    required String sno,
    required String party,
    required String gstin,
    required String pos,
    required String vchNo,
    required String date,
    required String qty,
    required String unit,
    required String hsn,
    required String invoiceValue,
    required String taxable,
    required String taxRate,
    required String igst,
    required String cgst,
    required String sgst,
    required String cess,
    required double rowWidth,
    bool isSubRow = false,
  }) {
    return Container(
      width: rowWidth,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: isSubRow ? const Color(0xFFFAFBFD) : Colors.white,
      ),
      child: Row(
        children: [
          if (_isColVisible('sno')) _DataCell(sno, width: 45, isMuted: true),
          if (_isColVisible('party'))
            Expanded(flex: 3, child: _DataCell(party, width: double.infinity, isBold: true)),
          if (_isColVisible('gstin'))
            Expanded(flex: 2, child: _DataCell(gstin, width: double.infinity, color: const Color(0xFF15803D))),
          if (_isColVisible('pos'))
            Expanded(flex: 2, child: _DataCell(pos, width: double.infinity)),
          if (_isColVisible('vchNo'))
            _DataCell(vchNo, width: 95, color: const Color(0xFF0F62FE), isBold: true),
          if (_isColVisible('date')) _DataCell(date, width: 85),
          if (_isColVisible('qty'))
            _DataCell(qty, width: 65, textAlign: TextAlign.right),
          if (_isColVisible('unit'))
            _DataCell(unit, width: 50, textAlign: TextAlign.center, isMuted: true),
          if (_isColVisible('hsn')) _DataCell(hsn, width: 75),
          if (_isColVisible('invoiceVal'))
            _DataCell(invoiceValue, width: 105, textAlign: TextAlign.right, isBold: true),
          if (_isColVisible('taxable'))
            _DataCell(taxable, width: 95, textAlign: TextAlign.right),
          if (_isColVisible('taxRate'))
            _DataCell(taxRate, width: 55, textAlign: TextAlign.right, isMuted: true),
          if (_isColVisible('igst'))
            _DataCell(igst != '0.00' ? igst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('cgst'))
            _DataCell(cgst != '0.00' ? cgst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('sgst'))
            _DataCell(sgst != '0.00' ? sgst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('cess'))
            _DataCell(cess != '0.00' && cess.isNotEmpty ? cess : '', width: 75, textAlign: TextAlign.right),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.voucherType.toUpperCase()} REGISTER',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD6E3F4)),
                  ),
                  child: Text(
                    'F.Y. $fy (${_formatDate(widget.fromDate)} to ${_formatDate(widget.toDate)})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF101C38)),
                  ),
                ),
                const Spacer(),
                _buildTopActionButton(
                  icon: Icons.view_column_rounded,
                  label: 'Columns',
                  color: const Color(0xFF0284C7),
                  onTap: _openColumnSettingsDialog,
                ),
                const SizedBox(width: 8),
                _buildTopActionButton(
                  icon: Icons.table_view_rounded,
                  label: 'Excel',
                  color: const Color(0xFF10A35B),
                  onTap: _handleExcelExport,
                ),
                const SizedBox(width: 8),
                _buildTopActionButton(
                  icon: Icons.data_object_rounded,
                  label: 'JSON',
                  color: const Color(0xFF7034E6),
                  onTap: _exportToJson,
                ),
                const SizedBox(width: 8),
                _buildTopActionButton(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: const Color(0xFF0F62FE),
                  onTap: _triggerPrint,
                ),
                const SizedBox(width: 14),
                const VerticalDivider(width: 1, indent: 14, endIndent: 14, color: Color(0xFFD6E3F4)),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7B9B)),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(hoverColor: const Color(0xFFFFECEC)),
                ),
              ],
            ),
          ),

          // Search & Metric Tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search by Voucher No, Party Name, GSTIN, HSN, Date...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Color(0xFF0F62FE)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickMetric(
                  label: 'Total Invoices',
                  value: '${_filtered.length}',
                  color: const Color(0xFF101B3A),
                ),
                const SizedBox(width: 8),
                _buildQuickMetric(
                  label: 'Total Qty',
                  value: _totalQuantity.toStringAsFixed(2),
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                _buildQuickMetric(
                  label: 'Taxable Val',
                  value: '₹${_totalTaxable.toStringAsFixed(2)}',
                  color: const Color(0xFF7034E6),
                ),
                const SizedBox(width: 8),
                _buildQuickMetric(
                  label: 'Invoice Total',
                  value: '₹${_totalInvoiceValue.toStringAsFixed(2)}',
                  color: const Color(0xFF0F62FE),
                ),
              ],
            ),
          ),

          // Main Table View
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x04092B60), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double activeMinWidth = _calculateActiveMinWidth();
                    final double dynamicTableWidth = math.max(constraints.maxWidth, activeMinWidth);

                    return Column(
                      children: [
                        // Table Headers
                        SingleChildScrollView(
                          controller: _horizontalHeaderCtrl,
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            width: dynamicTableWidth,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFD),
                              border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                            ),
                            child: Row(
                              children: [
                                if (_isColVisible('sno')) const _HeaderCell('S.No.', width: 45),
                                if (_isColVisible('party'))
                                  const Expanded(flex: 3, child: _HeaderCell('Party', width: double.infinity)),
                                if (_isColVisible('gstin'))
                                  const Expanded(flex: 2, child: _HeaderCell('GSTIN', width: double.infinity)),
                                if (_isColVisible('pos'))
                                  const Expanded(flex: 2, child: _HeaderCell('Place of Supply', width: double.infinity)),
                                if (_isColVisible('vchNo')) const _HeaderCell('Voc. No.', width: 95),
                                if (_isColVisible('date')) const _HeaderCell('Voc. Date', width: 85),
                                if (_isColVisible('qty'))
                                  const _HeaderCell('Qty.', width: 65, textAlign: TextAlign.right),
                                if (_isColVisible('unit'))
                                  const _HeaderCell('Unit', width: 50, textAlign: TextAlign.center),
                                if (_isColVisible('hsn')) const _HeaderCell('HSN', width: 75),
                                if (_isColVisible('invoiceVal'))
                                  const _HeaderCell('Invoice Value', width: 105, textAlign: TextAlign.right),
                                if (_isColVisible('taxable'))
                                  const _HeaderCell('Taxable', width: 95, textAlign: TextAlign.right),
                                if (_isColVisible('taxRate'))
                                  const _HeaderCell('Rate', width: 55, textAlign: TextAlign.right),
                                if (_isColVisible('igst'))
                                  const _HeaderCell('IGST', width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('cgst'))
                                  const _HeaderCell('CGST', width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('sgst'))
                                  const _HeaderCell('SGST', width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('cess'))
                                  const _HeaderCell('Cess', width: 75, textAlign: TextAlign.right),
                              ],
                            ),
                          ),
                        ),

                        // Table Body Rows
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F62FE)))
                              : _filtered.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.inbox_rounded, size: 44, color: Color(0xFF90A1BA)),
                                          SizedBox(height: 8),
                                          Text(
                                            'No matching vouchers found.',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      controller: _horizontalBodyCtrl,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: dynamicTableWidth,
                                        child: ListView.separated(
                                          itemCount: _filtered.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                                          itemBuilder: (context, idx) {
                                            final v = _filtered[idx];
                                            final vchNo = v['voucherNumber'] ?? '';
                                            final date = v['date'] ?? '';
                                            final fullParty = (v['party'] ?? '').toString();
                                            final partyName = _extractPartyName(fullParty);
                                            final gstin = _extractPartyGstin(fullParty);
                                            final isInterState = v['isInterState'] == true;
                                            final pos = _getPlaceOfSupply(gstin, isInterState);
                                            final invoiceTotal = double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;
                                            final cessTotal = _extractCessAmount(v);
                                            final items = v['items'] as List? ?? [];

                                            if (items.isEmpty) {
                                              return _buildRegisterRow(
                                                sno: '${idx + 1}',
                                                party: partyName,
                                                gstin: gstin,
                                                pos: pos,
                                                vchNo: vchNo.toString(),
                                                date: date.toString(),
                                                qty: '0.00',
                                                unit: 'Pcs',
                                                hsn: '',
                                                invoiceValue: invoiceTotal.toStringAsFixed(2),
                                                taxable: '0.00',
                                                taxRate: '0%',
                                                igst: (double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                cgst: (double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                sgst: (double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                cess: cessTotal.toStringAsFixed(2),
                                                rowWidth: dynamicTableWidth,
                                              );
                                            }

                                            return Column(
                                              children: List.generate(items.length, (itemIdx) {
                                                final item = items[itemIdx];
                                                final qty = (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                final unit = item['unit'] ?? 'Pcs';
                                                final hsn = (item['hsn'] ?? '').toString();
                                                final taxable = (double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                final taxRate = '${item['gstRate'] ?? 0}%';
                                                final igstVal = (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                final cgstVal = (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                final sgstVal = (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);

                                                return _buildRegisterRow(
                                                  sno: itemIdx == 0 ? '${idx + 1}' : '',
                                                  party: itemIdx == 0 ? partyName : '',
                                                  gstin: itemIdx == 0 ? gstin : '',
                                                  pos: itemIdx == 0 ? pos : '',
                                                  vchNo: itemIdx == 0 ? vchNo.toString() : '',
                                                  date: itemIdx == 0 ? date.toString() : '',
                                                  qty: qty,
                                                  unit: unit.toString(),
                                                  hsn: hsn,
                                                  invoiceValue: itemIdx == 0 ? invoiceTotal.toStringAsFixed(2) : '',
                                                  taxable: taxable,
                                                  taxRate: taxRate,
                                                  igst: igstVal,
                                                  cgst: cgstVal,
                                                  sgst: sgstVal,
                                                  cess: itemIdx == 0 ? cessTotal.toStringAsFixed(2) : '',
                                                  isSubRow: itemIdx > 0,
                                                  rowWidth: dynamicTableWidth,
                                                );
                                              }),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                        ),

                        // Footer Totals Row
                        SingleChildScrollView(
                          controller: _horizontalFooterCtrl,
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            width: dynamicTableWidth,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5FB),
                              border: Border(top: BorderSide(color: Color(0xFFD6E3F4), width: 1.2)),
                            ),
                            child: Row(
                              children: [
                                if (_isColVisible('sno')) const _FooterCell('', width: 45),
                                if (_isColVisible('party'))
                                  const Expanded(flex: 3, child: _FooterCell('TOTAL', width: double.infinity)),
                                if (_isColVisible('gstin'))
                                  const Expanded(flex: 2, child: _FooterCell('', width: double.infinity)),
                                if (_isColVisible('pos'))
                                  const Expanded(flex: 2, child: _FooterCell('', width: double.infinity)),
                                if (_isColVisible('vchNo')) const _FooterCell('', width: 95),
                                if (_isColVisible('date')) const _FooterCell('', width: 85),
                                if (_isColVisible('qty'))
                                  _FooterCell(_totalQuantity.toStringAsFixed(2), width: 65, textAlign: TextAlign.right),
                                if (_isColVisible('unit')) const _FooterCell('', width: 50),
                                if (_isColVisible('hsn')) const _FooterCell('', width: 75),
                                if (_isColVisible('invoiceVal'))
                                  _FooterCell(
                                    _totalInvoiceValue.toStringAsFixed(2),
                                    width: 105,
                                    textAlign: TextAlign.right,
                                    highlight: true,
                                  ),
                                if (_isColVisible('taxable'))
                                  _FooterCell(_totalTaxable.toStringAsFixed(2), width: 95, textAlign: TextAlign.right),
                                if (_isColVisible('taxRate')) const _FooterCell('', width: 55),
                                if (_isColVisible('igst'))
                                  _FooterCell(_totalIgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('cgst'))
                                  _FooterCell(_totalCgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('sgst'))
                                  _FooterCell(_totalSgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                if (_isColVisible('cess'))
                                  _FooterCell(_totalCess.toStringAsFixed(2), width: 75, textAlign: TextAlign.right),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;

  const _HeaderCell(this.text, {required this.width, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;
  final bool isBold;
  final bool isMuted;
  final Color? color;

  const _DataCell(
    this.text, {
    required this.width,
    this.textAlign = TextAlign.left,
    this.isBold = false,
    this.isMuted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? (isMuted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FooterCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;
  final bool highlight;

  const _FooterCell(this.text, {required this.width, this.textAlign = TextAlign.left, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: highlight ? const Color(0xFF0F62FE) : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}