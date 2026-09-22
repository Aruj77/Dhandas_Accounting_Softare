import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../constants/app_colors.dart';
import '../../../models/register_summary.dart';
import '../../../provider/sync_provider.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_excel_export_service.dart';
import '../../../services/voucher_pdf_export_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/export_dialog_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../widgets/common/data_table_cells.dart';
import '../../../widgets/common/quick_metric_badge.dart';
import 'voucher_entry_screen.dart';
import '../../../services/loading_service.dart';

class VoucherListScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final DateTime fromDate;
  final DateTime toDate;
  final String initialSeries;
  final VoidCallback onClose;

  const VoucherListScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.fromDate,
    required this.toDate,
    this.initialSeries = 'All',
    required this.onClose,
  });

  @override
  ConsumerState<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends ConsumerState<VoucherListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _horizontalHeaderCtrl = ScrollController();
  final _bodyHorizontalScrollCtrl = ScrollController();
  final _horizontalFooterCtrl = ScrollController();

  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  int _focusedIndex = -1;
  List<FocusNode> _rowFocusNodes = [];
  late String _selectedSeries;
  List<String> _availableSeries = ['All', 'Main'];

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

  late final Map<String, bool> _userSelectedColumns = {
    for (final k in _columnLabels.keys) k: true
  };

  RegisterSummary get _summary => RegisterSummary.fromVouchers(_filtered);

  String _getPos(String gstin, bool isInterState) => GstPartyUtils.getPlaceOfSupply(
        gstin,
        isInterState,
        companyGstin: (widget.company['gstin'] ?? '').toString(),
      );

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.initialSeries.trim().isEmpty ? 'All' : widget.initialSeries.trim();
    _loadAvailableSeries();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);
    _bodyHorizontalScrollCtrl.addListener(() {
      for (final ctrl in [_horizontalHeaderCtrl, _horizontalFooterCtrl]) {
        if (ctrl.hasClients && ctrl.offset != _bodyHorizontalScrollCtrl.offset) {
          ctrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncWorker = ref.read(syncWorkerProvider);
      syncWorker?.onRemoteMutationReceived = () {
        if (mounted) {
          _loadVouchers();
        }
      };
    });
  }

  Future<void> _loadAvailableSeries() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath']?.toString();
      final seriesSet = <String>{'All', 'Main'};
      if (_selectedSeries != 'All') {
        seriesSet.add(_selectedSeries);
      }
      if (folderPath != null) {
        try {
          final rawMasters = await StorageService.loadCompanyMasters(folderPath: folderPath);
          final loaded = rawMasters['series'] as List? ?? [];
          for (final s in loaded) {
            if (s != null && s.toString().trim().isNotEmpty) {
              seriesSet.add(s.toString().trim());
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _availableSeries = seriesSet.toList();
        });
      }
    }, message: '');
  }

  @override
  void dispose() {
    final syncWorker = ref.read(syncWorkerProvider);
    if (syncWorker?.onRemoteMutationReceived != null) {
      syncWorker?.onRemoteMutationReceived = null;
    }

    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _horizontalHeaderCtrl.dispose();
    _bodyHorizontalScrollCtrl.dispose();
    _horizontalFooterCtrl.dispose();
    for (final n in _rowFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes() {
    for (final n in _rowFocusNodes) {
      n.dispose();
    }
    _rowFocusNodes = List.generate(_filtered.length, (i) => FocusNode(debugLabel: 'VoucherRow_$i'));
  }

  Future<void> _loadVouchers() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath']?.toString();
      final fy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();

      if (folderPath != null) {
        final allVouchers = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: fy,
        );

        final targetType = widget.voucherType.toLowerCase().trim();

        for (final v in allVouchers) {
          final s = (v['series'] ?? v['seriesName'] ?? '').toString().trim();
          if (s.isNotEmpty && !_availableSeries.contains(s)) {
            _availableSeries.add(s);
          }
        }

        final matching = allVouchers.where((v) {
          final vchType = (v['voucherType'] ?? '').toString().toLowerCase().trim();
          bool typeMatches = vchType.isEmpty ||
              vchType == targetType ||
              vchType.contains(targetType) ||
              targetType.contains(vchType);
          if (!typeMatches) return false;

          if (_selectedSeries.toLowerCase() != 'all') {
            final rawSeries = (v['series'] ?? v['seriesName'] ?? '').toString().trim();
            final voucherSeries = rawSeries.isEmpty ? 'Main' : rawSeries;
            if (voucherSeries.toLowerCase() != _selectedSeries.toLowerCase()) {
              return false;
            }
          }

          final dt = AppDateUtils.parseDate(v['date']?.toString());
          if (dt == null) return true;

          final start = DateTime(widget.fromDate.year, widget.fromDate.month, widget.fromDate.day);
          final end = DateTime(widget.toDate.year, widget.toDate.month, widget.toDate.day, 23, 59, 59);

          return (dt.isAtSameMomentAs(start) || dt.isAfter(start)) &&
              (dt.isAtSameMomentAs(end) || dt.isBefore(end));
        }).toList();

        if (mounted) {
          setState(() {
            _vouchers = matching;
            _filtered = matching;
            _isLoading = false;
            _syncFocusNodes();
            _focusedIndex = matching.isNotEmpty ? 0 : -1;
          });

          if (_rowFocusNodes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _rowFocusNodes.isNotEmpty && _rowFocusNodes[0].canRequestFocus) {
                _rowFocusNodes[0].requestFocus();
              }
            });
          }
        }
      }
    }, message: 'Loading ${widget.voucherType} register...');
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _vouchers
          : _vouchers.where((v) {
              final vch = (v['voucherNumber'] ?? '').toString().toLowerCase();
              final party = (v['party'] ?? '').toString().toLowerCase();
              final gstin = GstPartyUtils.extractPartyGstin((v['party'] ?? '').toString()).toLowerCase();
              final items = (v['items'] as List? ?? []);
              return vch.contains(q) ||
                  party.contains(q) ||
                  gstin.contains(q) ||
                  items.any((it) =>
                      (it['hsn'] ?? '').toString().toLowerCase().contains(q) ||
                      (it['item'] ?? '').toString().toLowerCase().contains(q));
            }).toList();
      _syncFocusNodes();
      _focusedIndex = _filtered.isNotEmpty ? 0 : -1;
    });

    if (_rowFocusNodes.isNotEmpty && !_searchFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _rowFocusNodes.isNotEmpty && _rowFocusNodes[0].canRequestFocus) {
          _rowFocusNodes[0].requestFocus();
        }
      });
    }
  }

  bool _hasEntries(String colKey) {
    if (_filtered.isEmpty) return true;

    switch (colKey) {
      case 'gstin':
        return _filtered.any((v) => GstPartyUtils.extractPartyGstin(v['party']?.toString() ?? '').isNotEmpty);
      case 'pos':
        return _filtered.any((v) => _getPos(GstPartyUtils.extractPartyGstin(v['party']?.toString() ?? ''), v['isInterState'] == true).isNotEmpty);
      case 'hsn':
        return _filtered.any((v) => (v['items'] as List? ?? []).any((i) => (i['hsn']?.toString() ?? '').trim().isNotEmpty));
      case 'igst':
        return _filtered.any((v) => (double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0) > 0);
      case 'cgst':
        return _filtered.any((v) => (double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0) > 0);
      case 'sgst':
        return _filtered.any((v) => (double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0) > 0);
      case 'cess':
        return _filtered.any((v) => GstPartyUtils.extractCessAmount(v) > 0);
      default:
        return true;
    }
  }

  bool _isColVisible(String k) {
    return (_userSelectedColumns[k] ?? true) && _hasEntries(k);
  }

  double _calculateActiveMinWidth() {
    const weights = {
      'sno': 45.0, 'party': 160.0, 'gstin': 130.0, 'pos': 140.0, 'vchNo': 95.0,
      'date': 85.0, 'qty': 65.0, 'unit': 50.0, 'hsn': 75.0, 'invoiceVal': 105.0,
      'taxable': 95.0, 'taxRate': 55.0, 'igst': 80.0, 'cgst': 80.0, 'sgst': 80.0, 'cess': 75.0
    };
    return _columnLabels.keys.where(_isColVisible).fold(0.0, (w, k) => w + (weights[k] ?? 80.0));
  }

  Future<void> _handleExcelExport() async {
    try {
      final activeKeys = _columnLabels.keys.where(_isColVisible).toList();

      final savedPath = await VoucherExcelExportService.exportToExcel(
        company: widget.company,
        voucherType: widget.voucherType,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        filteredVouchers: _filtered,
        activeKeys: activeKeys,
        columnLabels: _columnLabels,
        extractPartyName: GstPartyUtils.extractPartyName,
        extractPartyGstin: GstPartyUtils.extractPartyGstin,
        getPlaceOfSupply: _getPos,
        extractCessAmount: GstPartyUtils.extractCessAmount,
        formatDate: AppDateUtils.formatDate,
        totalQuantity: _summary.totalQuantity,
        totalInvoiceValue: _summary.totalInvoiceValue,
        totalTaxable: _summary.totalTaxable,
        totalIgst: _summary.totalIgst,
        totalCgst: _summary.totalCgst,
        totalSgst: _summary.totalSgst,
        totalCess: _summary.totalCess,
        onConfirmOverwrite: (p) => ExportDialogUtils.confirmOverwrite(context, p),
      );
      if (savedPath != null && mounted) {
        ExportDialogUtils.showSuccessDialog(context, savedPath, 'Excel Workbook (.xlsx)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportToJson() async {
    await LoadingService.wrap(() async {
      try {
        final dir = await VoucherExcelExportService.getOrChooseExportDirectory();
        if (dir == null) return;
        final file = File('$dir${Platform.pathSeparator}${widget.voucherType.replaceAll(' ', '_').toLowerCase()}_register.json');
        if (!await ExportDialogUtils.confirmOverwrite(context, file.path)) return;

        final data = _filtered.map((v) => {
          'voucherNumber': v['voucherNumber'],
          'date': v['date'],
          'series': v['series'],
          'party': GstPartyUtils.extractPartyName((v['party'] ?? '').toString()),
          'gstin': GstPartyUtils.extractPartyGstin((v['party'] ?? '').toString()),
          'grandTotal': v['grandTotal'],
          'subTotal': v['subTotal'],
          'items': (v['items'] as List? ?? []).map((i) => {
            'qty': i['qty'], 'unit': i['unit'], 'hsn': i['hsn'], 'taxable': i['taxable'], 'gstRate': i['gstRate']
          }).toList(),
        }).toList();

        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
        if (mounted) ExportDialogUtils.showSuccessDialog(context, file.path, 'JSON');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }, message: 'Generating JSON File...');
  }

  Future<void> _openEdit(Map<String, dynamic> voucher) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoucherEntryScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          voucherToEdit: voucher,
          isEdit: true,
          keyboardSettings: KeyboardShortcutSettings.defaults(),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) {
      await _loadVouchers();
    }
  }

  void _openColumnSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.view_column_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Customize Columns', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Row(
                      children: [
                        Text(
                          _columnLabels[key]!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: hasData ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ),
                        if (!hasData) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('No entries', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    onChanged: (val) {
                      setDialogState(() => _userSelectedColumns[key] = val ?? false);
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
              child: const Text('Check All', style: TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Apply', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerPrint() {
    final activeKeys = _columnLabels.keys.where(_isColVisible).toList();
    double selectedMargin = 20.0, columnScale = 1.0, tableFontSize = 8.0, borderWidth = 0.5;
    bool isLandscape = true, isLegal = false, showAddress = true, showDateRange = true, showSubtitle = true, alternateRowColors = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPrintDialogState) {
          PdfPageFormat getActiveFormat() {
            final base = isLegal ? PdfPageFormat.legal : PdfPageFormat.a4;
            return isLandscape ? base.landscape : base.portrait;
          }

          Widget buildSidebarCard(String title, IconData icon, List<Widget> children) => Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(icon, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 0.5))]),
                    const SizedBox(height: 10),
                    ...children,
                  ],
                ),
              );

          return Dialog(
            backgroundColor: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: math.min(MediaQuery.of(context).size.width * 0.96, 1380),
              height: math.min(MediaQuery.of(context).size.height * 0.94, 900),
              child: Column(
                children: [
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2))),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary)),
                        const SizedBox(width: 10),
                        Text('Print Studio — ${widget.voucherType} Register', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)), child: Text('${isLegal ? 'Legal' : 'A4'} • ${isLandscape ? 'Landscape' : 'Portrait'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary))),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setPrintDialogState(() {
                            selectedMargin = 20.0; columnScale = 1.0; tableFontSize = 8.0; borderWidth = 0.5;
                            isLandscape = true; isLegal = false; showAddress = true; showDateRange = true; showSubtitle = true; alternateRowColors = false;
                          }),
                          icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.textSecondary),
                          label: const Text('Reset Defaults', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 320,
                          decoration: const BoxDecoration(color: AppColors.cardBg, border: Border(right: BorderSide(color: AppColors.border, width: 1.2))),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              buildSidebarCard('PAGE LAYOUT', Icons.description_rounded, [
                                const Text('Orientation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                SegmentedButton<bool>(
                                  segments: const [ButtonSegment(value: true, label: Text('Landscape', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), ButtonSegment(value: false, label: Text('Portrait', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))],
                                  selected: {isLandscape},
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.primary, selectedForegroundColor: AppColors.surface),
                                  onSelectionChanged: (val) => setPrintDialogState(() => isLandscape = val.first),
                                ),
                                const SizedBox(height: 12),
                                const Text('Paper Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                SegmentedButton<bool>(
                                  segments: const [ButtonSegment(value: false, label: Text('A4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), ButtonSegment(value: true, label: Text('Legal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))],
                                  selected: {isLegal},
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.primary, selectedForegroundColor: AppColors.surface),
                                  onSelectionChanged: (val) => setPrintDialogState(() => isLegal = val.first),
                                ),
                              ]),
                              buildSidebarCard('PAGE MARGINS', Icons.border_outer_rounded, [
                                Row(children: [Text('Margin: ${selectedMargin.toInt()} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), const Spacer()]),
                                Slider(value: selectedMargin, min: 8.0, max: 45.0, divisions: 37, activeColor: AppColors.primary, onChanged: (val) => setPrintDialogState(() => selectedMargin = val)),
                              ]),
                              buildSidebarCard('TABLE SCALING', Icons.tune_rounded, [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Party Flex', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), Text('${(columnScale * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary))]),
                                Slider(value: columnScale, min: 0.8, max: 1.6, divisions: 8, activeColor: AppColors.primary, onChanged: (val) => setPrintDialogState(() => columnScale = val)),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Font Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), Text('${tableFontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary))]),
                                Slider(value: tableFontSize, min: 7.0, max: 10.5, divisions: 7, activeColor: AppColors.primary, onChanged: (val) => setPrintDialogState(() => tableFontSize = val)),
                              ]),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: AppColors.background,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, elevation: 0, iconTheme: IconThemeData(color: AppColors.primary)),
                                primaryColor: AppColors.primary,
                                scaffoldBackgroundColor: AppColors.background,
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
                                  extractPartyName: GstPartyUtils.extractPartyName,
                                  extractPartyGstin: GstPartyUtils.extractPartyGstin,
                                  getPlaceOfSupply: _getPos,
                                  extractCessAmount: GstPartyUtils.extractCessAmount,
                                  formatDate: AppDateUtils.formatDate,
                                  totalQuantity: _summary.totalQuantity,
                                  totalInvoiceValue: _summary.totalInvoiceValue,
                                  totalTaxable: _summary.totalTaxable,
                                  totalIgst: _summary.totalIgst,
                                  totalCgst: _summary.totalCgst,
                                  totalSgst: _summary.totalSgst,
                                  totalCess: _summary.totalCess,
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
                                allowPrinting: true,
                                allowSharing: true,
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
      decoration: BoxDecoration(color: isSubRow ? AppColors.cardBg : Colors.transparent),
      child: Row(
        children: [
          if (_isColVisible('sno')) RegisterDataCell(sno, width: 45, isMuted: true),
          if (_isColVisible('party')) Expanded(flex: 3, child: RegisterDataCell(party, width: double.infinity, isBold: true)),
          if (_isColVisible('gstin')) Expanded(flex: 2, child: RegisterDataCell(gstin, width: double.infinity, color: AppColors.successDark)),
          if (_isColVisible('pos')) Expanded(flex: 2, child: RegisterDataCell(pos, width: double.infinity)),
          if (_isColVisible('vchNo')) RegisterDataCell(vchNo, width: 95, color: AppColors.primary, isBold: true),
          if (_isColVisible('date')) RegisterDataCell(date, width: 85),
          if (_isColVisible('qty')) RegisterDataCell(qty, width: 65, textAlign: TextAlign.right),
          if (_isColVisible('unit')) RegisterDataCell(unit, width: 50, textAlign: TextAlign.center, isMuted: true),
          if (_isColVisible('hsn')) RegisterDataCell(hsn, width: 75),
          if (_isColVisible('invoiceVal')) RegisterDataCell(invoiceValue, width: 105, textAlign: TextAlign.right, isBold: true),
          if (_isColVisible('taxable')) RegisterDataCell(taxable, width: 95, textAlign: TextAlign.right),
          if (_isColVisible('taxRate')) RegisterDataCell(taxRate, width: 55, textAlign: TextAlign.right, isMuted: true),
          if (_isColVisible('igst')) RegisterDataCell(igst != '0.00' ? igst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('cgst')) RegisterDataCell(cgst != '0.00' ? cgst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('sgst')) RegisterDataCell(sgst != '0.00' ? sgst : '', width: 80, textAlign: TextAlign.right),
          if (_isColVisible('cess')) RegisterDataCell(cess != '0.00' && cess.isNotEmpty ? cess : '', width: 75, textAlign: TextAlign.right),
        ],
      ),
    );
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (KeyboardShortcutService.isExit(event.logicalKey)) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isPrint(event)) {
      _triggerPrint();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isExportExcel(event)) {
      _handleExcelExport();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isExportJson(event)) {
      _exportToJson();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.isColumnsDialog(event)) {
      _openColumnSettingsDialog();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear;
    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherList,
      nodeMap: {
        FocusFieldNode.searchField: _searchFocusNode,
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleGlobalKeyEvent,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryAccent, AppColors.primary]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.surface),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.voucherType.toUpperCase()} REGISTER',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.surface,
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
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderFocus),
                      ),
                      child: Text(
                        'F.Y. $fy (${AppDateUtils.formatDate(widget.fromDate)} to ${AppDateUtils.formatDate(widget.toDate)})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableSeries.contains(_selectedSeries) ? _selectedSeries : 'All',
                          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primary),
                          items: _availableSeries.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == 'All' ? 'Series: All' : 'Series: $s',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null && val != _selectedSeries) {
                              setState(() {
                                _selectedSeries = val;
                                _isLoading = true;
                              });
                              _loadVouchers();
                            }
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openColumnSettingsDialog,
                      icon: const Icon(Icons.view_column_rounded, size: 16, color: AppColors.info),
                      label: const Text('Columns (Ctrl+Q)', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _handleExcelExport,
                      icon: const Icon(Icons.table_view_rounded, size: 16, color: AppColors.success),
                      label: const Text('Excel (Ctrl+E)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _exportToJson,
                      icon: const Icon(Icons.data_object_rounded, size: 16, color: AppColors.purple),
                      label: const Text('JSON (Ctrl+J)', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _triggerPrint,
                      icon: const Icon(Icons.print_rounded, size: 16, color: AppColors.primary),
                      label: const Text('Print (Ctrl+P)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
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
                          focusNode: _searchFocusNode,
                          onSubmitted: (_) {
                            if (_rowFocusNodes.isNotEmpty && _rowFocusNodes[0].canRequestFocus) {
                              _rowFocusNodes[0].requestFocus();
                              setState(() => _focusedIndex = 0);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by Voucher, Party, GSTIN, HSN...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    QuickMetricBadge(label: 'Total Invoices', value: '${_summary.totalInvoices}', color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Total Qty', value: _summary.totalQuantity.toStringAsFixed(2), color: AppColors.info),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Taxable Val', value: '₹${_summary.totalTaxable.toStringAsFixed(2)}', color: AppColors.purple),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Invoice Total', value: '₹${_summary.totalInvoiceValue.toStringAsFixed(2)}', color: AppColors.primary),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dynamicWidth = math.max(constraints.maxWidth, _calculateActiveMinWidth());
                        return Column(
                          children: [
                            SingleChildScrollView(
                              controller: _horizontalHeaderCtrl,
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: dynamicWidth,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.cardBg,
                                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
                                ),
                                child: Row(
                                  children: [
                                    if (_isColVisible('sno')) const RegisterHeaderCell('S.No.', width: 45),
                                    if (_isColVisible('party')) const Expanded(flex: 3, child: RegisterHeaderCell('Party', width: double.infinity)),
                                    if (_isColVisible('gstin')) const Expanded(flex: 2, child: RegisterHeaderCell('GSTIN', width: double.infinity)),
                                    if (_isColVisible('pos')) const Expanded(flex: 2, child: RegisterHeaderCell('Place of Supply', width: double.infinity)),
                                    if (_isColVisible('vchNo')) const RegisterHeaderCell('Voc. No.', width: 95),
                                    if (_isColVisible('date')) const RegisterHeaderCell('Voc. Date', width: 85),
                                    if (_isColVisible('qty')) const RegisterHeaderCell('Qty.', width: 65, textAlign: TextAlign.right),
                                    if (_isColVisible('unit')) const RegisterHeaderCell('Unit', width: 50, textAlign: TextAlign.center),
                                    if (_isColVisible('hsn')) const RegisterHeaderCell('HSN', width: 75),
                                    if (_isColVisible('invoiceVal')) const RegisterHeaderCell('Invoice Value', width: 105, textAlign: TextAlign.right),
                                    if (_isColVisible('taxable')) const RegisterHeaderCell('Taxable', width: 95, textAlign: TextAlign.right),
                                    if (_isColVisible('taxRate')) const RegisterHeaderCell('Rate', width: 55, textAlign: TextAlign.right),
                                    if (_isColVisible('igst')) const RegisterHeaderCell('IGST', width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('cgst')) const RegisterHeaderCell('CGST', width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('sgst')) const RegisterHeaderCell('SGST', width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('cess')) const RegisterHeaderCell('Cess', width: 75, textAlign: TextAlign.right),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                  : _filtered.isEmpty
                                      ? const Center(child: Text('No matching vouchers found.'))
                                      : SingleChildScrollView(
                                          controller: _bodyHorizontalScrollCtrl,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: dynamicWidth,
                                            child: ListView.separated(
                                              itemCount: _filtered.length,
                                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                                              itemBuilder: (context, idx) {
                                                final v = _filtered[idx];
                                                final fullParty = (v['party'] ?? '').toString();
                                                final gstin = GstPartyUtils.extractPartyGstin(fullParty);
                                                final isInter = v['isInterState'] == true;
                                                final items = v['items'] as List? ?? [];
                                                final isFocused = _focusedIndex == idx;
                                                if (_rowFocusNodes.length <= idx) _syncFocusNodes();

                                                return Focus(
                                                  focusNode: _rowFocusNodes[idx],
                                                  onFocusChange: (f) {
                                                    if (f) setState(() => _focusedIndex = idx);
                                                  },
                                                  onKeyEvent: (_, e) {
                                                    if (e is KeyDownEvent) {
                                                      if (KeyboardShortcutService.isConfirm(e.logicalKey)) {
                                                        _openEdit(v);
                                                        return KeyEventResult.handled;
                                                      }
                                                      if (KeyboardShortcutService.isDown(e.logicalKey)) {
                                                        if (idx + 1 < _rowFocusNodes.length) {
                                                          _rowFocusNodes[idx + 1].requestFocus();
                                                        } else if (_rowFocusNodes.isNotEmpty) {
                                                          _rowFocusNodes[0].requestFocus();
                                                        }
                                                        return KeyEventResult.handled;
                                                      }
                                                      if (KeyboardShortcutService.isUp(e.logicalKey)) {
                                                        if (idx - 1 >= 0) {
                                                          _rowFocusNodes[idx - 1].requestFocus();
                                                        } else {
                                                          _searchFocusNode.requestFocus();
                                                        }
                                                        return KeyEventResult.handled;
                                                      }
                                                    }
                                                    return KeyEventResult.ignored;
                                                  },
                                                  child: GestureDetector(
                                                    onDoubleTap: () => _openEdit(v),
                                                    onTap: () {
                                                      setState(() => _focusedIndex = idx);
                                                      _rowFocusNodes[idx].requestFocus();
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: isFocused ? AppColors.primaryLight : Colors.transparent,
                                                        border: isFocused ? Border.all(color: AppColors.primary, width: 1.5) : null,
                                                        borderRadius: isFocused ? BorderRadius.circular(6) : null,
                                                      ),
                                                      child: items.isEmpty
                                                          ? _buildRegisterRow(
                                                              sno: '${idx + 1}',
                                                              party: GstPartyUtils.extractPartyName(fullParty),
                                                              gstin: gstin,
                                                              pos: _getPos(gstin, isInter),
                                                              vchNo: v['voucherNumber'] ?? '',
                                                              date: v['date'] ?? '',
                                                              qty: '0.00',
                                                              unit: 'Pcs',
                                                              hsn: '',
                                                              invoiceValue: (double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                              taxable: '0.00',
                                                              taxRate: '0%',
                                                              igst: (double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                              cgst: (double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                              sgst: (double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                              cess: GstPartyUtils.extractCessAmount(v).toStringAsFixed(2),
                                                              rowWidth: dynamicWidth,
                                                            )
                                                          : Column(
                                                              children: List.generate(items.length, (iIdx) {
                                                                final item = items[iIdx];
                                                                return _buildRegisterRow(
                                                                  sno: iIdx == 0 ? '${idx + 1}' : '',
                                                                  party: iIdx == 0 ? GstPartyUtils.extractPartyName(fullParty) : '',
                                                                  gstin: iIdx == 0 ? gstin : '',
                                                                  pos: iIdx == 0 ? _getPos(gstin, isInter) : '',
                                                                  vchNo: iIdx == 0 ? (v['voucherNumber'] ?? '') : '',
                                                                  date: iIdx == 0 ? (v['date'] ?? '') : '',
                                                                  qty: (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                                  unit: (item['unit'] ?? 'Pcs').toString(),
                                                                  hsn: (item['hsn'] ?? '').toString(),
                                                                  invoiceValue: iIdx == 0 ? (double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2) : '',
                                                                  taxable: (double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                                  taxRate: '${item['gstRate'] ?? 0}%',
                                                                  igst: (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                                  cgst: (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                                  sgst: (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                                                                  cess: iIdx == 0 ? GstPartyUtils.extractCessAmount(v).toStringAsFixed(2) : '',
                                                                  isSubRow: iIdx > 0,
                                                                  rowWidth: dynamicWidth,
                                                                );
                                                              }),
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                            ),
                            SingleChildScrollView(
                              controller: _horizontalFooterCtrl,
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: dynamicWidth,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                  border: Border(top: BorderSide(color: AppColors.borderFocus, width: 1.2)),
                                ),
                                child: Row(
                                  children: [
                                    if (_isColVisible('sno')) const RegisterFooterCell('', width: 45),
                                    if (_isColVisible('party')) const Expanded(flex: 3, child: RegisterFooterCell('TOTAL', width: double.infinity)),
                                    if (_isColVisible('gstin')) const Expanded(flex: 2, child: RegisterFooterCell('', width: double.infinity)),
                                    if (_isColVisible('pos')) const Expanded(flex: 2, child: RegisterFooterCell('', width: double.infinity)),
                                    if (_isColVisible('vchNo')) const RegisterFooterCell('', width: 95),
                                    if (_isColVisible('date')) const RegisterFooterCell('', width: 85),
                                    if (_isColVisible('qty')) RegisterFooterCell(_summary.totalQuantity.toStringAsFixed(2), width: 65, textAlign: TextAlign.right),
                                    if (_isColVisible('unit')) const RegisterFooterCell('', width: 50),
                                    if (_isColVisible('hsn')) const RegisterFooterCell('', width: 75),
                                    if (_isColVisible('invoiceVal')) RegisterFooterCell(_summary.totalInvoiceValue.toStringAsFixed(2), width: 105, textAlign: TextAlign.right, highlight: true),
                                    if (_isColVisible('taxable')) RegisterFooterCell(_summary.totalTaxable.toStringAsFixed(2), width: 95, textAlign: TextAlign.right),
                                    if (_isColVisible('taxRate')) const RegisterFooterCell('', width: 55),
                                    if (_isColVisible('igst')) RegisterFooterCell(_summary.totalIgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('cgst')) RegisterFooterCell(_summary.totalCgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('sgst')) RegisterFooterCell(_summary.totalSgst.toStringAsFixed(2), width: 80, textAlign: TextAlign.right),
                                    if (_isColVisible('cess')) RegisterFooterCell(_summary.totalCess.toStringAsFixed(2), width: 75, textAlign: TextAlign.right),
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
        ),
      ),
    );
  }
}