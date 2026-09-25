import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../constants/app_colors.dart';
import '../../../models/company_model.dart';
import '../../../models/voucher_model.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_excel_export_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/export_dialog_utils.dart';
import '../../../utils/number_parsing_utils.dart';
import '../../../widgets/common/data_table_cells.dart';
import '../../../widgets/common/print_studio_dialog.dart';

class ConsolidatedHsnStockScreen extends StatefulWidget {
  final CompanyModel company;
  final DateTime fromDate;
  final DateTime toDate;

  const ConsolidatedHsnStockScreen({
    super.key,
    required this.company,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ConsolidatedHsnStockScreen> createState() => _ConsolidatedHsnStockScreenState();
}

class _ConsolidatedHsnStockScreenState extends State<ConsolidatedHsnStockScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'StockSearchNode');
  final _horizontalHeaderCtrl = ScrollController();
  final _bodyHorizontalScrollCtrl = ScrollController();
  final _bodyVerticalScrollCtrl = ScrollController();
  final _horizontalFooterCtrl = ScrollController();

  bool _isLoading = true;
  String _stockBy = 'HSN'; // 'HSN' or 'Tax Rate'
  List<Map<String, dynamic>> _rawVouchersData = [];
  List<dynamic> _masterItemsData = [];
  List<Map<String, dynamic>> _allRows = [];
  List<Map<String, dynamic>> _filteredRows = [];

  final Map<String, String> _columnLabels = {
    'sno': 'S.No.',
    'groupKey': 'HSN Code',
    'taxRate': 'Tax Rate',
    'unit': 'Unit',
    'openingQty': 'Opening Qty',
    'openingAmt': 'Opening Amnt',
    'qtyAdded': 'Qty Added',
    'amtAdded': 'Amnt Added',
    'qtyWithdraw': 'Qty Withdraw',
    'amtWithdraw': 'Amnt Withdraw',
    'closingQty': 'Closing Qty',
    'closingAmt': 'Closing Amt',
  };

  final Map<String, bool> _userSelectedColumns = {
    'sno': true,
    'groupKey': true,
    'taxRate': true,
    'unit': true,
    'openingQty': true,
    'openingAmt': true,
    'qtyAdded': true,
    'amtAdded': true,
    'qtyWithdraw': true,
    'amtWithdraw': true,
    'closingQty': true,
    'closingAmt': true,
  };

  final Map<String, double> _baseColumnWeights = {
    'sno': 50.0,
    'groupKey': 115.0,
    'taxRate': 85.0,
    'unit': 70.0,
    'openingQty': 105.0,
    'openingAmt': 120.0,
    'qtyAdded': 105.0,
    'amtAdded': 120.0,
    'qtyWithdraw': 110.0,
    'amtWithdraw': 130.0,
    'closingQty': 105.0,
    'closingAmt': 120.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearch);

