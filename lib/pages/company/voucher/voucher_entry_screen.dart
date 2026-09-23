import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/gst_constants.dart';
import '../../../database/app_database.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../provider/company_provider.dart';
import '../../../provider/sync_provider.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_calculation_service.dart';
import '../../../services/voucher_numbering_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../utils/voucher_master_actions.dart';
import '../../../widgets/voucher/popup/add_item_dialog.dart';
import '../../../widgets/voucher/popup/add_party_dialog.dart';
import '../../../widgets/voucher/popup/add_series_dialog.dart';
import '../../../widgets/voucher/popup/calculator_dialog.dart';
import '../../../widgets/voucher/popup/item_tax_details_dialog.dart';
import '../../../widgets/voucher/popup/sales_invoice_print_preview_dialog.dart';
import '../../../widgets/voucher/popup/voucher_dialog_utils.dart';
import '../../../widgets/voucher/popup/voucher_save_confirm_dialog.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
import '../../../widgets/voucher/voucher_summary_card.dart';
import '../../../widgets/voucher/voucher_sundry_card.dart';
import '../../../widgets/voucher/voucher_sundry_row.dart';

class VoucherEntryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final VoidCallback onClose;
  final KeyboardShortcutSettings keyboardSettings;
  final Map<String, dynamic>? voucherToEdit;
  final bool isEdit;

  const VoucherEntryScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onClose,
    required this.keyboardSettings,
    this.voucherToEdit,
    this.isEdit = false,
  });

  @override
  ConsumerState<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends ConsumerState<VoucherEntryScreen> {
  final _seriesController = TextEditingController(text: 'Main');
  final _seriesFocus = FocusNode();
  final _dateController = TextEditingController();
  final _dateFocusNode = FocusNode();
  final _vchNoController = TextEditingController();
  final _vchNoFocus = FocusNode();
  final _partyController = TextEditingController();
  final _partyFocus = FocusNode();
  final _saleTypeController = TextEditingController(text: 'Local Itemwise');
  final _saleTypeFocus = FocusNode();
  final _matCenterController = TextEditingController(text: 'Main Store');
  final _matCenterFocus = FocusNode();
  final _narrationController = TextEditingController();
  final _narrationFocus = FocusNode();
  final _saveButtonFocusNode = FocusNode();

  final ValueNotifier<VoucherTotalsResult> _totalsNotifier = ValueNotifier(
    const VoucherTotalsResult(
      totalQty: 0.0,
      subTotal: 0.0,
      totalCgst: 0.0,
      totalSgst: 0.0,
      totalIgst: 0.0,
      totalTax: 0.0,
      sundryTotal: 0.0,
      roundOff: 0.0,
      grandTotal: 0.0,
      totalItemAmount: 0.0,
    ),
  );

  final List<Map<String, dynamic>> _sessionSavedVouchers = [];
  int _sessionIndex = -1;
  late bool _isEditingExisting;

  Map<String, dynamic>? _activeEditingVoucher;

  final List<VoucherItemRow> _items = [];
  final List<VoucherSundryRow> _sundries = [];
  final List<String> _availableSeries = ['Main'];
  final Map<String, dynamic> _seriesSettings = {};

  List<PartyMasterModel> _debtorsList = [];
  List<PartyMasterModel> _creditorsList = [];
  List<ItemMasterModel> _itemsMasterList = [];

  final Map<String, ItemMasterModel> _itemCache = {};
  final Map<String, PartyMasterModel> _partyCache = {};

  List<String> _availableSaleTypes = [];
  List<String> _availableSundries = [];
  List<String> _availableMaterialCenters = [];
  List<String> _availableUnits = [];
  List<String> _availableTaxCategories = [];
  List<String> _availableAccountGroups = [];

  bool _isInterState = false;
  bool _autoRoundOff = true;
  bool _isAutoAdjustingSaleType = false;
  bool _isHandlingMasterNotFound = false;
  bool _isHandlingVchNoWarning = false;
  bool _isHandlingDuplicateVchWarning = false;
  bool _isHandlingTaxMismatch = false;
  bool _allowEmptyVchNo = false;
  bool _allowDuplicateVchNo = false;
  bool _isExitDialogOpen = false;
  String? _dateError;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  Timer? _calculationDebounceTimer;

  bool get _isSalesVoucher => widget.voucherType.toLowerCase().contains('sale');
  List<PartyMasterModel> get _currentAvailableParties =>
      _isSalesVoucher ? _debtorsList : _creditorsList;

  bool get _isViewingExistingVoucher => _isEditingExisting || _sessionIndex != -1;

  Color get _themeColor => _isSalesVoucher ? AppColors.warning : AppColors.primary;
  Color get _screenBg =>
      _isSalesVoucher ? AppColors.salesScreenBg : AppColors.generalScreenBg;
  Color get _topBarBg =>
      _isSalesVoucher ? AppColors.salesTopBarBg : AppColors.generalTopBarBg;

  @override
  void initState() {
    super.initState();
    _isEditingExisting = widget.isEdit;
    _activeEditingVoucher = widget.voucherToEdit;
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);
    _attachControllerListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(activeCompanyProvider) == null) {
        ref.read(activeCompanyProvider.notifier).state = widget.company;
      }
    });

    if (widget.isEdit && widget.voucherToEdit != null) {
      _loadExistingVoucherData(widget.voucherToEdit!);
    } else {
      _loadCompanyMastersOnly().then((_) => _initializeNewVoucher());
    }
  }

  @override
  void dispose() {
    _calculationDebounceTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _totalsNotifier.dispose();

    for (final c in [
      _seriesController,
      _dateController,
      _vchNoController,
      _saleTypeController,
      _partyController,
      _matCenterController,
      _narrationController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _seriesFocus,
      _dateFocusNode,
      _vchNoFocus,
      _saleTypeFocus,
      _partyFocus,
      _matCenterFocus,
      _narrationFocus,
      _saveButtonFocusNode,
    ]) {
      f.dispose();
    }
    for (final i in _items) {
      i.dispose();
    }
    for (final s in _sundries) {
      s.dispose();
    }
    super.dispose();
  }

  void _scheduleRecalculation([VoidCallback? preCalcAction]) {
    _calculationDebounceTimer?.cancel();
    _calculationDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      preCalcAction?.call();
      _calculateAllTotals();
    });
  }

  void _calculateAllTotals() {
    for (final s in _sundries) {
      final name = s.name.text.toLowerCase();
      if (!name.contains('round') &&
          !name.contains('rnd') &&
          s.percent.text.isNotEmpty &&
          !s.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromPercent(
          s,
          _totalsNotifier.value.subTotal,
        );
      }
    }

    final result = VoucherCalculationService.calculateTotals(
      items: _items,
      sundries: _sundries,
      isInterState: _isInterState,
      autoRoundOff: _autoRoundOff,
    );

    _totalsNotifier.value = result;
  }

  void _rebuildFastLookupCaches() {
    _itemCache.clear();
    for (final item in _itemsMasterList) {
      _itemCache[item.name.toLowerCase().trim()] = item;
    }
    _partyCache.clear();
    for (final party in _currentAvailableParties) {
      _partyCache[party.name.toLowerCase().trim()] = party;
      _partyCache[party.displayName.toLowerCase().trim()] = party;
    }
  }

  bool _isAnyMainTableCellFocused() {
    for (final r in _items) {
      if (r.itemFocus.hasFocus ||
          r.qtyFocus.hasFocus ||
          r.unitFocus.hasFocus ||
          r.priceFocus.hasFocus ||
          r.taxableFocus.hasFocus ||
          r.cgstFocus.hasFocus ||
          r.sgstFocus.hasFocus ||
          r.igstFocus.hasFocus ||
          r.amountFocus.hasFocus) {
        return true;
      }
    }
    return false;
  }

  bool _isAnySundryCellFocused() {
    for (final s in _sundries) {
      if (s.nameFocus.hasFocus ||
          s.percentFocus.hasFocus ||
          s.amountFocus.hasFocus) {
        return true;
      }
    }
    return false;
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed) {
      if (_isAnyMainTableCellFocused()) {
        _sundries.firstOrNull?.nameFocus.requestFocus();
        return true;
      }
      if (_isAnySundryCellFocused()) {
        _saveButtonFocusNode.requestFocus();
        return true;
      }
    }

    if (KeyboardShortcutService.matchesAction(
      widget.keyboardSettings,
      KeyboardShortcutService.goBackAction,
      event,
    )) {
      _requestExit();
      return true;
    }
    return false;
  }

  Future<void> _requestExit() async {
    if (_isExitDialogOpen) return;
    _isExitDialogOpen = true;
    final shouldExit =
        await VoucherDialogUtils.showUnsavedChangesDialog(context);
    _isExitDialogOpen = false;
    if (shouldExit && mounted) {
      widget.onClose();
    }
  }

  void _notify(String msg, {Color bg = AppColors.success, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.surface, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadExistingVoucherData(Map<String, dynamic> v) {
    if (!mounted) return;
    setState(() {
      _isEditingExisting = true;
      _activeEditingVoucher = v;
    });

    final series = v['series']?.toString() ?? 'Main';
    _seriesController.text = series;
    if (!_availableSeries.contains(series)) _availableSeries.add(series);

    _dateController.text = v['date']?.toString() ?? '';
    _vchNoController.text = v['voucherNumber']?.toString() ?? '';
    _partyController.text = v['party']?.toString() ?? '';
    _saleTypeController.text = v['saleType']?.toString() ?? 'Local Itemwise';
    _matCenterController.text = v['materialCenter']?.toString() ?? 'Main Store';
    _narrationController.text = v['narration']?.toString() ?? '';
    _isInterState = v['isInterState'] == true;
    _allowEmptyVchNo = _vchNoController.text.trim().isEmpty;
    _allowDuplicateVchNo = true;

    final fy = v['financialYear']?.toString() ??
        widget.company['activeFinancialYear']?.toString() ??
        AppDateUtils.defaultFinancialYear;
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _items.clear();
    for (final i in (v['items'] as List? ?? [])) {
      final row = VoucherItemRow()
        ..item.text = i['item']?.toString() ?? ''
        ..hsn = i['hsn']?.toString() ?? ''
        ..qty.text = i['qty']?.toString() ?? ''
        ..unit.text = i['unit']?.toString() ?? 'PCS'
        ..price.text = i['price']?.toString() ?? ''
        ..taxable.text = i['taxable']?.toString() ?? ''
        ..cgst.text = i['cgst']?.toString() ?? ''
        ..sgst.text = i['sgst']?.toString() ?? ''
        ..igst.text = i['igst']?.toString() ?? ''
        ..amount.text = i['amount']?.toString() ?? ''
        ..gstRate = double.tryParse(i['gstRate']?.toString() ?? '18') ?? 18.0;
      _attachItemRowListeners(row);
      _items.add(row);
    }
    while (_items.length < 15) {
      _addItemRow();
    }

    _sundries.clear();
    for (final s in (v['sundries'] as List? ?? [])) {
      final row = VoucherSundryRow()
        ..name.text = s['name']?.toString() ?? ''
        ..percent.text = s['percent']?.toString() ?? ''
        ..amount.text = s['amount']?.toString() ?? ''
        ..isNegative = s['isNegative'] == true;
      _attachSundryRowListeners(row);
      _sundries.add(row);
    }
    while (_sundries.length < 4) {
      _addSundryRow();
    }

    _loadCompanyMastersOnly();
    _calculateAllTotals();
  }

  Future<void> _loadCompanyMastersOnly() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath'];
      if (folderPath == null) return;
      final rawMasters =
          await StorageService.loadCompanyMasters(folderPath: folderPath);

      if (!mounted) return;

      PartyMasterModel parseParty(dynamic d, String defaultGroup) =>
          PartyMasterModel(
            name: d['name']?.toString() ?? '',
            gstin: d['gstin']?.toString() ?? '',
            group: d['group']?.toString() ?? defaultGroup,
          );

      _debtorsList = (rawMasters['debtors'] as List? ?? [])
          .map((d) => parseParty(d, 'Sundry Debtors'))
          .toList();
      _creditorsList = (rawMasters['creditors'] as List? ?? [])
          .map((c) => parseParty(c, 'Sundry Creditors'))
          .toList();

      _itemsMasterList = (rawMasters['items'] as List? ?? [])
          .map((i) => ItemMasterModel(
                name: i['name']?.toString() ?? '',
                hsn: i['hsn']?.toString() ?? '',
                unit: i['unit']?.toString() ?? 'PCS',
                taxCategory: i['taxCategory']?.toString() ?? 'GST 18%',
                taxRate: (i['taxRate'] as num?)?.toDouble() ?? 18.0,
                salesPrice: (i['salesPrice'] as num?)?.toDouble() ?? 0.0,
                purchasePrice: (i['purchasePrice'] as num?)?.toDouble() ?? 0.0,
                mrp: (i['mrp'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();

      _rebuildFastLookupCaches();

      _availableSeries
        ..clear()
        ..addAll((rawMasters['series'] as List? ?? ['Main'])
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty));
      if (!_availableSeries.contains('Main')) _availableSeries.insert(0, 'Main');

      if (rawMasters['seriesSettings'] is Map<String, dynamic>) {
        _seriesSettings.addAll(rawMasters['seriesSettings']);
      }

      _availableSaleTypes = (rawMasters['saleTypes'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _availableSundries = (rawMasters['billSundries'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _availableMaterialCenters = (rawMasters['materialCenters'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _availableUnits = (rawMasters['units'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _availableTaxCategories = (rawMasters['taxCategories'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      _availableAccountGroups = (rawMasters['accountGroups'] as List? ?? [])
          .map((e) => e.toString())
          .toList();

      if (_matCenterController.text.isEmpty &&
          _availableMaterialCenters.isNotEmpty) {
        _matCenterController.text = _availableMaterialCenters.first;
      }

      if (mounted) setState(() {});
    }, message: 'Loading Master Records...');
  }

  Future<void> _syncMastersToFile() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath'];
      if (folderPath == null) return;
      _rebuildFastLookupCaches();
      await StorageService.saveCompanyMasters(
        folderPath: folderPath,
        mastersData: {
          'debtors': _debtorsList
              .map((d) =>
                  {'name': d.name, 'gstin': d.gstin, 'group': d.group})
              .toList(),
          'creditors': _creditorsList
              .map((c) =>
                  {'name': c.name, 'gstin': c.gstin, 'group': c.group})
              .toList(),
          'items': _itemsMasterList
              .map((i) => {
                    'name': i.name,
                    'hsn': i.hsn,
                    'unit': i.unit,
                    'taxCategory': i.taxCategory,
                    'taxRate': i.taxRate,
                    'salesPrice': i.salesPrice,
                    'purchasePrice': i.purchasePrice,
                    'mrp': i.mrp,
                  })
              .toList(),
          'series': _availableSeries,
          'seriesSettings': _seriesSettings,
          'saleTypes': _availableSaleTypes,
          'billSundries': _availableSundries,
          'materialCenters': _availableMaterialCenters,
          'units': _availableUnits,
          'taxCategories': _availableTaxCategories,
          'accountGroups': _availableAccountGroups,
        },
      );
    }, message: 'Updating Masters Records...');
  }

  Future<void> _autogenerateVoucherNumber(String seriesName) async {
    await LoadingService.wrap(() async {
      final nextNo = await VoucherNumberingService.autogenerate(
        company: widget.company,
        voucherType: widget.voucherType,
        seriesName: seriesName,
        seriesSettings: _seriesSettings[seriesName] ?? {},
      );
      if (nextNo != null && mounted) {
        setState(() => _vchNoController.text = nextNo);
      }
    }, message: '');
  }

  void _attachItemRowListeners(VoucherItemRow row) {
    row.itemFocus.addListener(() {
      if (row.itemFocus.hasFocus || _isHandlingMasterNotFound) return;
      final text = row.item.text.trim();
      if (text.isEmpty) return;

      final exists = _itemCache.containsKey(text.toLowerCase());
      if (!exists) {
        _isHandlingMasterNotFound = true;
        VoucherDialogUtils.showMasterNotFoundDialog(
          context: context,
          title: 'Item not added in Master',
          message:
              '"$text" does not exist in your item master list. Would you like to add it now?',
          onAdd: () async {
            final index = _items.indexOf(row);
            if (index != -1 && !(await _openAddItemDialog(index))) {
              row.item.clear();
              row.itemFocus.requestFocus();
            }
            _isHandlingMasterNotFound = false;
          },
          onCancel: () {
            row.item.clear();
            row.itemFocus.requestFocus();
            _isHandlingMasterNotFound = false;
          },
        );
      }
    });

    void recalculateFromQtyOrPrice() {
      final q = double.tryParse(row.qty.text) ?? 0.0;
      final p = double.tryParse(row.price.text) ?? 0.0;

      if (q > 0 && p > 0) {
        VoucherCalculationService.recalculateTaxableAndTaxes(row, _isInterState);
      } else if (q > 0 && p == 0 && row.taxable.text.isNotEmpty) {
        final t = double.tryParse(row.taxable.text) ?? 0.0;
        if (t > 0) {
          row.price.text = (t / q).toStringAsFixed(2);
          VoucherCalculationService.recalculateTaxesFromTaxable(
              row, _isInterState);
        }
      } else if (row.qty.text.trim().isEmpty &&
          row.price.text.trim().isEmpty) {
        row.taxable.clear();
        row.cgst.clear();
        row.sgst.clear();
        row.igst.clear();
        row.amount.clear();
      }
    }

    row.qty.addListener(() {
      if (row.qtyFocus.hasFocus) {
        _scheduleRecalculation(recalculateFromQtyOrPrice);
      }
    });

    row.price.addListener(() {
      if (row.priceFocus.hasFocus) {
        _scheduleRecalculation(recalculateFromQtyOrPrice);
      }
    });

    row.taxable.addListener(() {
      if (!row.taxableFocus.hasFocus) return;
      _scheduleRecalculation(() {
        final t = double.tryParse(row.taxable.text) ?? 0.0;
        final q = double.tryParse(row.qty.text) ?? 0.0;
        if (t > 0) {
          if (q > 0) row.price.text = (t / q).toStringAsFixed(2);
          VoucherCalculationService.recalculateTaxesFromTaxable(
              row, _isInterState);
        } else {
          row.cgst.clear();
          row.sgst.clear();
          row.igst.clear();
          row.amount.clear();
        }
      });
    });

    for (final node in [row.cgst, row.sgst, row.igst]) {
      node.addListener(() {
        if (row.cgstFocus.hasFocus ||
            row.sgstFocus.hasFocus ||
            row.igstFocus.hasFocus) {
          _scheduleRecalculation(() {
            final t = double.tryParse(row.taxable.text) ?? 0.0;
            final tax = _isInterState
                ? (double.tryParse(row.igst.text) ?? 0.0)
                : ((double.tryParse(row.cgst.text) ?? 0.0) +
                    (double.tryParse(row.sgst.text) ?? 0.0));
            row.amount.text =
                (t + tax) == 0 ? '' : (t + tax).toStringAsFixed(2);
          });
        }
      });
    }

    row.amount.addListener(() {
      if (!row.amountFocus.hasFocus) return;
      _scheduleRecalculation(() {
        final amt = double.tryParse(row.amount.text) ?? 0.0;
        if (amt > 0) {
          VoucherCalculationService.recalculateFromInvoiceAmount(
              row, _isInterState);
        } else {
          row.taxable.clear();
          row.cgst.clear();
          row.sgst.clear();
          row.igst.clear();
        }
      });
    });
  }

  void _attachSundryRowListeners(VoucherSundryRow row) {
    row.name.addListener(() {
      _applySundryAutoValue(row);
      _calculateAllTotals();
    });
    row.percent.addListener(() {
      if (row.percentFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromPercent(
          row,
          _totalsNotifier.value.subTotal,
        );
        _calculateAllTotals();
      }
    });
    row.amount.addListener(() {
      if (row.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromAmount(
          row,
          _totalsNotifier.value.subTotal,
        );
        _calculateAllTotals();
      }
    });
  }

  Future<void> _checkVoucherNumberOnBlur() async {
    if (_isHandlingVchNoWarning || _isHandlingDuplicateVchWarning) return;
    if (_isEditingExisting) return;

    final vchText = _vchNoController.text.trim();

    if (vchText.isEmpty) {
      if (!_allowEmptyVchNo) {
        _isHandlingVchNoWarning = true;
        VoucherDialogUtils.showMissingVchNoWarning(
          context: context,
          onConfirm: () {
            _allowEmptyVchNo = true;
            _isHandlingVchNoWarning = false;
            _partyFocus.requestFocus();
          },
          onCancel: () {
            _allowEmptyVchNo = false;
            _isHandlingVchNoWarning = false;
            _vchNoFocus.requestFocus();
          },
        );
      }
      return;
    }

    if (_allowDuplicateVchNo) return;

    final folderPath = widget.company['folderPath']?.toString();
    final fy = (widget.company['activeFinancialYear'] ??
            AppDateUtils.defaultFinancialYear)
        .toString();
    if (folderPath == null) return;

    final existingVouchers = await StorageService.loadVouchers(
      folderPath: folderPath,
      financialYear: fy,
      voucherType: widget.voucherType,
      seriesName: _seriesController.text.trim(),
    );

    if (!mounted) return;

    final currentId = _activeEditingVoucher?['id']?.toString() ??
        widget.voucherToEdit?['id']?.toString();
    final match = existingVouchers.where((v) {
      final matchesNo = (v['voucherNumber'] ?? '')
              .toString()
              .trim()
              .toLowerCase() ==
          vchText.toLowerCase();
      final isSelf =
          currentId != null && (v['id'] ?? '').toString() == currentId;
      return matchesNo && !isSelf;
    }).firstOrNull;

    if (match != null && mounted) {
      _isHandlingDuplicateVchWarning = true;
      final assignedParty =
          GstPartyUtils.extractPartyName((match['party'] ?? '').toString());
      final displayName = assignedParty.isNotEmpty
          ? assignedParty
          : (widget.company['companyName'] ?? 'Unknown Company');

      VoucherDialogUtils.showDuplicateVchNoWarning(
        context: context,
        companyName: displayName,
        onNo: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = false;
          _vchNoController.clear();
          _vchNoFocus.requestFocus();
        },
        onOpenVoucher: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = true;
          _loadExistingVoucherData(match);
        },
        onYes: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = true;
          _partyFocus.requestFocus();
        },
      );
    }
  }

  void _attachControllerListeners() {
    _dateFocusNode.addListener(() {
      if (!_dateFocusNode.hasFocus) _parseAndValidateDate();
    });

    _vchNoFocus.addListener(() {
      if (_vchNoFocus.hasFocus) {
        _allowEmptyVchNo = false;
      } else {
        _checkVoucherNumberOnBlur();
      }
    });

    _vchNoController.addListener(() {
      _allowDuplicateVchNo = false;
    });

    _partyFocus.addListener(() {
      if (_partyFocus.hasFocus || _isHandlingMasterNotFound) return;
      final text = _partyController.text.trim();
      if (text.isEmpty) return;

      final exists = _partyCache.containsKey(text.toLowerCase());
      if (!exists) {
        _isHandlingMasterNotFound = true;
        VoucherDialogUtils.showMasterNotFoundDialog(
          context: context,
          title: 'Party not added in Master',
          message:
              '"$text" does not exist in your account ledger masters. Would you like to add it now?',
          onAdd: () async {
            if (!(await _openAddPartyDialog())) {
              _partyController.clear();
              _partyFocus.requestFocus();
            }
            _isHandlingMasterNotFound = false;
          },
          onCancel: () {
            _partyController.clear();
            _partyFocus.requestFocus();
            _isHandlingMasterNotFound = false;
          },
        );
      }
    });

    _seriesController
        .addListener(() => _autogenerateVoucherNumber(_seriesController.text));
    _partyController.addListener(() {
      _checkGstMode(autoAdjustSaleType: true);
      _refreshTaxesOnAllRows();
    });
    _saleTypeController.addListener(() {
      if (!_isAutoAdjustingSaleType && !_isHandlingTaxMismatch) {
        _handleManualSaleTypeChange();
      }
    });
  }

  void _handleManualSaleTypeChange() {
    if (_isHandlingTaxMismatch) return;
    final currentSaleType = _saleTypeController.text.trim();

    final validTypes = _availableSaleTypes.isNotEmpty
        ? _availableSaleTypes
        : const [
            'Local Itemwise',
            'InterState Itemwise',
            'Local Multirate',
            'InterState Multirate',
            'Local Exempt',
            'InterState Exempt',
          ];

    if (!validTypes.contains(currentSaleType)) return;

    final isExplicitLocal = currentSaleType.startsWith('Local');
    final isExplicitInterState = currentSaleType.startsWith('InterState');
    if (!isExplicitLocal && !isExplicitInterState) return;

    final compState = _getCompanyStateCode();
    final partyState = _extractPartyStateCode(_partyController.text);

    if (partyState.isNotEmpty) {
      final partyIsInterstate = compState != partyState;
      final mismatch = (partyIsInterstate && isExplicitLocal) ||
          (!partyIsInterstate && isExplicitInterState);

      if (mismatch) {
        _isHandlingTaxMismatch = true;
        final targetPrefix = partyIsInterstate ? 'InterState' : 'Local';
        final fromPrefix = partyIsInterstate ? 'Local' : 'InterState';

        VoucherDialogUtils.showTaxMismatchWarning(
          context: context,
          enteredType: '$fromPrefix transaction',
          partyBelongsToText: partyIsInterstate
              ? 'interstate (State code: $partyState)'
              : 'local / intra-state (State code: $partyState)',
          onAdjust: () {
            _isAutoAdjustingSaleType = true;
            _saleTypeController.text =
                currentSaleType.replaceFirst(fromPrefix, targetPrefix);
            _isAutoAdjustingSaleType = false;
            _isHandlingTaxMismatch = false;
            setState(() {
              _isInterState = partyIsInterstate;
              _refreshTaxesOnAllRows();
            });
          },
          onCancel: () => _isHandlingTaxMismatch = false,
        );
        return;
      }
    }
    setState(() {
      _isInterState = isExplicitInterState;
      _refreshTaxesOnAllRows();
    });
  }

  bool _parseAndValidateDate() {
    final rawText = _dateController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _dateError = 'Voucher Date cannot be empty');
      return false;
    }
    DateTime? parsed = AppDateUtils.parseDate(rawText);
    if (parsed == null) {
      setState(() => _dateError = 'Invalid date format');
      return false;
    }
    if (!rawText.contains(RegExp(r'[-/.](20\d\d|\d\d)$'))) {
      final month = parsed.month;
      final targetYear =
          (month >= 1 && month <= 3) ? _fyEndDate.year : _fyStartDate.year;
      parsed = DateTime(targetYear, month, parsed.day);
    }

    if (parsed.isBefore(_fyStartDate) || parsed.isAfter(_fyEndDate)) {
      setState(() => _dateError =
          'Date outside FY (${AppDateUtils.formatDate(_fyStartDate)} to ${AppDateUtils.formatDate(_fyEndDate)})');
      return false;
    }
    _dateController.text = AppDateUtils.formatDate(parsed);
    setState(() => _dateError = null);
    return true;
  }

  void _openCalculatorForController(
    TextEditingController controller, [
    VoucherItemRow? row,
    String? fieldName,
  ]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Calculator',
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.26),
      pageBuilder: (_, __, ___) => CalculatorDialog(
        initialValue: controller.text,
        onSubmitted: (val) {
          controller.text = val;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
          if (row != null) {
            if (fieldName == 'qty' || fieldName == 'price') {
              final q = double.tryParse(row.qty.text) ?? 0.0;
              final p = double.tryParse(row.price.text) ?? 0.0;
              if (q > 0 && p > 0) {
                VoucherCalculationService.recalculateTaxableAndTaxes(
                    row, _isInterState);
              }
            } else if (fieldName == 'taxable') {
              final t = double.tryParse(row.taxable.text) ?? 0.0;
              final q = double.tryParse(row.qty.text) ?? 0.0;
              if (q > 0 && t > 0) row.price.text = (t / q).toStringAsFixed(2);
              VoucherCalculationService.recalculateTaxesFromTaxable(
                  row, _isInterState);
            } else if (fieldName == 'amount') {
              VoucherCalculationService.recalculateFromInvoiceAmount(
                  row, _isInterState);
            }
          }
          _calculateAllTotals();
        },
      ),
    );
  }

  void _initializeNewVoucher() {
    if (!mounted) return;
    final fy = widget.company['activeFinancialYear']?.toString() ??
        AppDateUtils.defaultFinancialYear;
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _vchNoController.text = '';
    _partyController.text = '';
    _narrationController.text = '';
    _saleTypeController.text = _availableSaleTypes.isNotEmpty
        ? _availableSaleTypes.first
        : 'Local Itemwise';
    _matCenterController.text = _availableMaterialCenters.isNotEmpty
        ? _availableMaterialCenters.first
        : 'Main Store';
    _isInterState = false;
    _allowEmptyVchNo = false;
    _allowDuplicateVchNo = false;
    _isHandlingVchNoWarning = false;
    _isHandlingDuplicateVchWarning = false;
    _isHandlingTaxMismatch = false;
    _isEditingExisting = false;
    _activeEditingVoucher = null;

    final now = DateTime.now();
    _dateController.text =
        (now.isAfter(_fyStartDate) && now.isBefore(_fyEndDate))
            ? AppDateUtils.formatDate(now)
            : '01-04-${_fyStartDate.year}';

    _items.clear();
    for (int i = 0; i < 15; i++) {
      _addItemRow();
    }
    _sundries.clear();
    for (int i = 0; i < 4; i++) {
      _addSundryRow();
    }

    _calculateAllTotals();
    _autogenerateVoucherNumber(_seriesController.text);

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dateFocusNode.canRequestFocus) {
          _dateFocusNode.requestFocus();
        }
      });
    }
  }

  String _getCompanyStateCode() {
    final rawGstin = (widget.company['gstin'] ??
            widget.company['gstNumber'] ??
            '')
        .toString()
        .trim();
    if (rawGstin.length >= 2 && int.tryParse(rawGstin.substring(0, 2)) != null) {
      return rawGstin.substring(0, 2);
    }
    final rawState = (widget.company['state'] ??
            widget.company['stateName'] ??
            '')
        .toString()
        .trim();
    return GstConstants.getStateCodeByName(rawState) ?? '07';
  }

  String _extractPartyStateCode(String partyText) {
    final gstin = GstPartyUtils.extractPartyGstin(partyText.trim());
    if (gstin.length >= 2 && int.tryParse(gstin.substring(0, 2)) != null) {
      return gstin.substring(0, 2);
    }
    final matched = _partyCache[partyText.trim().toLowerCase()];
    return (matched != null && matched.gstin.trim().length >= 2)
        ? matched.gstin.trim().substring(0, 2)
        : '';
  }

  void _checkGstMode({bool autoAdjustSaleType = false}) {
    final compState = _getCompanyStateCode();
    final partyState = _extractPartyStateCode(_partyController.text);
    _isInterState = partyState.isNotEmpty && compState != partyState;
    if (autoAdjustSaleType) {
      final currentType = _saleTypeController.text;
      final suffix = currentType.contains('Multirate')
          ? 'Multirate'
          : (currentType.contains('Exempt') ? 'Exempt' : 'Itemwise');
      final targetType = '${_isInterState ? "InterState" : "Local"} $suffix';
      if (_saleTypeController.text != targetType) {
        _isAutoAdjustingSaleType = true;
        _saleTypeController.text = targetType;
        _isAutoAdjustingSaleType = false;
      }
    }
  }

  void _refreshTaxesOnAllRows() {
    for (final row in _items) {
      if (row.taxable.text.isNotEmpty) {
        VoucherCalculationService.recalculateTaxesFromTaxable(
            row, _isInterState);
      } else if (row.amount.text.isNotEmpty) {
        VoucherCalculationService.recalculateFromInvoiceAmount(
            row, _isInterState);
      }
    }
    _calculateAllTotals();
  }

  void _addSundryRow() {
    final row = VoucherSundryRow();
    _attachSundryRowListeners(row);
    _sundries.add(row);
  }

  void _addItemRow() {
    final row = VoucherItemRow();
    _attachItemRowListeners(row);
    _items.add(row);
  }

  void _applySundryAutoValue(VoucherSundryRow sundry) {
    final type = sundry.name.text.toLowerCase();
    if (type.contains('round off') || type.contains('rnd off')) {
      final totals = _totalsNotifier.value;
      double baseSum = totals.subTotal + totals.totalTax;
      for (final s in _sundries) {
        if (s != sundry) {
          final a = double.tryParse(s.amount.text) ?? 0.0;
          baseSum += (s.name.text.contains('-') || s.isNegative) ? -a : a;
        }
      }
      final remainder = baseSum % 1.0;
      final isAdd = sundry.name.text.contains('+');
      final diff =
          isAdd ? (remainder == 0 ? 0.0 : 1.0 - remainder) : remainder;
      sundry.amount.text = diff > 0 ? diff.toStringAsFixed(2) : '';
      sundry.percent.clear();
      sundry.isNegative = !isAdd;
    } else if (sundry.percent.text.isNotEmpty) {
      VoucherCalculationService.recalculateSundryFromPercent(
        sundry,
        _totalsNotifier.value.subTotal,
      );
    }
  }

  void _onItemMasterSelected(int index, ItemMasterModel selectedItem) {
    final row = _items[index]
      ..unit.text = selectedItem.unit
      ..gstRate = selectedItem.taxRate
      ..hsn = selectedItem.hsn;
    final defaultPrice = _isSalesVoucher
        ? selectedItem.salesPrice
        : selectedItem.purchasePrice;
    if (defaultPrice > 0) row.price.text = defaultPrice.toStringAsFixed(2);

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0 && defaultPrice > 0) {
      VoucherCalculationService.recalculateTaxableAndTaxes(row, _isInterState);
    } else if (row.taxable.text.isNotEmpty) {
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.amount.text.isNotEmpty) {
      VoucherCalculationService.recalculateFromInvoiceAmount(
          row, _isInterState);
    }
    _calculateAllTotals();
  }

  void _openTaxDetailsDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => ItemTaxDetailsDialog(
        row: _items[index],
        isInterState: _isInterState,
        onUpdated: _calculateAllTotals,
      ),
    );
  }

  Future<bool> _openAddItemDialog(int index, [ItemMasterModel? existingItem]) async {
    bool created = false;
    await showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        company: widget.company,
        folderPath: widget.company['folderPath'],
        isEdit: existingItem != null,
        initialItem: existingItem,
        onItemCreated: (itemData) async {
          // Immediately reload from disk to reflect freshly saved masters
          await _loadCompanyMastersOnly();

          if (!mounted) return;
          setState(() {
            _rebuildFastLookupCaches();
            int targetIndex = index;
            if (targetIndex < 0) {
              final emptyIdx =
                  _items.indexWhere((r) => r.item.text.trim().isEmpty);
              targetIndex = emptyIdx != -1 ? emptyIdx : _items.length;
            }
            while (targetIndex >= _items.length) {
              _addItemRow();
            }

            final itemName = itemData['name']?.toString() ?? '';
            _items[targetIndex].item.text = itemName;

            final matched = _itemCache[itemName.toLowerCase().trim()];
            if (matched != null) {
              _onItemMasterSelected(targetIndex, matched);
            }
          });

          created = true;
          _notify(existingItem != null ? 'Item updated!' : 'Registered: ${itemData['name']}');
        },
      ),
    );
    return created;
  }

  Future<bool> _openAddPartyDialog([PartyMasterModel? existingParty]) async {
    bool created = false;
    final folderPath = widget.company['folderPath']?.toString();

    await showDialog(
      context: context,
      builder: (_) => AddPartyDialog(
        voucherType: widget.voucherType,
        isEdit: existingParty != null,
        initialParty: existingParty,
        onPartyCreated: (data) async {
          // If creating a new party, persist it directly to disk
          if (existingParty == null && folderPath != null && folderPath.isNotEmpty) {
            try {
              final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
              final isCreditor = (data['group'] ?? '').toString().toLowerCase().contains('creditor');
              final listKey = isCreditor ? 'creditors' : 'debtors';

              final list = (raw[listKey] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

              list.add(data);
              raw[listKey] = list;
              await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
            } catch (e) {
              debugPrint('Error creating party: $e');
            }
          }

          // Reload from disk to keep local memory fresh
          await _loadCompanyMastersOnly();

          if (!mounted) return;
          setState(() {
            _rebuildFastLookupCaches();
            final partyName = data['name']?.toString() ?? '';
            _partyController.text = partyName;
          });

          created = true;
          _notify(existingParty != null ? 'Party updated!' : 'Registered: ${data['name']}');
        },
      ),
    );
    return created;
  }

  void _openQuickAddDialog(String masterType) {
    if (masterType == 'Account Ledger') return unawaited(_openAddPartyDialog());
    if (masterType == 'Item') {
      final idx = _items.indexWhere((i) => i.itemFocus.hasFocus);
      return unawaited(_openAddItemDialog(idx >= 0 ? idx : 0));
    }
    if (masterType == 'Series') {
      showDialog(
        context: context,
        builder: (_) => AddSeriesDialog(
          onSeriesCreated: (data) async {
            final name = data['name']?.toString() ?? 'Main';
            if (!mounted) return;
            setState(() {
              if (!_availableSeries.contains(name)) _availableSeries.add(name);
              _seriesSettings[name] = data;
              _seriesController.text = name;
            });
            await _syncMastersToFile();
            if (!mounted) return;
            _autogenerateVoucherNumber(name);
            _notify('Series "$name" configured successfully!');
          },
        ),
      );
    }
  }

  bool _handleAltE() {
    final focusedRow = _items.where((r) => r.itemFocus.hasFocus || r.amountFocus.hasFocus).firstOrNull;
    final originalItemName = focusedRow?.item.text.trim().toLowerCase() ?? '';

    return VoucherMasterActions.handleAltE(
      context: context,
      company: widget.company,
      partyFocus: _partyFocus,
      partyController: _partyController,
      availableParties: _currentAvailableParties,
      voucherType: widget.voucherType,
      items: _items,
      itemsMasterList: _itemsMasterList,
      onPartyUpdated: (updated) async {
        await _loadCompanyMastersOnly();
        if (!mounted) return;
        setState(() {
          _partyController.text = updated.displayName;
          _checkGstMode(autoAdjustSaleType: true);
          _refreshTaxesOnAllRows();
        });
      },
      onItemUpdated: (i, updated) async {
        await _loadCompanyMastersOnly();
        if (!mounted) return;
        setState(() {
          for (final r in _items.where((r) {
            final n = r.item.text.trim().toLowerCase();
            return n == originalItemName || n == updated.name.trim().toLowerCase();
          })) {
            r.item.text = updated.name;
            r.hsn = updated.hsn;
            r.unit.text = updated.unit;
            r.gstRate = updated.taxRate;
          }
          _onItemMasterSelected(i, updated);
        });
      },
      onSyncMasters: () async {
        // Reload directly from disk to keep local memory fresh without overwriting disk
        await _loadCompanyMastersOnly();
      },
    );
  }

  void _showValidationError(String msg, FocusNode? focus) {
    _notify(msg, bg: AppColors.error, icon: Icons.error_outline_rounded);
    focus?.requestFocus();
  }

  Map<String, dynamic> _buildCurrentVoucherPayload() {
    final persistentId = _activeEditingVoucher?['id'] ??
        widget.voucherToEdit?['id'] ??
        'vch_${DateTime.now().millisecondsSinceEpoch}';
    final totals = _totalsNotifier.value;
    final partyText = _partyController.text.trim();
    final partyState = _extractPartyStateCode(partyText);
    final partyGstin = GstPartyUtils.extractPartyGstin(partyText);
    final matchedParty = _partyCache[partyText.toLowerCase()];

    return {
      'id': persistentId,
      'voucherType': widget.voucherType,
      'voucherNumber': _vchNoController.text.trim(),
      'date': _dateController.text,
      'series': _seriesController.text,
      'saleType': _saleTypeController.text,
      'party': partyText,
      'partyGstin': partyGstin.isNotEmpty ? partyGstin : (matchedParty?.gstin ?? ''),
      'partyStateCode': partyState,
      'isInterState': _isInterState,
      'materialCenter': _matCenterController.text,
      'narration': _narrationController.text,
      'financialYear': widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear,
      'items': _items.where((i) => i.item.text.isNotEmpty).map((i) => {
            'item': i.item.text,
            'hsn': i.hsn.isNotEmpty
                ? i.hsn
                : (_itemCache[i.item.text.toLowerCase().trim()]?.hsn ?? ''),
            'qty': i.qty.text,
            'unit': i.unit.text.isNotEmpty ? i.unit.text : 'PCS',
            'price': i.price.text,
            'taxable': i.taxable.text,
            'cgst': i.cgst.text,
            'sgst': i.sgst.text,
            'igst': i.igst.text,
            'amount': i.amount.text,
            'gstRate': i.gstRate,
          }).toList(),
      'sundries': _sundries
          .where((s) => s.amount.text.isNotEmpty && s.amount.text != '0.00')
          .map((s) => {
                'name': s.name.text,
                'percent': s.percent.text,
                'amount': s.amount.text,
                'isNegative': s.isNegative,
              })
          .toList(),
      'subTotal': totals.subTotal,
      'cgst': totals.totalCgst,
      'sgst': totals.totalSgst,
      'igst': totals.totalIgst,
      'totalTax': totals.totalTax,
      'sundryTotal': totals.sundryTotal,
      'roundOff': totals.roundOff,
      'grandTotal': totals.grandTotal,
      'createdAt': _activeEditingVoucher?['createdAt'] ??
          widget.voucherToEdit?['createdAt'] ??
          DateTime.now().toIso8601String(),
    };
  }

  void _openPrintPreview() {
    showDialog(
      context: context,
      builder: (_) => SalesInvoicePrintPreviewDialog(
        company: widget.company,
        voucherData: _buildCurrentVoucherPayload(),
      ),
    );
  }

  Future<void> _saveVoucher() async {
    if (!_parseAndValidateDate() || _dateError != null) {
      return _showValidationError(
          _dateError ?? 'Valid Voucher Date required within F.Y.',
          _dateFocusNode);
    }
    if (_vchNoController.text.trim().isEmpty && !_allowEmptyVchNo) {
      return _showValidationError('Voucher Number is required.', _vchNoFocus);
    }
    final partyText = _partyController.text.trim();
    if (partyText.isEmpty || !_partyCache.containsKey(partyText.toLowerCase())) {
      return _showValidationError(
          'Select a valid registered Party Ledger.', _partyFocus);
    }

    final validItems = _items
        .where((i) =>
            i.item.text.trim().isNotEmpty &&
            (double.tryParse(i.qty.text) ?? 0) > 0 &&
            (double.tryParse(i.amount.text) ?? 0) > 0)
        .toList();

    if (validItems.isEmpty) {
      _showValidationError(
          'Add at least one item with Qty & Amount > 0.', null);
      _items.firstOrNull?.itemFocus.requestFocus();
      return;
    }

    final totals = _totalsNotifier.value;

    showDialog(
      context: context,
      builder: (_) => VoucherSaveConfirmDialog(
        summaryData: {
          'voucherType': widget.voucherType,
          'voucherNumber': _vchNoController.text.trim(),
          'date': _dateController.text,
          'party': partyText,
          'isInterState': _isInterState,
          'itemCount': validItems.length,
          'totalQty': totals.totalQty,
          'subTotal': totals.subTotal,
          'cgst': totals.totalCgst,
          'sgst': totals.totalSgst,
          'igst': totals.totalIgst,
          'sundryTotal': totals.sundryTotal,
          'roundOff': totals.roundOff,
          'grandTotal': totals.grandTotal,
        },
        onConfirm: _executeVoucherPersistence,
      ),
    );
  }

  Future<void> _executeVoucherPersistence() async {
    final payload = _buildCurrentVoucherPayload();
    final folderPath = widget.company['folderPath']?.toString();
    if (folderPath == null) return;

    final financialYear = widget.company['activeFinancialYear']?.toString() ??
        AppDateUtils.defaultFinancialYear;

    await StorageService.saveVoucher(
      folderPath: folderPath,
      financialYear: financialYear,
      voucherData: payload,
    );

    final syncWorker = ref.read(syncWorkerProvider);
    if (syncWorker != null) {
      final db = AppDatabase.forCompany(folderPath);
      try {
        await syncWorker.pushLocalMutation(db, payload);
      } catch (e) {
        debugPrint('SyncWorker pushLocalMutation error: $e');
      } finally {
        await db.close();
      }
    }

    if (!mounted) return;
    _notify('${widget.voucherType} [${_vchNoController.text}] saved!');

    if (!widget.isEdit) {
      final existingIdx = _sessionSavedVouchers.indexWhere(
        (v) =>
            (v['id'] ?? v['voucherNumber']) ==
            (payload['id'] ?? payload['voucherNumber']),
      );
      if (existingIdx != -1) {
        _sessionSavedVouchers[existingIdx] = payload;
      } else {
        _sessionSavedVouchers.add(payload);
      }
      _sessionIndex = -1;
    }

    if (_isSalesVoucher) {
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (ctx) => _PrintStudioConfirmDialog(
          vchNo: _vchNoController.text,
        ),
      );
      if ((shouldPrint ?? false) && mounted) {
        await showDialog(
          context: context,
          builder: (_) => SalesInvoicePrintPreviewDialog(
            company: widget.company,
            voucherData: payload,
          ),
        );
      }
    }
    if (!mounted) return;
    widget.isEdit ? widget.onClose() : _initializeNewVoucher();
  }

  void _navigateToPreviousVoucher() {
    if (_sessionSavedVouchers.isEmpty) return;
    if (_sessionIndex == -1) {
      _sessionIndex = _sessionSavedVouchers.length - 1;
      _loadExistingVoucherData(_sessionSavedVouchers[_sessionIndex]);
    } else if (_sessionIndex > 0) {
      _sessionIndex--;
      _loadExistingVoucherData(_sessionSavedVouchers[_sessionIndex]);
    }
    if (!mounted) return;
    setState(() {});
  }

  void _navigateToNextVoucher() {
    if (_sessionSavedVouchers.isEmpty || _sessionIndex == -1) return;
    if (_sessionIndex < _sessionSavedVouchers.length - 1) {
      _sessionIndex++;
      _loadExistingVoucherData(_sessionSavedVouchers[_sessionIndex]);
    } else if (_sessionIndex == _sessionSavedVouchers.length - 1) {
      _sessionIndex = -1;
      _initializeNewVoucher();
    }
    if (!mounted) return;
    setState(() {});
  }

  void _handleItemRowEnter(int index, String field) {
    final r = _items[index];
    switch (field) {
      case 'item':
        r.qtyFocus.requestFocus();
        break;
      case 'qty':
        r.priceFocus.requestFocus();
        break;
      case 'price':
        r.taxableFocus.requestFocus();
        break;
      case 'taxable':
        r.amountFocus.requestFocus();
        break;
      case 'amount':
        index + 1 < _items.length
            ? _items[index + 1].itemFocus.requestFocus()
            : _sundries.firstOrNull?.nameFocus.requestFocus();
        break;
    }
  }

  void _handleSundryRowEnter(int index, String field) {
    final s = _sundries[index];
    switch (field) {
      case 'name':
        s.percentFocus.requestFocus();
        break;
      case 'percent':
        s.amountFocus.requestFocus();
        break;
      case 'amount':
        index + 1 < _sundries.length
            ? _sundries[index + 1].nameFocus.requestFocus()
            : _saveButtonFocusNode.requestFocus();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear']?.toString() ??
        AppDateUtils.defaultFinancialYear;

    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherEntry,
      nodeMap: {
        FocusFieldNode.seriesField: _seriesFocus,
        FocusFieldNode.dateField: _dateFocusNode,
        FocusFieldNode.voucherNumberField: _vchNoFocus,
        FocusFieldNode.partyField: _partyFocus,
        FocusFieldNode.saleTypeField: _saleTypeFocus,
        FocusFieldNode.materialCenterField: _matCenterFocus,
        FocusFieldNode.narrationField: _narrationFocus,
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _requestExit();
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;

            if (KeyboardShortcutService.isPreviousVoucher(event)) {
              _navigateToPreviousVoucher();
              return KeyEventResult.handled;
            }

            if (KeyboardShortcutService.isNextVoucher(event)) {
              _navigateToNextVoucher();
              return KeyEventResult.handled;
            }

            if (KeyboardShortcutService.isPrint(event)) {
              _openPrintPreview();
              return KeyEventResult.handled;
            }

            if (KeyboardShortcutService.isModifyOrTaxDetails(event)) {
              if (_partyFocus.hasFocus) {
                if (_handleAltE()) return KeyEventResult.handled;
                return KeyEventResult.ignored;
              }

              for (int i = 0; i < _items.length; i++) {
                final r = _items[i];
                if (r.itemFocus.hasFocus) {
                  if (_handleAltE()) return KeyEventResult.handled;
                  return KeyEventResult.ignored;
                }
                if (r.amountFocus.hasFocus) {
                  _openTaxDetailsDialog(i);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            }

            if (KeyboardShortcutService.isCalculator(event)) {
              for (final r in _items) {
                final targets = [
                  MapEntry(r.qtyFocus, ('qty', r.qty)),
                  MapEntry(r.priceFocus, ('price', r.price)),
                  MapEntry(r.taxableFocus, ('taxable', r.taxable)),
                  MapEntry(r.amountFocus, ('amount', r.amount)),
                ];
                for (final e in targets) {
                  if (e.key.hasFocus) {
                    _openCalculatorForController(e.value.$2, r, e.value.$1);
                    return KeyEventResult.handled;
                  }
                }
              }
            }

            if (KeyboardShortcutService.isQuickAdd(event)) {
              if (_partyFocus.hasFocus) {
                _openAddPartyDialog();
                return KeyEventResult.handled;
              }
              if (_seriesFocus.hasFocus) {
                _openQuickAddDialog('Series');
                return KeyEventResult.handled;
              }
              if (_saleTypeFocus.hasFocus) {
                _openQuickAddDialog('Sale Type');
                return KeyEventResult.handled;
              }
              if (_matCenterFocus.hasFocus) {
                _openQuickAddDialog('Material Centre');
                return KeyEventResult.handled;
              }
              final idx = _items.indexWhere((i) => i.itemFocus.hasFocus);
              if (idx != -1) {
                _openAddItemDialog(idx);
                return KeyEventResult.handled;
              }
            }

            if (KeyboardShortcutService.matchesAction(
              widget.keyboardSettings,
              KeyboardShortcutService.saveVoucherAction,
              event,
            )) {
              _saveVoucher();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: _screenBg,
            body: Column(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: _topBarBg,
                  child: Row(
                    children: [
                      Icon(Icons.edit_document, size: 20, color: _themeColor),
                      const SizedBox(width: 8),
                      Text(
                        '${_isViewingExistingVoucher ? "EDIT" : "NEW"} ${widget.voucherType.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _themeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildTag(
                        'FY $fy',
                        AppColors.background,
                        AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildTag(
                        _isInterState
                            ? 'Inter-State (IGST)'
                            : 'Intra-State (CGST+SGST)',
                        _isInterState
                            ? AppColors.purpleLight
                            : AppColors.successLight,
                        _isInterState
                            ? AppColors.purple
                            : AppColors.successDark,
                        icon: _isInterState
                            ? Icons.alt_route_rounded
                            : Icons.check_circle_outline_rounded,
                        borderColor: _isInterState
                            ? AppColors.purpleBorder
                            : AppColors.successBorder,
                      ),
                      const Spacer(),
                      if (_isViewingExistingVoucher) ...[
                        OutlinedButton.icon(
                          onPressed: _openPrintPreview,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.borderFocus),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.print_rounded,
                              size: 15, color: AppColors.primary),
                          label: const Text(
                            'Print (Ctrl+P)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildScanButton(),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () =>
                            _openCalculatorForController(TextEditingController()),
                        icon: const Icon(Icons.calculate_outlined,
                            size: 16, color: AppColors.textSecondary),
                        label: const Text(
                          'Calc (F4)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Clear Voucher Data?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            content: const Text(
                              'This will reset all line items and headers for a fresh voucher entry.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _initializeNewVoucher();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(color: AppColors.surface),
                                ),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded,
                            size: 16, color: AppColors.textSecondary),
                        label: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: AppColors.textSecondary),
                        onPressed: _requestExit,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        VoucherHeaderCard(
                          seriesController: _seriesController,
                          seriesFocus: _seriesFocus,
                          availableSeries: _availableSeries,
                          dateController: _dateController,
                          dateFocus: _dateFocusNode,
                          dateError: _dateError,
                          vchNoController: _vchNoController,
                          vchNoFocus: _vchNoFocus,
                          partyController: _partyController,
                          partyFocus: _partyFocus,
                          availableParties: _currentAvailableParties,
                          saleTypeController: _saleTypeController,
                          saleTypeFocus: _saleTypeFocus,
                          matCenterController: _matCenterController,
                          matCenterFocus: _matCenterFocus,
                          narrationController: _narrationController,
                          narrationFocus: _narrationFocus,
                          onValidateDate: _parseAndValidateDate,
                          onQuickAdd: _openQuickAddDialog,
                          onAddParty: _openAddPartyDialog,
                          onNarrationSubmitted: () =>
                              _items.firstOrNull?.itemFocus.requestFocus(),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.tab &&
                                  !HardwareKeyboard.instance.isShiftPressed) {
                                _sundries.firstOrNull?.nameFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: ValueListenableBuilder<VoucherTotalsResult>(
                              valueListenable: _totalsNotifier,
                              builder: (context, totals, _) {
                                return VoucherItemsTable(
                                  items: _items,
                                  availableItems: _itemsMasterList,
                                  isInterState: _isInterState,
                                  totalQty: totals.totalQty,
                                  totalTaxable: totals.subTotal,
                                  totalAmount: totals.totalItemAmount,
                                  onAddRow: () => setState(_addItemRow),
                                  onRowEnter: _handleItemRowEnter,
                                  onAddItem: _openAddItemDialog,
                                  onItemSelected: _onItemMasterSelected,
                                  onOpenTaxDetails: _openTaxDetailsDialog,
                                  onTabToSundry: () => _sundries.firstOrNull?.nameFocus
                                      .requestFocus(),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 55,
                              child: ValueListenableBuilder<VoucherTotalsResult>(
                                valueListenable: _totalsNotifier,
                                builder: (context, totals, _) {
                                  return VoucherSundryCard(
                                    sundries: _sundries,
                                    availableSundries: _availableSundries,
                                    autoRoundOff: _autoRoundOff,
                                    roundOff: totals.roundOff,
                                    onAddSundry: () =>
                                        setState(_addSundryRow),
                                    onToggleRoundOff: () {
                                      _autoRoundOff = !_autoRoundOff;
                                      _calculateAllTotals();
                                    },
                                    onRowEnter: _handleSundryRowEnter,
                                    onTabToSave: () =>
                                        _saveButtonFocusNode.requestFocus(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 45,
                              child: ValueListenableBuilder<VoucherTotalsResult>(
                                valueListenable: _totalsNotifier,
                                builder: (context, totals, _) {
                                  return VoucherSummaryCard(
                                    isInterState: _isInterState,
                                    subTotal: totals.subTotal,
                                    totalCgst: totals.totalCgst,
                                    totalSgst: totals.totalSgst,
                                    totalIgst: totals.totalIgst,
                                    sundryTotal: totals.sundryTotal,
                                    roundOff: totals.roundOff,
                                    grandTotal: totals.grandTotal,
                                    saveButtonFocusNode: _saveButtonFocusNode,
                                    onSave: _saveVoucher,
                                    onClose: _requestExit,
                                    saveShortcutLabel:
                                        KeyboardShortcutService.labelForAction(
                                      widget.keyboardSettings,
                                      KeyboardShortcutService.saveVoucherAction,
                                    ),
                                    quitShortcutLabel:
                                        KeyboardShortcutService.labelForAction(
                                      widget.keyboardSettings,
                                      KeyboardShortcutService.goBackAction,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Shortcuts: ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _buildShortcutHint('[F2] Save'),
                      _buildShortcutHint('[Alt+P] Prev Vch'),
                      _buildShortcutHint('[Alt+N] Next Vch'),
                      if (_isEditingExisting)
                        _buildShortcutHint('[Ctrl+P] Print'),
                      _buildShortcutHint('[F4] Calculator'),
                      _buildShortcutHint('[Alt+C] Quick Add Master'),
                      _buildShortcutHint('[Alt+E] Edit Master / Tax Details'),
                      _buildShortcutHint('[Tab / Enter] Next Field'),
                      _buildShortcutHint('[Esc] Exit'),
                      const Spacer(),
                      const Text(
                        'Dhandas Modern Engine Active',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    String text,
    Color bg,
    Color fg, {
    IconData? icon,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: AppColors.aiScanGradient,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowGlow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _notify(
            'AI Scan: Initializing smart document recognition...',
            bg: AppColors.purple,
            icon: Icons.auto_awesome_rounded,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.surface),
                SizedBox(width: 6),
                Text(
                  'Scan with AI',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.overlayWhite20,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.overlayWhite40, width: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutHint(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PrintStudioConfirmDialog extends StatefulWidget {
  final String vchNo;

  const _PrintStudioConfirmDialog({required this.vchNo});

  @override
  State<_PrintStudioConfirmDialog> createState() =>
      _PrintStudioConfirmDialogState();
}

class _PrintStudioConfirmDialogState extends State<_PrintStudioConfirmDialog> {
  final FocusNode _openStudioFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _openStudioFocus.canRequestFocus) {
        _openStudioFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _openStudioFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Print Invoice',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Sales invoice [${widget.vchNo}] saved successfully.\n\nOpen Print Studio preview now?',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        Focus(
          focusNode: _openStudioFocus,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              Navigator.pop(context, true);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasFocus ? AppColors.primary : Colors.transparent,
                    width: 2.2,
                  ),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Open Print Studio',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}