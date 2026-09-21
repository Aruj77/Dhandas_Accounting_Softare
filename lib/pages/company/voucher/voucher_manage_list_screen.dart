import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../models/register_summary.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../widgets/common/data_table_cells.dart';
import '../../../widgets/common/quick_metric_badge.dart';
import 'voucher_entry_screen.dart';
import '../../../widgets/common/app_confirm_dialog.dart';
import '../../../services/loading_service.dart';

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
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _headerScrollCtrl = ScrollController();
  final _bodyHorizontalScrollCtrl = ScrollController();
  final _bodyVerticalScrollCtrl = ScrollController();
  final _footerScrollCtrl = ScrollController();

  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _selectedKeys = {};
  bool _isLoading = true;
  int _focusedIndex = -1;
  List<FocusNode> _rowFocusNodes = [];

  static const double _tableMinWidth = 1680.0;

  RegisterSummary get _summary => RegisterSummary.fromVouchers(_filtered);

  String _getPos(String gstin, bool isInterState) =>
      GstPartyUtils.getPlaceOfSupply(gstin, isInterState, companyGstin: (widget.company['gstin'] ?? '').toString());

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchCtrl.addListener(_onSearch);
    _bodyHorizontalScrollCtrl.addListener(() {
      for (final ctrl in [_headerScrollCtrl, _footerScrollCtrl]) {
        if (ctrl.hasClients && ctrl.offset != _bodyHorizontalScrollCtrl.offset) {
          ctrl.jumpTo(_bodyHorizontalScrollCtrl.offset);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _headerScrollCtrl.dispose();
    _bodyHorizontalScrollCtrl.dispose();
    _bodyVerticalScrollCtrl.dispose();
    _footerScrollCtrl.dispose();
    for (final n in _rowFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes() {
    for (final n in _rowFocusNodes) {
      n.dispose();
    }
    _rowFocusNodes = List.generate(_filtered.length, (i) => FocusNode(debugLabel: 'ManageRow_$i'));
  }

  void _handleSafeExit() {
    widget.onClose();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  String _resolveKey(Map<String, dynamic> v, int i) => v['id']?.toString() ?? v['voucherNumber']?.toString() ?? 'idx_$i';

  Future<void> _loadVouchers() async {
    await LoadingService.wrap(() async {
      final folderPath = widget.company['folderPath']?.toString();
      final fy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();

      if (folderPath != null) {
        final all = await StorageService.loadVouchers(folderPath: folderPath, financialYear: fy, voucherType: widget.voucherType);
        final matching = all.where((v) => (v['voucherType'] ?? '').toString().toLowerCase() == widget.voucherType.toLowerCase()).toList();
        if (mounted) {
          setState(() {
            _vouchers = matching;
            _filtered = matching;
            _selectedKeys.clear();
            _isLoading = false;
            _syncFocusNodes();
          });
        }
      }
    }, message: 'Loading Vouchers for management...');
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _vouchers : _vouchers.where((v) {
        final vch = (v['voucherNumber'] ?? '').toString().toLowerCase();
        final party = (v['party'] ?? '').toString().toLowerCase();
        final gstin = GstPartyUtils.extractPartyGstin((v['party'] ?? '').toString()).toLowerCase();
        final items = (v['items'] as List? ?? []);
        return vch.contains(q) || party.contains(q) || gstin.contains(q) || items.any((it) => (it['hsn'] ?? '').toString().toLowerCase().contains(q) || (it['item'] ?? '').toString().toLowerCase().contains(q));
      }).toList();
      _syncFocusNodes();
      if (_rowFocusNodes.isNotEmpty) {
        _rowFocusNodes[0].requestFocus();
        _focusedIndex = 0;
      }
    });
  }

  void _editVoucher(Map<String, dynamic> voucher) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VoucherEntryScreen(company: widget.company, voucherType: widget.voucherType, voucherToEdit: voucher, isEdit: true, keyboardSettings: KeyboardShortcutSettings.defaults(), onClose: () { Navigator.of(context).pop(); _loadVouchers(); })));
  }

  Future<void> _confirmAndDelete(List<Map<String, dynamic>> toDelete) async {
    await LoadingService.wrap(() async {
      if (toDelete.isEmpty) return;
      final isPlural = toDelete.length > 1;

      final shouldDelete = await AppConfirmDialog.show(
        context: context,
        title: 'Confirm Deletion',
        message: isPlural
            ? 'Permanently delete ${toDelete.length} selected vouchers?'
            : 'Delete Voucher [${toDelete.first['voucherNumber']}]?',
        confirmLabel: isPlural ? 'Delete All (${toDelete.length})' : 'Delete',
        type: ConfirmDialogType.danger,
      );

      if (!shouldDelete || !mounted) return;

      final keys = {for (int i = 0; i < toDelete.length; i++) _resolveKey(toDelete[i], i)};
      setState(() {
        _vouchers.removeWhere((v) => keys.contains(_resolveKey(v, _vouchers.indexOf(v))));
        _filtered.removeWhere((v) => keys.contains(_resolveKey(v, _filtered.indexOf(v))));
        _selectedKeys.removeAll(keys);
        _syncFocusNodes();
      });

      final folderPath = widget.company['folderPath']?.toString();
      final fy = (widget.company['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();
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
            content: Text(isPlural ? '${toDelete.length} vouchers deleted.' : 'Voucher deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }, message: 'Deleting Selected Vouchers...');
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = [for (int i = 0; i < _filtered.length; i++) _resolveKey(_filtered[i], i)];
    final allSelected = allKeys.isNotEmpty && allKeys.every(_selectedKeys.contains);

    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherManageList,
      nodeMap: {
        FocusFieldNode.searchField: _searchFocusNode,
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) { _handleSafeExit(); return KeyEventResult.handled; }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: _handleSafeExit),
            title: Text('Manage ${widget.voucherType} Register', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            actions: [
              if (_selectedKeys.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAndDelete(_vouchers.asMap().entries.where((e) => _selectedKeys.contains(_resolveKey(e.value, e.key))).map((e) => e.value).toList()),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.surface),
                    label: Text('Delete Selected (${_selectedKeys.length})', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.surface)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search voucher, party, GSTIN...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    QuickMetricBadge(label: 'Vouchers', value: '${_filtered.length}', color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Total Qty', value: _summary.totalQuantity.toStringAsFixed(2), color: AppColors.info),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Taxable Val', value: '₹${_summary.totalTaxable.toStringAsFixed(2)}', color: AppColors.purple),
                    const SizedBox(width: 8),
                    QuickMetricBadge(label: 'Invoice Total', value: '₹${_summary.totalInvoiceValue.toStringAsFixed(2)}', color: AppColors.primary),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 1.2)),
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
                                width: dynamicWidth, height: 40, decoration: const BoxDecoration(color: AppColors.cardBg, border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2))),
                                child: Row(
                                  children: [
                                    SizedBox(width: 40, child: Center(child: Checkbox(value: allSelected, activeColor: AppColors.primary, onChanged: (v) { setState(() { if (v == true) { _selectedKeys.addAll(allKeys); } else { _selectedKeys.clear(); } }); }))),
                                    const RegisterHeaderCell('S.No.', width: 45),
                                    const RegisterHeaderCell('Party', width: 180),
                                    const RegisterHeaderCell('GSTIN', width: 135),
                                    const RegisterHeaderCell('Place of Supply', width: 140),
                                    const RegisterHeaderCell('Voc. No.', width: 95),
                                    const RegisterHeaderCell('Voc. Date', width: 90),
                                    const RegisterHeaderCell('Qty.', width: 70, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('Unit', width: 55, textAlign: TextAlign.center),
                                    const RegisterHeaderCell('HSN', width: 80),
                                    const RegisterHeaderCell('Invoice Value', width: 115, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('Taxable', width: 105, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('Rate', width: 60, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('IGST', width: 85, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('CGST', width: 85, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('SGST', width: 85, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('Cess', width: 75, textAlign: TextAlign.right),
                                    const RegisterHeaderCell('Actions', width: 90, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : _filtered.isEmpty ? const Center(child: Text('No matching vouchers found.')) : Scrollbar(
                                controller: _bodyHorizontalScrollCtrl,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _bodyHorizontalScrollCtrl,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: dynamicWidth,
                                    child: Scrollbar(
                                      controller: _bodyVerticalScrollCtrl,
                                      thumbVisibility: true,
                                      child: ListView.separated(
                                        controller: _bodyVerticalScrollCtrl,
                                        itemCount: _filtered.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                                        itemBuilder: (context, idx) {
                                          final v = _filtered[idx], key = _resolveKey(v, idx), isSelected = _selectedKeys.contains(key);
                                          final fullParty = (v['party'] ?? '').toString(), gstin = GstPartyUtils.extractPartyGstin(fullParty);
                                          final items = v['items'] as List? ?? [], invoiceTotal = (double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2);
                                          final cessTotal = GstPartyUtils.extractCessAmount(v).toStringAsFixed(2);
                                          final isFocused = _focusedIndex == idx;
                                          if (_rowFocusNodes.length <= idx) _syncFocusNodes();

                                          Widget buildActions() => Container(width: 90, padding: const EdgeInsets.symmetric(horizontal: 4), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary), onPressed: () => _editVoucher(v), splashRadius: 18), IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => _confirmAndDelete([v]), splashRadius: 18)]));

                                          return Focus(
                                            focusNode: _rowFocusNodes[idx],
                                            onFocusChange: (f) { if (f) setState(() => _focusedIndex = idx); },
                                            onKeyEvent: (_, e) {
                                              if (e is KeyDownEvent) {
                                                if (KeyboardShortcutService.isConfirm(e.logicalKey)) { _editVoucher(v); return KeyEventResult.handled; }
                                                if (KeyboardShortcutService.isDown(e.logicalKey)) {
                                                  if (idx + 1 < _rowFocusNodes.length) { _rowFocusNodes[idx + 1].requestFocus(); } else if (_rowFocusNodes.isNotEmpty) { _rowFocusNodes[0].requestFocus(); }
                                                  return KeyEventResult.handled;
                                                }
                                                if (KeyboardShortcutService.isUp(e.logicalKey)) {
                                                  if (idx - 1 >= 0) { _rowFocusNodes[idx - 1].requestFocus(); } else if (_rowFocusNodes.isNotEmpty) { _rowFocusNodes[_rowFocusNodes.length - 1].requestFocus(); }
                                                  return KeyEventResult.handled;
                                                }
                                              }
                                              return KeyEventResult.ignored;
                                            },
                                            child: GestureDetector(
                                              onDoubleTap: () => _editVoucher(v),
                                              onTap: () { setState(() => _focusedIndex = idx); _rowFocusNodes[idx].requestFocus(); },
                                              child: Container(
                                                decoration: BoxDecoration(color: isFocused ? AppColors.primaryLight : (isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.surface), border: isFocused ? Border.all(color: AppColors.primary, width: 1.5) : null, borderRadius: isFocused ? BorderRadius.circular(6) : null),
                                                child: items.isEmpty
                                                    ? Row(
                                                        children: [
                                                          SizedBox(width: 40, child: Center(child: Checkbox(value: isSelected, activeColor: AppColors.primary, onChanged: (val) { setState(() { val == true ? _selectedKeys.add(key) : _selectedKeys.remove(key); }); }))),
                                                          RegisterDataCell('${idx + 1}', width: 45, isMuted: true),
                                                          RegisterDataCell(GstPartyUtils.extractPartyName(fullParty), width: 180, isBold: true),
                                                          RegisterDataCell(gstin, width: 135, color: AppColors.successDark),
                                                          RegisterDataCell(_getPos(gstin, v['isInterState'] == true), width: 140),
                                                          RegisterDataCell((v['voucherNumber'] ?? '').toString(), width: 95, color: AppColors.primary, isBold: true),
                                                          RegisterDataCell((v['date'] ?? '').toString(), width: 90),
                                                          const RegisterDataCell('0.00', width: 70, textAlign: TextAlign.right),
                                                          const RegisterDataCell('Pcs', width: 55, textAlign: TextAlign.center, isMuted: true),
                                                          const RegisterDataCell('', width: 80),
                                                          RegisterDataCell(invoiceTotal, width: 115, textAlign: TextAlign.right, isBold: true),
                                                          const RegisterDataCell('0.00', width: 105, textAlign: TextAlign.right),
                                                          const RegisterDataCell('0%', width: 60, textAlign: TextAlign.right, isMuted: true),
                                                          RegisterDataCell((double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                          RegisterDataCell((double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                          RegisterDataCell((double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                          RegisterDataCell(cessTotal, width: 75, textAlign: TextAlign.right),
                                                          buildActions(),
                                                        ],
                                                      )
                                                    : Column(
                                                        children: List.generate(items.length, (iIdx) {
                                                          final item = items[iIdx];
                                                          return Container(
                                                            color: iIdx > 0 ? AppColors.cardBg : Colors.transparent,
                                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                                            child: Row(
                                                              children: [
                                                                SizedBox(width: 40, child: iIdx == 0 ? Center(child: Checkbox(value: isSelected, activeColor: AppColors.primary, onChanged: (val) { setState(() { val == true ? _selectedKeys.add(key) : _selectedKeys.remove(key); }); })) : null),
                                                                RegisterDataCell(iIdx == 0 ? '${idx + 1}' : '', width: 45, isMuted: true),
                                                                RegisterDataCell(iIdx == 0 ? GstPartyUtils.extractPartyName(fullParty) : '', width: 180, isBold: true),
                                                                RegisterDataCell(iIdx == 0 ? gstin : '', width: 135, color: AppColors.successDark),
                                                                RegisterDataCell(iIdx == 0 ? _getPos(gstin, v['isInterState'] == true) : '', width: 140),
                                                                RegisterDataCell(iIdx == 0 ? (v['voucherNumber'] ?? '').toString() : '', width: 95, color: AppColors.primary, isBold: true),
                                                                RegisterDataCell(iIdx == 0 ? (v['date'] ?? '').toString() : '', width: 90),
                                                                RegisterDataCell((double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 70, textAlign: TextAlign.right),
                                                                RegisterDataCell((item['unit'] ?? 'Pcs').toString(), width: 55, textAlign: TextAlign.center, isMuted: true),
                                                                RegisterDataCell((item['hsn'] ?? '').toString(), width: 80),
                                                                RegisterDataCell(iIdx == 0 ? invoiceTotal : '', width: 115, textAlign: TextAlign.right, isBold: true),
                                                                RegisterDataCell((double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 105, textAlign: TextAlign.right),
                                                                RegisterDataCell('${item['gstRate'] ?? 0}%', width: 60, textAlign: TextAlign.right, isMuted: true),
                                                                RegisterDataCell((double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                                RegisterDataCell((double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                                RegisterDataCell((double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                                                RegisterDataCell(iIdx == 0 ? cessTotal : '', width: 75, textAlign: TextAlign.right),
                                                                iIdx == 0 ? buildActions() : const SizedBox(width: 90),
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                              ),
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
                                width: dynamicWidth, height: 38, decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.borderFocus, width: 1.2))),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40),
                                    const RegisterFooterCell('', width: 45),
                                    const RegisterFooterCell('TOTAL', width: 180, highlight: true),
                                    const RegisterFooterCell('', width: 135),
                                    const RegisterFooterCell('', width: 140),
                                    const RegisterFooterCell('', width: 95),
                                    const RegisterFooterCell('', width: 90),
                                    RegisterFooterCell(_summary.totalQuantity.toStringAsFixed(2), width: 70, textAlign: TextAlign.right),
                                    const RegisterFooterCell('', width: 55),
                                    const RegisterFooterCell('', width: 80),
                                    RegisterFooterCell(_summary.totalInvoiceValue.toStringAsFixed(2), width: 115, textAlign: TextAlign.right, highlight: true),
                                    RegisterFooterCell(_summary.totalTaxable.toStringAsFixed(2), width: 105, textAlign: TextAlign.right),
                                    const RegisterFooterCell('', width: 60),
                                    RegisterFooterCell(_summary.totalIgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                    RegisterFooterCell(_summary.totalCgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                    RegisterFooterCell(_summary.totalSgst.toStringAsFixed(2), width: 85, textAlign: TextAlign.right),
                                    RegisterFooterCell(_summary.totalCess.toStringAsFixed(2), width: 75, textAlign: TextAlign.right),
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
      ),
    );
  }
}