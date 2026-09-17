import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_shortcuts.dart';
import '../../../constants/gst_constants.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_calculation_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../widgets/voucher/popup/add_item_dialog.dart';
import '../../../widgets/voucher/popup/add_party_dialog.dart';
import '../../../widgets/voucher/popup/calculator_dialog.dart';
import '../../../widgets/voucher/popup/item_tax_details_dialog.dart';
import '../../../widgets/voucher/popup/sales_invoice_print_preview_dialog.dart';
import '../../../widgets/voucher/popup/voucher_save_confirm_dialog.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
import '../../../widgets/voucher/voucher_navigation_bar.dart';
import '../../../widgets/voucher/voucher_summary_card.dart';
import '../../../widgets/voucher/voucher_sundry_card.dart';
import '../../../widgets/voucher/voucher_sundry_row.dart';

class VoucherEntryScreen extends StatefulWidget {
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
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  final _seriesController = TextEditingController(text: 'Main');
  final _seriesFocus = FocusNode();
  final _dateController = TextEditingController();
  final _dateFocusNode = FocusNode();
  final _vchNoController = TextEditingController();
  final _vchNoFocus = FocusNode();
  final _saleTypeController = TextEditingController(text: 'Local Itemwise');
  final _saleTypeFocus = FocusNode();
  final _partyController = TextEditingController();
  final _partyFocus = FocusNode();
  final _matCenterController = TextEditingController(text: 'Main Store');
  final _matCenterFocus = FocusNode();
  final _narrationController = TextEditingController();
  final _narrationFocus = FocusNode();
  final _saveButtonFocusNode = FocusNode();

  final List<VoucherItemRow> _items = [];
  final List<VoucherSundryRow> _sundries = [];

  List<PartyMasterModel> _debtorsList = [];
  List<PartyMasterModel> _creditorsList = [];
  List<ItemMasterModel> _itemsMasterList = [];

  double _itemSubTotal = 0.0, _totalQty = 0.0, _totalCgst = 0.0, _totalSgst = 0.0;
  double _totalIgst = 0.0, _totalTax = 0.0, _sundryTotal = 0.0, _roundOff = 0.0;
  double _grandTotal = 0.0, _totalItemAmount = 0.0;

  bool _isInterState = false;
  bool _autoRoundOff = true;
  bool _isAutoAdjustingSaleType = false;
  String? _dateError;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  bool get _isSalesVoucher => widget.voucherType.toLowerCase().contains('sale');
  List<PartyMasterModel> get _currentAvailableParties => _isSalesVoucher ? _debtorsList : _creditorsList;

  @override
  void initState() {
    super.initState();
    _attachControllerListeners();
    if (widget.isEdit && widget.voucherToEdit != null) {
      _loadExistingVoucherData(widget.voucherToEdit!);
    } else {
      _loadCompanyMastersAndInitialize();
    }
  }

