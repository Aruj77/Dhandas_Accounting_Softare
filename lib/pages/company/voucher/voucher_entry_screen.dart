import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/voucher/voucher_item_row.dart';
import '../../../widgets/voucher/voucher_sundry_row.dart';
import '../../../widgets/voucher/voucher_header_card.dart';
import '../../../widgets/voucher/voucher_items_table.dart';
import '../../../widgets/voucher/voucher_sundry_card.dart';
import '../../../widgets/voucher/voucher_summary_card.dart';

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

  final TextEditingController _partyController =
      TextEditingController(text: 'Cash in Hand');
  final FocusNode _partyFocus = FocusNode();

  final TextEditingController _partyGstinController = TextEditingController();
  final FocusNode _partyGstinFocus = FocusNode();

  final TextEditingController _matCenterController =
      TextEditingController(text: 'Main Store');
  final FocusNode _matCenterFocus = FocusNode();

  final TextEditingController _narrationController = TextEditingController();
  final FocusNode _narrationFocus = FocusNode();

  final FocusNode _saveButtonFocusNode = FocusNode();

  final List<VoucherItemRow> _items = [];
  final List<VoucherSundryRow> _sundries = [];

  double _itemSubTotal = 0.0;
  double _totalCgst = 0.0;
  double _totalSgst = 0.0;
  double _totalIgst = 0.0;
  double _totalTax = 0.0;
  double _sundryTotal = 0.0;
  double _roundOff = 0.0;
  double _grandTotal = 0.0;

  bool _isInterState = false;
  bool _autoRoundOff = true;
  final double _defaultGstRate = 18.0;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    _vchNoController.text = '1/$fy';
    _parseFinancialYearBounds(fy);

    final companyGstin = widget.company['gstin']?.toString().trim() ?? '';
    _partyGstinController.text = companyGstin;
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

    _partyGstinController.addListener(() {
      _checkGstMode();
      for (final row in _items) {
        _recalculateTaxesFromTaxable(row);
      }
      _calculateAllTotals();
    });

    for (int i = 0; i < 5; i++) {
      _addItemRow();
    }

    _addDefaultSundryRows();
  }

  void _checkGstMode() {
    final companyGst = (widget.company['gstin'] ?? '').toString().trim();
    final partyGst = _partyGstinController.text.trim();

    if (companyGst.length >= 2 && partyGst.length >= 2) {
      final compState = companyGst.substring(0, 2);
      final partyState = partyGst.substring(0, 2);
      _isInterState = compState != partyState;
    } else {
      _isInterState = false;
    }
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
      setState(() => _dateError = 'Invalid day or month format');
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
        setState(() => _dateError = 'Invalid calendar date');
        return false;
      }
    } catch (_) {
      setState(() => _dateError = 'Invalid date');
      return false;
    }

    if (parsedDate.isBefore(_fyStartDate) || parsedDate.isAfter(_fyEndDate)) {
      final startFmt =
          '${_fyStartDate.day.toString().padLeft(2, '0')}-${_fyStartDate.month.toString().padLeft(2, '0')}-${_fyStartDate.year}';
      final endFmt =
          '${_fyEndDate.day.toString().padLeft(2, '0')}-${_fyEndDate.month.toString().padLeft(2, '0')}-${_fyEndDate.year}';
      setState(() => _dateError = 'Date must fall within F.Y. ($startFmt to $endFmt)');
      return false;
    }

    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    final yyyy = year.toString().padLeft(4, '0');

    _dateController.text = '$dd-$mm-$yyyy';
    setState(() => _dateError = null);
    return true;
  }

  void _addDefaultSundryRows() {
    final discount = VoucherSundryRow()
      ..name.text = 'Discount (-)'
      ..isNegative = true;
    discount.amount.addListener(_calculateAllTotals);

    final freight = VoucherSundryRow()..name.text = 'Freight / Transport (+)';
    freight.amount.addListener(_calculateAllTotals);

    _sundries.add(discount);
    _sundries.add(freight);
  }

  void _addItemRow() {
    final row = VoucherItemRow();

    row.qty.addListener(() {
      _recalculateTaxableAndTaxes(row);
      _calculateAllTotals();
    });

    row.price.addListener(() {
      _recalculateTaxableAndTaxes(row);
      _calculateAllTotals();
    });

    row.taxable.addListener(() {
      if (row.taxableFocus.hasFocus) {
        _recalculateTaxesFromTaxable(row);
        _calculateAllTotals();
      }
    });

    row.cgst.addListener(() {
      if (row.cgstFocus.hasFocus) {
        row.sgst.text = row.cgst.text;
        _calculateAllTotals();
      }
    });

    row.sgst.addListener(() {
      if (row.sgstFocus.hasFocus) {
        _calculateAllTotals();
      }
    });

    row.igst.addListener(() {
      if (row.igstFocus.hasFocus) {
        _calculateAllTotals();
      }
    });

    _items.add(row);
  }

  void _recalculateTaxableAndTaxes(VoucherItemRow row) {
    final q = double.tryParse(row.qty.text) ?? 0.0;
    final p = double.tryParse(row.price.text) ?? 0.0;
    final taxVal = q * p;
    row.taxable.text = taxVal.toStringAsFixed(2);
    _recalculateTaxesFromTaxable(row);
  }

  void _recalculateTaxesFromTaxable(VoucherItemRow row) {
    final taxVal = double.tryParse(row.taxable.text) ?? 0.0;
    if (_isInterState) {
      final igstVal = (taxVal * _defaultGstRate) / 100;
      row.igst.text = igstVal.toStringAsFixed(2);
      row.cgst.text = '0.00';
      row.sgst.text = '0.00';
    } else {
      final halfRate = _defaultGstRate / 2;
      final cVal = (taxVal * halfRate) / 100;
      row.cgst.text = cVal.toStringAsFixed(2);
      row.sgst.text = cVal.toStringAsFixed(2);
      row.igst.text = '0.00';
    }
  }

  void _calculateAllTotals() {
    double totalTaxable = 0.0;
    double cgstAccum = 0.0;
    double sgstAccum = 0.0;
    double igstAccum = 0.0;

    for (final row in _items) {
      final t = double.tryParse(row.taxable.text) ?? 0.0;
      final c = double.tryParse(row.cgst.text) ?? 0.0;
      final s = double.tryParse(row.sgst.text) ?? 0.0;
      final i = double.tryParse(row.igst.text) ?? 0.0;

      row.amount = t + (_isInterState ? i : (c + s));
      totalTaxable += t;

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
      if (s.isNegative) {
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
      _itemSubTotal = totalTaxable;
      _totalCgst = cgstAccum;
      _totalSgst = sgstAccum;
      _totalIgst = igstAccum;
      _totalTax = totalTaxCalculated;
      _sundryTotal = sundrySum;
      _roundOff = rOff;
      _grandTotal = gTotal;
    });
  }

  void _openQuickAddDialog(String masterType) {
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
      'partyGstin': _partyGstinController.text,
      'isInterState': _isInterState,
      'materialCenter': _matCenterController.text,
      'narration': _narrationController.text,
      'financialYear': widget.company['activeFinancialYear'],
      'items': _items
          .where((i) => i.item.text.isNotEmpty)
          .map((i) => {
                'item': i.item.text,
                'qty': i.qty.text,
                'unit': i.unit.text,
                'price': i.price.text,
                'taxable': i.taxable.text,
                'cgst': i.cgst.text,
                'sgst': i.sgst.text,
                'igst': i.igst.text,
                'amount': i.amount,
              })
          .toList(),
      'sundries': _sundries
          .where((s) => s.name.text.isNotEmpty)
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
                  '${widget.voucherType} #${_vchNoController.text} saved successfully for F.Y. $fy',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10A35B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onClose();
      }
    }
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
    _partyGstinController.dispose();
    _partyGstinFocus.dispose();
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

    return Focus(
      autofocus: true,
      onKeyEvent: _handleVoucherKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FB),
        body: Column(
          children: [
            // TOP SUITE NAV BAR
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'NEW ${widget.voucherType.toUpperCase()}',
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
                      'F.Y. $fy',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF101C38)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // GST TAX MODEL BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isInterState ? const Color(0xFFFAF5FF) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isInterState ? const Color(0xFFE9D5FF) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isInterState ? Icons.alt_route_rounded : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: _isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isInterState ? 'Inter-State Supply (IGST)' : 'Intra-State Supply (CGST + SGST)',
                          style: TextStyle(
                            fontSize: 11,
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
                    'Save Voucher',
                    isPrimary: true,
                  ),
                  const SizedBox(width: 8),
                  _buildShortcutBadge(
                    KeyboardShortcutService.labelForAction(widget.keyboardSettings, KeyboardShortcutService.goBackAction),
                    'Close Entry',
                  ),
                  const SizedBox(width: 8),
                  _buildShortcutBadge('Tab', 'Next Block'),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7B9B)),
                    onPressed: widget.onClose,
                    style: IconButton.styleFrom(hoverColor: const Color(0xFFFFECEC)),
                  ),
                ],
              ),
            ),

            // MAIN VOUCHER BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      partyGstinController: _partyGstinController,
                      partyGstinFocus: _partyGstinFocus,
                      matCenterController: _matCenterController,
                      matCenterFocus: _matCenterFocus,
                      narrationController: _narrationController,
                      narrationFocus: _narrationFocus,
                      onValidateDate: () => _parseAndValidateDate(),
                      onQuickAdd: _openQuickAddDialog,
                      onNarrationSubmitted: _focusFirstItemRow,
                    ),

                    const SizedBox(height: 18),

                    // 2. ITEMS TABLE
                    VoucherItemsTable(
                      items: _items,
                      isInterState: _isInterState,
                      subTotal: _itemSubTotal,
                      totalTax: _totalTax,
                      onAddRow: () => setState(_addItemRow),
                      onRowEnter: _handleItemRowEnter,
                      onQuickAdd: _openQuickAddDialog,
                      onTabToSundry: _focusFirstSundryRow,
                    ),

                    const SizedBox(height: 18),

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
                                final row = VoucherSundryRow();
                                row.amount.addListener(_calculateAllTotals);
                                _sundries.add(row);
                              });
                            },
                            onToggleRoundOff: () {
                              setState(() {
                                _autoRoundOff = !_autoRoundOff;
                                _calculateAllTotals();
                              });
                            },
                            onToggleNegative: (idx) {
                              setState(() {
                                _sundries[idx].isNegative = !_sundries[idx].isNegative;
                                _calculateAllTotals();
                              });
                            },
                            onRowEnter: _handleSundryRowEnter,
                            onQuickAdd: _openQuickAddDialog,
                            onTabToSave: () => _saveButtonFocusNode.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 18),
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
                            onClose: widget.onClose,
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
    );
  }

  KeyEventResult _handleVoucherKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (KeyboardShortcutService.matchesAction(
      widget.keyboardSettings,
      KeyboardShortcutService.goBackAction,
      event,
    )) {
      widget.onClose();
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEBF3FE) : const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary ? const Color(0xFFBCD8FD) : const Color(0xFFE2EAF5),
        ),
      ),
      child: Row(
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isPrimary ? const Color(0xFF0F62FE) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPrimary ? const Color(0xFF0F62FE) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}