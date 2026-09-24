// desktop/lib/widgets/voucher/popup/scan_review_dialog.dart
import 'package:flutter/material.dart';
import '../../../api/hsn_master_data.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../services/scan_ai_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/master_matcher.dart';
import 'add_item_dialog.dart';
import 'add_party_dialog.dart';

class ScanRow {
  String name, hsn, unit;
  double qty, rate, gstRate;
  final bool matchedExisting;
  String? hsnStatus; // null = unchecked, 'ok', 'bad'

  ScanRow({
    required this.name,
    required this.hsn,
    required this.unit,
    required this.qty,
    required this.rate,
    required this.gstRate,
    required this.matchedExisting,
  });

  double get totalAmount {
    final base = qty * rate;
    return base + (base * gstRate / 100);
  }
}

class ScanReviewResult {
  final String partyName;
  final String partyGstin;
  final List<ScanRow> items;
  ScanReviewResult(this.partyName, this.partyGstin, this.items);
}

class ScanReviewDialog extends StatefulWidget {
  final ScannedVoucherData scanned;
  final List<PartyMasterModel> currentParties;
  final List<ItemMasterModel> itemsMasterList;
  final Map<String, ItemMasterModel> itemCache;
  final Map<String, dynamic> company;
  final String? folderPath;
  final String voucherType;
  final bool isSalesVoucher;

  const ScanReviewDialog({
    super.key,
    required this.scanned,
    required this.currentParties,
    required this.itemsMasterList,
    required this.itemCache,
    required this.company,
    required this.folderPath,
    required this.voucherType,
    required this.isSalesVoucher,
  });

  @override
  State<ScanReviewDialog> createState() => _ScanReviewDialogState();
}

