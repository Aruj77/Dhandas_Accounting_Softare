import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/voucher/add_item_dialog.dart';
import '../../../widgets/voucher/add_party_dialog.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
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
  final TextEditingController _seriesController = TextEditingController(text: 'Main');
  final FocusNode _seriesFocus = FocusNode();

  final TextEditingController _dateController = TextEditingController();
  final FocusNode _dateFocusNode = FocusNode();
  String? _dateError;

  final TextEditingController _vchNoController = TextEditingController();
  final FocusNode _vchNoFocus = FocusNode();

  final TextEditingController _saleTypeController =
      TextEditingController(text: 'GST 18% (Item Wise)');
  final FocusNode _saleTypeFocus = FocusNode();

  final TextEditingController _partyController = TextEditingController();
  final FocusNode _partyFocus = FocusNode();

  final TextEditingController _matCenterController =
      TextEditingController(text: 'Main Store');
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
  List<PartyMasterModel> get _currentAvailableParties => _isSalesVoucher ? _debtorsList : _creditorsList;

  @override
  void initState() {
    super.initState();
    _loadCompanyMastersAndInitialize();
  }

  Future<void> _loadCompanyMastersAndInitialize() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath != null) {
      final rawMasters = await StorageService.loadCompanyMasters(folderPath: folderPath);
      
      final rawDebtors = rawMasters['debtors'] as List? ?? [];
      final rawCreditors = rawMasters['creditors'] as List? ?? [];
      final rawItems = rawMasters['items'] as List? ?? [];

      _debtorsList = rawDebtors.map((d) => PartyMasterModel(
        name: d['name']?.toString() ?? '',
        gstin: d['gstin']?.toString() ?? '',
        group: d['group']?.toString() ?? 'Sundry Debtors',
      )).toList();

      _creditorsList = rawCreditors.map((c) => PartyMasterModel(
        name: c['name']?.toString() ?? '',
        gstin: c['gstin']?.toString() ?? '',
        group: c['group']?.toString() ?? 'Sundry Creditors',
      )).toList();

      _itemsMasterList = rawItems.map((i) => ItemMasterModel(
        name: i['name']?.toString() ?? '',
        hsn: i['hsn']?.toString() ?? '',
        unit: i['unit']?.toString() ?? 'Pcs',
        taxCategory: i['taxCategory']?.toString() ?? 'GST 18%',
        taxRate: (i['taxRate'] is num) ? (i['taxRate'] as num).toDouble() : 18.0,
        salesPrice: (i['salesPrice'] is num) ? (i['salesPrice'] as num).toDouble() : 0.0,
        purchasePrice: (i['purchasePrice'] is num) ? (i['purchasePrice'] as num).toDouble() : 0.0,
        mrp: (i['mrp'] is num) ? (i['mrp'] as num).toDouble() : 0.0,
      )).toList();
    }

    _initializeNewVoucher();
  }

  Future<void> _syncMastersToFile() async {
    final folderPath = widget.company['folderPath'];
    if (folderPath == null) return;

    final mastersData = {
      'debtors': _debtorsList.map((d) => {
        'name': d.name,
        'gstin': d.gstin,
        'group': d.group,
      }).toList(),
      'creditors': _creditorsList.map((c) => {
        'name': c.name,
        'gstin': c.gstin,
        'group': c.group,
      }).toList(),
      'items': _itemsMasterList.map((i) => {
        'name': i.name,
        'hsn': i.hsn,
        'unit': i.unit,
        'taxCategory': i.taxCategory,
        'taxRate': i.taxRate,
        'salesPrice': i.salesPrice,
        'purchasePrice': i.purchasePrice,
        'mrp': i.mrp,
      }).toList(),
    };

    await StorageService.saveCompanyMasters(
      folderPath: folderPath,
      mastersData: mastersData,
    );
  }

  void _initializeNewVoucher() {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    _vchNoController.text = '1/$fy';
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
        _recalculateTaxesFromTaxable(row);
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

    if (day == null || month == null || month < 1 || month > 12 || day < 1 || day > 31) {
      setState(() => _dateError = 'Invalid date');
      return false;
    }

    if (year == null) {
      if (month >= 4 && month <= 12) {
        year = _fyStartDate.year;
      } else {
        year = _fyEndDate.year;
      }
    }

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
          if (s.name.text == 'Rnd off -' || s.isNegative) {
            baseSum -= a;
          } else {
            baseSum += a;
          }
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
          _recalculateTaxesFromTaxable(row);
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
          _recalculateTaxesFromTaxable(row);
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
        _recalculateTaxesFromTaxable(row);
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
        _recalculateFromInvoiceAmount(row);
        _calculateAllTotals();
      }
    });

    _items.add(row);
  }

  void _onItemMasterSelected(int index, ItemMasterModel selectedItem) {
    final row = _items[index];
    row.unit.text = selectedItem.unit;
    row.gstRate = selectedItem.taxRate;

    final defaultPrice = _isSalesVoucher ? selectedItem.salesPrice : selectedItem.purchasePrice;
    if (defaultPrice > 0) {
      row.price.text = defaultPrice.toStringAsFixed(2);
    }

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0 && defaultPrice > 0) {
      final taxVal = q * defaultPrice;
      row.taxable.text = taxVal.toStringAsFixed(2);
      _recalculateTaxesFromTaxable(row);
    } else if (row.taxable.text.isNotEmpty) {
      _recalculateTaxesFromTaxable(row);
    } else if (row.amount.text.isNotEmpty) {
      _recalculateFromInvoiceAmount(row);
    }
    _calculateAllTotals();
  }

  void _recalculateFromInvoiceAmount(VoucherItemRow row) {
    final invoiceAmt = double.tryParse(row.amount.text) ?? 0.0;
    if (invoiceAmt <= 0) return;

    final rate = row.gstRate;
    final taxableVal = invoiceAmt / (1.0 + (rate / 100.0));
    final totalTaxVal = invoiceAmt - taxableVal;

    row.taxable.text = taxableVal.toStringAsFixed(2);

    if (_isInterState) {
      row.igst.text = totalTaxVal.toStringAsFixed(2);
      row.cgst.text = '';
      row.sgst.text = '';
    } else {
      final halfTax = totalTaxVal / 2.0;
      row.cgst.text = halfTax.toStringAsFixed(2);
      row.sgst.text = halfTax.toStringAsFixed(2);
      row.igst.text = '';
    }

    final q = double.tryParse(row.qty.text) ?? 0.0;
    if (q > 0) {
      row.price.text = (taxableVal / q).toStringAsFixed(2);
    }
  }

  void _recalculateAmountFromTaxes(VoucherItemRow row) {
    final t = double.tryParse(row.taxable.text) ?? 0.0;
    final c = double.tryParse(row.cgst.text) ?? 0.0;
    final s = double.tryParse(row.sgst.text) ?? 0.0;
    final i = double.tryParse(row.igst.text) ?? 0.0;
    final gross = t + (_isInterState ? i : (c + s));
    row.amount.text = gross == 0 ? '' : gross.toStringAsFixed(2);
  }

  void _recalculateTaxesFromTaxable(VoucherItemRow row) {
    final taxVal = double.tryParse(row.taxable.text) ?? 0.0;
    final rate = row.gstRate;
    double taxTotal = 0.0;

    if (_isInterState) {
      final igstVal = (taxVal * rate) / 100.0;
      row.igst.text = igstVal == 0 ? '' : igstVal.toStringAsFixed(2);
      row.cgst.text = '';
      row.sgst.text = '';
      taxTotal = igstVal;
    } else {
      final halfRate = rate / 2.0;
      final cVal = (taxVal * halfRate) / 100.0;
      row.cgst.text = cVal == 0 ? '' : cVal.toStringAsFixed(2);
      row.sgst.text = cVal == 0 ? '' : cVal.toStringAsFixed(2);
      row.igst.text = '';
      taxTotal = cVal * 2.0;
    }

    final gross = taxVal + taxTotal;
    row.amount.text = gross == 0 ? '' : gross.toStringAsFixed(2);
  }

  void _calculateAllTotals() {
    double totalTaxable = 0.0;
    double accumQty = 0.0;
    double cgstAccum = 0.0;
    double sgstAccum = 0.0;
    double igstAccum = 0.0;
    double accumAmount = 0.0;

    for (final row in _items) {
      final q = double.tryParse(row.qty.text) ?? 0.0;
      final t = double.tryParse(row.taxable.text) ?? 0.0;
      final c = double.tryParse(row.cgst.text) ?? 0.0;
      final s = double.tryParse(row.sgst.text) ?? 0.0;
      final i = double.tryParse(row.igst.text) ?? 0.0;
      final amt = double.tryParse(row.amount.text) ?? 0.0;

      accumQty += q;
      totalTaxable += t;
      accumAmount += amt;

      if (_isInterState) {
        igstAccum += i;
      } else {
        cgstAccum += c;
        sgstAccum += s;
      }
    }

    double sundrySum = 0.0;
    for (final s in _sundries) {
      final amt = double.tryParse(s.amount.text) ?? 0.0;
      if (s.name.text == 'Round off+') {
        sundrySum += amt;
      } else if (s.name.text == 'Rnd off -' || s.isNegative) {
        sundrySum -= amt.abs();
      } else {
        sundrySum += amt.abs();
      }
    }

    final totalTaxCalculated = _isInterState ? igstAccum : (cgstAccum + sgstAccum);
    final preFinal = totalTaxable + totalTaxCalculated + sundrySum;
    double rOff = 0.0;
    double gTotal = preFinal;

    if (_autoRoundOff) {
      gTotal = preFinal.roundToDouble();
      rOff = gTotal - preFinal;
    }

    setState(() {
      _totalQty = accumQty;
      _itemSubTotal = totalTaxable;
      _totalCgst = cgstAccum;
      _totalSgst = sgstAccum;
      _totalIgst = igstAccum;
      _totalTax = totalTaxCalculated;
      _sundryTotal = sundrySum;
      _roundOff = rOff;
      _grandTotal = gTotal;
      _totalItemAmount = accumAmount;
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
                content: Text('Registered and saved to company: ${newModel.name}'),
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
          final group = partyData['group'] ?? (_isSalesVoucher ? 'Sundry Debtors' : 'Sundry Creditors');
          final newModel = PartyMasterModel(name: name, gstin: gstin, group: group);

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
                content: Text('Registered and saved to company: ${newModel.displayName}'),
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
            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F62FE), size: 22),
            const SizedBox(width: 8),
            Text('Add $masterType', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE)),
            child: const Text('Save Master', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVoucher() async {
    final isValid = _parseAndValidateDate();
    if (!isValid || _dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_dateError ?? 'Date verification failed'),
          backgroundColor: const Color(0xFFEE4343),
        ),
      );
      return;
    }

    final voucherPayload = {
      'voucherType': widget.voucherType,
      'voucherNumber': _vchNoController.text,
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
          .map((i) => {
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
              })
          .toList(),
      'sundries': _sundries
          .where((s) => s.amount.text != '' && s.amount.text != '0.00')
          .map((s) => {
                'name': s.name.text,
                'amount': s.amount.text,
                'isNegative': s.isNegative,
              })
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
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${widget.voucherType} saved successfully! Ready for next entry.',
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

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cancelFocusNode.requestFocus();
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('You have unsaved changes. Do you want to exit without saving?'),
          actions: [
            OutlinedButton(
              focusNode: cancelFocusNode,
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE4343)),
              child: const Text('Exit Without Saving', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    cancelFocusNode.dispose();
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

  Color _getVoucherHeaderColor() {
    final vch = widget.voucherType.toLowerCase();
    if (vch.contains('sale')) return const Color(0xFF0F62FE);
    if (vch.contains('purchase')) return const Color(0xFF7034E6);
    if (vch.contains('payment') || vch.contains('receipt')) return const Color(0xFF10A35B);
    return const Color(0xFF0D9488);
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    final headerColor = _getVoucherHeaderColor();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleVoucherKeyEvent,
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5FB),
          body: Column(
            children: [
              // TOP SUITE NAV BAR
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: headerColor,
                  border: const Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'NEW ${widget.voucherType.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'F.Y. $fy',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: headerColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isInterState ? const Color(0xFFFAF5FF) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isInterState ? Icons.alt_route_rounded : Icons.check_circle_outline_rounded,
                            size: 11,
                            color: _isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST+SGST)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildShortcutBadge(
                      KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.saveVoucherAction),
                      'Save',
                      isPrimary: true,
                    ),
                    const SizedBox(width: 6),
                    _buildShortcutBadge(
                      KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.goBackAction),
                      'Quit',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      onPressed: () async {
                        if (await _onWillPop()) {
                          widget.onClose();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // MAIN VOUCHER BODY
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 1. HEADER METADATA CARD
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

                      // 2. ITEMS TABLE
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

                      // 3. DUAL LOWER PANELS
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
                              onTabToSave: () => _saveButtonFocusNode.requestFocus(),
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
                              saveShortcutLabel: KeyboardShortcutService.labelForAction(
                                widget.keyboardSettings,
                                KeyboardShortcutService.saveVoucherAction,
                              ),
                              quitShortcutLabel: KeyboardShortcutService.labelForAction(
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

  KeyEventResult _handleVoucherKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (KeyboardShortcutService.matchesAction(
      widget.keyboardSettings,
      KeyboardShortcutService.goBackAction,
      event,
    )) {
      _onWillPop().then((shouldClose) {
        if (shouldClose) widget.onClose();
      });
      return KeyEventResult.handled;
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
  }

  Widget _buildShortcutBadge(String key, String desc, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isPrimary ? const Color(0xFF0F62FE) : Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPrimary ? const Color(0xFF0F62FE) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}