  void _loadExistingVoucherData(Map<String, dynamic> v) {
    _seriesController.text = v['series']?.toString() ?? 'Main';
    _dateController.text = v['date']?.toString() ?? '';
    _vchNoController.text = v['voucherNumber']?.toString() ?? '';
    _saleTypeController.text = v['saleType']?.toString() ?? 'Local Itemwise';
    _partyController.text = v['party']?.toString() ?? '';
    _matCenterController.text = v['materialCenter']?.toString() ?? 'Main Store';
    _narrationController.text = v['narration']?.toString() ?? '';
    _isInterState = v['isInterState'] == true;

    final bounds = AppDateUtils.parseFinancialYearBounds(
      v['financialYear']?.toString() ?? widget.company['activeFinancialYear']?.toString() ?? AppDateUtils.defaultFinancialYear,
    );
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _items.clear();
    for (final itemData in (v['items'] as List? ?? [])) {
      final row = VoucherItemRow()
        ..item.text = itemData['item']?.toString() ?? ''
        ..hsn = itemData['hsn']?.toString() ?? ''
        ..qty.text = itemData['qty']?.toString() ?? ''
        ..unit.text = itemData['unit']?.toString() ?? 'Pcs'
        ..price.text = itemData['price']?.toString() ?? ''
        ..taxable.text = itemData['taxable']?.toString() ?? ''
        ..cgst.text = itemData['cgst']?.toString() ?? ''
        ..sgst.text = itemData['sgst']?.toString() ?? ''
        ..igst.text = itemData['igst']?.toString() ?? ''
        ..amount.text = itemData['amount']?.toString() ?? ''
        ..gstRate = double.tryParse(itemData['gstRate']?.toString() ?? '18') ?? 18.0;
      _attachItemRowListeners(row);
      _items.add(row);
    }
    while (_items.length < 20) { _addItemRow(); }

    _sundries.clear();
    for (final sData in (v['sundries'] as List? ?? [])) {
      final sundry = VoucherSundryRow()
        ..name.text = sData['name']?.toString() ?? ''
        ..percent.text = sData['percent']?.toString() ?? ''
        ..amount.text = sData['amount']?.toString() ?? ''
        ..isNegative = sData['isNegative'] == true;
      _attachSundryRowListeners(sundry);
      _sundries.add(sundry);
    }
    while (_sundries.length < 5) { _addSundryRow(); }

    _loadCompanyMastersOnly();
    _calculateAllTotals();
  }

