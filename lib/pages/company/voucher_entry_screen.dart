import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';

class VoucherEntryScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final VoidCallback onClose;

  const VoucherEntryScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onClose,
  });

  @override
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _ItemRow {
  final TextEditingController item = TextEditingController();
  final FocusNode itemFocus = FocusNode();
  final TextEditingController qty = TextEditingController(text: '1.00');
  final TextEditingController unit = TextEditingController(text: 'PCS');
  final TextEditingController price = TextEditingController(text: '0.00');
  double amount = 0.0;

  void dispose() {
    item.dispose();
    itemFocus.dispose();
    qty.dispose();
    unit.dispose();
    price.dispose();
  }
}

class _SundryRow {
  final TextEditingController name = TextEditingController();
  final FocusNode nameFocus = FocusNode();
  final TextEditingController amount = TextEditingController(text: '0.00');
  bool isNegative = false;

  void dispose() {
    name.dispose();
    nameFocus.dispose();
    amount.dispose();
  }
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  final TextEditingController _seriesController =
      TextEditingController(text: 'Main');
  final FocusNode _seriesFocus = FocusNode();

  final TextEditingController _dateController = TextEditingController();
  final FocusNode _dateFocusNode = FocusNode();
  String? _dateError;

  final TextEditingController _vchNoController = TextEditingController();
  final TextEditingController _saleTypeController =
      TextEditingController(text: 'GST 18% (Item Wise)');
  final FocusNode _saleTypeFocus = FocusNode();

  final TextEditingController _partyController =
      TextEditingController(text: 'Cash in Hand');
  final FocusNode _partyFocus = FocusNode();

  final TextEditingController _matCenterController =
      TextEditingController(text: 'Main Store');
  final FocusNode _matCenterFocus = FocusNode();

  final TextEditingController _narrationController = TextEditingController();

  final List<_ItemRow> _items = [];
  final List<_SundryRow> _sundries = [];

  double _itemSubTotal = 0.0;
  double _cgst = 0.0;
  double _sgst = 0.0;
  double _totalTax = 0.0;
  double _sundryTotal = 0.0;
  double _roundOff = 0.0;
  double _grandTotal = 0.0;

  bool _autoRoundOff = true;

  DateTime _fyStartDate = DateTime(2026, 4, 1);
  DateTime _fyEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';
    _vchNoController.text = '1/$fy';
    _parseFinancialYearBounds(fy);

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

    for (int i = 0; i < 5; i++) {
      _addItemRow();
    }

    _addDefaultSundryRows();
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
      setState(() =>
          _dateError = 'Date must fall within F.Y. ($startFmt to $endFmt)');
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
    final discount = _SundryRow()
      ..name.text = 'Discount (-)'
      ..isNegative = true;
    discount.amount.addListener(_calculateAllTotals);

    final freight = _SundryRow()..name.text = 'Freight / Transport (+)';
    freight.amount.addListener(_calculateAllTotals);

