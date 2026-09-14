import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';

class VoucherListScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onClose;

  const VoucherListScreen({
    super.key,
    required this.company,
    required this.voucherType,
    required this.fromDate,
    required this.toDate,
    required this.onClose,
  });

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseVchDate(String? raw) {
    if (raw == null) return null;
    final sanitized = raw.trim().replaceAll('/', '-').replaceAll('.', '-');
    final parts = sanitized.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _loadVouchers() async {
    final folderPath = widget.company['folderPath']?.toString();
    final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

    if (folderPath != null) {
      final allVouchers = await StorageService.loadVouchers(
        folderPath: folderPath,
        financialYear: fy,
      );

      final matching = allVouchers.where((v) {
        final type = (v['voucherType'] ?? '').toString().toLowerCase();
        if (type != widget.voucherType.toLowerCase()) return false;

        final dt = _parseVchDate(v['date']?.toString());
        if (dt == null) return true;

        final afterStart = dt.isAfter(widget.fromDate.subtract(const Duration(seconds: 1)));
        final beforeEnd = dt.isBefore(widget.toDate.add(const Duration(days: 1)));
        return afterStart && beforeEnd;
      }).toList();

      if (mounted) {
        setState(() {
          _vouchers = matching;
          _filtered = matching;
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
          return vchNo.contains(q) || party.contains(q) || date.contains(q);
        }).toList();
      }
    });
  }

  double get _totalAmount {
    return _filtered.fold(0.0, (acc, item) {
      final g = double.tryParse(item['grandTotal']?.toString() ?? '0') ?? 0.0;
      return acc + g;
    });
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final fy = widget.company['activeFinancialYear'] ?? '2026-27';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: Column(
        children: [
          // TOP BAR
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.voucherType.toUpperCase()} REGISTER',
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
                    'F.Y. $fy (${_formatDate(widget.fromDate)} to ${_formatDate(widget.toDate)})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101C38),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7B9B)),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(hoverColor: const Color(0xFFFFECEC)),
                ),
              ],
            ),
          ),

          // FILTER BAR & SUMMARY
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search by Voucher No, Party Name, or Date...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0F62FE)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2EAF5)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Total Amount: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TABLE
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x04092B60), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFD),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5))),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('S.N.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 2, child: Text('Vch Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 3, child: Text('Voucher No.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 5, child: Text('Party / Ledger Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 3, child: Text('Tax Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 2, child: Text('Tax (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                          Expanded(flex: 3, child: Text('Total Amount (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7B9B)))),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F62FE)))
                          : _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF90A1BA)),
                                      SizedBox(height: 10),
                                      Text(
                                        'No vouchers recorded in this date range.',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                                  itemBuilder: (context, idx) {
                                    final v = _filtered[idx];
                                    final vchNo = v['voucherNumber'] ?? '—';
                                    final date = v['date'] ?? '—';
                                    final party = v['party'] ?? '—';
                                    final saleType = v['saleType'] ?? 'GST Regular';
                                    final totalTax = double.tryParse(v['totalTax']?.toString() ?? '0') ?? 0.0;
                                    final grandTotal = double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;

                                    return InkWell(
                                      onTap: () {},
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '${idx + 1}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF90A1BA)),
                                              ),
                                            ),
                                            Expanded(flex: 2, child: Text(date.toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                vchNo.toString(),
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE)),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 5,
                                              child: Text(
                                                party.toString(),
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF101C38)),
                                              ),
                                            ),
                                            Expanded(flex: 3, child: Text(saleType.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                totalTax.toStringAsFixed(2),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                grandTotal.toStringAsFixed(2),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF101B3A)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}