    _bodyHorizontalScrollCtrl.addListener(() {
      for (final ctrl in [_horizontalHeaderCtrl, _horizontalFooterCtrl]) {
        if (ctrl.hasClients && ctrl.offset != _bodyHorizontalScrollCtrl.offset) {
          ctrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _horizontalHeaderCtrl.dispose();
    _bodyHorizontalScrollCtrl.dispose();
    _bodyVerticalScrollCtrl.dispose();
    _horizontalFooterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final folderPath = widget.company.folderPath;
    final fy = widget.company.activeFinancialYear;

    final rawVouchers = await StorageService.loadVouchers(folderPath: folderPath, financialYear: fy);
    final masters = await StorageService.loadCompanyMasters(folderPath: folderPath);

    _rawVouchersData = rawVouchers;
    _masterItemsData = masters['items'] as List<dynamic>? ?? [];

    _aggregateStock();
  }

  void _aggregateStock() {
    final Map<String, String> itemHsnMap = {};
    final Map<String, double> itemTaxMap = {};
    final Map<String, String> itemUnitMap = {};

    for (final item in _masterItemsData) {
      if (item is Map) {
        final name = item['name']?.toString() ?? item['itemName']?.toString() ?? '';
        final hsn = item['hsn']?.toString() ?? item['hsnCode']?.toString() ?? '9988';
        final tax = NumberParsing.toDouble(item['taxRate'] ?? item['gstRate'] ?? 18.0);
        final unit = item['unit']?.toString() ?? 'Pcs';
        if (name.isNotEmpty) {
          itemHsnMap[name] = hsn;
        }
        itemTaxMap[hsn] = tax;
        itemUnitMap[hsn] = unit;
      }
    }

    final Map<String, Map<String, dynamic>> aggregates = {};

    for (final vchJson in _rawVouchersData) {
      final v = VoucherModel.fromJson(vchJson);
      final itemsList = vchJson['items'] as List<dynamic>? ?? [];

      for (final rawItem in itemsList) {
        final itemMap = rawItem is Map<String, dynamic> ? rawItem : <String, dynamic>{};
        final itemName = itemMap['itemName']?.toString() ?? itemMap['name']?.toString() ?? itemMap['item']?.toString() ?? '';
        final qty = NumberParsing.toDouble(itemMap['qty'] ?? itemMap['quantity'] ?? 1.0);
        final taxableAmt = NumberParsing.toDouble(itemMap['taxable'] ?? itemMap['amount'] ?? itemMap['total'] ?? 0.0);

        final hsn = itemMap['hsn']?.toString().isNotEmpty == true 
            ? itemMap['hsn'].toString() 
            : (itemHsnMap[itemName] ?? '9988');
        final taxRate = NumberParsing.toDouble(itemMap['gstRate'] ?? itemMap['taxRate'] ?? itemTaxMap[hsn] ?? 18.0);
        final unit = itemMap['unit']?.toString() ?? itemUnitMap[hsn] ?? 'Pcs';

        final String groupKey = _stockBy == 'HSN' ? hsn : '${taxRate.toStringAsFixed(1)}%';

        aggregates.putIfAbsent(groupKey, () => {
          'groupKey': groupKey,
          'taxRate': taxRate,
          'unit': unit,
          'openingQty': 10.0,
          'openingAmt': 1000.0,
          'qtyAdded': 0.0,
          'amtAdded': 0.0,
          'qtyWithdraw': 0.0,
          'amtWithdraw': 0.0,
        });

        final row = aggregates[groupKey]!;
        if (v.isPurchase) {
          row['qtyAdded'] = (row['qtyAdded'] as double) + qty;
          row['amtAdded'] = (row['amtAdded'] as double) + taxableAmt;
        } else if (v.isSale) {
          row['qtyWithdraw'] = (row['qtyWithdraw'] as double) + qty;
          row['amtWithdraw'] = (row['amtWithdraw'] as double) + taxableAmt;
        }
      }
    }

    final List<Map<String, dynamic>> processedRows = [];
    aggregates.forEach((k, data) {
      final openingQty = data['openingQty'] as double;
      final openingAmt = data['openingAmt'] as double;
      final qtyAdded = data['qtyAdded'] as double;
      final amtAdded = data['amtAdded'] as double;
      final qtyWithdraw = data['qtyWithdraw'] as double;
      final amtWithdraw = data['amtWithdraw'] as double;

      final closingQty = (openingQty + qtyAdded) - qtyWithdraw;
      final closingAmt = (openingAmt + amtAdded) - amtWithdraw;

      processedRows.add({
        'groupKey': k,
        'taxRate': data['taxRate'],
        'unit': data['unit'],
        'openingQty': openingQty,
        'openingAmt': openingAmt,
        'qtyAdded': qtyAdded,
        'amtAdded': amtAdded,
        'qtyWithdraw': qtyWithdraw,
        'amtWithdraw': amtWithdraw,
        'closingQty': closingQty,
        'closingAmt': closingAmt,
      });
    });

    if (mounted) {
      setState(() {
        _columnLabels['groupKey'] = _stockBy == 'HSN' ? 'HSN Code' : 'Tax Slab';
        _allRows = processedRows;
        _filteredRows = processedRows;
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredRows = q.isEmpty
          ? _allRows
          : _allRows.where((row) {
              final group = row['groupKey'].toString().toLowerCase();
              final unit = row['unit'].toString().toLowerCase();
              return group.contains(q) || unit.contains(q);
            }).toList();
    });
  }

  bool _isColVisible(String k) => _userSelectedColumns[k] ?? true;

  double _getCalculatedColWidth(String key, double containerWidth) {
    final activeKeys = _columnLabels.keys.where(_isColVisible).toList();
    final double baseSum = activeKeys.fold(0.0, (sum, k) => sum + (_baseColumnWeights[k] ?? 100.0));
    final double scale = math.max(1.0, containerWidth / baseSum);
    return (_baseColumnWeights[key] ?? 100.0) * scale;
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
              Text(
                'Customize Columns',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _columnLabels.keys.map((key) {
                  final isChecked = _userSelectedColumns[key] ?? true;
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(
                      _columnLabels[key]!,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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

  Future<void> _handleExcelExport() async {
    try {
      final dir = await VoucherExcelExportService.getOrChooseExportDirectory();
      if (dir == null) return;
      final file = File('$dir${Platform.pathSeparator}consolidated_stock_${_stockBy.toLowerCase()}_report.csv');

      final activeKeys = _columnLabels.keys.where(_isColVisible).toList();
      final headers = activeKeys.map((k) => _columnLabels[k]).join(',');
      final buffer = StringBuffer()..writeln(headers);

      for (int i = 0; i < _filteredRows.length; i++) {
        final row = _filteredRows[i];
        final values = activeKeys.map((k) {
          if (k == 'sno') return '${i + 1}';
          return row[k]?.toString() ?? '';
        }).join(',');
        buffer.writeln(values);
      }

      await file.writeAsString(buffer.toString());
      if (mounted) {
        ExportDialogUtils.showSuccessDialog(context, file.path, 'Excel CSV File');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.show(context, message: 'Export failed: $e', type: NotificationType.error);
      }
    }
  }

  Future<void> _exportToJson() async {
    await LoadingService.wrap(() async {
      try {
        final dir = await VoucherExcelExportService.getOrChooseExportDirectory();
        if (dir == null) return;
        final file = File('$dir${Platform.pathSeparator}consolidated_stock_${_stockBy.toLowerCase()}_report.json');

        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_filteredRows));
        if (mounted) {
          ExportDialogUtils.showSuccessDialog(context, file.path, 'JSON');
        }
      } catch (e) {
        if (mounted) {
          NotificationService.show(context, message: 'Export failed: $e', type: NotificationType.error);
        }
      }
    }, message: 'Generating JSON File...');
  }
  void _triggerPrint() {
    final activeKeys = _columnLabels.keys.where(_isColVisible).toList();

    PrintStudioDialog.show(
      context: context,
      title: 'Consolidated Stock Report ($_stockBy)',
      pdfFileName: 'consolidated_stock_${_stockBy.toLowerCase()}_report.pdf',
      onBuildPdf: (format, config) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: format.copyWith(
              marginLeft: config.margin,
              marginRight: config.margin,
              marginTop: config.margin,
              marginBottom: config.margin,
            ),
            build: (context) => [
              pw.Text(
                '${widget.company.companyName} - Consolidated Stock Report ($_stockBy)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Period: ${AppDateUtils.formatDate(widget.fromDate)} to ${AppDateUtils.formatDate(widget.toDate)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: activeKeys.map((k) => _columnLabels[k]!).toList(),
                data: _filteredRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return activeKeys.map((k) {
                    if (k == 'sno') return '${i + 1}';
                    if (k.toLowerCase().contains('amt') || k.toLowerCase().contains('rate')) {
                      return NumberParsing.toDouble(row[k]).toStringAsFixed(2);
                    }
                    return row[k]?.toString() ?? '';
                  }).toList();
                }).toList(),
                cellStyle: pw.TextStyle(fontSize: config.tableFontSize),
                headerStyle: pw.TextStyle(fontSize: config.tableFontSize, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
        return pdf.save();
      },
    );
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (KeyboardShortcutService.isExit(event.logicalKey)) {
      Navigator.pop(context);
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
    double totalOpeningQty = 0, totalOpeningAmt = 0;
    double totalQtyAdded = 0, totalAmtAdded = 0;
    double totalQtyWithdraw = 0, totalAmtWithdraw = 0;
    double totalClosingQty = 0, totalClosingAmt = 0;

    for (final r in _filteredRows) {
      totalOpeningQty += (r['openingQty'] as double);
      totalOpeningAmt += (r['openingAmt'] as double);
      totalQtyAdded += (r['qtyAdded'] as double);
      totalAmtAdded += (r['amtAdded'] as double);
      totalQtyWithdraw += (r['qtyWithdraw'] as double);
      totalAmtWithdraw += (r['amtWithdraw'] as double);
      totalClosingQty += (r['closingQty'] as double);
      totalClosingAmt += (r['closingAmt'] as double);
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Top Bar
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
                    child: const Row(
                      children: [
                        Icon(Icons.table_chart_rounded, size: 16, color: AppColors.surface),
                        SizedBox(width: 6),
                        Text(
                          'CONSOLIDATED STOCK REPORT',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.surface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown: Stock by HSN or Tax Rate
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _stockBy,
                        icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primary),
                        items: const [
                          DropdownMenuItem(
                            value: 'HSN',
                            child: Text('Stock by: HSN', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          DropdownMenuItem(
                            value: 'Tax Rate',
                            child: Text('Stock by: Tax Rate', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null && val != _stockBy) {
                            setState(() => _stockBy = val);
                            _aggregateStock();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderFocus),
                    ),
                    child: Text(
                      'Period: ${AppDateUtils.formatDate(widget.fromDate)} to ${AppDateUtils.formatDate(widget.toDate)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Custom Stock Header Metrics Bar (replacing generic invoice register bar)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 240,
                    height: 36,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search ${_stockBy == 'HSN' ? 'HSN' : 'Tax Slab'} or Unit...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildMetricBadge('Total Opn Qty', totalOpeningQty.toCurrency(), AppColors.textPrimary),
                  const SizedBox(width: 10),
                  _buildMetricBadge('Total Opn Amnt', '₹${totalOpeningAmt.toCurrency()}', AppColors.textPrimary),
                  const SizedBox(width: 10),
                  _buildMetricBadge('Total Clo Qty', totalClosingQty.toCurrency(), AppColors.primary),
                  const SizedBox(width: 10),
                  _buildMetricBadge('Total Clo Amt', '₹${totalClosingAmt.toCurrency()}', AppColors.primary),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth;
                      return Column(
                        children: [
                          SingleChildScrollView(
                            controller: _horizontalHeaderCtrl,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: tableWidth,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.cardBg,
                                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
                              ),
                              child: Row(
                                children: [
                                  if (_isColVisible('sno')) RegisterHeaderCell('S.No.', width: _getCalculatedColWidth('sno', tableWidth)),
                                  if (_isColVisible('groupKey')) RegisterHeaderCell(_columnLabels['groupKey']!, width: _getCalculatedColWidth('groupKey', tableWidth)),
                                  if (_isColVisible('taxRate')) RegisterHeaderCell('Tax Rate', width: _getCalculatedColWidth('taxRate', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('unit')) RegisterHeaderCell('Unit', width: _getCalculatedColWidth('unit', tableWidth), textAlign: TextAlign.center),
                                  if (_isColVisible('openingQty')) RegisterHeaderCell('Opening Qty', width: _getCalculatedColWidth('openingQty', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('openingAmt')) RegisterHeaderCell('Opening Amnt', width: _getCalculatedColWidth('openingAmt', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('qtyAdded')) RegisterHeaderCell('Qty Added', width: _getCalculatedColWidth('qtyAdded', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('amtAdded')) RegisterHeaderCell('Amnt Added', width: _getCalculatedColWidth('amtAdded', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('qtyWithdraw')) RegisterHeaderCell('Qty Withdraw', width: _getCalculatedColWidth('qtyWithdraw', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('amtWithdraw')) RegisterHeaderCell('Amnt Withdraw', width: _getCalculatedColWidth('amtWithdraw', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('closingQty')) RegisterHeaderCell('Closing Qty', width: _getCalculatedColWidth('closingQty', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('closingAmt')) RegisterHeaderCell('Closing Amt', width: _getCalculatedColWidth('closingAmt', tableWidth), textAlign: TextAlign.right),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : _filteredRows.isEmpty
                                    ? const Center(child: Text('No matching stock records found.'))
                                    : Scrollbar(
                                        controller: _bodyHorizontalScrollCtrl,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: _bodyHorizontalScrollCtrl,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: tableWidth,
                                            child: Scrollbar(
                                              controller: _bodyVerticalScrollCtrl,
                                              thumbVisibility: true,
                                              child: ListView.separated(
                                                controller: _bodyVerticalScrollCtrl,
                                                itemCount: _filteredRows.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                                                itemBuilder: (context, idx) {
                                                  final row = _filteredRows[idx];
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    child: Row(
                                                      children: [
                                                        if (_isColVisible('sno')) RegisterDataCell('${idx + 1}', width: _getCalculatedColWidth('sno', tableWidth), isMuted: true),
                                                        if (_isColVisible('groupKey')) RegisterDataCell(row['groupKey'].toString(), width: _getCalculatedColWidth('groupKey', tableWidth), isBold: true, color: AppColors.primary),
                                                        if (_isColVisible('taxRate')) RegisterDataCell('${row['taxRate']}%', width: _getCalculatedColWidth('taxRate', tableWidth), textAlign: TextAlign.right),
                                                        if (_isColVisible('unit')) RegisterDataCell(row['unit'].toString(), width: _getCalculatedColWidth('unit', tableWidth), textAlign: TextAlign.center, isMuted: true),
                                                        if (_isColVisible('openingQty')) RegisterDataCell((row['openingQty'] as double).toCurrency(), width: _getCalculatedColWidth('openingQty', tableWidth), textAlign: TextAlign.right),
                                                        if (_isColVisible('openingAmt')) RegisterDataCell((row['openingAmt'] as double).toCurrency(), width: _getCalculatedColWidth('openingAmt', tableWidth), textAlign: TextAlign.right),
                                                        if (_isColVisible('qtyAdded')) RegisterDataCell((row['qtyAdded'] as double).toCurrency(), width: _getCalculatedColWidth('qtyAdded', tableWidth), textAlign: TextAlign.right, color: AppColors.successDark),
                                                        if (_isColVisible('amtAdded')) RegisterDataCell((row['amtAdded'] as double).toCurrency(), width: _getCalculatedColWidth('amtAdded', tableWidth), textAlign: TextAlign.right, color: AppColors.successDark),
                                                        if (_isColVisible('qtyWithdraw')) RegisterDataCell((row['qtyWithdraw'] as double).toCurrency(), width: _getCalculatedColWidth('qtyWithdraw', tableWidth), textAlign: TextAlign.right, color: AppColors.error),
                                                        if (_isColVisible('amtWithdraw')) RegisterDataCell((row['amtWithdraw'] as double).toCurrency(), width: _getCalculatedColWidth('amtWithdraw', tableWidth), textAlign: TextAlign.right, color: AppColors.error),
                                                        if (_isColVisible('closingQty')) RegisterDataCell((row['closingQty'] as double).toCurrency(), width: _getCalculatedColWidth('closingQty', tableWidth), textAlign: TextAlign.right, isBold: true),
                                                        if (_isColVisible('closingAmt')) RegisterDataCell((row['closingAmt'] as double).toCurrency(), width: _getCalculatedColWidth('closingAmt', tableWidth), textAlign: TextAlign.right, isBold: true, color: AppColors.primary),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                          ),
                          SingleChildScrollView(
                            controller: _horizontalFooterCtrl,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: tableWidth,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                border: Border(top: BorderSide(color: AppColors.borderFocus, width: 1.2)),
                              ),
                              child: Row(
                                children: [
                                  if (_isColVisible('sno')) RegisterFooterCell('', width: _getCalculatedColWidth('sno', tableWidth)),
                                  if (_isColVisible('groupKey')) RegisterFooterCell('TOTAL', width: _getCalculatedColWidth('groupKey', tableWidth)),
                                  if (_isColVisible('taxRate')) RegisterFooterCell('', width: _getCalculatedColWidth('taxRate', tableWidth)),
                                  if (_isColVisible('unit')) RegisterFooterCell('', width: _getCalculatedColWidth('unit', tableWidth)),
                                  if (_isColVisible('openingQty')) RegisterFooterCell(totalOpeningQty.toCurrency(), width: _getCalculatedColWidth('openingQty', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('openingAmt')) RegisterFooterCell(totalOpeningAmt.toCurrency(), width: _getCalculatedColWidth('openingAmt', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('qtyAdded')) RegisterFooterCell(totalQtyAdded.toCurrency(), width: _getCalculatedColWidth('qtyAdded', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('amtAdded')) RegisterFooterCell(totalAmtAdded.toCurrency(), width: _getCalculatedColWidth('amtAdded', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('qtyWithdraw')) RegisterFooterCell(totalQtyWithdraw.toCurrency(), width: _getCalculatedColWidth('qtyWithdraw', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('amtWithdraw')) RegisterFooterCell(totalAmtWithdraw.toCurrency(), width: _getCalculatedColWidth('amtWithdraw', tableWidth), textAlign: TextAlign.right),
                                  if (_isColVisible('closingQty')) RegisterFooterCell(totalClosingQty.toCurrency(), width: _getCalculatedColWidth('closingQty', tableWidth), textAlign: TextAlign.right, highlight: true),
                                  if (_isColVisible('closingAmt')) RegisterFooterCell(totalClosingAmt.toCurrency(), width: _getCalculatedColWidth('closingAmt', tableWidth), textAlign: TextAlign.right, highlight: true),
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
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}