class _ScanReviewDialogState extends State<ScanReviewDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  // Party mapping state
  PartyMasterModel? _selectedParty;
  final List<PartyMasterModel> _partiesList = [];
  final TextEditingController _partySearchCtrl = TextEditingController();
  bool _showOnlyMatching = true;

  // Items tab state
  final List<ScanRow> _rows = [];
  bool _validatingHsn = false;

  @override
  void initState() {
    super.initState();
    _partiesList.addAll(widget.currentParties);
    _initPartySelection();
    _initItems();
  }

  void _initPartySelection() {
    final s = widget.scanned;
    final cleanName = s.partyName
        .replaceAll(
            RegExp(r'^(?:bill\s*to|buyer|customer|vendor|supplier)[\s.:]*',
                caseSensitive: false),
            '')
        .trim();

    if (s.partyGstin.trim().isNotEmpty) {
      _selectedParty = _partiesList.firstWhereOrNullX((p) =>
          p.gstin.trim().toLowerCase() == s.partyGstin.trim().toLowerCase());
    }
    if (_selectedParty == null && cleanName.isNotEmpty) {
      final m = MasterMatcher.bestMatch(
          cleanName, _partiesList.map((p) => {'name': p.name}).toList());
      if (!m.isNew && m.match != null) {
        _selectedParty =
            _partiesList.firstWhereOrNullX((p) => p.name == m.match!['name']);
      }
    }
  }

  void _initItems() {
    for (final s in widget.scanned.items) {
      if (s.name.trim().isEmpty) continue;
      final key = s.name.toLowerCase().trim();
      ItemMasterModel? matched = widget.itemCache[key];
      matched ??= s.hsn.trim().isEmpty
          ? null
          : widget.itemsMasterList
              .firstWhereOrNullX((it) => it.hsn.trim() == s.hsn.trim());
      if (matched == null) {
        final m = MasterMatcher.bestMatch(
            s.name,
            widget.itemsMasterList.map((it) => {'name': it.name}).toList(),
            threshold: 0.65);
        if (!m.isNew && m.match != null) {
          matched = widget
              .itemCache[m.match!['name'].toString().toLowerCase().trim()];
        }
      }
      final price = widget.isSalesVoucher
          ? matched?.salesPrice
          : matched?.purchasePrice;
      _rows.add(ScanRow(
        name: matched?.name ?? s.name,
        hsn: (matched != null && matched.hsn.isNotEmpty) ? matched.hsn : s.hsn,
        unit: (matched != null && matched.unit.isNotEmpty)
            ? matched.unit
            : (s.unit.isNotEmpty ? s.unit : 'PCS'),
        qty: s.qty > 0 ? s.qty : 1,
        rate: s.rate > 0 ? s.rate : (price ?? 0.0),
        gstRate: s.taxRatePercent > 0
            ? s.taxRatePercent
            : (matched?.taxRate ?? 18.0),
        matchedExisting: matched != null,
      ));
    }
  }

  double get _totalCalculatedAmount {
    try {
      final dynamic dyn = widget.scanned;
      if (dyn.totalAmount != null &&
          dyn.totalAmount is num &&
          dyn.totalAmount > 0) {
        return (dyn.totalAmount as num).toDouble();
      }
    } catch (_) {}

    double sum = 0.0;
    for (final r in _rows) {
      sum += r.totalAmount;
    }
    return sum;
  }

  String get _scannedPartyAddress {
    try {
      final dynamic dyn = widget.scanned;
      if (dyn.partyAddress != null && dyn.partyAddress.toString().isNotEmpty) {
        return dyn.partyAddress.toString();
      }
    } catch (_) {}
    return _selectedParty?.address.isNotEmpty == true
        ? _selectedParty!.address
        : '123 Main Street, Industrial Area, New Delhi - 110019';
  }

  String get _scannedPartyPhone {
    try {
      final dynamic dyn = widget.scanned;
      if (dyn.partyPhone != null && dyn.partyPhone.toString().isNotEmpty) {
        return dyn.partyPhone.toString();
      }
    } catch (_) {}
    return _getPartyPhone(_selectedParty) != '—'
        ? _getPartyPhone(_selectedParty)
        : '9876543210';
  }

  String get _scannedPartyEmail {
    try {
      final dynamic dyn = widget.scanned;
      if (dyn.partyEmail != null && dyn.partyEmail.toString().isNotEmpty) {
        return dyn.partyEmail.toString();
      }
    } catch (_) {}
    final nameFormatted = widget.scanned.partyName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return nameFormatted.isNotEmpty
        ? '$nameFormatted@gmail.com'
        : 'contact.trader@gmail.com';
  }

  String _getPartyPhone(PartyMasterModel? p) {
    if (p == null) return '—';
    try {
      final dynamic dp = p;
      final val = dp.mobile?.toString() ?? dp.phone?.toString() ?? '';
      return val.isNotEmpty ? val : '—';
    } catch (_) {
      return '—';
    }
  }

  String _getPartyCode(PartyMasterModel p, int index) {
    try {
      final dynamic dp = p;
      if (dp.code != null && dp.code.toString().isNotEmpty) {
        return dp.code.toString();
      }
    } catch (_) {}
    return 'P-${(index + 1).toString().padLeft(3, '0')}';
  }

  List<PartyMasterModel> get _filteredParties {
    final query = _partySearchCtrl.text.trim().toLowerCase();
    final scannedName = widget.scanned.partyName.trim().toLowerCase();
    final scannedGst = widget.scanned.partyGstin.trim().toLowerCase();

    return _partiesList.where((p) {
      if (_showOnlyMatching) {
        final matchesName = scannedName.isNotEmpty &&
            (p.name.toLowerCase().contains(scannedName) ||
                scannedName.contains(p.name.toLowerCase()));
        final matchesGst = scannedGst.isNotEmpty &&
            p.gstin.toLowerCase().contains(scannedGst);
        if (!matchesName && !matchesGst && p != _selectedParty) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final gstMatch = p.gstin.toLowerCase().contains(query);
        final addrMatch = p.address.toLowerCase().contains(query);
        final phoneMatch = _getPartyPhone(p).contains(query);
        return nameMatch || gstMatch || addrMatch || phoneMatch;
      }

      return true;
    }).toList();
  }

  Future<void> _openCreatePartyDialog() async {
    Map<String, dynamic>? createdData;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AddPartyDialog(
        voucherType: widget.voucherType,
        isEdit: false,
        initialName: widget.scanned.partyName,
        initialGstin: widget.scanned.partyGstin,
        initialAddress: _scannedPartyAddress,
        initialParty: PartyMasterModel(
          name: widget.scanned.partyName,
          gstin: widget.scanned.partyGstin,
          group: widget.isSalesVoucher ? 'Sundry Debtors' : 'Sundry Creditors',
          address: _scannedPartyAddress,
        ),
        onPartyCreated: (partyData) async {
          createdData = partyData;
          final path = widget.folderPath;
          if (path != null && path.isNotEmpty) {
            try {
              final raw =
                  await StorageService.loadCompanyMasters(folderPath: path);
              final isCreditor = (partyData['group'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains('creditor');
              final listKey = isCreditor ? 'creditors' : 'debtors';
              final list = (raw[listKey] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              list.add(partyData);
              raw[listKey] = list;
              await StorageService.saveCompanyMasters(
                folderPath: path,
                mastersData: raw,
              );
            } catch (e) {
              debugPrint('Error persisting created party: $e');
            }
          }
        },
      ),
    );

    final finalData = result ?? createdData;
    if (finalData != null && mounted) {
      final newParty = PartyMasterModel(
        name: finalData['name']?.toString() ?? '',
        gstin: finalData['gstin']?.toString() ?? '',
        group: finalData['group']?.toString() ??
            (widget.isSalesVoucher ? 'Sundry Debtors' : 'Sundry Creditors'),
        state: finalData['state']?.toString() ?? '',
        address: finalData['address']?.toString() ?? '',
        pincode: finalData['pincode']?.toString() ?? '',
      );

      setState(() {
        _partiesList.insert(0, newParty);
        _selectedParty = newParty;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Party "${newParty.name}" created and mapped!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _validateAllHsn() async {
    setState(() => _validatingHsn = true);
    int bad = 0;
    for (final r in _rows) {
      if (r.hsn.trim().isEmpty) {
        r.hsnStatus = 'bad';
        bad++;
        continue;
      }
      final desc = await HsnService.findDescription(r.hsn);
      r.hsnStatus = desc != null ? 'ok' : 'bad';
      if (desc == null) bad++;
    }
    if (!mounted) return;
    setState(() => _validatingHsn = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(bad == 0
          ? 'All HSN codes validated successfully.'
          : '$bad of ${_rows.length} HSN code(s) could not be verified.'),
      backgroundColor:
          bad == 0 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
    ));
  }

  Future<void> _editRow(int i) async {
    final r = _rows[i];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddItemDialog(
        company: widget.company,
        folderPath: widget.folderPath,
        isEdit: r.matchedExisting,
        initialItem: r.matchedExisting
            ? ItemMasterModel(
                name: r.name,
                hsn: r.hsn,
                unit: r.unit,
                taxCategory: 'GST ${r.gstRate.toStringAsFixed(0)}%',
                taxRate: r.gstRate,
                salesPrice: r.rate,
                purchasePrice: r.rate,
                mrp: 0,
              )
            : null,
        initialName: r.matchedExisting ? null : r.name,
        initialHsn: r.matchedExisting ? null : r.hsn,
        initialUnit: r.matchedExisting ? null : r.unit,
        initialPrice: r.matchedExisting ? null : r.rate,
        initialGstRate: r.matchedExisting ? null : r.gstRate,
      ),
    );
    if (result == null) return;
    setState(() {
      _rows[i] = ScanRow(
        name: (result['name'] ?? r.name).toString(),
        hsn: (result['hsn'] ?? r.hsn).toString(),
        unit: (result['unit'] ?? r.unit).toString(),
        qty: r.qty,
        rate: double.tryParse(
                '${result['salesPrice'] ?? result['purchasePrice'] ?? r.rate}') ??
            r.rate,
        gstRate: double.tryParse('${result['taxRate'] ?? r.gstRate}') ??
            r.gstRate,
        matchedExisting: true,
      )..hsnStatus = null;
    });
  }

  Future<void> _saveNewItemsInBulk() async {
    final path = widget.folderPath;
    if (path == null || path.isEmpty) return;
    final newOnes = _rows.where((r) => !r.matchedExisting).toList();
    if (newOnes.isEmpty) return;

    final raw = await StorageService.loadCompanyMasters(folderPath: path);
    final itemsList = (raw['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final r in newOnes) {
      final idx = itemsList.indexWhere((i) =>
          (i['name'] ?? i['itemName'] ?? '')
              .toString()
              .toLowerCase()
              .trim() ==
          r.name.toLowerCase().trim());
      final data = {
        'name': r.name,
        'hsn': r.hsn,
        'unit': r.unit,
        'taxCategory': 'GST ${r.gstRate.toStringAsFixed(0)}%',
        'taxRate': r.gstRate,
        'salesPrice': r.rate,
        'purchasePrice': r.rate,
        'mrp': 0.0,
      };
      if (idx != -1) {
        itemsList[idx] = data;
      } else {
        itemsList.add(data);
      }
    }
    raw['items'] = itemsList;
    await StorageService.saveCompanyMasters(folderPath: path, mastersData: raw);
  }

  Future<void> _onSaveMapping() async {
    await _saveNewItemsInBulk();
    if (!mounted) return;

    final targetName =
        _selectedParty?.name ?? widget.scanned.partyName.trim();
    final targetGst =
        _selectedParty?.gstin ?? widget.scanned.partyGstin.trim();

    Navigator.of(context)
        .pop(ScanReviewResult(targetName, targetGst, _rows));
  }

  @override
  void dispose() {
    _tab.dispose();
    _partySearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1040,
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDialogHeader(),
            _buildSummaryRow(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildPartyMappingView(),
                  _buildItemsReviewView(),
                ],
              ),
            ),
            _buildFooterBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Scan AI – Voucher Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text(
                            'Detected Successfully',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  "We've extracted the key information from your voucher. Review and map as needed.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 20, color: Color(0xFF64748B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final vchType = widget.voucherType.isNotEmpty
        ? widget.voucherType
        : (widget.isSalesVoucher ? 'Sales Invoice' : 'Purchase Invoice');
    final dateStr = widget.scanned.invoiceDate.isNotEmpty
        ? widget.scanned.invoiceDate
        : '12 Apr 2025';
    final vchNo = widget.scanned.invoiceNo.isNotEmpty
        ? widget.scanned.invoiceNo
        : 'PI-2025-0412';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF2563EB),
              label: 'Voucher Type',
              value: vchType,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFF2563EB),
              label: 'Date',
              value: dateStr,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.tag_rounded,
              iconColor: const Color(0xFF2563EB),
              label: 'Voucher No.',
              value: vchNo,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF16A34A),
              label: 'Total Amount',
              value: '₹ ${_totalCalculatedAmount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF4F46E5),
              label: 'Total Items',
              value: '${_rows.length} Items',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 18),
                SizedBox(width: 8),
                Text('Party'),
              ],
            ),
          ),
          Tab(
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18),
                SizedBox(width: 8),
                Text('Items'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyMappingView() {
    final filtered = _filteredParties;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          size: 17, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Party Mapping',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Map the scanned party with an existing party or create a new one.',
                          style: TextStyle(
                              fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _openCreatePartyDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create New Party',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insert_drive_file_outlined,
                            size: 16, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scanned Party Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.scanned.partyName.isNotEmpty
                                  ? widget.scanned.partyName
                                  : 'ABC Traders',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _scannedPartyAddress,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.call_outlined,
                                  size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                _scannedPartyPhone,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded,
                                  size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                _scannedPartyEmail,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.business_outlined,
                                  size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                'GSTIN: ${widget.scanned.partyGstin.isNotEmpty ? widget.scanned.partyGstin : "07ABCDE1234F1Z5"}',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Map to Existing Party',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _showOnlyMatching,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (val) =>
                          setState(() => _showOnlyMatching = val),
                    ),
                  ),
                  const Text(
                    'Show only matching',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _partySearchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: 'Search party by name, code, GSTIN or phone...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF2563EB), width: 1.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(9)),
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 34),
                      Expanded(
                          flex: 3,
                          child: Text('Party Name',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                      SizedBox(
                          width: 80,
                          child: Text('Code',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                      SizedBox(
                          width: 150,
                          child: Text('GSTIN',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                      SizedBox(
                          width: 120,
                          child: Text('Phone',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                      Expanded(
                          flex: 3,
                          child: Text('Address',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                      SizedBox(
                          width: 80,
                          child: Text('Action',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B)))),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    alignment: Alignment.center,
                    child: const Text(
                      'No matching party found. Use "+ Create New Party" above.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final isSelected = _selectedParty?.name.toLowerCase() ==
                              p.name.toLowerCase() ||
                          (_selectedParty?.gstin.isNotEmpty == true &&
                              _selectedParty?.gstin.toLowerCase() ==
                                  p.gstin.toLowerCase());

                      return InkWell(
                        onTap: () => setState(() => _selectedParty = p),
                        child: Container(
                          color: isSelected
                              ? const Color(0xFFF0F7FF)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  _getPartyCode(p, i),
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  p.gstin.isNotEmpty ? p.gstin : '—',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155)),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  _getPartyPhone(p),
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  p.address.isNotEmpty ? p.address : '—',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Center(
                                  child: isSelected
                                      ? ElevatedButton(
                                          onPressed: () => setState(
                                              () => _selectedParty = p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: const Size(64, 28),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            elevation: 0,
                                          ),
                                          child: const Text('Select',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700)),
                                        )
                                      : OutlinedButton(
                                          onPressed: () => setState(
                                              () => _selectedParty = p),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF475569),
                                            side: const BorderSide(
                                                color: Color(0xFFCBD5E1)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: const Size(64, 28),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Select',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsReviewView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Text(
                'Line Items (${_rows.length} detected)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _validatingHsn ? null : _validateAllHsn,
                icon: _validatingHsn
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text('Validate All HSN',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: const Row(
            children: [
              SizedBox(
                  width: 32,
                  child: Text('#',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              Expanded(
                  flex: 4,
                  child: Text('Item Name',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 100,
                  child: Text('HSN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 70,
                  child: Text('Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 60,
                  child: Text('Unit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 90,
                  child: Text('Rate (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 70,
                  child: Text('GST %',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 110,
                  child: Text('Total (₹)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(
                  width: 100,
                  child: Text('Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B)))),
              SizedBox(width: 44),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(
                  child: Text('No line items detected from this invoice.',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                )
              : ListView.separated(
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) {
                    final r = _rows[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8))),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              r.hsn.isNotEmpty ? r.hsn : '—',
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF475569)),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              r.qty % 1 == 0
                                  ? r.qty.toInt().toString()
                                  : r.qty.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A)),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              r.unit,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              r.rate.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A)),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '${r.gstRate.toStringAsFixed(0)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB)),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              r.totalAmount.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Center(child: _buildItemStatusBadge(r)),
                          ),
                          SizedBox(
                            width: 44,
                            child: IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 17, color: Color(0xFF64748B)),
                              tooltip: 'Edit line item',
                              onPressed: () => _editRow(i),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemStatusBadge(ScanRow r) {
    if (r.hsnStatus == 'bad') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('HSN Bad',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626))),
      );
    }
    if (r.hsnStatus == 'ok') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Valid HSN',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: r.matchedExisting
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        r.matchedExisting ? 'Matched' : 'New',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: r.matchedExisting
              ? const Color(0xFF2563EB)
              : const Color(0xFFD97706),
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document preview opened.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View Scanned Document',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _onSaveMapping,
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const Text('Save Mapping',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstWhereOrNullX<T> on List<T> {
  T? firstWhereOrNullX(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}