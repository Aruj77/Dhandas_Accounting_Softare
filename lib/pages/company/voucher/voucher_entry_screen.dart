// lib/pages/company/voucher/voucher_entry_screen.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../models/company_model.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../models/voucher_header_controllers.dart';
import '../../../models/voucher_model.dart';
import '../../../provider/company_provider.dart';
import '../../../repositories/master_repository.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/scan_ai_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_calculation_service.dart';
import '../../../services/voucher_numbering_service.dart';
import '../../../utils/app_action_bottom_sheet.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../utils/math_expression_evaluator.dart';
import '../../../utils/number_parsing_utils.dart';
import '../../../widgets/voucher/popup/add_item_dialog.dart';
import '../../../widgets/voucher/popup/add_party_dialog.dart';
import '../../../widgets/voucher/popup/add_series_dialog.dart';
import '../../../widgets/voucher/popup/calculator_dialog.dart';
import '../../../widgets/voucher/popup/item_tax_details_dialog.dart';
import '../../../widgets/voucher/popup/print_studio_confirm_dialog.dart';
import '../../../widgets/voucher/popup/sales_invoice_print_preview_dialog.dart';
import '../../../widgets/voucher/popup/scan_review_dialog.dart';
import '../../../widgets/voucher/popup/voucher_dialog_utils.dart';
import '../../../widgets/voucher/popup/voucher_save_confirm_dialog.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
import '../../../widgets/voucher/voucher_summary_card.dart';
import '../../../widgets/voucher/voucher_sundry_card.dart';
import '../../../widgets/voucher/voucher_sundry_row.dart';

enum _ScanDocumentSource { camera, gallery, pdf }

class VoucherEntryScreen extends ConsumerStatefulWidget {
  final CompanyModel company;
  final String voucherType;
  final VoidCallback onClose;
  final KeyboardShortcutSettings keyboardSettings;
  final VoucherModel? voucherToEdit;
  final bool isEdit;
  final VoucherModel? scanPrefill;