  Future<void> _loadCompanyMastersOnly() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath == null) return;
    final rawMasters = await StorageService.loadCompanyMasters(folderPath: folderPath);
    _debtorsList = (rawMasters['debtors'] as List? ?? []).map((d) => PartyMasterModel(name: d['name']?.toString() ?? '', gstin: d['gstin']?.toString() ?? '', group: d['group']?.toString() ?? 'Sundry Debtors')).toList();
    _creditorsList = (rawMasters['creditors'] as List? ?? []).map((c) => PartyMasterModel(name: c['name']?.toString() ?? '', gstin: c['gstin']?.toString() ?? '', group: c['group']?.toString() ?? 'Sundry Creditors')).toList();
    _itemsMasterList = (rawMasters['items'] as List? ?? []).map((i) => ItemMasterModel(name: i['name']?.toString() ?? '', hsn: i['hsn']?.toString() ?? '', unit: i['unit']?.toString() ?? 'Pcs', taxCategory: i['taxCategory']?.toString() ?? 'GST 18%', taxRate: (i['taxRate'] is num) ? (i['taxRate'] as num).toDouble() : 18.0, salesPrice: (i['salesPrice'] is num) ? (i['salesPrice'] as num).toDouble() : 0.0, purchasePrice: (i['purchasePrice'] is num) ? (i['purchasePrice'] as num).toDouble() : 0.0, mrp: (i['mrp'] is num) ? (i['mrp'] as num).toDouble() : 0.0)).toList();
  }

  void _attachItemRowListeners(VoucherItemRow row) {
    void handlePriceOrQty() {
      final q = double.tryParse(row.qty.text) ?? 0.0, p = double.tryParse(row.price.text) ?? 0.0, t = double.tryParse(row.taxable.text) ?? 0.0;
      if (p > 0 && q > 0) {
        row.taxable.text = (q * p).toStringAsFixed(2);
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
      } else if (t > 0) {
        if (p > 0) row.qty.text = (t / p).toStringAsFixed(2);
        if (q > 0) row.price.text = (t / q).toStringAsFixed(2);
      }
      _calculateAllTotals();
    }

    row.qty.addListener(() { if (row.qtyFocus.hasFocus) handlePriceOrQty(); });
    row.price.addListener(() { if (row.priceFocus.hasFocus) handlePriceOrQty(); });
    row.taxable.addListener(() {
      if (row.taxableFocus.hasFocus) {
        final t = double.tryParse(row.taxable.text) ?? 0.0, q = double.tryParse(row.qty.text) ?? 0.0;
        if (q > 0) row.price.text = (t / q).toStringAsFixed(2);
        VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
        _calculateAllTotals();
      }
    });
    for (final node in [row.cgst, row.sgst, row.igst]) {
      node.addListener(() {
        if (row.cgstFocus.hasFocus || row.sgstFocus.hasFocus || row.igstFocus.hasFocus) {
          final t = double.tryParse(row.taxable.text) ?? 0.0;
          final tax = _isInterState ? (double.tryParse(row.igst.text) ?? 0.0) : ((double.tryParse(row.cgst.text) ?? 0.0) + (double.tryParse(row.sgst.text) ?? 0.0));
          row.amount.text = (t + tax) == 0 ? '' : (t + tax).toStringAsFixed(2);
          _calculateAllTotals();
        }
      });
    }
    row.amount.addListener(() {
      if (row.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
        _calculateAllTotals();
      }
    });
  }

  void _attachSundryRowListeners(VoucherSundryRow row) {
    row.name.addListener(() { _applySundryAutoValue(row); _calculateAllTotals(); });
    row.percent.addListener(() { if (row.percentFocus.hasFocus) { VoucherCalculationService.recalculateSundryFromPercent(row, _itemSubTotal); _calculateAllTotals(); } });
    row.amount.addListener(() { if (row.amountFocus.hasFocus) { VoucherCalculationService.recalculateSundryFromAmount(row, _itemSubTotal); _calculateAllTotals(); } });
  }

  void _attachControllerListeners() {
    _dateFocusNode.addListener(() { if (!_dateFocusNode.hasFocus) _parseAndValidateDate(); });
    _partyController.addListener(() { _checkGstMode(autoAdjustSaleType: true); _refreshTaxesOnAllRows(); });
    _saleTypeController.addListener(() { if (!_isAutoAdjustingSaleType) _handleManualSaleTypeChange(); });
  }

  bool _parseAndValidateDate() {
    final parsed = AppDateUtils.parseDate(_dateController.text);
    if (parsed == null || parsed.isBefore(_fyStartDate) || parsed.isAfter(_fyEndDate)) {
      setState(() => _dateError = parsed == null ? 'Invalid date' : 'Date must fall within F.Y.');
      return false;
    }
    _dateController.text = AppDateUtils.formatDate(parsed);
    setState(() => _dateError = null);
    return true;
  }

  void _openCalculatorForController(TextEditingController controller) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Calculator',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => CalculatorDialog(
        initialValue: controller.text,
        onSubmitted: (val) {
          controller.text = val;
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
          _calculateAllTotals();
        },
      ),
    );
  }

  Future<void> _loadCompanyMastersAndInitialize() async {
    await _loadCompanyMastersOnly();
    _initializeNewVoucher();
  }

  Future<void> _syncMastersToFile() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath == null) return;
    await StorageService.saveCompanyMasters(
      folderPath: folderPath,
      mastersData: {
        'debtors': _debtorsList.map((d) => {'name': d.name, 'gstin': d.gstin, 'group': d.group}).toList(),
        'creditors': _creditorsList.map((c) => {'name': c.name, 'gstin': c.gstin, 'group': c.group}).toList(),
        'items': _itemsMasterList.map((i) => {'name': i.name, 'hsn': i.hsn, 'unit': i.unit, 'taxCategory': i.taxCategory, 'taxRate': i.taxRate, 'salesPrice': i.salesPrice, 'purchasePrice': i.purchasePrice, 'mrp': i.mrp}).toList(),
      },
    );
  }

  void _initializeNewVoucher() {
    final fy = widget.company['activeFinancialYear']?.toString() ?? AppDateUtils.defaultFinancialYear;
    _vchNoController.text = '';
    final bounds = AppDateUtils.parseFinancialYearBounds(fy);
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;
    _isAutoAdjustingSaleType = true;
    _partyController.text = '';
    _saleTypeController.text = 'Local Itemwise';
    _isInterState = false;
    _isAutoAdjustingSaleType = false;

    final now = DateTime.now();
    _dateController.text = (now.isAfter(_fyStartDate) && now.isBefore(_fyEndDate)) ? AppDateUtils.formatDate(now) : '01-04-${_fyStartDate.year}';
    _items.clear();
    for (int i = 0; i < 20; i++) { _addItemRow(); }
    _sundries.clear();
    for (int i = 0; i < 5; i++) { _addSundryRow(); }
    if (mounted) setState(() {});
  }

  String _getCompanyStateCode() {
    final rawGstin = (widget.company['gstin'] ?? widget.company['gstNumber'] ?? '').toString().trim();
    if (rawGstin.length >= 2 && int.tryParse(rawGstin.substring(0, 2)) != null) return rawGstin.substring(0, 2);
    final rawState = (widget.company['state'] ?? widget.company['stateName'] ?? '').toString().trim();
    return GstConstants.getStateCodeByName(rawState) ?? '07';
  }

  String _extractPartyStateCode(String partyText) {
    final gstin = GstPartyUtils.extractPartyGstin(partyText.trim());
    if (gstin.length >= 2 && int.tryParse(gstin.substring(0, 2)) != null) return gstin.substring(0, 2);
    final cleanLower = partyText.trim().toLowerCase();
    final matched = _currentAvailableParties.where((p) => p.name.trim().toLowerCase() == cleanLower || p.displayName.trim().toLowerCase() == cleanLower).firstOrNull;
    if (matched != null && matched.gstin.trim().length >= 2) return matched.gstin.trim().substring(0, 2);
    return '';
  }

  void _checkGstMode({bool autoAdjustSaleType = false}) {
    final compState = _getCompanyStateCode(), partyState = _extractPartyStateCode(_partyController.text);
    _isInterState = partyState.isNotEmpty ? compState != partyState : false;
    if (autoAdjustSaleType) {
      final currentType = _saleTypeController.text;
      String suffix = 'Itemwise';
      if (currentType.contains('Multirate')) suffix = 'Multirate';
      if (currentType.contains('Exempt')) suffix = 'Exempt';
      final targetType = _isInterState ? 'InterState $suffix' : 'Local $suffix';
      if (_saleTypeController.text != targetType) {
        _isAutoAdjustingSaleType = true;
        _saleTypeController.text = targetType;
        _isAutoAdjustingSaleType = false;
      }
    }
  }

  void _handleManualSaleTypeChange() {
    final currentSaleType = _saleTypeController.text.trim();
    final isExplicitLocal = currentSaleType.startsWith('Local'), isExplicitInterState = currentSaleType.startsWith('InterState');
    final compState = _getCompanyStateCode(), partyState = _extractPartyStateCode(_partyController.text);

    if (partyState.isNotEmpty) {
      final partyIsInterstate = compState != partyState;
      if (partyIsInterstate && isExplicitLocal) {
        _showTaxMismatchWarning('local transaction', 'interstate (State code: $partyState)', () {
          _isAutoAdjustingSaleType = true;
          _saleTypeController.text = currentSaleType.replaceFirst('Local', 'InterState');
          _isAutoAdjustingSaleType = false;
          setState(() { _isInterState = true; _refreshTaxesOnAllRows(); });
        });
      } else if (!partyIsInterstate && isExplicitInterState) {
        _showTaxMismatchWarning('interstate transaction', 'local / intra-state (State code: $partyState)', () {
          _isAutoAdjustingSaleType = true;
          _saleTypeController.text = currentSaleType.replaceFirst('InterState', 'Local');
          _isAutoAdjustingSaleType = false;
          setState(() { _isInterState = false; _refreshTaxesOnAllRows(); });
        });
      }
    }
    setState(() { _isInterState = isExplicitInterState; _refreshTaxesOnAllRows(); });
  }

  void _showTaxMismatchWarning(String enteredType, String partyBelongsToText, VoidCallback onAdjust) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24), SizedBox(width: 8), Text('Taxation Warning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))]),
        content: Text('You are entering a $enteredType but party belongs to $partyBelongsToText.\n\nDo you want to continue?', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
        actions: [
          OutlinedButton(onPressed: () { Navigator.pop(ctx); onAdjust(); }, child: const Text('Adjust to Party')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning), child: const Text('Yes, Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
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

  void _applySundryAutoValue(VoucherSundryRow sundry) {
    final type = sundry.name.text;
    if (type.contains('Round off') || type.contains('Round Off') || type.contains('Rnd off')) {
      double baseSum = _itemSubTotal + _totalTax;
      for (final s in _sundries) {
        if (s != sundry) {
          final a = double.tryParse(s.amount.text) ?? 0.0;
          baseSum += (s.name.text.contains('-') || s.isNegative) ? -a : a;
        }
      }
      final remainder = baseSum % 1.0;
      if (type.contains('+')) {
        final diff = remainder == 0 ? 0.0 : (1.0 - remainder);
        sundry.amount.text = diff > 0 ? diff.toStringAsFixed(2) : '';
        sundry.percent.clear();
        sundry.isNegative = false;
      } else {
        sundry.amount.text = remainder > 0 ? remainder.toStringAsFixed(2) : '';
        sundry.percent.clear();
        sundry.isNegative = true;
      }
    } else if (sundry.percent.text.isNotEmpty) {
      VoucherCalculationService.recalculateSundryFromPercent(sundry, _itemSubTotal);
    }
  }

  void _addItemRow() {
    final row = VoucherItemRow();
    _attachItemRowListeners(row);
    _items.add(row);
  }

  void _onItemMasterSelected(int index, ItemMasterModel selectedItem) {
    final row = _items[index]
      ..unit.text = selectedItem.unit
      ..gstRate = selectedItem.taxRate
      ..hsn = selectedItem.hsn;
    final defaultPrice = _isSalesVoucher ? selectedItem.salesPrice : selectedItem.purchasePrice;
    if (defaultPrice > 0) row.price.text = defaultPrice.toStringAsFixed(2);

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0 && defaultPrice > 0) {
      row.taxable.text = (q * defaultPrice).toStringAsFixed(2);
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.taxable.text.isNotEmpty) {
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.amount.text.isNotEmpty) {
      VoucherCalculationService.recalculateFromInvoiceAmount(row, _isInterState);
    }
    _calculateAllTotals();
  }

  void _calculateAllTotals() {
    for (final s in _sundries) {
      if (!s.name.text.contains('Round') && !s.name.text.contains('Rnd') && s.percent.text.isNotEmpty && !s.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateSundryFromPercent(s, _itemSubTotal);
      }
    }
    final res = VoucherCalculationService.calculateTotals(items: _items, sundries: _sundries, isInterState: _isInterState, autoRoundOff: _autoRoundOff);
    setState(() {
      _totalQty = res.totalQty; _itemSubTotal = res.subTotal; _totalCgst = res.totalCgst; _totalSgst = res.totalSgst;
      _totalIgst = res.totalIgst; _totalTax = res.totalTax; _sundryTotal = res.sundryTotal; _roundOff = res.roundOff;
      _grandTotal = res.grandTotal; _totalItemAmount = res.totalItemAmount;
    });
  }

  void _openTaxDetailsDialog(int index) {
    showDialog(context: context, builder: (_) => ItemTaxDetailsDialog(row: _items[index], isInterState: _isInterState, onUpdated: () => setState(_calculateAllTotals)));
  }

  void _openAddItemDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        onItemCreated: (itemData) async {
          final newModel = ItemMasterModel(name: itemData['name'], hsn: itemData['hsn'], unit: itemData['unit'], taxCategory: itemData['taxCategory'], taxRate: itemData['taxRate'], salesPrice: itemData['salesPrice'], purchasePrice: itemData['purchasePrice'], mrp: itemData['mrp']);
          setState(() { _itemsMasterList.add(newModel); _items[index].item.text = newModel.name; _onItemMasterSelected(index, newModel); });
          await _syncMastersToFile();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registered: ${newModel.name}'), backgroundColor: AppColors.success));
        },
      ),
    );
  }

  void _openAddPartyDialog() {
    showDialog(
      context: context,
      builder: (_) => AddPartyDialog(
        voucherType: widget.voucherType,
        onPartyCreated: (partyData) async {
          final newModel = PartyMasterModel(name: partyData['name'] ?? '', gstin: partyData['gstin'] ?? '', group: partyData['group'] ?? (_isSalesVoucher ? 'Sundry Debtors' : 'Sundry Creditors'));
          setState(() {
            if (_isSalesVoucher) { _debtorsList.add(newModel); } else { _creditorsList.add(newModel); }
            _partyController.text = newModel.displayName;
          });
          await _syncMastersToFile();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registered: ${newModel.displayName}'), backgroundColor: AppColors.success));
        },
      ),
    );
  }

  void _openQuickAddDialog(String masterType) {
    if (masterType == 'Account Ledger') { _openAddPartyDialog(); return; }
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22), const SizedBox(width: 8), Text('Add $masterType', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
        content: TextField(controller: nameCtrl, autofocus: true, decoration: InputDecoration(hintText: 'Enter new $masterType name', filled: true, fillColor: AppColors.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created: "${nameCtrl.text.trim()}"'), backgroundColor: AppColors.success)); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Save', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showValidationError(String msg, FocusNode? focus) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)))]), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    focus?.requestFocus();
  }

  Future<void> _saveVoucher() async {
    if (!_parseAndValidateDate() || _dateError != null) return _showValidationError(_dateError ?? 'Valid Voucher Date required within F.Y.', _dateFocusNode);
    if (_vchNoController.text.trim().isEmpty) return _showValidationError('Voucher Number is required.', _vchNoFocus);
    if (_partyController.text.trim().isEmpty) return _showValidationError('Select or add a Party Ledger.', _partyFocus);
    if (!_currentAvailableParties.any((p) => p.displayName == _partyController.text.trim() || p.name == _partyController.text.trim())) return _showValidationError('Selected party is not registered.', _partyFocus);

    final validItems = _items.where((i) => i.item.text.trim().isNotEmpty && (double.tryParse(i.qty.text) ?? 0.0) > 0 && (double.tryParse(i.amount.text) ?? 0.0) > 0).toList();
    if (validItems.isEmpty) { _showValidationError('Add at least one item with Qty & Amount > 0.', null); _items.firstOrNull?.itemFocus.requestFocus(); return; }

    showDialog(
      context: context,
      builder: (_) => VoucherSaveConfirmDialog(
        summaryData: {
          'voucherType': widget.voucherType, 'voucherNumber': _vchNoController.text.trim(), 'date': _dateController.text, 'party': _partyController.text.trim(),
          'isInterState': _isInterState, 'itemCount': validItems.length, 'totalQty': _totalQty, 'subTotal': _itemSubTotal, 'cgst': _totalCgst, 'sgst': _totalSgst,
          'igst': _totalIgst, 'sundryTotal': _sundryTotal, 'roundOff': _roundOff, 'grandTotal': _grandTotal,
        },
        onConfirm: _executeVoucherPersistence,
      ),
    );
  }

  Future<void> _executeVoucherPersistence() async {
    final payload = {
      'id': widget.voucherToEdit?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'voucherType': widget.voucherType, 'voucherNumber': _vchNoController.text.trim(), 'date': _dateController.text, 'series': _seriesController.text,
      'saleType': _saleTypeController.text, 'party': _partyController.text, 'isInterState': _isInterState, 'materialCenter': _matCenterController.text,
      'narration': _narrationController.text, 'financialYear': widget.company['activeFinancialYear'],
      'items': _items.where((i) => i.item.text.isNotEmpty).map((i) => {'item': i.item.text, 'hsn': i.hsn.isNotEmpty ? i.hsn : (_itemsMasterList.where((m) => m.name.trim().toLowerCase() == i.item.text.trim().toLowerCase()).firstOrNull?.hsn ?? ''), 'qty': i.qty.text, 'unit': i.unit.text.isNotEmpty ? i.unit.text : 'Pcs', 'price': i.price.text, 'taxable': i.taxable.text, 'cgst': i.cgst.text, 'sgst': i.sgst.text, 'igst': i.igst.text, 'amount': i.amount.text, 'gstRate': i.gstRate}).toList(),
      'sundries': _sundries.where((s) => s.amount.text.isNotEmpty && s.amount.text != '0.00').map((s) => {'name': s.name.text, 'percent': s.percent.text, 'amount': s.amount.text, 'isNegative': s.isNegative}).toList(),
      'subTotal': _itemSubTotal, 'cgst': _totalCgst, 'sgst': _totalSgst, 'igst': _totalIgst, 'totalTax': _totalTax, 'sundryTotal': _sundryTotal, 'roundOff': _roundOff, 'grandTotal': _grandTotal,
      'createdAt': widget.voucherToEdit?['createdAt'] ?? DateTime.now().toIso8601String(),
    };

    final folderPath = widget.company['folderPath'];
    if (folderPath != null) {
      await StorageService.saveVoucher(folderPath: folderPath, financialYear: widget.company['activeFinancialYear']?.toString() ?? AppDateUtils.defaultFinancialYear, voucherData: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.voucherType} [${_vchNoController.text}] saved!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));

      if (_isSalesVoucher) {
        final shouldPrint = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 20)), const SizedBox(width: 10), const Text('Print Sales Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
            content: Text('Sales Invoice [${_vchNoController.text}] recorded.\n\nPrint this invoice now?', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            actions: [OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Yes, Print', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))],
          ),
        );
        if ((shouldPrint ?? false) && mounted) {
          await showDialog(context: context, builder: (_) => SalesInvoicePrintPreviewDialog(company: widget.company, voucherData: payload));
        }
      }
      widget.isEdit ? widget.onClose() : _initializeNewVoucher();
    }
  }

  Future<bool> _onWillPop() async {
    final close = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorDark, size: 20)), const SizedBox(width: 10), const Text('Unsaved Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark))]),
        content: const Text('You have unsaved changes. Discard and exit?', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Exit Without Saving', style: TextStyle(fontWeight: FontWeight.w800)))],
      ),
    );
    return close ?? false;
  }

  void _handleItemRowEnter(int index, String field) {
    final r = _items[index];
    if (field == 'item') { r.qtyFocus.requestFocus(); }
    else if (field == 'qty') { r.priceFocus.requestFocus(); }
    else if (field == 'price') { r.taxableFocus.requestFocus(); }
    else if (field == 'taxable') { r.amountFocus.requestFocus(); }
    else if (field == 'amount') { index + 1 < _items.length ? _items[index + 1].itemFocus.requestFocus() : _sundries.firstOrNull?.nameFocus.requestFocus(); }
  }

  void _handleSundryRowEnter(int index, String field) {
    final s = _sundries[index];
    if (field == 'name') { s.percentFocus.requestFocus(); }
    else if (field == 'percent') { s.amountFocus.requestFocus(); }
    else if (field == 'amount') { index + 1 < _sundries.length ? _sundries[index + 1].nameFocus.requestFocus() : _saveButtonFocusNode.requestFocus(); }
  }

  Color _getVoucherColor() {
    final v = widget.voucherType.toLowerCase();
    return v.contains('sale') ? const Color(0xFFEC7615) : v.contains('purchase') ? AppColors.purple : (v.contains('payment') || v.contains('receipt')) ? AppColors.success : const Color(0xFF0D9488);
  }

  @override
  void dispose() {
    for (final c in [_seriesController, _dateController, _vchNoController, _saleTypeController, _partyController, _matCenterController, _narrationController]) { c.dispose(); }
    for (final f in [_seriesFocus, _dateFocusNode, _vchNoFocus, _saleTypeFocus, _partyFocus, _matCenterFocus, _narrationFocus, _saveButtonFocusNode]) { f.dispose(); }
    for (final i in _items) { i.dispose(); }
    for (final s in _sundries) { s.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear']?.toString() ?? AppDateUtils.defaultFinancialYear;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.f4) {
            for (final r in _items) {
              for (final e in [MapEntry(r.qtyFocus, r.qty), MapEntry(r.priceFocus, r.price), MapEntry(r.taxableFocus, r.taxable), MapEntry(r.amountFocus, r.amount)]) {
                if (e.key.hasFocus) { _openCalculatorForController(e.value); return KeyEventResult.handled; }
              }
            }
          }
          if (AppShortcuts.isQuickAdd(event)) {
            if (_partyFocus.hasFocus) { _openAddPartyDialog(); return KeyEventResult.handled; }
            if (_seriesFocus.hasFocus) { _openQuickAddDialog('Series'); return KeyEventResult.handled; }
            if (_saleTypeFocus.hasFocus) { _openQuickAddDialog('Sale Type'); return KeyEventResult.handled; }
            if (_matCenterFocus.hasFocus) { _openQuickAddDialog('Material Centre'); return KeyEventResult.handled; }
            for (int i = 0; i < _items.length; i++) { if (_items[i].itemFocus.hasFocus) { _openAddItemDialog(i); return KeyEventResult.handled; } }
          }
          if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.goBackAction, event)) {
            _onWillPop().then((close) { if (close) widget.onClose(); });
            return KeyEventResult.handled;
          }
          if (KeyboardShortcutService.matchesAction(widget.keyboardSettings, KeyboardShortcutService.saveVoucherAction, event)) {
            _saveVoucher(); return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: _getVoucherColor().withValues(alpha: 0.05),
          body: Column(
            children: [
              VoucherNavigationBar(voucherType: widget.voucherType, financialYear: fy, isInterState: _isInterState, headerColor: _getVoucherColor(), keyboardSettings: widget.keyboardSettings, onSave: _saveVoucher, onClose: () async { if (await _onWillPop()) widget.onClose(); }),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      VoucherHeaderCard(
                        seriesController: _seriesController, seriesFocus: _seriesFocus, dateController: _dateController, dateFocus: _dateFocusNode,
                        dateError: _dateError, vchNoController: _vchNoController, vchNoFocus: _vchNoFocus, saleTypeController: _saleTypeController,
                        saleTypeFocus: _saleTypeFocus, partyController: _partyController, partyFocus: _partyFocus, availableParties: _currentAvailableParties,
                        matCenterController: _matCenterController, matCenterFocus: _matCenterFocus, narrationController: _narrationController, narrationFocus: _narrationFocus,
                        onValidateDate: _parseAndValidateDate, onQuickAdd: _openQuickAddDialog, onAddParty: _openAddPartyDialog, onNarrationSubmitted: () => _items.firstOrNull?.itemFocus.requestFocus(),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: VoucherItemsTable(
                          items: _items, availableItems: _itemsMasterList, isInterState: _isInterState, totalQty: _totalQty, totalTaxable: _itemSubTotal,
                          totalAmount: _totalItemAmount, onAddRow: () => setState(_addItemRow), onRowEnter: _handleItemRowEnter, onAddItem: _openAddItemDialog,
                          onItemSelected: _onItemMasterSelected, onOpenTaxDetails: _openTaxDetailsDialog, onTabToSundry: () => _sundries.firstOrNull?.nameFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 55,
                            child: VoucherSundryCard(
                              sundries: _sundries, autoRoundOff: _autoRoundOff, roundOff: _roundOff, onAddSundry: () => setState(_addSundryRow),
                              onToggleRoundOff: () { setState(() { _autoRoundOff = !_autoRoundOff; _calculateAllTotals(); }); },
                              onRowEnter: _handleSundryRowEnter, onTabToSave: () => _saveButtonFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 45,
                            child: VoucherSummaryCard(
                              isInterState: _isInterState, subTotal: _itemSubTotal, totalCgst: _totalCgst, totalSgst: _totalSgst, totalIgst: _totalIgst,
                              sundryTotal: _sundryTotal, roundOff: _roundOff, grandTotal: _grandTotal, saveButtonFocusNode: _saveButtonFocusNode,
                              onSave: _saveVoucher, onClose: () async { if (await _onWillPop()) widget.onClose(); },
                              saveShortcutLabel: KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.saveVoucherAction),
                              quitShortcutLabel: KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.goBackAction),
                            ),
                          ),
                        ],
                      ),
                    ],
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