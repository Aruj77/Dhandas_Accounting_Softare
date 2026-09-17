import 'package:flutter/material.dart';

import '../../../core/keyboard/keyboard_system.dart';
import '../../../services/storage_service.dart';
import '../../../services/voucher_calculation_service.dart';
import '../../../widgets/voucher/popup/add_item_dialog.dart';
import '../../../widgets/voucher/popup/add_party_dialog.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
import '../../../widgets/voucher/voucher_navigation_bar.dart';
import '../../../widgets/voucher/popup/voucher_save_confirm_dialog.dart';
import '../../../widgets/voucher/voucher_summary_card.dart';
import '../../../widgets/voucher/voucher_sundry_card.dart';
import '../../../widgets/voucher/voucher_sundry_row.dart';

class VoucherEntryScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final VoidCallback onClose;
  final KeyboardShortcutSettings keyboardSettings;

  const VoucherEntryScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onClose,
    required this.keyboardSettings,
  });

  @override
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  final TextEditingController _seriesController = TextEditingController(
    text: 'Main',
  );
  final FocusNode _seriesFocus = FocusNode();

  final TextEditingController _dateController = TextEditingController();
  final FocusNode _dateFocusNode = FocusNode();
  String? _dateError;

  // Kept empty by default
  final TextEditingController _vchNoController = TextEditingController(
    text: '',
  );
  final FocusNode _vchNoFocus = FocusNode();

  final TextEditingController _saleTypeController = TextEditingController(
    text: 'GST 18% (Item Wise)',
  );
  final FocusNode _saleTypeFocus = FocusNode();

  final TextEditingController _partyController = TextEditingController();
  final FocusNode _partyFocus = FocusNode();

  final TextEditingController _matCenterController = TextEditingController(
    text: 'Main Store',
  );
  final FocusNode _matCenterFocus = FocusNode();

  final TextEditingController _narrationController = TextEditingController();
  final FocusNode _narrationFocus = FocusNode();

  final FocusNode _saveButtonFocusNode = FocusNode();

  final List<VoucherItemRow> _items = [];
  final List<VoucherSundryRow> _sundries = [];

  List<PartyMasterModel> _debtorsList = [];
  List<PartyMasterModel> _creditorsList = [];
  List<ItemMasterModel> _itemsMasterList = [];

  double _itemSubTotal = 0.0;
  double _totalQty = 0.0;
  double _totalCgst = 0.0;
  double _totalSgst = 0.0;
  double _totalIgst = 0.0;
  double _totalTax = 0.0;
  double _sundryTotal = 0.0;
  double _roundOff = 0.0;
  double _grandTotal = 0.0;
  double _totalItemAmount = 0.0;

  bool _isInterState = false;
  bool _autoRoundOff = true;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  bool get _isSalesVoucher => widget.voucherType.toLowerCase().contains('sale');
  List<PartyMasterModel> get _currentAvailableParties =>
      _isSalesVoucher ? _debtorsList : _creditorsList;

  @override
  void initState() {
    super.initState();
    _loadCompanyMastersAndInitialize();
  }

  Future<void> _loadCompanyMastersAndInitialize() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath != null) {
      final rawMasters = await StorageService.loadCompanyMasters(
        folderPath: folderPath,
      );

      final rawDebtors = rawMasters['debtors'] as List? ?? [];
      final rawCreditors = rawMasters['creditors'] as List? ?? [];
      final rawItems = rawMasters['items'] as List? ?? [];

      _debtorsList = rawDebtors
          .map(
            (d) => PartyMasterModel(
              name: d['name']?.toString() ?? '',
              gstin: d['gstin']?.toString() ?? '',
              group: d['group']?.toString() ?? 'Sundry Debtors',
            ),
          )
          .toList();

      _creditorsList = rawCreditors
          .map(
            (c) => PartyMasterModel(
              name: c['name']?.toString() ?? '',
              gstin: c['gstin']?.toString() ?? '',
              group: c['group']?.toString() ?? 'Sundry Creditors',
            ),
          )
          .toList();

      _itemsMasterList = rawItems
          .map(
            (i) => ItemMasterModel(
              name: i['name']?.toString() ?? '',
              hsn: i['hsn']?.toString() ?? '',
              unit: i['unit']?.toString() ?? 'Pcs',
              taxCategory: i['taxCategory']?.toString() ?? 'GST 18%',
              taxRate: (i['taxRate'] is num)
                  ? (i['taxRate'] as num).toDouble()
                  : 18.0,
              salesPrice: (i['salesPrice'] is num)
                  ? (i['salesPrice'] as num).toDouble()
                  : 0.0,
              purchasePrice: (i['purchasePrice'] is num)
                  ? (i['purchasePrice'] as num).toDouble()
                  : 0.0,
              mrp: (i['mrp'] is num) ? (i['mrp'] as num).toDouble() : 0.0,
            ),
          )
          .toList();
    }

    _initializeNewVoucher();
  }

  Future<void> _syncMastersToFile() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath == null) return;

    final mastersData = {
      'debtors': _debtorsList
          .map((d) => {'name': d.name, 'gstin': d.gstin, 'group': d.group})
          .toList(),
      'creditors': _creditorsList
          .map((c) => {'name': c.name, 'gstin': c.gstin, 'group': c.group})
          .toList(),
      'items': _itemsMasterList
          .map(
            (i) => {
              'name': i.name,
              'hsn': i.hsn,
              'unit': i.unit,
              'taxCategory': i.taxCategory,
              'taxRate': i.taxRate,
              'salesPrice': i.salesPrice,
              'purchasePrice': i.purchasePrice,
              'mrp': i.mrp,
            },
          )
          .toList(),
    };

    await StorageService.saveCompanyMasters(
      folderPath: folderPath,
      mastersData: mastersData,
    );
  }

  void _initializeNewVoucher() {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    _vchNoController.text = ''; // Remains completely blank by default
    _parseFinancialYearBounds(fy);

    _partyController.text = '';
    _checkGstMode();

    final now = DateTime.now();
    if (now.isAfter(_fyStartDate) && now.isBefore(_fyEndDate)) {
      _dateController.text =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    } else {
      _dateController.text = '01-04-${_fyStartDate.year}';
    }

    _dateFocusNode.addListener(() {
      if (!_dateFocusNode.hasFocus) {
        _parseAndValidateDate();
      }
    });

    _partyController.addListener(() {
      _checkGstMode();
      for (final row in _items) {
        VoucherCalculationService.recalculateTaxesFromTaxable(
          row,
          _isInterState,
        );
      }
      _calculateAllTotals();
    });

    _items.clear();
    for (int i = 0; i < 20; i++) {
      _addItemRow();
    }

    _sundries.clear();
    for (int i = 0; i < 5; i++) {
      _addSundryRow();
    }

    if (mounted) setState(() {});
  }

  void _checkGstMode() {
    final companyGst = (widget.company['gstin'] ?? '').toString().trim();
    final partyText = _partyController.text.trim();

    String partyGstin = '';
    final match = RegExp(r'\[([A-Z0-9]{15})\]').firstMatch(partyText);
    if (match != null) {
      partyGstin = match.group(1) ?? '';
    } else if (partyText.length == 15) {
      partyGstin = partyText;
    }

    if (companyGst.length >= 2 && partyGstin.length >= 2) {
      final compState = companyGst.substring(0, 2);
      final partyState = partyGstin.substring(0, 2);
      _isInterState = compState != partyState;
    } else {
      _isInterState = false;
    }
  }

  String _getUnitString(dynamic unitValue) {
    if (unitValue is TextEditingController) {
      return unitValue.text.isNotEmpty ? unitValue.text : 'Pcs';
    }
    return unitValue?.toString() ?? 'Pcs';
  }

  void _parseFinancialYearBounds(String fyStr) {
    try {
      final sanitized = fyStr.trim();
      final parts = sanitized.split(RegExp(r'[-/]'));
      var startY = int.parse(parts[0].trim());
      if (startY < 100) startY += 2000;

      var endY = startY + 1;
      if (parts.length > 1) {
        final parsedEnd = int.tryParse(parts[1].trim());
        if (parsedEnd != null) {
          endY = parsedEnd < 100 ? 2000 + parsedEnd : parsedEnd;
        }
      }

      setState(() {
        _fyStartDate = DateTime(startY, 4, 1);
        _fyEndDate = DateTime(endY, 3, 31, 23, 59, 59);
      });
    } catch (_) {
      setState(() {
        _fyStartDate = DateTime(2026, 4, 1);
        _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);
      });
    }
  }

  bool _parseAndValidateDate() {
    final raw = _dateController.text.trim();
    if (raw.isEmpty) {
      setState(() => _dateError = 'Date cannot be empty');
      return false;
    }

    final sanitized = raw.replaceAll('/', '-').replaceAll('.', '-');
    final parts = sanitized.split('-').where((p) => p.isNotEmpty).toList();

    int? day;
    int? month;
    int? year;

    if (parts.length == 1 && parts[0].length == 4) {
      day = int.tryParse(parts[0].substring(0, 2));
      month = int.tryParse(parts[0].substring(2, 4));
    } else if (parts.length >= 2) {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      if (parts.length == 3) {
        var y = int.tryParse(parts[2]);
        if (y != null && y < 100) y += 2000;
        year = y;
      }
    }

    if (day == null ||
        month == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      setState(() => _dateError = 'Invalid date');
      return false;
    }

    year ??= (month >= 4 && month <= 12) ? _fyStartDate.year : _fyEndDate.year;

    DateTime parsedDate;
    try {
      parsedDate = DateTime(year, month, day);
      if (parsedDate.day != day || parsedDate.month != month) {
        setState(() => _dateError = 'Invalid date');
        return false;
      }
    } catch (_) {
      setState(() => _dateError = 'Invalid date');
      return false;
    }

    if (parsedDate.isBefore(_fyStartDate) || parsedDate.isAfter(_fyEndDate)) {
      setState(() => _dateError = 'Date must fall within F.Y.');
      return false;
    }

    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    final yyyy = year.toString().padLeft(4, '0');

    _dateController.text = '$dd-$mm-$yyyy';
    setState(() => _dateError = null);
    return true;
  }

  void _addSundryRow() {
    final row = VoucherSundryRow();
    row.name.addListener(() {
      _applySundryAutoValue(row);
      _calculateAllTotals();
    });
    row.amount.addListener(_calculateAllTotals);
    _sundries.add(row);
  }

  void _applySundryAutoValue(VoucherSundryRow sundry) {
    final type = sundry.name.text;
    if (type == 'Round off+' || type == 'Rnd off -') {
      double baseSum = _itemSubTotal + _totalTax;
      for (final s in _sundries) {
        if (s != sundry) {
          final a = double.tryParse(s.amount.text) ?? 0.0;
          baseSum += (s.name.text == 'Rnd off -' || s.isNegative) ? -a : a;
        }
      }
      final remainder = baseSum % 1.0;
      if (type == 'Round off+') {
        final diff = remainder == 0 ? 0.0 : (1.0 - remainder);
        sundry.amount.text = diff > 0 ? diff.toStringAsFixed(2) : '';
        sundry.isNegative = false;
      } else {
        sundry.amount.text = remainder > 0 ? remainder.toStringAsFixed(2) : '';
        sundry.isNegative = true;
      }
    }
  }

  void _addItemRow() {
    final row = VoucherItemRow();

    row.qty.addListener(() {
      if (row.qtyFocus.hasFocus) {
        final q = double.tryParse(row.qty.text) ?? 0.0;
        final p = double.tryParse(row.price.text) ?? 0.0;
        final t = double.tryParse(row.taxable.text) ?? 0.0;

        if (p > 0) {
          final taxVal = q * p;
          row.taxable.text = taxVal > 0 ? taxVal.toStringAsFixed(2) : '';
          VoucherCalculationService.recalculateTaxesFromTaxable(
            row,
            _isInterState,
          );
        } else if (t > 0 && q > 0) {
          row.price.text = (t / q).toStringAsFixed(2);
        }
        _calculateAllTotals();
      }
    });

    row.price.addListener(() {
      if (row.priceFocus.hasFocus) {
        final q = double.tryParse(row.qty.text) ?? 0.0;
        final p = double.tryParse(row.price.text) ?? 0.0;
        final t = double.tryParse(row.taxable.text) ?? 0.0;

        if (q > 0) {
          final taxVal = q * p;
          row.taxable.text = taxVal > 0 ? taxVal.toStringAsFixed(2) : '';
          VoucherCalculationService.recalculateTaxesFromTaxable(
            row,
            _isInterState,
          );
        } else if (t > 0 && p > 0) {
          row.qty.text = (t / p).toStringAsFixed(2);
        }
        _calculateAllTotals();
      }
    });

    row.taxable.addListener(() {
      if (row.taxableFocus.hasFocus) {
        final t = double.tryParse(row.taxable.text) ?? 0.0;
        final q = double.tryParse(row.qty.text) ?? 0.0;

        if (q > 0) {
          row.price.text = (t / q).toStringAsFixed(2);
        }
        VoucherCalculationService.recalculateTaxesFromTaxable(
          row,
          _isInterState,
        );
        _calculateAllTotals();
      }
    });

    row.cgst.addListener(() {
      if (row.cgstFocus.hasFocus) {
        row.sgst.text = row.cgst.text;
        _recalculateAmountFromTaxes(row);
        _calculateAllTotals();
      }
    });

    row.sgst.addListener(() {
      if (row.sgstFocus.hasFocus) {
        _recalculateAmountFromTaxes(row);
        _calculateAllTotals();
      }
    });

    row.igst.addListener(() {
      if (row.igstFocus.hasFocus) {
        _recalculateAmountFromTaxes(row);
        _calculateAllTotals();
      }
    });

    row.amount.addListener(() {
      if (row.amountFocus.hasFocus) {
        VoucherCalculationService.recalculateFromInvoiceAmount(
          row,
          _isInterState,
        );
        _calculateAllTotals();
      }
    });

    _items.add(row);
  }

  void _onItemMasterSelected(int index, ItemMasterModel selectedItem) {
    final row = _items[index];
    row.unit.text = selectedItem.unit;
    row.gstRate = selectedItem.taxRate;

    final defaultPrice = _isSalesVoucher
        ? selectedItem.salesPrice
        : selectedItem.purchasePrice;
    if (defaultPrice > 0) {
      row.price.text = defaultPrice.toStringAsFixed(2);
    }

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0 && defaultPrice > 0) {
      final taxVal = q * defaultPrice;
      row.taxable.text = taxVal.toStringAsFixed(2);
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.taxable.text.isNotEmpty) {
      VoucherCalculationService.recalculateTaxesFromTaxable(row, _isInterState);
    } else if (row.amount.text.isNotEmpty) {
      VoucherCalculationService.recalculateFromInvoiceAmount(
        row,
        _isInterState,
      );
    }
    _calculateAllTotals();
  }

  void _recalculateAmountFromTaxes(VoucherItemRow row) {
    final t = double.tryParse(row.taxable.text) ?? 0.0;
    final c = double.tryParse(row.cgst.text) ?? 0.0;
    final s = double.tryParse(row.sgst.text) ?? 0.0;
    final i = double.tryParse(row.igst.text) ?? 0.0;
    final gross = t + (_isInterState ? i : (c + s));
    row.amount.text = gross == 0 ? '' : gross.toStringAsFixed(2);
  }

  void _calculateAllTotals() {
    final result = VoucherCalculationService.calculateTotals(
      items: _items,
      sundries: _sundries,
      isInterState: _isInterState,
      autoRoundOff: _autoRoundOff,
    );

    setState(() {
      _totalQty = result.totalQty;
      _itemSubTotal = result.subTotal;
      _totalCgst = result.totalCgst;
      _totalSgst = result.totalSgst;
      _totalIgst = result.totalIgst;
      _totalTax = result.totalTax;
      _sundryTotal = result.sundryTotal;
      _roundOff = result.roundOff;
      _grandTotal = result.grandTotal;
      _totalItemAmount = result.totalItemAmount;
    });
  }

  void _openAddItemDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AddItemDialog(
        onItemCreated: (itemData) async {
          final newModel = ItemMasterModel(
            name: itemData['name'],
            hsn: itemData['hsn'],
            unit: itemData['unit'],
            taxCategory: itemData['taxCategory'],
            taxRate: itemData['taxRate'],
            salesPrice: itemData['salesPrice'],
            purchasePrice: itemData['purchasePrice'],
            mrp: itemData['mrp'],
          );

          setState(() {
            _itemsMasterList.add(newModel);
            _items[index].item.text = newModel.name;
            _onItemMasterSelected(index, newModel);
          });

          await _syncMastersToFile();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Registered and saved to company: ${newModel.name}',
                ),
                backgroundColor: const Color(0xFF10A35B),
              ),
            );
          }
        },
      ),
    );
  }

  void _openAddPartyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddPartyDialog(
        voucherType: widget.voucherType,
        onPartyCreated: (partyData) async {
          final name = partyData['name'] ?? '';
          final gstin = partyData['gstin'] ?? '';
          final group =
              partyData['group'] ??
              (_isSalesVoucher ? 'Sundry Debtors' : 'Sundry Creditors');
          final newModel = PartyMasterModel(
            name: name,
            gstin: gstin,
            group: group,
          );

          setState(() {
            if (_isSalesVoucher) {
              _debtorsList.add(newModel);
            } else {
              _creditorsList.add(newModel);
            }
            _partyController.text = newModel.displayName;
          });

          await _syncMastersToFile();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Registered and saved to company: ${newModel.displayName}',
                ),
                backgroundColor: const Color(0xFF10A35B),
              ),
            );
          }
        },
      ),
    );
  }

  void _openQuickAddDialog(String masterType) {
    if (masterType == 'Account Ledger') {
      _openAddPartyDialog();
      return;
    }

    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF0F62FE),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Add $masterType',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new $masterType name',
            filled: true,
            fillColor: const Color(0xFFF8FAFD),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created master: "${nameCtrl.text.trim()}"'),
                  backgroundColor: const Color(0xFF10A35B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F62FE),
            ),
            child: const Text(
              'Save Master',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message, FocusNode? targetFocus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEE4343),
        behavior: SnackBarBehavior.floating,
      ),
    );
    targetFocus?.requestFocus();
  }

  Future<void> _saveVoucher() async {
    // 1. Validate Date
    final isDateValid = _parseAndValidateDate();
    if (!isDateValid || _dateError != null) {
      _showValidationError(
        _dateError ??
            'Please enter a valid Voucher Date within the Financial Year',
        _dateFocusNode,
      );
      return;
    }

    // 2. Validate Voucher Number
    final vchNo = _vchNoController.text.trim();
    if (vchNo.isEmpty) {
      _showValidationError(
        'Voucher Number is required and cannot be blank.',
        _vchNoFocus,
      );
      return;
    }

    // 3. Validate Party
    final partyName = _partyController.text.trim();
    if (partyName.isEmpty) {
      _showValidationError(
        'Please select or add a Party/Account Ledger.',
        _partyFocus,
      );
      return;
    }

    final isPartyListed = _currentAvailableParties.any(
      (p) => p.displayName == partyName || p.name == partyName,
    );
    if (!isPartyListed) {
      _showValidationError(
        'Selected party "$partyName" is not registered. Choose from the list or click + to add.',
        _partyFocus,
      );
      return;
    }

    // 4. Validate Items (At least 1 item with positive quantity & amount)
    final validItems = _items.where((i) {
      final name = i.item.text.trim();
      final q = double.tryParse(i.qty.text) ?? 0.0;
      final amt = double.tryParse(i.amount.text) ?? 0.0;
      return name.isNotEmpty && q > 0 && amt > 0;
    }).toList();

    if (validItems.isEmpty) {
      _showValidationError(
        'Add at least one valid item with Item Name, Qty (> 0), and Amount.',
        null,
      );
      if (_items.isNotEmpty) _items[0].itemFocus.requestFocus();
      return;
    }

    // 5. Present Confirmation Summary Modal with Auto-Focus on Save
    final summaryData = {
      'voucherType': widget.voucherType,
      'voucherNumber': vchNo,
      'date': _dateController.text,
      'party': partyName,
      'isInterState': _isInterState,
      'itemCount': validItems.length,
      'totalQty': _totalQty,
      'subTotal': _itemSubTotal,
      'cgst': _totalCgst,
      'sgst': _totalSgst,
      'igst': _totalIgst,
      'sundryTotal': _sundryTotal,
      'roundOff': _roundOff,
      'grandTotal': _grandTotal,
    };

    showDialog(
      context: context,
      builder: (ctx) => VoucherSaveConfirmDialog(
        summaryData: summaryData,
        onConfirm: _executeVoucherPersistence,
      ),
    );
  }

  Future<void> _executeVoucherPersistence() async {
    final voucherPayload = {
      'voucherType': widget.voucherType,
      'voucherNumber': _vchNoController.text.trim(),
      'date': _dateController.text,
      'series': _seriesController.text,
      'saleType': _saleTypeController.text,
      'party': _partyController.text,
      'isInterState': _isInterState,
      'materialCenter': _matCenterController.text,
      'narration': _narrationController.text,
      'financialYear': widget.company['activeFinancialYear'],
      'items': _items
          .where((i) => i.item.text.isNotEmpty)
          .map(
            (i) => {
              'item': i.item.text,
              'qty': i.qty.text,
              'unit': _getUnitString(i.unit),
              'price': i.price.text,
              'taxable': i.taxable.text,
              'cgst': i.cgst.text,
              'sgst': i.sgst.text,
              'igst': i.igst.text,
              'amount': i.amount.text,
              'gstRate': i.gstRate,
            },
          )
          .toList(),
      'sundries': _sundries
          .where((s) => s.amount.text != '' && s.amount.text != '0.00')
          .map(
            (s) => {
              'name': s.name.text,
              'amount': s.amount.text,
              'isNegative': s.isNegative,
            },
          )
          .toList(),
      'subTotal': _itemSubTotal,
      'cgst': _totalCgst,
      'sgst': _totalSgst,
      'igst': _totalIgst,
      'totalTax': _totalTax,
      'sundryTotal': _sundryTotal,
      'roundOff': _roundOff,
      'grandTotal': _grandTotal,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final folderPath = widget.company['folderPath'];
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';

    if (folderPath != null) {
      await StorageService.saveVoucher(
        folderPath: folderPath,
        financialYear: fy,
        voucherData: voucherPayload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.voucherType} [${_vchNoController.text}] saved successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10A35B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _initializeNewVoucher();
      }
    }
  }

  Future<bool> _onWillPop() async {
    final FocusNode cancelFocusNode = FocusNode();
    final FocusNode exitFocusNode = FocusNode();

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cancelFocusNode.requestFocus();
        });

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101B3A),
                ),
              ),
            ],
          ),
          content: const Text(
            'You have unsaved changes in this voucher. Are you sure you want to discard and exit?',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          actions: [
            // Cancel Action (Focused by default with prominent ring)
            Focus(
              focusNode: cancelFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      backgroundColor: isFocused
                          ? const Color(0xFFF1F5FB)
                          : Colors.transparent,
                      side: BorderSide(
                        color: isFocused
                            ? const Color(0xFF0F62FE)
                            : const Color(0xFFCBD5E1),
                        width: isFocused ? 2.0 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel (Esc)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isFocused
                            ? const Color(0xFF0F62FE)
                            : const Color(0xFF475569),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            // Exit Action (Highlights with red focus ring when tabbed to)
            Focus(
              focusNode: exitFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE4343),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: isFocused ? 3 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isFocused
                              ? const Color(0xFF7F1D1D)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Exit Without Saving',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    cancelFocusNode.dispose();
    exitFocusNode.dispose();
    return shouldClose ?? false;
  }

  void _focusFirstItemRow() {
    if (_items.isNotEmpty) {
      _items[0].itemFocus.requestFocus();
    }
  }

  void _focusFirstSundryRow() {
    if (_sundries.isNotEmpty) {
      _sundries[0].nameFocus.requestFocus();
    } else {
      _saveButtonFocusNode.requestFocus();
    }
  }

  void _handleItemRowEnter(int index, String field) {
    if (field == 'item') {
      _items[index].qtyFocus.requestFocus();
    } else if (field == 'qty') {
      _items[index].priceFocus.requestFocus();
    } else if (field == 'price') {
      _items[index].taxableFocus.requestFocus();
    } else if (field == 'taxable') {
      if (_isInterState) {
        _items[index].igstFocus.requestFocus();
      } else {
        _items[index].cgstFocus.requestFocus();
      }
    } else if (field == 'cgst') {
      _items[index].sgstFocus.requestFocus();
    } else if (field == 'sgst' || field == 'igst') {
      _items[index].amountFocus.requestFocus();
    } else if (field == 'amount') {
      if (index + 1 < _items.length) {
        _items[index + 1].itemFocus.requestFocus();
      } else {
        _focusFirstSundryRow();
      }
    }
  }

  void _handleSundryRowEnter(int index, String field) {
    if (field == 'name') {
      _sundries[index].amountFocus.requestFocus();
    } else if (field == 'amount') {
      if (index + 1 < _sundries.length) {
        _sundries[index + 1].nameFocus.requestFocus();
      } else {
        _saveButtonFocusNode.requestFocus();
      }
    }
  }

  Color _getVoucherHeaderColor() {
    final vch = widget.voucherType.toLowerCase();
    if (vch.contains('sale')) {
      return const Color.fromARGB(255, 236, 118, 21);
    }
    if (vch.contains('purchase')) {
      return const Color(0xFF7034E6);
    }
    if (vch.contains('payment') || vch.contains('receipt')) {
      return const Color(0xFF10A35B);
    }
    return const Color(0xFF0D9488);
  }

  Color _getVoucherBackgroundColor() {
    final vch = widget.voucherType.toLowerCase();
    if (vch.contains('sale')) {
      return const Color.fromARGB(255, 255, 241, 223); // Cool Blue-Grey tint
    }
    if (vch.contains('purchase')) {
      return const Color.fromARGB(255, 230, 220, 255); // Soft Violet tint
    }
    if (vch.contains('payment')) {
      return const Color.fromRGBO(227, 252, 222, 1); // Soft Warm Red tint
    }
    if (vch.contains('receipt')) {
      return const Color.fromARGB(255, 240, 253, 254); // Soft Mint tint
    }
    if (vch.contains('journal')) {
      return const Color.fromARGB(255, 255, 251, 23); // Soft Amber tint
    }
    if (vch.contains('contra')) {
      return const Color.fromARGB(255, 248, 249, 255); // Soft Sky tint
    }
    return const Color.fromARGB(255, 255, 245, 185); // Default tint
  }

  @override
  void dispose() {
    _seriesController.dispose();
    _seriesFocus.dispose();
    _dateController.dispose();
    _dateFocusNode.dispose();
    _vchNoController.dispose();
    _vchNoFocus.dispose();
    _saleTypeController.dispose();
    _saleTypeFocus.dispose();
    _partyController.dispose();
    _partyFocus.dispose();
    _matCenterController.dispose();
    _matCenterFocus.dispose();
    _narrationController.dispose();
    _narrationFocus.dispose();
    _saveButtonFocusNode.dispose();

    for (final item in _items) {
      item.dispose();
    }
    for (final sundry in _sundries) {
      sundry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    final headerColor = _getVoucherHeaderColor();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          widget.onClose();
        }
      },
      child: KeyboardScope(
        autofocus: true,
        onAction: _handleVoucherAction,
        // Scope to this screen's own action set so Busy-style F3/F7/F9/etc.
        // here never collide with the app-level meaning of the same bare
        // key elsewhere (e.g. F3 = Open Company on the home screen).
        actionIds: const [
          KeyboardAction.back,
          KeyboardAction.cancel,
          KeyboardAction.save,
          KeyboardAction.saveVoucher,
          KeyboardAction.help,
          KeyboardAction.newRecord,
          KeyboardAction.delete,
          KeyboardAction.duplicate,
          KeyboardAction.print,
          KeyboardAction.export,
          KeyboardAction.createLedger,
          KeyboardAction.createItem,
          KeyboardAction.findMaster,
          KeyboardAction.repeatField,
          KeyboardAction.cancelVoucher,
          KeyboardAction.calculator,
          KeyboardAction.hideRow,
          KeyboardAction.unhideRow,
        ],
        child: Scaffold(
          backgroundColor: _getVoucherBackgroundColor(),
          body: Column(
            children: [
              // 1. EXTRACTED TOP NAVIGATION BAR
              VoucherNavigationBar(
                voucherType: widget.voucherType,
                financialYear: fy,
                isInterState: _isInterState,
                headerColor: headerColor,
                keyboardSettings: widget.keyboardSettings,
                onSave: _saveVoucher,
                onClose: () async {
                  if (await _onWillPop()) {
                    widget.onClose();
                  }
                },
              ),

              // 2. MAIN VOUCHER BODY
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Header Metadata Card
                      VoucherHeaderCard(
                        seriesController: _seriesController,
                        seriesFocus: _seriesFocus,
                        dateController: _dateController,
                        dateFocus: _dateFocusNode,
                        dateError: _dateError,
                        vchNoController: _vchNoController,
                        vchNoFocus: _vchNoFocus,
                        saleTypeController: _saleTypeController,
                        saleTypeFocus: _saleTypeFocus,
                        partyController: _partyController,
                        partyFocus: _partyFocus,
                        availableParties: _currentAvailableParties,
                        matCenterController: _matCenterController,
                        matCenterFocus: _matCenterFocus,
                        narrationController: _narrationController,
                        narrationFocus: _narrationFocus,
                        onValidateDate: () => _parseAndValidateDate(),
                        onQuickAdd: _openQuickAddDialog,
                        onAddParty: _openAddPartyDialog,
                        onNarrationSubmitted: _focusFirstItemRow,
                      ),

                      const SizedBox(height: 10),

                      // Items Table
                      Expanded(
                        child: VoucherItemsTable(
                          items: _items,
                          availableItems: _itemsMasterList,
                          isInterState: _isInterState,
                          totalQty: _totalQty,
                          totalTaxable: _itemSubTotal,
                          totalCgst: _totalCgst,
                          totalSgst: _totalSgst,
                          totalIgst: _totalIgst,
                          totalAmount: _totalItemAmount,
                          onAddRow: () => setState(_addItemRow),
                          onRowEnter: _handleItemRowEnter,
                          onAddItem: _openAddItemDialog,
                          onItemSelected: _onItemMasterSelected,
                          onTabToSundry: _focusFirstSundryRow,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Dual Lower Panels (Sundry & Summary)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 55,
                            child: VoucherSundryCard(
                              sundries: _sundries,
                              autoRoundOff: _autoRoundOff,
                              roundOff: _roundOff,
                              onAddSundry: () {
                                setState(() {
                                  _addSundryRow();
                                });
                              },
                              onToggleRoundOff: () {
                                setState(() {
                                  _autoRoundOff = !_autoRoundOff;
                                  _calculateAllTotals();
                                });
                              },
                              onRowEnter: _handleSundryRowEnter,
                              onTabToSave: () =>
                                  _saveButtonFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 45,
                            child: VoucherSummaryCard(
                              isInterState: _isInterState,
                              subTotal: _itemSubTotal,
                              totalCgst: _totalCgst,
                              totalSgst: _totalSgst,
                              totalIgst: _totalIgst,
                              sundryTotal: _sundryTotal,
                              roundOff: _roundOff,
                              grandTotal: _grandTotal,
                              saveButtonFocusNode: _saveButtonFocusNode,
                              onSave: _saveVoucher,
                              onClose: () async {
                                if (await _onWillPop()) {
                                  widget.onClose();
                                }
                              },
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

  // Every action id comes from the single global KeyboardAction/KeyboardRegistry
  // definition; this screen only decides what a given action does while a
  // voucher is open. Unmapped actions are ignored so they still reach fields.
  KeyEventResult _handleVoucherAction(String actionId, KeyEvent event) {
    switch (actionId) {
      case KeyboardAction.back:
      case KeyboardAction.cancel:
        _onWillPop().then((shouldClose) {
          if (shouldClose) widget.onClose();
        });
        return KeyEventResult.handled;

      case KeyboardAction.save:
      case KeyboardAction.saveVoucher:
        _saveVoucher();
        return KeyEventResult.handled;

      case KeyboardAction.help:
        KeyboardHelpDialog.show(context);
        return KeyEventResult.handled;

      case KeyboardAction.newRecord:
        _saveVoucher();
        return KeyEventResult.handled;

      case KeyboardAction.delete:
        return KeyEventResult.ignored;

      case KeyboardAction.duplicate:
      case KeyboardAction.print:
      case KeyboardAction.export:
        return KeyEventResult.ignored;

      // ---- Busy-style voucher-entry shortcuts ----
      case KeyboardAction.createLedger:
        _openQuickAddDialog('Account Ledger');
        return KeyEventResult.handled;

      case KeyboardAction.createItem:
        _openQuickAddDialog('Item');
        return KeyEventResult.handled;

      case KeyboardAction.findMaster:
        _openAddPartyDialog();
        return KeyEventResult.handled;

      case KeyboardAction.cancelVoucher:
        _onWillPop().then((shouldClose) {
          if (shouldClose) widget.onClose();
        });
        return KeyEventResult.handled;

      case KeyboardAction.repeatField:
      case KeyboardAction.hideRow:
      case KeyboardAction.unhideRow:
      case KeyboardAction.calculator:
        // Key is captured and routed here; feature not built yet on this
        // screen. Wire real behaviour when that feature exists.
        return KeyEventResult.ignored;

      default:
        return KeyEventResult.ignored;
    }
  }
}
