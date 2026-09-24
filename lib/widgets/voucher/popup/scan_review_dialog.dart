// One consolidated dialog for reviewing an AI-scanned invoice — replaces the
// old flow of opening a separate AddItemDialog for every unmatched line
// item (100 items -> 100 popups). Two tabs: Party, Items. Items are shown
// as an auto-filled table; a pencil icon opens AddItemDialog for that ONE
// row only, on demand. A "Validate HSN" action checks every row locally.
import 'package:flutter/material.dart';

import '../../../api/hsn_master_data.dart';
import '../../../constants/gst_constants.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../services/scan_ai_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/master_matcher.dart';
import 'add_item_dialog.dart';

class ScanRow {
  String name, hsn, unit;
  double qty, rate, gstRate;
  final bool matchedExisting;
  String? hsnStatus; // null=unchecked, 'ok', 'bad'

  ScanRow({
    required this.name,
    required this.hsn,
    required this.unit,
    required this.qty,
    required this.rate,
    required this.gstRate,
    required this.matchedExisting,
  });
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
  static const _brand = Color(0xFF3D5AFE);

  // Party tab state.
  PartyMasterModel? _matchedParty;
  bool _editParty = false;
  bool _showOnlyMatching = true;
  final _pSearch = TextEditingController();
  final _pName = TextEditingController();
  final _pGstin = TextEditingController();
  final _pGroup = TextEditingController();
  final _pState = TextEditingController();
  final _pAddress = TextEditingController();
  final _pPincode = TextEditingController();
  String _scannedName = '', _scannedGstin = '';

  // Items tab state.
  final List<ScanRow> _rows = [];
  bool _validating = false;

  double get _totalAmount =>
      _rows.fold(0.0, (a, r) => a + r.qty * r.rate * (1 + r.gstRate / 100));

  @override
  void initState() {
    super.initState();
    _initParty();
    _initItems();
  }

  void _initParty() {
    final s = widget.scanned;
    final cleanName = s.partyName
        .replaceAll(RegExp(r'^(?:bill\s*to|buyer|customer)[\s.:]*', caseSensitive: false), '')
        .trim();

    if (s.partyGstin.trim().isNotEmpty) {
      _matchedParty = widget.currentParties.firstWhereOrNullX(
          (p) => p.gstin.trim().toLowerCase() == s.partyGstin.trim().toLowerCase());
    }
    if (_matchedParty == null && cleanName.isNotEmpty) {
      final m = MasterMatcher.bestMatch(
          cleanName, widget.currentParties.map((p) => {'name': p.name}).toList());
      if (!m.isNew && m.match != null) {
        _matchedParty = widget.currentParties.firstWhereOrNullX(
            (p) => p.name == m.match!['name']);
      }
    }

    _scannedName = cleanName;
    _scannedGstin = s.partyGstin.trim();
    _applyParty(_matchedParty, fallbackName: cleanName);
  }

  void _applyParty(PartyMasterModel? p, {String fallbackName = ''}) {
    final isSales = widget.voucherType.toLowerCase().contains('sale');
    _matchedParty = p;
    _pName.text = p?.name ?? fallbackName;
    _pGstin.text = (p?.gstin.isNotEmpty ?? false) ? p!.gstin : _scannedGstin;
    _pGroup.text = p?.group ?? (isSales ? 'Sundry Debtors' : 'Sundry Creditors');
    _pState.text = p?.state ?? '';
    _pAddress.text = p?.address ?? '';
    _pPincode.text = p?.pincode ?? '';
    _editParty = p == null; // new party -> editable straight away
  }

