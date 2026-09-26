// desktop/lib/pages/company/voucher/voucher_list_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../models/company_model.dart';
import '../../../models/register_summary.dart';
import '../../../models/voucher_model.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_excel_export_service.dart';
import '../../../services/voucher_pdf_export_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/export_dialog_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../utils/number_parsing_utils.dart';
import '../../../utils/register_header_bar.dart';
import '../../../widgets/common/app_confirm_dialog.dart';
import '../../../widgets/common/data_table_cells.dart';
import '../../../widgets/common/print_studio_dialog.dart';
import 'voucher_entry_screen.dart';

class VoucherListScreen extends ConsumerStatefulWidget {
  final CompanyModel company;
  final String voucherType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String initialSeries;
  final VoidCallback onClose;

  const VoucherListScreen({
    super.key,
    required this.company,
    required this.voucherType,
    this.fromDate,
    this.toDate,
    this.initialSeries = 'All',
    required this.onClose,
  });

  @override
  ConsumerState<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends ConsumerState<VoucherListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'VoucherListSearch');
  final _horizontalHeaderCtrl = ScrollController();
  final _bodyHorizontalScrollCtrl = ScrollController();
  final _bodyVerticalScrollCtrl = ScrollController();
  final _horizontalFooterCtrl = ScrollController();

  List<VoucherModel> _vouchers = [];
  List<VoucherModel> _filtered = [];
  final Set<String> _selectedKeys = {};
  bool _isLoading = true;
  int _focusedIndex = -1;
  List<FocusNode> _rowFocusNodes = [];
  late String _selectedSeries;
  List<String> _availableSeries = ['All', 'Main'];

  late DateTime _effectiveFromDate;
  late DateTime _effectiveToDate;

  KeyboardShortcutSettings _keyboardSettings = KeyboardShortcutSettings.defaults();

  static const double _checkboxColWidth = 42.0;
  static const double _actionsColWidth = 76.0;

  // Proportional flex weights across the screen
  static const Map<String, int> _columnFlex = {
    'sno': 4,
    'party': 18,
    'gstin': 14,
    'pos': 13,
    'vchNo': 10,
    'date': 9,
    'qty': 7,
    'unit': 5,
    'hsn': 8,
    'invoiceVal': 12,
    'taxable': 11,
    'taxRate': 6,
    'igst': 8,
    'cgst': 8,
    'sgst': 8,
    'cess': 7,
  };

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

  RegisterSummary get _summary =>
      RegisterSummary.fromVouchers(_filtered.map((v) => v.toJson()).toList());

  String _getPos(String gstin, bool isInterState) =>
      GstPartyUtils.getPlaceOfSupply(
        gstin,
        isInterState,
        companyGstin: widget.company.gstin,
      );

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.initialSeries.trim().isEmpty
        ? 'All'
        : widget.initialSeries.trim();

    final bounds = widget.company.fyBounds;
    _effectiveFromDate = widget.fromDate ?? bounds.startDate;
    _effectiveToDate = widget.toDate ?? bounds.endDate;

    _loadKeyboardSettings();
    _loadAvailableSeries();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);

    _bodyHorizontalScrollCtrl.addListener(() {
      for (final ctrl in [_horizontalHeaderCtrl, _horizontalFooterCtrl]) {
        if (ctrl.hasClients &&
            ctrl.offset != _bodyHorizontalScrollCtrl.offset) {
          ctrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
        }
      }
    });
  }

  Future<void> _loadKeyboardSettings() async {
    final settings = await KeyboardShortcutService.loadSettings();
    if (mounted) {
      setState(() => _keyboardSettings = settings);
    }
  }

  Future<void> _loadAvailableSeries() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company.folderPath;
      final seriesSet = <String>{'All', 'Main'};
      if (_selectedSeries != 'All') seriesSet.add(_selectedSeries);
      if (folderPath.isNotEmpty) {
        try {
          final rawMasters =
              await StorageService.loadCompanyMasters(folderPath: folderPath);
          final loaded = rawMasters['series'] as List? ?? [];
          for (final s in loaded) {
            if (s != null && s.toString().trim().isNotEmpty) {
              seriesSet.add(s.toString().trim());
            }
          }
        } catch (_) {}
      }
      if (mounted) setState(() => _availableSeries = seriesSet.toList());
    }, message: '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _horizontalHeaderCtrl.dispose();
    _bodyHorizontalScrollCtrl.dispose();
    _bodyVerticalScrollCtrl.dispose();
    _horizontalFooterCtrl.dispose();

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && _rowFocusNodes.contains(primaryFocus)) {
      primaryFocus.unfocus();
    }
    for (final n in _rowFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && _rowFocusNodes.contains(primaryFocus)) {
      if (_searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      } else {
        primaryFocus.unfocus();
      }
    }

    for (final n in _rowFocusNodes) {
      n.dispose();
    }

    _rowFocusNodes = List.generate(
      _filtered.length,
      (i) => FocusNode(debugLabel: 'VoucherRow_$i'),
    );
  }

  Future<void> _loadVouchers() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company.folderPath;
      final fy = widget.company.activeFinancialYear;

      if (folderPath.isNotEmpty) {
        final rawVouchers = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: fy,
          voucherType: widget.voucherType,
        );
        final allVouchers = rawVouchers.map(VoucherModel.fromJson).toList();
        final targetType = widget.voucherType.toLowerCase().trim();

        for (final v in allVouchers) {
          final s = v.series.trim();
          if (s.isNotEmpty && !_availableSeries.contains(s)) {
            _availableSeries.add(s);
          }
        }

        final start = DateTime(
          _effectiveFromDate.year,
          _effectiveFromDate.month,
          _effectiveFromDate.day,
        );
        final end = DateTime(
          _effectiveToDate.year,
          _effectiveToDate.month,
          _effectiveToDate.day,
          23,
          59,
          59,
        );

        final matching = allVouchers.where((v) {
          final vchType = v.voucherType.toLowerCase().trim();
          final bool typeMatches = vchType.isEmpty ||
              vchType == targetType ||
              vchType.contains(targetType) ||
              targetType.contains(vchType);
          if (!typeMatches) return false;

          if (_selectedSeries.toLowerCase() != 'all') {
            if (v.series.toLowerCase() != _selectedSeries.toLowerCase()) {
              return false;
            }
          }

          final dt = v.parsedDate;
          if (dt == null) return true;

          return (dt.isAtSameMomentAs(start) || dt.isAfter(start)) &&
              (dt.isAtSameMomentAs(end) || dt.isBefore(end));
        }).toList();

        if (mounted) {
          setState(() {
            _vouchers = matching;
            _filtered = matching;
            _selectedKeys.clear();
            _isLoading = false;
            _syncFocusNodes();
            _focusedIndex = matching.isNotEmpty ? 0 : -1;
          });

          if (_rowFocusNodes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _rowFocusNodes.isNotEmpty &&
                  _rowFocusNodes[0].canRequestFocus) {
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
              final vch = v.voucherNumber.toLowerCase();
              final party = v.party.toLowerCase();
              final gstin = v.partyGstin.toLowerCase();
              return vch.contains(q) ||
                  party.contains(q) ||
                  gstin.contains(q) ||
                  v.items.any((it) =>
                      it.hsn.toLowerCase().contains(q) ||
                      it.item.toLowerCase().contains(q));
            }).toList();
      _syncFocusNodes();
      _focusedIndex = _filtered.isNotEmpty ? 0 : -1;
    });

    if (_rowFocusNodes.isNotEmpty && !_searchFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _rowFocusNodes.isNotEmpty &&
            _rowFocusNodes[0].canRequestFocus) {
          _rowFocusNodes[0].requestFocus();
        }
      });
    }
  }

  bool _hasEntries(String colKey) {
    if (_filtered.isEmpty) return true;
    switch (colKey) {
      case 'gstin':
        return _filtered.any((v) => v.partyGstin.isNotEmpty);
      case 'pos':
        return _filtered.any((v) =>
            _getPos(v.partyGstin, v.isInterState).isNotEmpty);
      case 'hsn':
        return _filtered.any((v) => v.items.any((i) => i.hsn.isNotEmpty));
      case 'igst':
        return _filtered.any(
            (v) => v.igst > 0 || v.items.any((i) => i.igst > 0));
      case 'cgst':
        return _filtered.any(
            (v) => v.cgst > 0 || v.items.any((i) => i.cgst > 0));
      case 'sgst':
        return _filtered.any(
            (v) => v.sgst > 0 || v.items.any((i) => i.sgst > 0));
      case 'cess':
        return _filtered.any(
            (v) => GstPartyUtils.extractCessAmount(v.toJson()) > 0);
      default:
        return true;
    }
  }

  bool _isColVisible(String k) =>
      (_userSelectedColumns[k] ?? true) && _hasEntries(k);

  Future<void> _confirmAndDelete(List<VoucherModel> toDelete) async {
    await LoadingService.wrap(() async {
      if (toDelete.isEmpty) return;
      final isPlural = toDelete.length > 1;

      final shouldDelete = await AppConfirmDialog.show(
        context: context,
        title: 'Confirm Deletion',
        message: isPlural
            ? 'Permanently delete ${toDelete.length} selected vouchers?'
            : 'Delete Voucher [${toDelete.first.voucherNumber}]?',
        confirmLabel:
            isPlural ? 'Delete All (${toDelete.length})' : 'Delete',
        type: ConfirmDialogType.danger,
      );

      if (!shouldDelete || !mounted) return;

      final deleteIds = toDelete.map((v) => v.id).toSet();
      setState(() {
        _vouchers.removeWhere((v) => deleteIds.contains(v.id));
        _filtered.removeWhere((v) => deleteIds.contains(v.id));
        _selectedKeys.removeAll(deleteIds);
        _syncFocusNodes();
      });

      final folderPath = widget.company.folderPath;
      final fy = widget.company.activeFinancialYear;
      if (folderPath.isNotEmpty) {
        await StorageService.saveAllVouchers(
          folderPath: folderPath,
          financialYear: fy,
          voucherType: widget.voucherType,
          vouchers: _vouchers.map((v) => v.toJson()).toList(),
        );
      }
      if (mounted) {
        NotificationService.show(
          context,
          message: isPlural
              ? '${toDelete.length} vouchers deleted.'
              : 'Voucher deleted.',
          type: NotificationType.success,
        );
      }
    }, message: 'Deleting Selected Vouchers...');
  }

  Future<void> _handleExcelExport() async {
    try {
      final activeKeys = _columnLabels.keys.where(_isColVisible).toList();
      final savedPath = await VoucherExcelExportService.exportToExcel(
        company: widget.company.toJson(),
        voucherType: widget.voucherType,
        fromDate: _effectiveFromDate,
        toDate: _effectiveToDate,
        filteredVouchers: _filtered.map((v) => v.toJson()).toList(),
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
        onConfirmOverwrite: (p) =>
            ExportDialogUtils.confirmOverwrite(context, p),
      );
      if (savedPath != null && mounted) {
        ExportDialogUtils.showSuccessDialog(
            context, savedPath, 'Excel Workbook (.xlsx)');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.show(
          context,
          message: 'Export failed: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _exportToJson() async {
    await LoadingService.wrap(() async {
      try {
        final dir =
            await VoucherExcelExportService.getOrChooseExportDirectory();
        if (dir == null) return;
        final file = File(
            '$dir${Platform.pathSeparator}${widget.voucherType.replaceAll(' ', '_').toLowerCase()}_register.json');
        if (!await ExportDialogUtils.confirmOverwrite(context, file.path)) {
          return;
        }

        final data = _filtered
            .map((v) => {
                  'voucherNumber': v.voucherNumber,
                  'date': v.date,
                  'series': v.series,
                  'party': v.party,
                  'gstin': v.partyGstin,
                  'grandTotal': v.grandTotal,
                  'subTotal': v.subTotal,
                  'items': v.items
                      .map((i) => {
                            'qty': i.qty,
                            'unit': i.unit,
                            'hsn': i.hsn,
                            'taxable': i.taxable,
                            'gstRate': i.gstRate,
                          })
                      .toList(),
                })
            .toList();

        await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(data));
        if (mounted) {
          ExportDialogUtils.showSuccessDialog(context, file.path, 'JSON');
        }
      } catch (e) {
        if (mounted) {
          NotificationService.show(
            context,
            message: 'Export failed: $e',
            type: NotificationType.error,
          );
        }
      }
    }, message: 'Generating JSON File...');
  }

  Future<void> _openEdit(VoucherModel voucher) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoucherEntryScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          voucherToEdit: voucher,
          isEdit: true,
          keyboardSettings: _keyboardSettings,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) await _loadVouchers();
  }

  void _openColumnSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.view_column_rounded,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Customize Columns',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
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
                            color: hasData
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        if (!hasData) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'No entries',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onChanged: (val) {
                      setDialogState(
                          () => _userSelectedColumns[key] = val ?? false);
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
              child: const Text('Check All',
                  style: TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerPrint() {
    final activeKeys = _columnLabels.keys.where(_isColVisible).toList();

    PrintStudioDialog.show(
      context: context,
      title: '${widget.voucherType} Register',
      pdfFileName: '${widget.voucherType.replaceAll(' ', '_').toLowerCase()}_register.pdf',
      onBuildPdf: (format, config) => VoucherPdfExportService.generateRegisterPdf(
        format: format,
        company: widget.company.toJson(),
        voucherType: widget.voucherType,
        fromDate: _effectiveFromDate,
        toDate: _effectiveToDate,
        filteredVouchers: _filtered.map((v) => v.toJson()).toList(),
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
        pageMargin: config.margin,
        columnScale: config.columnScale,
        tableFontSize: config.tableFontSize,
        borderWidth: config.borderWidth,
        showAddress: config.showAddress,
        showDateRange: config.showDateRange,
        showSubtitle: config.showSubtitle,
        alternateRowColors: config.alternateRowColors,
      ),
    );
  }

  Widget _buildRegisterRow({
    required int index,
    required VoucherModel voucher,
    VoucherItemModel? item,
    bool isSubRow = false,
  }) {
    final key = voucher.id;
    final isSelected = _selectedKeys.contains(key);
    final pos = _getPos(voucher.partyGstin, voucher.isInterState);

    final qtyStr = item != null ? item.qty.toCurrency() : '0.00';
    final unitStr = item?.unit ?? 'Pcs';
    final hsnStr = item?.hsn ?? '';
    final taxableStr =
        (item != null ? item.taxable : voucher.subTotal).toCurrency();
    final rateStr = item != null ? '${item.gstRate.toStringAsFixed(0)}%' : '0%';

    final igstVal = item?.igst ?? voucher.igst;
    final cgstVal = item?.cgst ?? voucher.cgst;
    final sgstVal = item?.sgst ?? voucher.sgst;

    final igstStr = igstVal > 0 ? igstVal.toCurrency() : '';
    final cgstStr = cgstVal > 0 ? cgstVal.toCurrency() : '';
    final sgstStr = sgstVal > 0 ? sgstVal.toCurrency() : '';

    String cessStr = '';
    if (!isSubRow) {
      final cess = GstPartyUtils.extractCessAmount(voucher.toJson());
      if (cess > 0) cessStr = cess.toCurrency();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSubRow ? AppColors.cardBg : Colors.transparent,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _checkboxColWidth,
            child: isSubRow
                ? null
                : Center(
                    child: Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedKeys.add(key);
                          } else {
                            _selectedKeys.remove(key);
                          }
                        });
                      },
                    ),
                  ),
          ),
          if (_isColVisible('sno'))
            Expanded(
              flex: _columnFlex['sno']!,
              child: RegisterDataCell(
                isSubRow ? '' : '${index + 1}',
                width: double.infinity,
                isMuted: true,
              ),
            ),
          if (_isColVisible('party'))
            Expanded(
              flex: _columnFlex['party']!,
              child: RegisterDataCell(
                isSubRow ? '' : voucher.party,
                width: double.infinity,
                isBold: true,
              ),
            ),
          if (_isColVisible('gstin'))
            Expanded(
              flex: _columnFlex['gstin']!,
              child: RegisterDataCell(
                isSubRow ? '' : voucher.partyGstin,
                width: double.infinity,
                color: AppColors.successDark,
              ),
            ),
          if (_isColVisible('pos'))
            Expanded(
              flex: _columnFlex['pos']!,
              child: RegisterDataCell(
                isSubRow ? '' : pos,
                width: double.infinity,
              ),
            ),
          if (_isColVisible('vchNo'))
            Expanded(
              flex: _columnFlex['vchNo']!,
              child: RegisterDataCell(
                isSubRow ? '' : voucher.voucherNumber,
                width: double.infinity,
                color: AppColors.primary,
                isBold: true,
              ),
            ),
          if (_isColVisible('date'))
            Expanded(
              flex: _columnFlex['date']!,
              child: RegisterDataCell(
                isSubRow ? '' : voucher.date,
                width: double.infinity,
              ),
            ),
          if (_isColVisible('qty'))
            Expanded(
              flex: _columnFlex['qty']!,
              child: RegisterDataCell(
                qtyStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          if (_isColVisible('unit'))
            Expanded(
              flex: _columnFlex['unit']!,
              child: RegisterDataCell(
                unitStr,
                width: double.infinity,
                textAlign: TextAlign.center,
                isMuted: true,
              ),
            ),
          if (_isColVisible('hsn'))
            Expanded(
              flex: _columnFlex['hsn']!,
              child: RegisterDataCell(
                hsnStr,
                width: double.infinity,
              ),
            ),
          if (_isColVisible('invoiceVal'))
            Expanded(
              flex: _columnFlex['invoiceVal']!,
              child: RegisterDataCell(
                isSubRow ? '' : voucher.grandTotal.toCurrency(),
                width: double.infinity,
                textAlign: TextAlign.right,
                isBold: true,
              ),
            ),
          if (_isColVisible('taxable'))
            Expanded(
              flex: _columnFlex['taxable']!,
              child: RegisterDataCell(
                taxableStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          if (_isColVisible('taxRate'))
            Expanded(
              flex: _columnFlex['taxRate']!,
              child: RegisterDataCell(
                rateStr,
                width: double.infinity,
                textAlign: TextAlign.right,
                isMuted: true,
              ),
            ),
          if (_isColVisible('igst'))
            Expanded(
              flex: _columnFlex['igst']!,
              child: RegisterDataCell(
                igstStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          if (_isColVisible('cgst'))
            Expanded(
              flex: _columnFlex['cgst']!,
              child: RegisterDataCell(
                cgstStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          if (_isColVisible('sgst'))
            Expanded(
              flex: _columnFlex['sgst']!,
              child: RegisterDataCell(
                sgstStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          if (_isColVisible('cess'))
            Expanded(
              flex: _columnFlex['cess']!,
              child: RegisterDataCell(
                cessStr,
                width: double.infinity,
                textAlign: TextAlign.right,
              ),
            ),
          SizedBox(
            width: _actionsColWidth,
            child: isSubRow
                ? const SizedBox(width: _actionsColWidth)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.edit_note_rounded,
                            size: 20, color: AppColors.primary),
                        onPressed: () => _openEdit(voucher),
                        splashRadius: 16,
                        tooltip: 'Edit Voucher',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        onPressed: () => _confirmAndDelete([voucher]),
                        splashRadius: 16,
                        tooltip: 'Delete Voucher',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (KeyboardShortcutService.matchesAction(_keyboardSettings, KeyboardShortcutService.goBackAction, event)) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (KeyboardShortcutService.matchesAction(_keyboardSettings, KeyboardShortcutService.printInvoiceAction, event)) {
      _triggerPrint();
      return KeyEventResult.handled;
    }
    if (KeyboardShortcutService.matchesAction(_keyboardSettings, KeyboardShortcutService.exportExcelAction, event)) {
      _handleExcelExport();
      return KeyEventResult.handled;
    }
    if (KeyboardShortcutService.matchesAction(_keyboardSettings, KeyboardShortcutService.exportJsonAction, event)) {
      _exportToJson();
      return KeyEventResult.handled;
    }
    if (KeyboardShortcutService.matchesAction(_keyboardSettings, KeyboardShortcutService.columnsDialogAction, event)) {
      _openColumnSettingsDialog();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company.activeFinancialYear;
    final allKeys = [for (final v in _filtered) v.id];
    final allSelected =
        allKeys.isNotEmpty && allKeys.every(_selectedKeys.contains);

    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherList,
      nodeMap: {FocusFieldNode.searchField: _searchFocusNode},
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleGlobalKeyEvent,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Top Bar with requested colorful buttons
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.primaryAccent,
                          AppColors.primary,
                        ]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 16,
                            color: AppColors.surface,
                          ),
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
                        'F.Y. $fy (${AppDateUtils.formatDate(_effectiveFromDate)} to ${AppDateUtils.formatDate(_effectiveToDate)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableSeries.contains(_selectedSeries)
                              ? _selectedSeries
                              : 'All',
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              size: 18, color: AppColors.primary),
                          items: _availableSeries
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s == 'All' ? 'Series: All' : 'Series: $s',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ))
                              .toList(),
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
                    if (_selectedKeys.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final toDelete = _vouchers
                                .where((v) => _selectedKeys.contains(v.id))
                                .toList();
                            _confirmAndDelete(toDelete);
                          },
                          icon: const Icon(Icons.delete_forever_rounded,
                              size: 16, color: AppColors.surface),
                          label: Text(
                            'Delete Selected (${_selectedKeys.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.surface,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _openColumnSettingsDialog,
                      icon: const Icon(Icons.view_column_rounded,
                          size: 16, color: AppColors.info),
                      label: Text(
                        'Columns (${KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.columnsDialogAction)})',
                        style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _handleExcelExport,
                      icon: const Icon(Icons.table_view_rounded,
                          size: 16, color: AppColors.success),
                      label: Text(
                        'Excel (${KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.exportExcelAction)})',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _exportToJson,
                      icon: const Icon(Icons.data_object_rounded,
                          size: 16, color: AppColors.purple),
                      label: Text(
                        'JSON (${KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.exportJsonAction)})',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _triggerPrint,
                      icon: const Icon(Icons.print_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text(
                        'Print (${KeyboardShortcutService.labelForAction(_keyboardSettings, KeyboardShortcutService.printInvoiceAction)})',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.textSecondary),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              RegisterHeaderBar(
                searchController: _searchCtrl,
                searchFocusNode: _searchFocusNode,
                summary: _summary,
                isManageMode: true,
                onSubmitted: (_) {
                  if (_rowFocusNodes.isNotEmpty &&
                      _rowFocusNodes[0].canRequestFocus) {
                    _rowFocusNodes[0].requestFocus();
                    setState(() => _focusedIndex = 0);
                  }
                },
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
                        // Enforce minWidth 1000 for compact screens, stretch to 100% on larger screens
                        final tableWidth = math.max(constraints.maxWidth, 1000.0);

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
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border, width: 1.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: _checkboxColWidth,
                                      child: Center(
                                        child: Checkbox(
                                          value: allSelected,
                                          activeColor: AppColors.primary,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedKeys.addAll(allKeys);
                                              } else {
                                                _selectedKeys.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_isColVisible('sno'))
                                      Expanded(
                                        flex: _columnFlex['sno']!,
                                        child: const RegisterHeaderCell('S.No.', width: double.infinity),
                                      ),
                                    if (_isColVisible('party'))
                                      Expanded(
                                        flex: _columnFlex['party']!,
                                        child: const RegisterHeaderCell('Party', width: double.infinity),
                                      ),
                                    if (_isColVisible('gstin'))
                                      Expanded(
                                        flex: _columnFlex['gstin']!,
                                        child: const RegisterHeaderCell('GSTIN', width: double.infinity),
                                      ),
                                    if (_isColVisible('pos'))
                                      Expanded(
                                        flex: _columnFlex['pos']!,
                                        child: const RegisterHeaderCell('Place of Supply', width: double.infinity),
                                      ),
                                    if (_isColVisible('vchNo'))
                                      Expanded(
                                        flex: _columnFlex['vchNo']!,
                                        child: const RegisterHeaderCell('Voc. No.', width: double.infinity),
                                      ),
                                    if (_isColVisible('date'))
                                      Expanded(
                                        flex: _columnFlex['date']!,
                                        child: const RegisterHeaderCell('Voc. Date', width: double.infinity),
                                      ),
                                    if (_isColVisible('qty'))
                                      Expanded(
                                        flex: _columnFlex['qty']!,
                                        child: const RegisterHeaderCell('Qty.', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('unit'))
                                      Expanded(
                                        flex: _columnFlex['unit']!,
                                        child: const RegisterHeaderCell('Unit', width: double.infinity, textAlign: TextAlign.center),
                                      ),
                                    if (_isColVisible('hsn'))
                                      Expanded(
                                        flex: _columnFlex['hsn']!,
                                        child: const RegisterHeaderCell('HSN', width: double.infinity),
                                      ),
                                    if (_isColVisible('invoiceVal'))
                                      Expanded(
                                        flex: _columnFlex['invoiceVal']!,
                                        child: const RegisterHeaderCell('Invoice Value', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('taxable'))
                                      Expanded(
                                        flex: _columnFlex['taxable']!,
                                        child: const RegisterHeaderCell('Taxable', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('taxRate'))
                                      Expanded(
                                        flex: _columnFlex['taxRate']!,
                                        child: const RegisterHeaderCell('Rate', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('igst'))
                                      Expanded(
                                        flex: _columnFlex['igst']!,
                                        child: const RegisterHeaderCell('IGST', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('cgst'))
                                      Expanded(
                                        flex: _columnFlex['cgst']!,
                                        child: const RegisterHeaderCell('CGST', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('sgst'))
                                      Expanded(
                                        flex: _columnFlex['sgst']!,
                                        child: const RegisterHeaderCell('SGST', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    if (_isColVisible('cess'))
                                      Expanded(
                                        flex: _columnFlex['cess']!,
                                        child: const RegisterHeaderCell('Cess', width: double.infinity, textAlign: TextAlign.right),
                                      ),
                                    const SizedBox(
                                      width: _actionsColWidth,
                                      child: RegisterHeaderCell('Actions', width: _actionsColWidth, textAlign: TextAlign.center),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary))
                                  : _filtered.isEmpty
                                      ? const Center(
                                          child: Text('No matching vouchers found.'))
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
                                                  itemCount: _filtered.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(height: 1, color: AppColors.borderLight),
                                                  itemBuilder: (context, idx) {
                                                    if (idx >= _rowFocusNodes.length) {
                                                      return const SizedBox.shrink();
                                                    }

                                                    final v = _filtered[idx];
                                                    final isFocused = _focusedIndex == idx;

                                                    return Focus(
                                                      focusNode: _rowFocusNodes[idx],
                                                      onFocusChange: (f) {
                                                        if (f) setState(() => _focusedIndex = idx);
                                                      },
                                                      onKeyEvent: (_, e) {
                                                        if (e is KeyDownEvent || e is KeyRepeatEvent) {
                                                          if (KeyboardShortcutService.matchesAction(
                                                                  _keyboardSettings,
                                                                  KeyboardShortcutService.activateAction,
                                                                  e) ||
                                                              KeyboardShortcutService.isConfirm(e)) {
                                                            _openEdit(v);
                                                            return KeyEventResult.handled;
                                                          }
                                                          if (KeyboardShortcutService.matchesAction(
                                                                  _keyboardSettings,
                                                                  KeyboardShortcutService.moveDownAction,
                                                                  e) ||
                                                              KeyboardShortcutService.isDown(e)) {
                                                            if (idx + 1 < _rowFocusNodes.length) {
                                                              _rowFocusNodes[idx + 1].requestFocus();
                                                            } else if (_rowFocusNodes.isNotEmpty) {
                                                              _rowFocusNodes[0].requestFocus();
                                                            }
                                                            return KeyEventResult.handled;
                                                          }
                                                          if (KeyboardShortcutService.matchesAction(
                                                                  _keyboardSettings,
                                                                  KeyboardShortcutService.moveUpAction,
                                                                  e) ||
                                                              KeyboardShortcutService.isUp(e)) {
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
                                                            color: isFocused
                                                                ? AppColors.primaryLight
                                                                : (_selectedKeys.contains(v.id)
                                                                    ? AppColors.primaryLight.withValues(alpha: 0.45)
                                                                    : Colors.transparent),
                                                            border: isFocused
                                                                ? Border.all(color: AppColors.primary, width: 1.5)
                                                                : null,
                                                            borderRadius: isFocused
                                                                ? BorderRadius.circular(6)
                                                                : null,
                                                          ),
                                                          child: v.items.isEmpty
                                                              ? _buildRegisterRow(
                                                                  index: idx,
                                                                  voucher: v,
                                                                )
                                                              : Column(
                                                                  children: List.generate(
                                                                    v.items.length,
                                                                    (iIdx) => _buildRegisterRow(
                                                                      index: idx,
                                                                      voucher: v,
                                                                      item: v.items[iIdx],
                                                                      isSubRow: iIdx > 0,
                                                                    ),
                                                                  ),
                                                                ),
                                                        ),
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
                                  border: Border(
                                    top: BorderSide(color: AppColors.borderFocus, width: 1.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: _checkboxColWidth),
                                    if (_isColVisible('sno'))
                                      Expanded(
                                        flex: _columnFlex['sno']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('party'))
                                      Expanded(
                                        flex: _columnFlex['party']!,
                                        child: const RegisterFooterCell('TOTAL', width: double.infinity),
                                      ),
                                    if (_isColVisible('gstin'))
                                      Expanded(
                                        flex: _columnFlex['gstin']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('pos'))
                                      Expanded(
                                        flex: _columnFlex['pos']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('vchNo'))
                                      Expanded(
                                        flex: _columnFlex['vchNo']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('date'))
                                      Expanded(
                                        flex: _columnFlex['date']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('qty'))
                                      Expanded(
                                        flex: _columnFlex['qty']!,
                                        child: RegisterFooterCell(
                                          _summary.totalQuantity.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (_isColVisible('unit'))
                                      Expanded(
                                        flex: _columnFlex['unit']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('hsn'))
                                      Expanded(
                                        flex: _columnFlex['hsn']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('invoiceVal'))
                                      Expanded(
                                        flex: _columnFlex['invoiceVal']!,
                                        child: RegisterFooterCell(
                                          _summary.totalInvoiceValue.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                          highlight: true,
                                        ),
                                      ),
                                    if (_isColVisible('taxable'))
                                      Expanded(
                                        flex: _columnFlex['taxable']!,
                                        child: RegisterFooterCell(
                                          _summary.totalTaxable.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (_isColVisible('taxRate'))
                                      Expanded(
                                        flex: _columnFlex['taxRate']!,
                                        child: const RegisterFooterCell('', width: double.infinity),
                                      ),
                                    if (_isColVisible('igst'))
                                      Expanded(
                                        flex: _columnFlex['igst']!,
                                        child: RegisterFooterCell(
                                          _summary.totalIgst.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (_isColVisible('cgst'))
                                      Expanded(
                                        flex: _columnFlex['cgst']!,
                                        child: RegisterFooterCell(
                                          _summary.totalCgst.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (_isColVisible('sgst'))
                                      Expanded(
                                        flex: _columnFlex['sgst']!,
                                        child: RegisterFooterCell(
                                          _summary.totalSgst.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (_isColVisible('cess'))
                                      Expanded(
                                        flex: _columnFlex['cess']!,
                                        child: RegisterFooterCell(
                                          _summary.totalCess.toCurrency(),
                                          width: double.infinity,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    const SizedBox(width: _actionsColWidth),
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