    _sundries.add(discount);
    _sundries.add(freight);
  }

  void _addItemRow() {
    final row = _ItemRow();
    row.qty.addListener(_calculateAllTotals);
    row.price.addListener(_calculateAllTotals);
    _items.add(row);
  }

  // Alias provided to resolve lingering listener callbacks from 
  void _calculateAllTotals() {
    double itemSum = 0.0;
    for (final row in _items) {
      final q = double.tryParse(row.qty.text) ?? 0.0;
      final p = double.tryParse(row.price.text) ?? 0.0;
      row.amount = q * p;
      itemSum += row.amount;
    }

    const defaultTaxRate = 18.0;
    final taxSum = (itemSum * defaultTaxRate) / 100;

    double sundrySum = 0.0;
    for (final s in _sundries) {
      final amt = double.tryParse(s.amount.text) ?? 0.0;
      if (s.isNegative) {
        sundrySum -= amt.abs();
      } else {
        sundrySum += amt.abs();
      }
    }

    final preFinal = itemSum + taxSum + sundrySum;
    double rOff = 0.0;
    double gTotal = preFinal;

    if (_autoRoundOff) {
      gTotal = preFinal.roundToDouble();
      rOff = gTotal - preFinal;
    }

    setState(() {
      _itemSubTotal = itemSum;
      _cgst = taxSum / 2;
      _sgst = taxSum / 2;
      _totalTax = taxSum;
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
            const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF0F62FE), size: 22),
            const SizedBox(width: 8),
            Text('Add $masterType',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                backgroundColor: const Color(0xFF0F62FE)),
            child: const Text('Save Master',
                style: TextStyle(color: Colors.white)),
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
      'cgst': _cgst,
      'sgst': _sgst,
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
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
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

  @override
  void dispose() {
    _seriesController.dispose();
    _seriesFocus.dispose();
    _dateController.dispose();
    _dateFocusNode.dispose();
    _vchNoController.dispose();
    _saleTypeController.dispose();
    _saleTypeFocus.dispose();
    _partyController.dispose();
    _partyFocus.dispose();
    _matCenterController.dispose();
    _matCenterFocus.dispose();
    _narrationController.dispose();

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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.f2): _saveVoucher,
      },
      child: Focus(
        autofocus: true,
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
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 16, color: Colors.white),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5FB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD6E3F4)),
                      ),
                      child: Text(
                        'F.Y. $fy',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101C38),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildShortcutBadge('F2', 'Save Voucher', isPrimary: true),
                    const SizedBox(width: 8),
                    _buildShortcutBadge('Esc', 'Close Entry'),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Color(0xFF6B7B9B)),
                      onPressed: widget.onClose,
                      style: IconButton.styleFrom(
                          hoverColor: const Color(0xFFFFECEC)),
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
                      // VOUCHER HEADER FIELDS
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFFE2EAF5), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x04092B60),
                                blurRadius: 10,
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldWithFocus(
                                  label: 'Series',
                                  controller: _seriesController,
                                  focusNode: _seriesFocus,
                                  width: 130,
                                  icon: Icons.tag_rounded,
                                  masterType: 'Series',
                                ),
                                const SizedBox(width: 14),
                                _buildDateInput(
                                  label: 'Voucher Date',
                                  controller: _dateController,
                                  focusNode: _dateFocusNode,
                                  width: 170,
                                ),
                                const SizedBox(width: 14),
                                _buildPlainField(
                                  label: 'Voucher Number',
                                  controller: _vchNoController,
                                  width: 170,
                                  icon: Icons.confirmation_number_outlined,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildFieldWithFocus(
                                    label: 'Taxation / Sale Type',
                                    controller: _saleTypeController,
                                    focusNode: _saleTypeFocus,
                                    icon: Icons.account_tree_outlined,
                                    masterType: 'Sale Type',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildFieldWithFocus(
                                    label: 'Party / Account Ledger',
                                    controller: _partyController,
                                    focusNode: _partyFocus,
                                    icon: Icons.person_outline_rounded,
                                    masterType: 'Account Ledger',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: _buildFieldWithFocus(
                                    label: 'Material Centre',
                                    controller: _matCenterController,
                                    focusNode: _matCenterFocus,
                                    icon: Icons.storefront_outlined,
                                    masterType: 'Material Centre',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildPlainField(
                              label: 'Narration / Remarks',
                              controller: _narrationController,
                              icon: Icons.notes_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ITEM TABLE
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFFE2EAF5), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x04092B60),
                                blurRadius: 10,
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFD),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(18)),
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFE2EAF5), width: 1.2)),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Text('S.N.',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Text('Item Name & Description',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Qty',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Unit',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Price (₹)',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Amount (₹)',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF6B7B9B))),
                                  ),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFF1F5FB)),
                              itemBuilder: (context, index) {
                                final row = _items[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF90A1BA),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: _buildGridInputWithFocus(
                                          controller: row.item,
                                          focusNode: row.itemFocus,
                                          hint: 'Type or select item...',
                                          masterType: 'Item',
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: _buildSimpleGridInput(
                                          controller: row.qty,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 1,
                                        child: _buildSimpleGridInput(
                                          controller: row.unit,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: _buildSimpleGridInput(
                                          controller: row.price,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          row.amount.toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF101B3A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAFBFD),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(18)),
                                border: Border(
                                    top: BorderSide(color: Color(0xFFF1F5FB))),
                              ),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => setState(_addItemRow),
                                    icon: const Icon(Icons.add_rounded,
                                        size: 16, color: Color(0xFF0F62FE)),
                                    label: const Text(
                                      'Add Item Row',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F62FE)),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Subtotal Items:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7B9B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${_itemSubTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF101B3A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // DUAL LOWER PANELS: BILL SUNDRY & TAX SUMMARY
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. BILL SUNDRY & EXPENSES TABLE
                          Expanded(
                            flex: 55,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFE2EAF5), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x04092B60),
                                      blurRadius: 10,
                                      offset: Offset(0, 3)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.tune_rounded,
                                              size: 18,
                                              color: Color(0xFF0F62FE)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Bill Sundry & Expenses',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF101B3A)),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            final row = _SundryRow();
                                            row.amount.addListener(
                                                _calculateAllTotals);
                                            _sundries.add(row);
                                          });
                                        },
                                        icon: const Icon(Icons.add, size: 15),
                                        label: const Text('Add Sundry',
                                            style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _sundries.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final s = _sundries[idx];
                                      return Row(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: _buildGridInputWithFocus(
                                              controller: s.name,
                                              focusNode: s.nameFocus,
                                              hint: 'Sundry name (Freight/Dis.)',
                                              masterType: 'Bill Sundry',
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                s.isNegative = !s.isNegative;
                                                _calculateAllTotals();
                                              });
                                            },
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: s.isNegative
                                                    ? const Color(0xFFFFECEC)
                                                    : const Color(0xFFE5F8EE),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                s.isNegative
                                                    ? '(-) Sub'
                                                    : '(+) Add',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: s.isNegative
                                                      ? const Color(0xFFEE4343)
                                                      : const Color(0xFF10A35B),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 3,
                                            child: _buildSimpleGridInput(
                                              controller: s.amount,
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFD),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFE4EDF7)),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _autoRoundOff,
                                          activeColor: const Color(0xFF0F62FE),
                                          onChanged: (val) {
                                            setState(() {
                                              _autoRoundOff = val ?? true;
                                              _calculateAllTotals();
                                            });
                                          },
                                        ),
                                        const Text(
                                          'Auto Round-off Grand Total',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155)),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${_roundOff >= 0 ? '+' : ''}${_roundOff.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _roundOff == 0
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF0F62FE),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          // 2. SUMMARY CARD
                          Expanded(
                            flex: 45,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFE2EAF5), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x04092B60),
                                      blurRadius: 10,
                                      offset: Offset(0, 3)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.pie_chart_outline_rounded,
                                          size: 18, color: Color(0xFF10A35B)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Taxation & Summary',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF101B3A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildModernSummaryRow('Taxable Amount',
                                      '₹${_itemSubTotal.toStringAsFixed(2)}'),
                                  const SizedBox(height: 6),
                                  _buildModernSummaryRow('CGST Output (9.0%)',
                                      '₹${_cgst.toStringAsFixed(2)}'),
                                  const SizedBox(height: 6),
                                  _buildModernSummaryRow('SGST Output (9.0%)',
                                      '₹${_sgst.toStringAsFixed(2)}'),
                                  const SizedBox(height: 6),
                                  _buildModernSummaryRow('Bill Sundries / Other',
                                      '${_sundryTotal >= 0 ? '+' : ''}₹${_sundryTotal.toStringAsFixed(2)}'),
                                  const SizedBox(height: 6),
                                  _buildModernSummaryRow('Rounding Off',
                                      '${_roundOff >= 0 ? '+' : ''}₹${_roundOff.toStringAsFixed(2)}'),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(
                                        color: Color(0xFFE8EEF7), height: 1),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF1F6FE),
                                            Color(0xFFE9F2FE)
                                          ]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Grand Total',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF0F62FE))),
                                        Text('₹${_grandTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF0F62FE))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: widget.onClose,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 13),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Quit (Esc)'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: _saveVoucher,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0F62FE),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 13),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.check_rounded,
                                            size: 18),
                                        label: const Text('Save (F2)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildShortcutBadge(String key, String desc,
      {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEBF3FE) : const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isPrimary
                ? const Color(0xFFBCD8FD)
                : const Color(0xFFE2EAF5)),
      ),
      child: Row(
        children: [
          Text(key,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isPrimary
                      ? const Color(0xFF0F62FE)
                      : const Color(0xFF334155))),
          const SizedBox(width: 6),
          Text(desc,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? const Color(0xFF0F62FE)
                      : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    double? width,
  }) {
    final field = SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => _parseAndValidateDate(),
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7B9B)),
          prefixIcon: const Icon(Icons.calendar_today_rounded,
              size: 16, color: Color(0xFF0F62FE)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: _dateError != null
                    ? const Color(0xFFEE4343)
                    : const Color(0xFFE2EAF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: _dateError != null
                    ? const Color(0xFFEE4343)
                    : const Color(0xFF0F62FE),
                width: 1.3),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (width != null) SizedBox(width: width, child: field) else field,
        if (_dateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: SizedBox(
              width: width ?? 200,
              child: Text(
                _dateError!,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEE4343)),
                maxLines: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlainField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    double? width,
  }) {
    final field = SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7B9B)),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF0F62FE)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF0F62FE), width: 1.3),
          ),
        ),
      ),
    );

    if (width != null) return SizedBox(width: width, child: field);
    return field;
  }

  Widget _buildFieldWithFocus({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String masterType,
    double? width,
  }) {
    Widget buildField() {
      return ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final isFocused = focusNode.hasFocus;
          return SizedBox(
            height: 42,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101B3A)),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7B9B)),
                    prefixIcon:
                        Icon(icon, size: 16, color: const Color(0xFF0F62FE)),
                    contentPadding: EdgeInsets.only(
                        left: 12,
                        right: isFocused ? 32 : 12,
                        top: 0,
                        bottom: 0),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF0F62FE), width: 1.3),
                    ),
                  ),
                ),
                if (isFocused)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: InkWell(
                      onTap: () => _openQuickAddDialog(masterType),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F62FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:
                            const Icon(Icons.add, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    if (width != null) return SizedBox(width: width, child: buildField());
    return buildField();
  }

  Widget _buildGridInputWithFocus({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String masterType,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return SizedBox(
          height: 38,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101B3A)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF90A1BA),
                      fontWeight: FontWeight.w400),
                  contentPadding: EdgeInsets.only(
                      left: 10,
                      right: isFocused ? 28 : 10,
                      top: 8,
                      bottom: 8),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFD),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF0F62FE), width: 1.2)),
                ),
              ),
              if (isFocused)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: InkWell(
                    onTap: () => _openQuickAddDialog(masterType),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F62FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          const Icon(Icons.add, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleGridInput({
    required TextEditingController controller,
    TextAlign textAlign = TextAlign.left,
  }) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFFAFBFD),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF0F62FE), width: 1.2)),
        ),
      ),
    );
  }

  Widget _buildModernSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101B38),
          ),
        ),
      ],
    );
  }
}