  List<PartyMasterModel> get _filteredParties {
    final q = _pSearch.text.trim().toLowerCase();
    return widget.currentParties.where((p) {
      if (_showOnlyMatching && _scannedGstin.isNotEmpty &&
          p.gstin.trim().toLowerCase() != _scannedGstin.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.gstin.toLowerCase().contains(q) ||
          p.mobile.toLowerCase().contains(q);
    }).toList();
  }

  void _initItems() {
    for (final s in widget.scanned.items) {
      if (s.name.trim().isEmpty) continue;
      final key = s.name.toLowerCase().trim();
      ItemMasterModel? matched = widget.itemCache[key];
      matched ??= s.hsn.trim().isEmpty
          ? null
          : widget.itemsMasterList.firstWhereOrNullX((it) => it.hsn.trim() == s.hsn.trim());
      if (matched == null) {
        final m = MasterMatcher.bestMatch(
            s.name,
            widget.itemsMasterList.map((it) => {'name': it.name}).toList(),
            threshold: 0.65);
        if (!m.isNew && m.match != null) {
          matched = widget.itemCache[m.match!['name'].toString().toLowerCase().trim()];
        }
      }
      final price = widget.isSalesVoucher ? matched?.salesPrice : matched?.purchasePrice;
      _rows.add(ScanRow(
        name: matched?.name ?? s.name,
        hsn: (matched != null && matched.hsn.isNotEmpty) ? matched.hsn : s.hsn,
        unit: (matched != null && matched.unit.isNotEmpty)
            ? matched.unit
            : (s.unit.isNotEmpty ? s.unit : 'PCS'),
        qty: s.qty > 0 ? s.qty : 1,
        rate: s.rate > 0 ? s.rate : (price ?? 0.0),
        gstRate: s.taxRatePercent > 0 ? s.taxRatePercent : (matched?.taxRate ?? 18.0),
        matchedExisting: matched != null,
      ));
    }
  }

  Future<void> _validateAllHsn() async {
    setState(() => _validating = true);
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
    setState(() => _validating = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(bad == 0
          ? 'All HSN codes validated successfully.'
          : '$bad of ${_rows.length} HSN code(s) could not be validated — check the Items tab.'),
      backgroundColor: bad == 0 ? Colors.green[700] : Colors.orange[800],
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
                mrp: 0)
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
        rate: double.tryParse('${result['salesPrice'] ?? result['purchasePrice'] ?? r.rate}') ?? r.rate,
        gstRate: double.tryParse('${result['taxRate'] ?? r.gstRate}') ?? r.gstRate,
        matchedExisting: true,
        )
        ..hsnStatus = null;
    });
  }

  Future<void> _savePartyIfNeeded() async {
    final path = widget.folderPath;
    if (path == null || path.isEmpty) return;
    final isNew = _matchedParty == null;
    final changed = _matchedParty != null &&
        (_matchedParty!.name != _pName.text.trim() ||
            _matchedParty!.gstin != _pGstin.text.trim() ||
            _matchedParty!.state != _pState.text.trim() ||
            _matchedParty!.address != _pAddress.text.trim() ||
            _matchedParty!.pincode != _pPincode.text.trim());
    if (!isNew && !changed) return;

    final data = {
      'name': _pName.text.trim(),
      'gstin': _pGstin.text.trim().toUpperCase(),
      'group': _pGroup.text.trim(),
      'country': 'India',
      'state': _pState.text.trim(),
      'address': _pAddress.text.trim(),
      'pincode': _pPincode.text.trim(),
      'aadhaar': '',
      'mobile': '',
    };

    final raw = await StorageService.loadCompanyMasters(folderPath: path);
    final isCreditor = data['group']!.toLowerCase().contains('creditor');
    final listKey = isCreditor ? 'creditors' : 'debtors';
    final list = (raw[listKey] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final origName = _matchedParty?.name.toLowerCase().trim();
    final idx = list.indexWhere((e) => (e['name'] ?? '').toString().toLowerCase().trim() == (origName ?? data['name']!.toLowerCase()));
    if (idx != -1) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    raw[listKey] = list;
    await StorageService.saveCompanyMasters(folderPath: path, mastersData: raw);
  }

  Future<void> _saveNewItemsInBulk() async {
    final path = widget.folderPath;
    if (path == null || path.isEmpty) return;
    final newOnes = _rows.where((r) => !r.matchedExisting).toList();
    if (newOnes.isEmpty) return;

    final raw = await StorageService.loadCompanyMasters(folderPath: path);
    final itemsList = (raw['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    for (final r in newOnes) {
      final idx = itemsList.indexWhere(
          (i) => (i['name'] ?? i['itemName'] ?? '').toString().toLowerCase().trim() == r.name.toLowerCase().trim());
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

  Future<void> _onSave() async {
    if (_pName.text.trim().isEmpty && _rows.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _savePartyIfNeeded();
    await _saveNewItemsInBulk();
    if (!mounted) return;
    Navigator.of(context).pop(ScanReviewResult(_pName.text.trim(), _pGstin.text.trim(), _rows));
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_pSearch, _pName, _pGstin, _pGroup, _pState, _pAddress, _pPincode]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scanned;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 860,
        height: 660,
        child: Column(children: [
          _buildHeader(s),
          _buildSummaryStrip(s),
          TabBar(controller: _tab, labelColor: _brand, indicatorColor: _brand, tabs: const [
            Tab(icon: Icon(Icons.groups_outlined), text: 'Party'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Items'),
          ]),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _buildPartyTab(),
              _buildItemsTab(),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Original document preview is not attached to this scan.'))),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Scanned Document'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _validating ? null : _validateAllHsn,
                icon: _validating
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Validate All HSN'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _brand),
                onPressed: _onSave,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save Mapping'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(ScannedVoucherData s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_brand, Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Scan AI — Voucher Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 13, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text('Detected Successfully',
                      style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const Text("We've extracted the key information. Review and map as needed.",
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ]),
    );
  }

  Widget _buildSummaryStrip(ScannedVoucherData s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        _metric(Icons.description_outlined, 'Voucher Type', widget.voucherType, Colors.blue),
        _metric(Icons.calendar_today_outlined, 'Date',
            s.invoiceDate.isEmpty ? '—' : s.invoiceDate, Colors.blue),
        _metric(Icons.tag, 'Voucher No.', s.invoiceNo.isEmpty ? '—' : s.invoiceNo, Colors.purple),
        _metric(Icons.currency_rupee, 'Total Amount', '₹${_totalAmount.toStringAsFixed(2)}', Colors.green),
        _metric(Icons.inventory_2_outlined, 'Total Items', '${_rows.length} Items', Colors.indigo),
      ]),
    );
  }

  Widget _metric(IconData icon, String label, String value, MaterialColor color) {
    return Expanded(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color[700]),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
            Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPartyTab() {
    final isNew = _matchedParty == null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Party Mapping',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create New Party'),
            onPressed: () => setState(() => _applyParty(null, fallbackName: _scannedName)),
          ),
        ]),
        const SizedBox(height: 10),
        // Scanned party details card.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.blue[50]?.withOpacity(0.5),
              border: Border.all(color: Colors.blue.shade100),
              borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scanned Party Details',
                style: TextStyle(fontSize: 11, color: _brand, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_scannedName.isEmpty ? '(No name detected)' : _scannedName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (_scannedGstin.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('GSTIN: $_scannedGstin', style: const TextStyle(fontSize: 12)),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (!isNew)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Party "${_matchedParty!.name}" already exists. Edit details?')),
              ChoiceChip(
                  label: const Text('Yes'),
                  selected: _editParty,
                  onSelected: (v) => setState(() => _editParty = true)),
              const SizedBox(width: 6),
              ChoiceChip(
                  label: const Text('No'),
                  selected: !_editParty,
                  onSelected: (v) => setState(() => _editParty = false)),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('New party — details prefilled from the scan. Edit below or pick a match.',
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500, fontSize: 12.5)),
          ),
        const Text('Map to Existing Party', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _pSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: 'Search party by name, GSTIN or phone…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: _showOnlyMatching, activeTrackColor: _brand,
              onChanged: (v) => setState(() => _showOnlyMatching = v)),
          const Text('Show only matching', style: TextStyle(fontSize: 12.5)),
        ]),
        const SizedBox(height: 10),
        _partyResultsTable(),
        const SizedBox(height: 16),
        AbsorbPointer(
          absorbing: !isNew && !_editParty,
          child: Opacity(
            opacity: (!isNew && !_editParty) ? 0.6 : 1,
            child: Column(children: [
              TextField(controller: _pName, decoration: const InputDecoration(labelText: 'Party Name')),
              const SizedBox(height: 10),
              TextField(controller: _pGstin, decoration: const InputDecoration(labelText: 'GSTIN')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: ['Sundry Debtors', 'Sundry Creditors'].contains(_pGroup.text)
                    ? _pGroup.text
                    : 'Sundry Debtors',
                decoration: const InputDecoration(labelText: 'Group'),
                items: const [
                  DropdownMenuItem(value: 'Sundry Debtors', child: Text('Sundry Debtors')),
                  DropdownMenuItem(value: 'Sundry Creditors', child: Text('Sundry Creditors')),
                ],
                onChanged: (v) => setState(() => _pGroup.text = v ?? _pGroup.text),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: GstConstants.allSortedStateNames.contains(_pState.text) ? _pState.text : null,
                decoration: const InputDecoration(labelText: 'State'),
                items: GstConstants.allSortedStateNames
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _pState.text = v ?? ''),
              ),
              const SizedBox(height: 10),
              TextField(controller: _pAddress, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              TextField(controller: _pPincode, decoration: const InputDecoration(labelText: 'Pincode')),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _partyResultsTable() {
    final results = _filteredParties;
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: const Text('No matching party found. Use "Create New Party" above.',
            style: TextStyle(color: Colors.black54)),
      );
    }
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: const Row(children: [
            SizedBox(width: 30),
            Expanded(flex: 3, child: Text('Party Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 3, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            SizedBox(width: 70),
          ]),
        ),
        ...results.take(6).map((p) {
          final selected = _matchedParty?.name == p.name;
          return Container(
            color: selected ? _brand.withOpacity(0.06) : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Radio<String>(
                  value: p.name,
                  groupValue: _matchedParty?.name,
                  onChanged: (_) => setState(() => _applyParty(p)),
                ),
              ),
              Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
              Expanded(flex: 2, child: Text(p.gstin.isEmpty ? '—' : p.gstin, style: const TextStyle(fontSize: 12))),
              Expanded(flex: 2, child: Text(p.mobile.isEmpty ? '—' : p.mobile, style: const TextStyle(fontSize: 12))),
              Expanded(flex: 3, child: Text(p.address.isEmpty ? '—' : p.address,
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
              SizedBox(
                width: 70,
                child: selected
                    ? const Icon(Icons.check_circle, color: _brand, size: 18)
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 30)),
                        onPressed: () => setState(() => _applyParty(p)),
                        child: const Text('Select', style: TextStyle(fontSize: 11)),
                      ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildItemsTab() {
    if (_rows.isEmpty) {
      return const Center(child: Text('No line items detected from this invoice.'));
    }
    return Column(children: [
      Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Row(children: [
          Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('GST%', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 90, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 36),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: _rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = _rows[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Expanded(flex: 3, child: Text(r.name, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(r.hsn.isEmpty ? '—' : r.hsn)),
                Expanded(child: Text(r.qty % 1 == 0 ? r.qty.toInt().toString() : r.qty.toString())),
                Expanded(child: Text(r.rate.toStringAsFixed(2))),
                Expanded(child: Text('${r.gstRate.toStringAsFixed(0)}%')),
                SizedBox(width: 90, child: _statusChip(r)),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit item',
                    onPressed: () => _editRow(i),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Total (incl. GST): ', style: TextStyle(fontWeight: FontWeight.w600)),
          Text('₹${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _brand)),
        ]),
      ),
    ]);
  }

  Widget _statusChip(ScanRow r) {
    if (r.hsnStatus == 'bad') {
      return Chip(
        label: const Text('HSN bad', style: TextStyle(fontSize: 11)),
        backgroundColor: Colors.red[50],
        avatar: const Icon(Icons.error_outline, size: 14, color: Colors.red),
        padding: EdgeInsets.zero,
      );
    }
    if (r.hsnStatus == 'ok') {
      return Chip(
        label: const Text('Valid', style: TextStyle(fontSize: 11)),
        backgroundColor: Colors.green[50],
        avatar: const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
        padding: EdgeInsets.zero,
      );
    }
    return Chip(
      label: Text(r.matchedExisting ? 'Matched' : 'New', style: const TextStyle(fontSize: 11)),
      backgroundColor: r.matchedExisting ? Colors.blue[50] : Colors.orange[50],
      padding: EdgeInsets.zero,
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
