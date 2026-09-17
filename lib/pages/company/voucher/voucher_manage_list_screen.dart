import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import 'voucher_entry_screen.dart';

class VoucherManageListScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final VoidCallback onClose;

  const VoucherManageListScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onClose,
  });

  @override
  State<VoucherManageListScreen> createState() => _VoucherManageListScreenState();
}

class _VoucherManageListScreenState extends State<VoucherManageListScreen> {
  static const Map<String, String> _gstStateCodes = {
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra & Nagar Haveli and Daman & Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _headerScrollCtrl = ScrollController();
  final ScrollController _bodyHorizontalScrollCtrl = ScrollController();
  final ScrollController _bodyVerticalScrollCtrl = ScrollController();
  final ScrollController _footerScrollCtrl = ScrollController();

  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _selectedKeys = {};
  bool _isLoading = true;

  static const double _tableMinWidth = 1680.0;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);

    _bodyHorizontalScrollCtrl.addListener(() {
      if (_headerScrollCtrl.hasClients &&
          _headerScrollCtrl.offset != _bodyHorizontalScrollCtrl.offset) {
        _headerScrollCtrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
      }
      if (_footerScrollCtrl.hasClients &&
          _footerScrollCtrl.offset != _bodyHorizontalScrollCtrl.offset) {
        _footerScrollCtrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerScrollCtrl.dispose();
    _bodyHorizontalScrollCtrl.dispose();
    _bodyVerticalScrollCtrl.dispose();
    _footerScrollCtrl.dispose();
    super.dispose();
  }

  void _handleSafeExit() {
    widget.onClose();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _resolveVoucherKey(Map<String, dynamic> v, int index) {
    final id = v['id']?.toString().trim();
    if (id != null && id.isNotEmpty) return id;
    final vchNo = v['voucherNumber']?.toString().trim();
    if (vchNo != null && vchNo.isNotEmpty) return 'vch_$vchNo';
    return 'idx_$index';
  }

  Future<void> _loadVouchers() async {
    final folderPath = widget.company['folderPath']?.toString();
    final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

    if (folderPath != null) {
      final allVouchers = await StorageService.loadVouchers(
        folderPath: folderPath,
        financialYear: fy,
        voucherType: widget.voucherType,
      );

      final matching = allVouchers.where((v) {
        return (v['voucherType'] ?? '').toString().toLowerCase() ==
            widget.voucherType.toLowerCase();
      }).toList();

      if (mounted) {
        setState(() {
          _vouchers = matching;
          _filtered = matching;
          _selectedKeys.clear();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _vouchers;
      } else {
        _filtered = _vouchers.where((v) {
          final vchNo = (v['voucherNumber'] ?? '').toString().toLowerCase();
          final party = (v['party'] ?? '').toString().toLowerCase();
          final date = (v['date'] ?? '').toString().toLowerCase();
          final gstin = _extractPartyGstin((v['party'] ?? '').toString()).toLowerCase();
          final items = v['items'] as List? ?? [];
          final hasItemMatch = items.any((it) {
            final hsn = (it['hsn'] ?? '').toString().toLowerCase();
            final name = (it['item'] ?? '').toString().toLowerCase();
            return hsn.contains(q) || name.contains(q);
          });
          return vchNo.contains(q) || party.contains(q) || date.contains(q) || gstin.contains(q) || hasItemMatch;
        }).toList();
      }
    });
  }

  String _extractPartyName(String fullParty) {
    final bracketIndex = fullParty.indexOf('[');
    if (bracketIndex != -1) {
      return fullParty.substring(0, bracketIndex).trim();
    }
    return fullParty.trim();
  }

  String _extractPartyGstin(String fullParty) {
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(fullParty);
    if (match != null) {
      return match.group(1)!.trim();
    }
    if (fullParty.trim().length == 15) {
      return fullParty.trim();
    }
    return '';
  }

  String _getPlaceOfSupply(String gstin, bool isInterState) {
    if (gstin.length >= 2) {
      final code = gstin.substring(0, 2);
      final state = _gstStateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    final compGst = (widget.company['gstin'] ?? '').toString().trim();
    if (!isInterState && compGst.length >= 2) {
      final code = compGst.substring(0, 2);
      final state = _gstStateCodes[code] ?? 'State $code';
      return '$code-$state';
    }
    return isInterState ? 'Inter-State' : 'Local';
  }

  double _extractCessAmount(Map<String, dynamic> voucher) {
    final sundries = voucher['sundries'] as List? ?? [];
    double cessTotal = 0.0;
    for (final s in sundries) {
      if (s is Map<String, dynamic>) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        if (name.contains('cess')) {
          final amt = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
          cessTotal += amt;
        }
      }
    }
    return cessTotal;
  }

  double get _totalQuantity {
    return _filtered.fold(0.0, (acc, v) {
      final items = v['items'] as List? ?? [];
      final itemSum = items.fold(0.0, (sum, i) => sum + (double.tryParse(i['qty']?.toString() ?? '0') ?? 0.0));
      return acc + itemSum;
    });
  }

  double get _totalInvoiceValue {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['grandTotal']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalTaxable {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['subTotal']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalIgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalCgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalSgst {
    return _filtered.fold(0.0, (acc, item) {
      return acc + (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0);
    });
  }

  double get _totalCess {
    return _filtered.fold(0.0, (acc, item) => acc + _extractCessAmount(item));
  }

  void _editVoucher(Map<String, dynamic> voucher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoucherEntryScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          voucherToEdit: voucher,
          isEdit: true,
          keyboardSettings: KeyboardShortcutSettings.defaults(),
          onClose: () {
            Navigator.of(context).pop();
            _loadVouchers();
          },
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteVouchers(List<Map<String, dynamic>> vouchersToDelete) async {
    if (vouchersToDelete.isEmpty) return;

    final count = vouchersToDelete.length;
    final isPlural = count > 1;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Color(0xFFEE4343), size: 24),
            SizedBox(width: 8),
            Text('Confirm Deletion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          isPlural
              ? 'Are you sure you want to permanently delete $count selected vouchers? This operation cannot be reversed.'
              : 'Are you sure you want to delete Voucher [${vouchersToDelete.first['voucherNumber']}]?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE4343),
              foregroundColor: Colors.white,
            ),
            child: Text(isPlural ? 'Delete All ($count)' : 'Delete', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final keysToDelete = <String>{};
      for (int i = 0; i < vouchersToDelete.length; i++) {
        keysToDelete.add(_resolveVoucherKey(vouchersToDelete[i], i));
      }

      setState(() {
        _vouchers.removeWhere((v) => keysToDelete.contains(_resolveVoucherKey(v, _vouchers.indexOf(v))));
        _filtered.removeWhere((v) => keysToDelete.contains(_resolveVoucherKey(v, _filtered.indexOf(v))));
        _selectedKeys.removeAll(keysToDelete);
      });

      final folderPath = widget.company['folderPath']?.toString();
      final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();
      if (folderPath != null) {
        await StorageService.saveAllVouchers(
          folderPath: folderPath,
          financialYear: fy,
          voucherType: widget.voucherType,
          vouchers: _vouchers,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPlural ? '$count vouchers deleted.' : 'Voucher deleted successfully.'),
            backgroundColor: const Color(0xFFEE4343),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRowCell(
    String text, {
    required double width,
    TextAlign textAlign = TextAlign.left,
    bool isBold = false,
    bool isMuted = false,
    Color? color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? (isMuted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required double width,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooterCell(
    String text, {
    required double width,
    TextAlign textAlign = TextAlign.left,
    bool highlight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: highlight ? const Color(0xFF0F62FE) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = [for (int i = 0; i < _filtered.length; i++) _resolveVoucherKey(_filtered[i], i)];
    final bool allSelected = allKeys.isNotEmpty && allKeys.every((k) => _selectedKeys.contains(k));

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _handleSafeExit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF101C38)),
            onPressed: _handleSafeExit,
          ),
          title: Row(
            children: [
              Text(
                'Manage ${widget.voucherType} Register',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF101C38)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD6E3F4)),
                ),
                child: Text(
                  '${widget.company['activeFinancialYear'] ?? '2026-27'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE)),
                ),
              ),
            ],
          ),
          actions: [
            if (_selectedKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final toDelete = <Map<String, dynamic>>[];
                    for (int i = 0; i < _vouchers.length; i++) {
                      if (_selectedKeys.contains(_resolveVoucherKey(_vouchers[i], i))) {
                        toDelete.add(_vouchers[i]);
                      }
                    }
                    _confirmAndDeleteVouchers(toDelete);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Delete Selected (${_selectedKeys.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE4343),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search by Voucher No, Party Name, GSTIN, HSN, Date...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Color(0xFF0F62FE)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickMetric('Vouchers', '${_filtered.length}', const Color(0xFF101B3A)),
                  const SizedBox(width: 8),
                  _buildQuickMetric('Total Qty', _totalQuantity.toStringAsFixed(2), const Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  _buildQuickMetric('Taxable Val', '₹${_totalTaxable.toStringAsFixed(2)}', const Color(0xFF7034E6)),
                  const SizedBox(width: 8),
                  _buildQuickMetric('Invoice Total', '₹${_totalInvoiceValue.toStringAsFixed(2)}', const Color(0xFF0F62FE)),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04092B60), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dynamicWidth = math.max(constraints.maxWidth, _tableMinWidth);

                      return Column(
                        children: [
                          SingleChildScrollView(
                            controller: _headerScrollCtrl,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: dynamicWidth,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFD),
                                border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Checkbox(
                                        value: allSelected,
                                        activeColor: const Color(0xFF0F62FE),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              for (int i = 0; i < _filtered.length; i++) {
                                                _selectedKeys.add(_resolveVoucherKey(_filtered[i], i));
                                              }
                                            } else {
                                              _selectedKeys.clear();
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  _buildHeaderCell('S.No.', width: 45),
                                  _buildHeaderCell('Party', width: 180),
                                  _buildHeaderCell('GSTIN', width: 135),
                                  _buildHeaderCell('Place of Supply', width: 140),
                                  _buildHeaderCell('Voc. No.', width: 95),
                                  _buildHeaderCell('Voc. Date', width: 90),
                                  _buildHeaderCell('Qty.', width: 70, textAlign: TextAlign.right),
                                  _buildHeaderCell('Unit', width: 55, textAlign: TextAlign.center),
                                  _buildHeaderCell('HSN', width: 80),
                                  _buildHeaderCell('Invoice Value', width: 115, textAlign: TextAlign.right),
                                  _buildHeaderCell('Taxable', width: 105, textAlign: TextAlign.right),
                                  _buildHeaderCell('Rate', width: 60, textAlign: TextAlign.right),
                                  _buildHeaderCell('IGST', width: 85, textAlign: TextAlign.right),
                                  _buildHeaderCell('CGST', width: 85, textAlign: TextAlign.right),
                                  _buildHeaderCell('SGST', width: 85, textAlign: TextAlign.right),
                                  _buildHeaderCell('Cess', width: 75, textAlign: TextAlign.right),
                                  _buildHeaderCell('Actions', width: 90, textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F62FE)))
                                : _filtered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No matching vouchers found.',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                        ),
                                      )
                                    : Scrollbar(
                                        controller: _bodyHorizontalScrollCtrl,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        notificationPredicate: (notif) => notif.depth == 1,
                                        child: SingleChildScrollView(
                                          controller: _bodyHorizontalScrollCtrl,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: dynamicWidth,
                                            child: Scrollbar(
                                              controller: _bodyVerticalScrollCtrl,
                                              thumbVisibility: true,
                                              trackVisibility: true,
                                              notificationPredicate: (notif) => notif.depth == 0,
                                              child: ListView.separated(
                                                controller: _bodyVerticalScrollCtrl,
                                                itemCount: _filtered.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                                                itemBuilder: (context, idx) {
                                                  final v = _filtered[idx];
                                                  final key = _resolveVoucherKey(v, idx);
                                                  final isSelected = _selectedKeys.contains(key);
                                                  final vchNo = v['voucherNumber'] ?? '';
                                                  final date = v['date'] ?? '';
                                                  final fullParty = (v['party'] ?? '').toString();
                                                  final partyName = _extractPartyName(fullParty);
                                                  final gstin = _extractPartyGstin(fullParty);
                                                  final isInterState = v['isInterState'] == true;
                                                  final pos = _getPlaceOfSupply(gstin, isInterState);
                                                  final invoiceTotal = double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;
                                                  final cessTotal = _extractCessAmount(v);
                                                  final items = v['items'] as List? ?? [];

                                                  return Container(
                                                    color: isSelected ? const Color(0xFFEFF6FE) : Colors.white,
                                                    child: items.isEmpty
                                                        ? Row(
                                                            children: [
                                                              SizedBox(
                                                                width: 40,
                                                                child: Center(
                                                                  child: Checkbox(
                                                                    value: isSelected,
                                                                    activeColor: const Color(0xFF0F62FE),
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
                                                              _buildRowCell('${idx + 1}', width: 45, isMuted: true),
                                                              _buildRowCell(partyName, width: 180, isBold: true),
                                                              _buildRowCell(gstin, width: 135, color: const Color(0xFF15803D)),
                                                              _buildRowCell(pos, width: 140),
                                                              _buildRowCell(vchNo.toString(), width: 95, color: const Color(0xFF0F62FE), isBold: true),
                                                              _buildRowCell(date.toString(), width: 90),
                                                              _buildRowCell('0.00', width: 70, textAlign: TextAlign.right),
                                                              _buildRowCell('Pcs', width: 55, textAlign: TextAlign.center, isMuted: true),
                                                              _buildRowCell('', width: 80),
                                                              _buildRowCell(invoiceTotal.toStringAsFixed(2), width: 115, textAlign: TextAlign.right, isBold: true),
                                                              _buildRowCell('0.00', width: 105, textAlign: TextAlign.right),
                                                              _buildRowCell('0%', width: 60, textAlign: TextAlign.right, isMuted: true),
                                                              _buildRowCell((double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                              _buildRowCell((double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                              _buildRowCell((double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                              _buildRowCell(cessTotal.toStringAsFixed(2), width: 75, textAlign: TextAlign.right),
                                                              _buildActionButtons(v, width: 90),
                                                            ],
                                                          )
                                                        : Column(
                                                            children: List.generate(items.length, (itemIdx) {
                                                              final item = items[itemIdx];
                                                              final qty = (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                              final unit = item['unit'] ?? 'Pcs';
                                                              final hsn = (item['hsn'] ?? '').toString();
                                                              final taxable = (double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                              final taxRate = '${item['gstRate'] ?? 0}%';
                                                              final igstVal = (double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                              final cgstVal = (double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                                              final sgstVal = (double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);

                                                              return Container(
                                                                color: itemIdx > 0 ? const Color(0xFFFAFBFD) : Colors.transparent,
                                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 40,
                                                                      child: itemIdx == 0
                                                                          ? Center(
                                                                              child: Checkbox(
                                                                                value: isSelected,
                                                                                activeColor: const Color(0xFF0F62FE),
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
                                                                            )
                                                                          : null,
                                                                    ),
                                                                    _buildRowCell(itemIdx == 0 ? '${idx + 1}' : '', width: 45, isMuted: true),
                                                                    _buildRowCell(itemIdx == 0 ? partyName : '', width: 180, isBold: true),
                                                                    _buildRowCell(itemIdx == 0 ? gstin : '', width: 135, color: const Color(0xFF15803D)),
                                                                    _buildRowCell(itemIdx == 0 ? pos : '', width: 140),
                                                                    _buildRowCell(itemIdx == 0 ? vchNo.toString() : '', width: 95, color: const Color(0xFF0F62FE), isBold: true),
                                                                    _buildRowCell(itemIdx == 0 ? date.toString() : '', width: 90),
                                                                    _buildRowCell(qty, width: 70, textAlign: TextAlign.right),
                                                                    _buildRowCell(unit.toString(), width: 55, textAlign: TextAlign.center, isMuted: true),
                                                                    _buildRowCell(hsn, width: 80),
                                                                    _buildRowCell(itemIdx == 0 ? invoiceTotal.toStringAsFixed(2) : '', width: 115, textAlign: TextAlign.right, isBold: true),
                                                                    _buildRowCell(taxable, width: 105, textAlign: TextAlign.right),
                                                                    _buildRowCell(taxRate, width: 60, textAlign: TextAlign.right, isMuted: true),
                                                                    _buildRowCell(igstVal, width: 85, textAlign: TextAlign.right),
                                                                    _buildRowCell(cgstVal, width: 85, textAlign: TextAlign.right),
                                                                    _buildRowCell(sgstVal, width: 85, textAlign: TextAlign.right),
                                                                    _buildRowCell(itemIdx == 0 ? cessTotal.toStringAsFixed(2) : '', width: 75, textAlign: TextAlign.right),
                                                                    itemIdx == 0
                                                                        ? _buildActionButtons(v, width: 90)
                                                                        : const SizedBox(width: 90),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
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
                            controller: _footerScrollCtrl,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: dynamicWidth,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5FB),
                                border: Border(top: BorderSide(color: Color(0xFFD6E3F4), width: 1.2)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 40),
                                  _buildFooterCell('', width: 45),
                                  _buildFooterCell('TOTAL', width: 180, highlight: true),
                                  _buildFooterCell('', width: 135),
                                  _buildFooterCell('', width: 140),
                                  _buildFooterCell('', width: 95),
                                  _buildFooterCell('', width: 90),
                                  _buildFooterCell(_totalQuantity.toStringAsFixed(2), width: 70, textAlign: TextAlign.right),
                                  _buildFooterCell('', width: 55),
                                  _buildFooterCell('', width: 80),
                                  _buildFooterCell(_totalInvoiceValue.toStringAsFixed(2), width: 115, textAlign: TextAlign.right, highlight: true),
                                  _buildFooterCell(_totalTaxable.toStringAsFixed(2), width: 105, textAlign: TextAlign.right),
                                  _buildFooterCell('', width: 60),
                                  _buildFooterCell(_totalIgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                  _buildFooterCell(_totalCgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                  _buildFooterCell(_totalSgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                  _buildFooterCell(_totalCess.toStringAsFixed(2), width: 75, textAlign: TextAlign.right),
                                  const SizedBox(width: 90),
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

  Widget _buildActionButtons(Map<String, dynamic> v, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF0F62FE)),
            onPressed: () => _editVoucher(v),
            tooltip: 'Edit Voucher',
            splashRadius: 18,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEE4343)),
            onPressed: () => _confirmAndDeleteVouchers([v]),
            tooltip: 'Delete Voucher',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}