  const VoucherEntryScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onClose,
    required this.keyboardSettings,
    this.voucherToEdit,
    this.isEdit = false,
    this.scanPrefill,
  });

  @override
  ConsumerState<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends ConsumerState<VoucherEntryScreen> {
  final _h = VoucherHeaderControllers();
  final _totalsNotifier = ValueNotifier<VoucherTotalsResult>(
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

  final List<VoucherModel> _sessionSavedVouchers = [];
  int _sessionIndex = -1;
  late bool _isEditingExisting;
  VoucherModel? _activeEditingVoucher;

  final List<VoucherItemRow> _items = [];
  final List<VoucherSundryRow> _sundries = [];
  final List<String> _availableSeries = ['Main'];
  final Map<String, dynamic> _seriesSettings = {};

  List<PartyMasterModel> _debtorsList = [];
  List<PartyMasterModel> _creditorsList = [];
  List<ItemMasterModel> _itemsMasterList = [];

  Map<String, ItemMasterModel> _itemCache = {};
  Map<String, PartyMasterModel> _partyCache = {};

  List<String> _availableSaleTypes = [];
  List<String> _availableSundries = [];
  List<String> _availableMaterialCenters = [];

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

  bool _isItemDialogOpen = false;
  bool _isPartyDialogOpen = false;
  bool _isSeriesDialogOpen = false;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  Timer? _debounceTimer;

  CompanyModel get _currentCompany {
    final active = ref.read(activeCompanyProvider);
    if (active is CompanyModel) return active;
    return widget.company;
  }

  bool get _isSalesVoucher => widget.voucherType.toLowerCase().contains('sale');
  List<PartyMasterModel> get _currentParties =>
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
    _attachHeaderListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(activeCompanyProvider) == null) {
        ref.read(activeCompanyProvider.notifier).state = widget.company;
      }
    });

    if (widget.isEdit && widget.voucherToEdit != null) {
      _loadExistingVoucherData(widget.voucherToEdit!);
    } else if (widget.scanPrefill != null) {
      _applyScanPrefill(widget.scanPrefill!);
    } else {
      _loadCompanyMastersOnly().then((_) => _initializeNewVoucher());
    }
  }

  @override
  void didUpdateWidget(covariant VoucherEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company.id != widget.company.id ||
        oldWidget.voucherType != widget.voucherType) {
      _loadCompanyMastersOnly().then((_) {
        if (mounted) {
          setState(() {
            _checkGstMode(autoAdjustSaleType: true);
            _refreshTaxesOnAllRows();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _totalsNotifier.dispose();
    _h.dispose();
    for (final i in _items) {
      i.dispose();
    }
    for (final s in _sundries) {
      s.dispose();
    }
    super.dispose();
  }

  String _formatPartyDisplay(String name, String gstin) =>
      GstPartyUtils.formatPartyDisplay(name, gstin);

  PartyMasterModel? _findParty(String text) {
    final clean = text.trim().toLowerCase();
    if (_partyCache.containsKey(clean)) return _partyCache[clean];
    final nameOnly = GstPartyUtils.extractPartyName(text).trim().toLowerCase();
    return _partyCache[nameOnly];
  }

  void _rebuildFastLookupCaches() {
    _itemCache = {
      for (final i in _itemsMasterList) i.name.toLowerCase().trim(): i,
    };
    _partyCache = {
      for (final p in _currentParties) ...{
        p.name.toLowerCase().trim(): p,
        if (p.gstin.isNotEmpty) ...{
          '${p.name} (${p.gstin})'.toLowerCase().trim(): p,
          '${p.name} - ${p.gstin}'.toLowerCase().trim(): p,
          p.gstin.toLowerCase().trim(): p,
        },
      },
    };
  }

  void _scheduleRecalculation([VoidCallback? action]) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      action?.call();
      _calculateAllTotals();
    });
  }

  void _calculateAllTotals() {
    final subTotal = _totalsNotifier.value.subTotal;
    for (final s in _sundries) {
      final name = s.name.text.toLowerCase();
      if (!name.contains('round') &&
          !name.contains('rnd') &&
          s.percent.text.isNotEmpty &&
          !s.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromPercent(s, subTotal);
      }
    }

    _totalsNotifier.value = VoucherCalculationService.calculateTotals(
      items: _items,
      sundries: _sundries,
      isInterState: _isInterState,
      autoRoundOff: _autoRoundOff,
    );
  }

  bool _isAnyItemCellFocused() => _items.any((r) => [
        r.itemFocus,
        r.qtyFocus,
        r.unitFocus,
        r.priceFocus,
        r.taxableFocus,
        r.cgstFocus,
        r.sgstFocus,
        r.igstFocus,
        r.amountFocus,
      ].any((f) => f.hasFocus));

  bool _isAnySundryCellFocused() => _sundries.any(
      (s) => [s.nameFocus, s.percentFocus, s.amountFocus].any((f) => f.hasFocus));

  bool _handleSmartCtrlC() {
    try {
      final primaryFocus = FocusManager.instance.primaryFocus;
      final context = primaryFocus?.context;

      if (context != null) {
        final editableState =
            context.findAncestorStateOfType<EditableTextState>();
        if (editableState != null) {
          final sel = editableState.textEditingValue.selection;
          if (!sel.isCollapsed && sel.start != sel.end) {
            return false;
          }
        }
      }
    } catch (_) {}

    return _handleQuickAddShortcut();
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.quickAddMasterAction, event)) if (_handleSmartCtrlC()) return true;
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.modifyMasterAction, event)) if (_handleCtrlE()) return true;
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.previousVoucherAction, event)) {
      _navigateToPreviousVoucher();
      return true;
    }
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.nextVoucherAction, event)) {
      _navigateToNextVoucher();
      return true;
    }
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.saveVoucherAction, event)) {
      _saveVoucher();
      return true;
    }
    if (KeyboardShortcutService.isTab(event, requireUnshifted: true)) {
      if (_isAnyItemCellFocused()) {
        _sundries.firstOrNull?.nameFocus.requestFocus();
        return true;
      }
      if (_isAnySundryCellFocused()) {
        _h.saveButtonFocus.requestFocus();
        return true;
      }
    }

    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.goBackAction, event)) {
      _requestExit();
      return true;
    }
    return false;
  }

  KeyEventResult _onGlobalKeyAction(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.printInvoiceAction, event)) {
      _openPrintPreview();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.calculatorAction, event)) {
      for (final r in _items) {
        final targets = [
          (r.qtyFocus, 'qty', r.qty),
          (r.priceFocus, 'price', r.price),
          (r.taxableFocus, 'taxable', r.taxable),
          (r.amountFocus, 'amount', r.amount),
        ];
        for (final (focus, name, ctrl) in targets) {
          if (focus.hasFocus) {
            _openCalculatorForController(ctrl, r, name);
            return KeyEventResult.handled;
          }
        }
      }
    }

    return KeyEventResult.ignored;
  }

  Future<void> _requestExit() async {
    if (_isExitDialogOpen) return;
    _isExitDialogOpen = true;
    final shouldExit = await VoucherDialogUtils.showUnsavedChangesDialog(context);
    _isExitDialogOpen = false;
    if (shouldExit && mounted) widget.onClose();
  }

  void _notify(String msg, {Color bg = AppColors.success, IconData? icon}) {
    if (!mounted) return;
    NotificationService.show(
      context,
      message: msg,
      type: bg == AppColors.error ? NotificationType.error : NotificationType.success,
      icon: icon,
    );
  }

  void _applyScanPrefill(VoucherModel v) {
    if (!mounted) return;

    _h.date.text = v.date;
    _h.vchNo.text = v.voucherNumber;
    _h.party.text = _formatPartyDisplay(v.party, v.partyGstin);
    _allowEmptyVchNo = _h.vchNo.text.trim().isEmpty;
    _allowDuplicateVchNo = true;

    _items.clear();
    for (final i in v.items) {
      final row = VoucherItemRow()
        ..item.text = i.item
        ..hsn = i.hsn
        ..qty.text = i.qty % 1 == 0 ? i.qty.toInt().toString() : i.qty.toString()
        ..unit.text = i.unit
        ..price.text = i.price > 0 ? i.price.toCurrency() : ''
        ..gstRate = i.gstRate;
      _attachItemRowListeners(row);
      _items.add(row);
    }
    while (_items.length < 15) {
      _addItemRow();
    }

    _loadCompanyMastersOnly();
    _calculateAllTotals();
  }

  void _loadExistingVoucherData(VoucherModel v) {
    if (!mounted) return;
    setState(() {
      _isEditingExisting = true;
      _activeEditingVoucher = v;
    });

    final series = v.series.isNotEmpty ? v.series : 'Main';
    _h.series.text = series;
    if (!_availableSeries.contains(series)) _availableSeries.add(series);

    _h.date.text = v.date;
    _h.vchNo.text = v.voucherNumber;
    _h.party.text = _formatPartyDisplay(v.party, v.partyGstin);
    _h.saleType.text = v.saleType;
    _h.matCenter.text = v.materialCenter;
    _h.narration.text = v.narration;
    _isInterState = v.isInterState;
    _allowEmptyVchNo = v.voucherNumber.isEmpty;
    _allowDuplicateVchNo = true;

    final bounds = _currentCompany.fyBounds;
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _items.clear();
    for (final i in v.items) {
      final row = VoucherItemRow()
        ..item.text = i.item
        ..hsn = i.hsn
        ..qty.text = i.qty % 1 == 0 ? i.qty.toInt().toString() : i.qty.toString()
        ..unit.text = i.unit
        ..price.text = i.price > 0 ? i.price.toCurrency() : ''
        ..taxable.text = i.taxable > 0 ? i.taxable.toCurrency() : ''
        ..cgst.text = i.cgst > 0 ? i.cgst.toCurrency() : ''
        ..sgst.text = i.sgst > 0 ? i.sgst.toCurrency() : ''
        ..igst.text = i.igst > 0 ? i.igst.toCurrency() : ''
        ..amount.text = i.amount > 0 ? i.amount.toCurrency() : ''
        ..gstRate = i.gstRate;
      _attachItemRowListeners(row);
      _items.add(row);
    }
    while (_items.length < 15) {
      _addItemRow();
    }

    _sundries.clear();
    for (final s in v.sundries) {
      final row = VoucherSundryRow()
        ..name.text = s.name
        ..percent.text = s.percent
        ..amount.text = s.amount > 0 ? s.amount.toCurrency() : ''
        ..isNegative = s.isNegative;
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
      final folderPath = _currentCompany.folderPath;
      if (folderPath.isEmpty) return;
      final masters = await MasterRepository.loadMasters(folderPath: folderPath);
      if (!mounted) return;

      _debtorsList = masters.debtors;
      _creditorsList = masters.creditors;
      _itemsMasterList = masters.items;

      _rebuildFastLookupCaches();

      _availableSeries
        ..clear()
        ..addAll(masters.series);
      if (!_availableSeries.contains('Main')) _availableSeries.insert(0, 'Main');

      _seriesSettings
        ..clear()
        ..addAll(masters.seriesSettings);

      _availableSaleTypes = masters.saleTypes;
      _availableSundries = masters.billSundries;
      _availableMaterialCenters = masters.materialCenters;

      if (_h.matCenter.text.isEmpty && _availableMaterialCenters.isNotEmpty) {
        _h.matCenter.text = _availableMaterialCenters.first;
      }

      if (mounted) setState(() {});
    }, message: 'Loading Master Records...');
  }

  Future<void> _autogenerateVoucherNumber(String seriesName) async {
    await LoadingService.wrap(() async {
      final nextNo = await VoucherNumberingService.autogenerate(
        company: _currentCompany.toJson(),
        voucherType: widget.voucherType,
        seriesName: seriesName,
        seriesSettings: _seriesSettings[seriesName] ?? {},
      );
      if (nextNo != null && mounted) {
        setState(() => _h.vchNo.text = nextNo);
      }
    }, message: '');
  }

  bool _evaluateController(TextEditingController controller, {bool isQty = false}) {
    final text = controller.text.trim();
    if (text.isEmpty) return false;

    final evaluated = MathExpressionEvaluator.tryEvaluate(text);
    if (evaluated != null) {
      final formatted = MathExpressionEvaluator.formatResult(evaluated, isQty: isQty);
      if (controller.text != formatted) {
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        return true;
      }
    }
    return false;
  }

  void _evaluateAndRecalculateItemField(VoucherItemRow row, String field) {
    final isQty = field == 'qty';
    final ctrl = switch (field) {
      'qty' => row.qty,
      'price' => row.price,
      'taxable' => row.taxable,
      'amount' => row.amount,
      _ => null,
    };

    if (ctrl != null) _evaluateController(ctrl, isQty: isQty);

    final q = row.qty.text.evalMath();
    final p = row.price.text.evalMath();

    if (field == 'qty' || field == 'price') {
      if (q > 0 && p > 0) {
        row.taxable.text = (q * p).toCurrency();
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
      }
    } else if (field == 'taxable') {
      final t = row.taxable.text.evalMath();
      if (t > 0) {
        if (q > 0) row.price.text = (t / q).toCurrency();
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
      }
    } else if (field == 'amount') {
      final amt = row.amount.text.evalMath();
      if (amt > 0) {
        VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
      }
    }
    _calculateAllTotals();
  }

  void _attachItemRowListeners(VoucherItemRow row) {
    row.itemFocus.addListener(() {
      if (row.itemFocus.hasFocus || _isHandlingMasterNotFound) return;
      final text = row.item.text.trim();
      if (text.isEmpty) return;

      final matched = _itemCache[text.toLowerCase()];
      if (matched != null) {
        final index = _items.indexOf(row);
        if (index != -1) _onItemMasterSelected(index, matched);
        return;
      }

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
    });

    void recalculateFromQtyOrPrice() {
      final qText = row.qty.text.trim();
      final pText = row.price.text.trim();

      if (qText.isEmpty && pText.isEmpty) {
        _clearRowTaxes(row);
        return;
      }

      final q = qText.evalMath();
      final p = pText.evalMath();

      if (q > 0 && p > 0) {
        row.taxable.text = (q * p).toCurrency();
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
      }
    }

    row.qty.addListener(() {
      if (row.qtyFocus.hasFocus) _scheduleRecalculation(recalculateFromQtyOrPrice);
    });
    row.price.addListener(() {
      if (row.priceFocus.hasFocus) _scheduleRecalculation(recalculateFromQtyOrPrice);
    });

    row.qtyFocus.addListener(() {
      if (!row.qtyFocus.hasFocus) _evaluateAndRecalculateItemField(row, 'qty');
    });
    row.priceFocus.addListener(() {
      if (!row.priceFocus.hasFocus) _evaluateAndRecalculateItemField(row, 'price');
    });
    row.taxableFocus.addListener(() {
      if (!row.taxableFocus.hasFocus) _evaluateAndRecalculateItemField(row, 'taxable');
    });
    row.amountFocus.addListener(() {
      if (!row.amountFocus.hasFocus) _evaluateAndRecalculateItemField(row, 'amount');
    });

    row.taxable.addListener(() {
      if (!row.taxableFocus.hasFocus) return;
      _scheduleRecalculation(() {
        final tText = row.taxable.text.trim();
        if (tText.isEmpty) {
          _clearRowTaxes(row);
          return;
        }

        final t = tText.evalMath();
        final q = row.qty.text.evalMath();

        if (t > 0) {
          if (q > 0 && !row.priceFocus.hasFocus) {
            row.price.text = (t / q).toCurrency();
          }
          VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
        }
      });
    });

    for (final node in [row.cgst, row.sgst, row.igst]) {
      node.addListener(() {
        if (row.cgstFocus.hasFocus ||
            row.sgstFocus.hasFocus ||
            row.igstFocus.hasFocus) {
          _scheduleRecalculation(() {
            final t = row.taxable.text.evalMath();
            final tax = _isInterState
                ? row.igst.text.toCleanDouble()
                : (row.cgst.text.toCleanDouble() + row.sgst.text.toCleanDouble());
            row.amount.text = (t + tax) == 0 ? '' : (t + tax).toCurrency();
          });
        }
      });
    }

    row.amount.addListener(() {
      if (!row.amountFocus.hasFocus) return;
      _scheduleRecalculation(() {
        final aText = row.amount.text.trim();
        if (aText.isEmpty) {
          _clearRowTaxes(row);
          return;
        }

        final amt = aText.evalMath();
        if (amt > 0) {
          final originalText = row.amount.text;
          row.amount.text = amt.toCurrency();
          VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
          if (row.amountFocus.hasFocus && row.amount.text != originalText) {
            row.amount.value = TextEditingValue(
              text: originalText,
              selection: TextSelection.collapsed(offset: originalText.length),
            );
          }
        }
      });
    });
  }

  void _clearRowTaxes(VoucherItemRow row) {
    row.taxable.clear();
    row.cgst.clear();
    row.sgst.clear();
    row.igst.clear();
    row.amount.clear();
  }

  void _attachSundryRowListeners(VoucherSundryRow row) {
    row.name.addListener(() {
      _applySundryAutoValue(row);
      _calculateAllTotals();
    });
    row.percent.addListener(() {
      if (row.percentFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromPercent(
            row, _totalsNotifier.value.subTotal);
        _calculateAllTotals();
      }
    });
    row.amount.addListener(() {
      if (row.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromAmount(
            row, _totalsNotifier.value.subTotal);
        _calculateAllTotals();
      }
    });
  }

  void _attachHeaderListeners() {
    _h.dateFocus.addListener(() {
      if (!_h.dateFocus.hasFocus) _parseAndValidateDate();
    });

    _h.vchNoFocus.addListener(() {
      if (_h.vchNoFocus.hasFocus) {
        _allowEmptyVchNo = false;
      } else {
        _checkVoucherNumberOnBlur();
      }
    });

    _h.vchNo.addListener(() => _allowDuplicateVchNo = false);

    _h.partyFocus.addListener(() {
      if (_h.partyFocus.hasFocus || _isHandlingMasterNotFound) return;
      final text = _h.party.text.trim();
      if (text.isEmpty) return;

      final matched = _findParty(text);
      if (matched != null) {
        final formatted = _formatPartyDisplay(matched.name, matched.gstin);
        if (_h.party.text != formatted) {
          _h.party.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
        if (mounted) {
          setState(() {
            _checkGstMode(autoAdjustSaleType: true);
            _refreshTaxesOnAllRows();
          });
        }
        return;
      }

      _isHandlingMasterNotFound = true;
      VoucherDialogUtils.showMasterNotFoundDialog(
        context: context,
        title: 'Party not added in Master',
        message:
            '"$text" does not exist in your account ledger masters. Would you like to add it now?',
        onAdd: () async {
          if (!(await _openAddPartyDialog())) {
            _h.party.clear();
            _h.partyFocus.requestFocus();
          }
          _isHandlingMasterNotFound = false;
        },
        onCancel: () {
          _h.party.clear();
          _h.partyFocus.requestFocus();
          _isHandlingMasterNotFound = false;
        },
      );
    });

    _h.series.addListener(() => _autogenerateVoucherNumber(_h.series.text));
    _h.party.addListener(() {
      if (mounted) {
        setState(() {
          _checkGstMode(autoAdjustSaleType: true);
          _refreshTaxesOnAllRows();
        });
      }
    });
    _h.saleType.addListener(() {
      if (!_isAutoAdjustingSaleType && !_isHandlingTaxMismatch) {
        _handleManualSaleTypeChange();
      }
    });
  }

  Future<void> _checkVoucherNumberOnBlur() async {
    if (_isHandlingVchNoWarning ||
        _isHandlingDuplicateVchWarning ||
        _isEditingExisting) {
      return;
    }
    final vchText = _h.vchNo.text.trim();

    if (vchText.isEmpty) {
      if (!_allowEmptyVchNo) {
        _isHandlingVchNoWarning = true;
        VoucherDialogUtils.showMissingVchNoWarning(
          context: context,
          onConfirm: () {
            _allowEmptyVchNo = true;
            _isHandlingVchNoWarning = false;
            _h.partyFocus.requestFocus();
          },
          onCancel: () {
            _allowEmptyVchNo = false;
            _isHandlingVchNoWarning = false;
            _h.vchNoFocus.requestFocus();
          },
        );
      }
      return;
    }

    if (_allowDuplicateVchNo) return;
    final folderPath = _currentCompany.folderPath;
    final fy = _currentCompany.activeFinancialYear;
    if (folderPath.isEmpty) return;

    final existingVouchers = await StorageService.loadVouchers(
      folderPath: folderPath,
      financialYear: fy,
      voucherType: widget.voucherType,
      seriesName: _h.series.text.trim(),
    );
    if (!mounted) return;

    final currentId = _activeEditingVoucher?.id ?? widget.voucherToEdit?.id;
    final match = existingVouchers
        .map((e) => VoucherModel.fromJson(e))
        .firstWhereOrNull((v) =>
            v.voucherNumber.toLowerCase() == vchText.toLowerCase() &&
            v.id != currentId);

    if (match != null && mounted) {
      _isHandlingDuplicateVchWarning = true;
      final assignedParty = GstPartyUtils.extractPartyName(match.party);
      final displayName = assignedParty.isNotEmpty
          ? assignedParty
          : _currentCompany.companyName;

      VoucherDialogUtils.showDuplicateVchNoWarning(
        context: context,
        companyName: displayName,
        onNo: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = false;
          _h.vchNo.clear();
          _h.vchNoFocus.requestFocus();
        },
        onOpenVoucher: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = true;
          _loadExistingVoucherData(match);
        },
        onYes: () {
          _isHandlingDuplicateVchWarning = false;
          _allowDuplicateVchNo = true;
          _h.partyFocus.requestFocus();
        },
      );
    }
  }

  void _handleManualSaleTypeChange() {
    if (_isHandlingTaxMismatch) return;
    final currentSaleType = _h.saleType.text.trim();
    final isExplicitLocal = currentSaleType.startsWith('Local');
    final isExplicitInterState = currentSaleType.startsWith('InterState');
    if (!isExplicitLocal && !isExplicitInterState) return;

    final compState = _currentCompany.stateCode;
    final partyState = _extractPartyStateCode(_h.party.text);

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
            _h.saleType.text =
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
    final rawText = _h.date.text.trim();
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
    _h.date.text = AppDateUtils.formatDate(parsed);
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
              TextPosition(offset: controller.text.length));
          if (row != null && fieldName != null) {
            _evaluateAndRecalculateItemField(row, fieldName);
          }
          _calculateAllTotals();
        },
      ),
    );
  }

  void _initializeNewVoucher() {
    if (!mounted) return;
    final bounds = _currentCompany.fyBounds;
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _h.clearVoucherSpecifics(
      defaultSaleType: _availableSaleTypes.firstOrNull ?? 'Local Itemwise',
      defaultMatCenter: _availableMaterialCenters.firstOrNull ?? 'Main Store',
    );
    _isInterState = false;
    _allowEmptyVchNo = false;
    _allowDuplicateVchNo = false;
    _isHandlingVchNoWarning = false;
    _isHandlingDuplicateVchWarning = false;
    _isHandlingTaxMismatch = false;
    _isEditingExisting = false;
    _activeEditingVoucher = null;

    final now = DateTime.now();
    _h.date.text = (now.isAfter(_fyStartDate) && now.isBefore(_fyEndDate))
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
    _autogenerateVoucherNumber(_h.series.text);

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_h.dateFocus.canRequestFocus) _h.dateFocus.requestFocus();
      });
    }
  }

  String _extractPartyStateCode(String partyText) {
    final matched = _findParty(partyText);
    final partyGstin = matched?.gstin.trim() ?? '';
    return GstPartyUtils.extractStateCode(
      partyText,
      fallbackStateCode: partyGstin.length >= 2 ? partyGstin.substring(0, 2) : '',
    );
  }

  void _checkGstMode({bool autoAdjustSaleType = false}) {
    final compState = _currentCompany.stateCode;
    final partyState = _extractPartyStateCode(_h.party.text);
    _isInterState = partyState.isNotEmpty && compState != partyState;
    if (autoAdjustSaleType) {
      final currentType = _h.saleType.text;
      final suffix = currentType.contains('Multirate')
          ? 'Multirate'
          : (currentType.contains('Exempt') ? 'Exempt' : 'Itemwise');
      final targetType = '${_isInterState ? "InterState" : "Local"} $suffix';
      if (_h.saleType.text != targetType) {
        _isAutoAdjustingSaleType = true;
        _h.saleType.text = targetType;
        _isAutoAdjustingSaleType = false;
      }
    }
  }

  void _refreshTaxesOnAllRows() {
    for (final row in _items) {
      if (row.taxable.text.isNotEmpty) {
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
      } else if (row.amount.text.isNotEmpty) {
        VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
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
          final a = s.amount.text.toCleanDouble();
          baseSum += (s.name.text.contains('-') || s.isNegative) ? -a : a;
        }
      }
      final remainder = baseSum % 1.0;
      final isAdd = sundry.name.text.contains('+');
      final diff = isAdd ? (remainder == 0 ? 0.0 : 1.0 - remainder) : remainder;
      sundry.amount.text = diff > 0 ? diff.toCurrency() : '';
      sundry.percent.clear();
      sundry.isNegative = !isAdd;
    } else if (sundry.percent.text.isNotEmpty) {
      VoucherCalculationService.recalculateSundryFromPercent(
          sundry, _totalsNotifier.value.subTotal);
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
    if (defaultPrice > 0 && row.price.text.isEmpty) {
      row.price.text = defaultPrice.toCurrency();
    }

    final q = row.qty.text.evalMath();
    final p = row.price.text.evalMath();
    if (q > 0 && p > 0) {
      row.taxable.text = (q * p).toCurrency();
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.taxable.text.isNotEmpty) {
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.amount.text.isNotEmpty) {
      VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
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
    if (_isItemDialogOpen) return false;
    _isItemDialogOpen = true;
    bool created = false;

    try {
      final itemData = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => AddItemDialog(
          company: _currentCompany.toJson(),
          folderPath: _currentCompany.folderPath,
          isEdit: existingItem != null,
          initialItem: existingItem,
        ),
      );

      if (itemData != null && mounted) {
        created = true;
        final folderPath = _currentCompany.folderPath;
        if (folderPath.isNotEmpty) {
          await MasterRepository.upsertItem(
            folderPath: folderPath,
            item: ItemMasterModel.fromJson(itemData),
            oldName: existingItem?.name,
          );
        }

        await _loadCompanyMastersOnly();
        if (!mounted) return created;
        setState(() {
          _rebuildFastLookupCaches();
          int targetIndex = index;
          if (targetIndex < 0) {
            final emptyIdx = _items.indexWhere((r) => r.item.text.trim().isEmpty);
            targetIndex = emptyIdx != -1 ? emptyIdx : _items.length;
          }
          while (targetIndex >= _items.length) {
            _addItemRow();
          }

          final itemName = itemData['name']?.toString() ?? '';
          _items[targetIndex].item.text = itemName;

          final matched = _itemCache[itemName.toLowerCase().trim()];
          if (matched != null) _onItemMasterSelected(targetIndex, matched);
        });

        _notify(existingItem != null ? 'Item updated!' : 'Registered: ${itemData['name']}');
      }
    } finally {
      _isItemDialogOpen = false;
    }
    return created;
  }

  Future<bool> _openAddPartyDialog([PartyMasterModel? existingParty]) async {
    if (_isPartyDialogOpen) return false;
    _isPartyDialogOpen = true;
    bool created = false;
    final folderPath = _currentCompany.folderPath;

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AddPartyDialog(
          voucherType: widget.voucherType,
          isEdit: existingParty != null,
          initialParty: existingParty,
          onPartyCreated: (data) async {
            created = true;
            if (folderPath.isNotEmpty) {
              await MasterRepository.upsertParty(
                folderPath: folderPath,
                party: PartyMasterModel.fromJson(data),
                oldName: existingParty?.name,
              );
            }
          },
        ),
      );

      if (result != null && mounted) {
        await _loadCompanyMastersOnly();
        if (!mounted) return true;
        setState(() {
          _rebuildFastLookupCaches();
          final partyName = result['name']?.toString() ?? '';
          final gstin = result['gstin']?.toString() ?? '';
          _h.party.text = _formatPartyDisplay(partyName, gstin);
          _checkGstMode(autoAdjustSaleType: true);
          _refreshTaxesOnAllRows();
        });

        _notify(existingParty != null ? 'Party updated!' : 'Registered: ${result['name']}');
      }
    } finally {
      _isPartyDialogOpen = false;
    }
    return created;
  }

  void _openQuickAddDialog(String masterType) {
    if (_isSeriesDialogOpen) return;
    switch (masterType) {
      case 'Account Ledger':
        unawaited(_openAddPartyDialog());
      case 'Item':
        final idx = _items.indexWhere((i) => i.itemFocus.hasFocus);
        unawaited(_openAddItemDialog(idx >= 0 ? idx : 0));
      case 'Series':
        _isSeriesDialogOpen = true;
        showDialog(
          context: context,
          builder: (dialogContext) => AddSeriesDialog(
            onSeriesCreated: (data) async {
              if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop(true);
              }
              final name = data['name']?.toString() ?? 'Main';
              final folderPath = _currentCompany.folderPath;
              if (folderPath.isNotEmpty) {
                await MasterRepository.upsertSeries(
                  folderPath: folderPath,
                  seriesName: name,
                  seriesSettings: data,
                );
              }
              if (!mounted) return;
              setState(() {
                if (!_availableSeries.contains(name)) _availableSeries.add(name);
                _seriesSettings[name] = data;
                _h.series.text = name;
              });
              _autogenerateVoucherNumber(name);
              _notify('Series "$name" configured successfully!');
            },
          ),
        ).then((_) => _isSeriesDialogOpen = false);
    }
  }

  bool _handleQuickAddShortcut() {
    if (_h.partyFocus.hasFocus) {
      unawaited(_openAddPartyDialog());
      return true;
    }
    if (_h.seriesFocus.hasFocus) {
      _openQuickAddDialog('Series');
      return true;
    }
    if (_h.saleTypeFocus.hasFocus) {
      _openQuickAddDialog('Sale Type');
      return true;
    }
    if (_h.matCenterFocus.hasFocus) {
      _openQuickAddDialog('Material Centre');
      return true;
    }

    final focusedItemIdx = _items.indexWhere((i) => [
          i.itemFocus,
          i.qtyFocus,
          i.unitFocus,
          i.priceFocus,
          i.taxableFocus,
          i.cgstFocus,
          i.sgstFocus,
          i.igstFocus,
          i.amountFocus,
        ].any((f) => f.hasFocus));

    if (focusedItemIdx != -1) {
      unawaited(_openAddItemDialog(focusedItemIdx));
      return true;
    }

    if (_h.party.text.trim().isEmpty) {
      unawaited(_openAddPartyDialog());
    } else {
      final emptyItemIdx = _items.indexWhere((i) => i.item.text.trim().isEmpty);
      unawaited(_openAddItemDialog(emptyItemIdx != -1 ? emptyItemIdx : 0));
    }
    return true;
  }

  bool _handleCtrlE() {
    if (_h.partyFocus.hasFocus) {
      final partyText = _h.party.text.trim();
      final party = _findParty(partyText);
      unawaited(_openAddPartyDialog(party));
      return true;
    }

    for (int i = 0; i < _items.length; i++) {
      final r = _items[i];
      final isItemRowFocused = [
        r.itemFocus,
        r.qtyFocus,
        r.unitFocus,
        r.priceFocus,
        r.taxableFocus,
        r.cgstFocus,
        r.sgstFocus,
        r.igstFocus,
      ].any((f) => f.hasFocus);

      if (isItemRowFocused) {
        final itemName = r.item.text.trim().toLowerCase();
        final item = _itemCache[itemName] ??
            _itemsMasterList.firstWhereOrNull(
              (it) => it.name.trim().toLowerCase() == itemName,
            );
        unawaited(_openAddItemDialog(i, item));
        return true;
      }

      if (r.amountFocus.hasFocus) {
        _openTaxDetailsDialog(i);
        return true;
      }
    }

    if (_h.party.text.trim().isNotEmpty) {
      final party = _findParty(_h.party.text.trim());
      unawaited(_openAddPartyDialog(party));
      return true;
    }

    final firstFilledItem = _items.firstWhereOrNull((i) => i.item.text.trim().isNotEmpty);
    if (firstFilledItem != null) {
      final idx = _items.indexOf(firstFilledItem);
      final item = _itemCache[firstFilledItem.item.text.trim().toLowerCase()];
      unawaited(_openAddItemDialog(idx, item));
      return true;
    }

    return false;
  }

  void _showValidationError(String msg, FocusNode? focus) {
    _notify(msg, bg: AppColors.error, icon: Icons.error_outline_rounded);
    focus?.requestFocus();
  }

  VoucherModel _buildCurrentVoucherPayload() {
    final totals = _totalsNotifier.value;
    final partyText = _h.party.text.trim();
    final partyState = _extractPartyStateCode(partyText);
    final partyGstin = GstPartyUtils.extractPartyGstin(partyText);
    final matchedParty = _findParty(partyText);
    final cleanPartyName = matchedParty?.name ?? GstPartyUtils.extractPartyName(partyText).trim();

    return VoucherModel(
      id: _activeEditingVoucher?.id ?? widget.voucherToEdit?.id ?? 'vch_${DateTime.now().millisecondsSinceEpoch}',
      voucherType: widget.voucherType,
      voucherNumber: _h.vchNo.text.trim(),
      date: _h.date.text,
      series: _h.series.text,
      saleType: _h.saleType.text,
      party: cleanPartyName.isNotEmpty ? cleanPartyName : partyText,
      partyGstin: partyGstin.isNotEmpty ? partyGstin : (matchedParty?.gstin ?? ''),
      partyStateCode: partyState,
      isInterState: _isInterState,
      materialCenter: _h.matCenter.text,
      narration: _h.narration.text,
      financialYear: _currentCompany.activeFinancialYear,
      items: _items.where((i) => i.item.text.isNotEmpty).map((i) {
        final q = i.qty.text.evalMath();
        final p = i.price.text.evalMath();
        final t = i.taxable.text.evalMath(q * p);
        final a = i.amount.text.evalMath();

        return VoucherItemModel(
          item: i.item.text,
          hsn: i.hsn.isNotEmpty ? i.hsn : (_itemCache[i.item.text.toLowerCase().trim()]?.hsn ?? ''),
          qty: q,
          unit: i.unit.text.isNotEmpty ? i.unit.text : 'PCS',
          price: p,
          taxable: t,
          cgst: i.cgst.text.toCleanDouble(),
          sgst: i.sgst.text.toCleanDouble(),
          igst: i.igst.text.toCleanDouble(),
          amount: a,
          gstRate: i.gstRate,
        );
      }).toList(),
      sundries: _sundries.where((s) => s.amount.text.isNotEmpty && s.amount.text != '0.00').map((s) => VoucherSundryModel(
        name: s.name.text,
        percent: s.percent.text,
        amount: s.amount.text.toCleanDouble(),
        isNegative: s.isNegative,
      )).toList(),
      subTotal: totals.subTotal,
      cgst: totals.totalCgst,
      sgst: totals.totalSgst,
      igst: totals.totalIgst,
      totalTax: totals.totalTax,
      sundryTotal: totals.sundryTotal,
      roundOff: totals.roundOff,
      grandTotal: totals.grandTotal,
      createdAt: _activeEditingVoucher?.createdAt ?? widget.voucherToEdit?.createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  void _openPrintPreview() {
    showDialog(
      context: context,
      builder: (_) => SalesInvoicePrintPreviewDialog(
        company: _currentCompany.toJson(),
        voucherData: _buildCurrentVoucherPayload().toJson(),
      ),
    );
  }

  Future<void> _saveVoucher() async {
    for (final r in _items) {
      if (r.item.text.trim().isNotEmpty) {
        _evaluateController(r.qty, isQty: true);
        _evaluateController(r.price);
        _evaluateController(r.taxable);
        _evaluateController(r.amount);
      }
    }
    _calculateAllTotals();

    if (!_parseAndValidateDate() || _dateError != null) {
      return _showValidationError(
          _dateError ?? 'Valid Voucher Date required within F.Y.', _h.dateFocus);
    }
    if (_h.vchNo.text.trim().isEmpty && !_allowEmptyVchNo) {
      return _showValidationError('Voucher Number is required.', _h.vchNoFocus);
    }
    final partyText = _h.party.text.trim();
    if (partyText.isEmpty || _findParty(partyText) == null) {
      return _showValidationError(
          'Select a valid registered Party Ledger.', _h.partyFocus);
    }

    final validItems = _items
        .where((i) =>
            i.item.text.trim().isNotEmpty &&
            i.qty.text.toCleanDouble() > 0 &&
            i.amount.text.toCleanDouble() > 0)
        .toList();

    if (validItems.isEmpty) {
      _showValidationError('Add at least one item with Qty & Amount > 0.', null);
      _items.firstOrNull?.itemFocus.requestFocus();
      return;
    }

    final totals = _totalsNotifier.value;

    showDialog(
      context: context,
      builder: (_) => VoucherSaveConfirmDialog(
        summaryData: {
          'voucherType': widget.voucherType,
          'voucherNumber': _h.vchNo.text.trim(),
          'date': _h.date.text,
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
    final folderPath = _currentCompany.folderPath;
    if (folderPath.isEmpty) return;

    final financialYear = _currentCompany.activeFinancialYear;

    await StorageService.saveVoucher(
      folderPath: folderPath,
      financialYear: financialYear,
      voucherData: payload.toJson(),
    );

    if (!mounted) return;
    _notify('${widget.voucherType} [${_h.vchNo.text}] saved!');

    if (!widget.isEdit) {
      final existingIdx = _sessionSavedVouchers.indexWhere(
        (v) => v.id == payload.id || v.voucherNumber == payload.voucherNumber,
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
        builder: (_) => PrintStudioConfirmDialog(vchNo: _h.vchNo.text),
      );
      if ((shouldPrint ?? false) && mounted) {
        await showDialog(
          context: context,
          builder: (_) => SalesInvoicePrintPreviewDialog(
            company: _currentCompany.toJson(),
            voucherData: payload.toJson(),
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
    if (mounted) setState(() {});
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
    if (mounted) setState(() {});
  }

  void _handleItemRowEnter(int index, String field) {
    final r = _items[index];
    _evaluateAndRecalculateItemField(r, field);

    switch (field) {
      case 'item':
        r.qtyFocus.requestFocus();
      case 'qty':
        r.priceFocus.requestFocus();
      case 'price':
        r.taxableFocus.requestFocus();
      case 'taxable':
        r.amountFocus.requestFocus();
      case 'amount':
        index + 1 < _items.length
            ? _items[index + 1].itemFocus.requestFocus()
            : _sundries.firstOrNull?.nameFocus.requestFocus();
    }
  }

  void _handleSundryRowEnter(int index, String field) {
    final s = _sundries[index];
    switch (field) {
      case 'name':
        s.percentFocus.requestFocus();
      case 'percent':
        s.amountFocus.requestFocus();
      case 'amount':
        index + 1 < _sundries.length
            ? _sundries[index + 1].nameFocus.requestFocus()
            : _h.saveButtonFocus.requestFocus();
    }
  }

  Future<void> _handleScanWithAiPro() async {
    _ScanDocumentSource? selectedSource;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppActionBottomSheet(
        title: 'Scan with AI Pro',
        subtitle: 'Upload invoice image or PDF document to auto-extract details',
        actions: [
          AppActionItem(
            title: 'Camera',
            desc: 'Capture invoice directly using your camera',
            icon: Icons.camera_alt_rounded,
            color: AppColors.primary,
            onTap: () {
              selectedSource = _ScanDocumentSource.camera;
              Navigator.pop(ctx);
            },
          ),
          AppActionItem(
            title: 'Gallery (Image)',
            desc: 'Upload PNG or JPEG invoice from your device',
            icon: Icons.image_rounded,
            color: AppColors.purple,
            onTap: () {
              selectedSource = _ScanDocumentSource.gallery;
              Navigator.pop(ctx);
            },
          ),
          AppActionItem(
            title: 'PDF Document',
            desc: 'Import digital PDF invoice document',
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.error,
            onTap: () {
              selectedSource = _ScanDocumentSource.pdf;
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );

    if (selectedSource == null || !mounted) return;

    Uint8List? fileBytes;
    String fileName = 'invoice.pdf';
    String mediaType = 'application/pdf';

    try {
      if (selectedSource == _ScanDocumentSource.camera ||
          selectedSource == _ScanDocumentSource.gallery) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: selectedSource == _ScanDocumentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 90,
        );
        if (picked == null) return;
        fileBytes = await picked.readAsBytes();
        fileName = picked.name;
        mediaType = picked.name.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
      } else if (selectedSource == _ScanDocumentSource.pdf) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
        if (result == null || result.files.single.bytes == null) return;
        fileBytes = result.files.single.bytes!;
        fileName = result.files.single.name;
        mediaType = 'application/pdf';
      }
    } catch (e) {
      _notify('Failed to select file: $e', bg: AppColors.error);
      return;
    }

    if (!mounted || fileBytes == null) return;

    ScannedVoucherData? scanned;
    await LoadingService.wrap(() async {
      try {
        scanned = await ScanAiService.extractFromFile(
          fileBytes!,
          fileName: fileName,
          mediaType: mediaType,
        );
      } catch (e) {
        _notify(e.toString(), bg: AppColors.error);
      }
    }, message: 'AI is analyzing invoice details...');

    if (scanned == null || !mounted) return;

    if (scanned!.invoiceDate.isNotEmpty) {
      _h.date.text = scanned!.invoiceDate;
      _parseAndValidateDate();
    }
    if (scanned!.invoiceNo.isNotEmpty &&
        !scanned!.invoiceNo.toLowerCase().contains("invoice")) {
      _h.vchNo.text = scanned!.invoiceNo;
      _allowEmptyVchNo = false;
      _allowDuplicateVchNo = true;
    }

    final reviewed = await showDialog<ScanReviewResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanReviewDialog(
        scanned: scanned!,
        currentParties: _currentParties,
        itemsMasterList: _itemsMasterList,
        itemCache: _itemCache,
        company: _currentCompany.toJson(),
        folderPath: _currentCompany.folderPath,
        voucherType: widget.voucherType,
        isSalesVoucher: _isSalesVoucher,
      ),
    );
    if (reviewed == null || !mounted) return;

    await _loadCompanyMastersOnly();
    _rebuildFastLookupCaches();

    if (reviewed.partyName.isNotEmpty) {
      _h.party.text = _formatPartyDisplay(reviewed.partyName, reviewed.partyGstin);
      _checkGstMode(autoAdjustSaleType: true);
      _refreshTaxesOnAllRows();
    }

    for (int i = 0; i < reviewed.items.length; i++) {
      while (_items.length <= i) {
        _addItemRow();
      }
      final row = _items[i];
      final r = reviewed.items[i];
      row.item.text = r.name;
      row.hsn = r.hsn;
      row.qty.text = r.qty % 1 == 0 ? r.qty.toInt().toString() : r.qty.toString();
      row.unit.text = r.unit;
      row.price.text = r.rate.toCurrency();
      row.gstRate = r.gstRate;
      VoucherCalculationService.recalculateTaxableAndTaxes(row, _isInterState);
    }
    while (_items.length < 15) {
      _addItemRow();
    }

    if (scanned!.sundries.isNotEmpty) {
      for (int i = 0; i < scanned!.sundries.length; i++) {
        final sData = scanned!.sundries[i];
        while (_sundries.length <= i) {
          _addSundryRow();
        }
        final sRow = _sundries[i];
        sRow.name.text = sData.name;
        sRow.amount.text = sData.amount.toCurrency();
        sRow.isNegative = sData.isNegative;
      }
    }

    _calculateAllTotals();
    _notify('Invoice scanned & populated successfully!', bg: AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CompanyModel?>(activeCompanyProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        _loadCompanyMastersOnly().then((_) {
          if (mounted) {
            setState(() {
              _checkGstMode(autoAdjustSaleType: true);
              _refreshTaxesOnAllRows();
            });
          }
        });
      }
    });

    final fy = _currentCompany.activeFinancialYear;

    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherEntry,
      nodeMap: _h.focusNodeMap,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _requestExit();
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _onGlobalKeyAction,
          child: Scaffold(
            backgroundColor: _screenBg,
            body: Column(
              children: [
                _buildTopBar(fy),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        VoucherHeaderCard(
                          seriesController: _h.series,
                          seriesFocus: _h.seriesFocus,
                          availableSeries: _availableSeries,
                          dateController: _h.date,
                          dateFocus: _h.dateFocus,
                          dateError: _dateError,
                          vchNoController: _h.vchNo,
                          vchNoFocus: _h.vchNoFocus,
                          partyController: _h.party,
                          partyFocus: _h.partyFocus,
                          availableParties: _currentParties,
                          saleTypeController: _h.saleType,
                          saleTypeFocus: _h.saleTypeFocus,
                          matCenterController: _h.matCenter,
                          matCenterFocus: _h.matCenterFocus,
                          narrationController: _h.narration,
                          narrationFocus: _h.narrationFocus,
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
                              if (KeyboardShortcutService.isTab(event, requireUnshifted: true)) {
                                _sundries.firstOrNull?.nameFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: ValueListenableBuilder<VoucherTotalsResult>(
                              valueListenable: _totalsNotifier,
                              builder: (context, totals, _) => VoucherItemsTable(
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
                                onTabToSundry: () => _sundries
                                    .firstOrNull?.nameFocus
                                    .requestFocus(),
                              ),
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
                                builder: (context, totals, _) => VoucherSundryCard(
                                  sundries: _sundries,
                                  availableSundries: _availableSundries,
                                  autoRoundOff: _autoRoundOff,
                                  roundOff: totals.roundOff,
                                  onAddSundry: () => setState(_addSundryRow),
                                  onToggleRoundOff: () {
                                    _autoRoundOff = !_autoRoundOff;
                                    _calculateAllTotals();
                                  },
                                  onRowEnter: _handleSundryRowEnter,
                                  onTabToSave: () =>
                                      _h.saveButtonFocus.requestFocus(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 45,
                              child: ValueListenableBuilder<VoucherTotalsResult>(
                                valueListenable: _totalsNotifier,
                                builder: (context, totals, _) =>
                                    VoucherSummaryCard(
                                  isInterState: _isInterState,
                                  subTotal: totals.subTotal,
                                  totalCgst: totals.totalCgst,
                                  totalSgst: totals.totalSgst,
                                  totalIgst: totals.totalIgst,
                                  sundryTotal: totals.sundryTotal,
                                  roundOff: totals.roundOff,
                                  grandTotal: totals.grandTotal,
                                  saveButtonFocusNode: _h.saveButtonFocus,
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFooterBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String fy) {
    return Container(
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
          _buildTag('FY $fy', AppColors.background, AppColors.textPrimary),
          const SizedBox(width: 8),
          _buildTag(
            _isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST+SGST)',
            _isInterState ? AppColors.purpleLight : AppColors.successLight,
            _isInterState ? AppColors.purple : AppColors.successDark,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.print_rounded, size: 15, color: AppColors.primary),
              label: Text(
                'Print (${KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.printInvoiceAction)})',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _buildScanButton(),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () => _openCalculatorForController(TextEditingController()),
            icon: const Icon(Icons.calculate_outlined, size: 16, color: AppColors.textSecondary),
            label: Text(
              'Calc (${KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.calculatorAction)})',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: _showClearConfirmationDialog,
            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.textSecondary),
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
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
            onPressed: _requestExit,
          ),
        ],
      ),
    );
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset', style: TextStyle(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBar() {
    String s(String action) => KeyboardShortcutService.labelForAction(widget.keyboardSettings, action);

    return Container(
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
          _buildShortcutHint('[${s(KeyboardShortcutService.saveVoucherAction)}] Save'),
          _buildShortcutHint('[${s(KeyboardShortcutService.previousVoucherAction)}] Prev Vch'),
          _buildShortcutHint('[${s(KeyboardShortcutService.nextVoucherAction)}] Next Vch'),
          if (_isEditingExisting) _buildShortcutHint('[${s(KeyboardShortcutService.printInvoiceAction)}] Print'),
          _buildShortcutHint('[${s(KeyboardShortcutService.calculatorAction)}] Calc'),
          _buildShortcutHint('[${s(KeyboardShortcutService.quickAddMasterAction)}] Quick Add'),
          _buildShortcutHint('[${s(KeyboardShortcutService.modifyMasterAction)}] Edit Master'),
          _buildShortcutHint('[Tab] Next Field'),
          _buildShortcutHint('[${s(KeyboardShortcutService.goBackAction)}] Exit'),
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
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
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
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _handleScanWithAiPro,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.surface),
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
                    padding: EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
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