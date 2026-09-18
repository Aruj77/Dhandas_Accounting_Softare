import 'package:flutter/material.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/storage_service.dart';
import '../../../pages/company/voucher/voucher_entry_screen.dart';
import '../../../pages/company/voucher/voucher_manage_list_screen.dart';

class VoucherModifyDialog extends StatefulWidget {
  final Map<String, dynamic> company;
  final String voucherType;
  final VoidCallback onVoucherUpdated;

  const VoucherModifyDialog({
    super.key,
    required this.company,
    required this.voucherType,
    required this.onVoucherUpdated,
  });

  @override
  State<VoucherModifyDialog> createState() => _VoucherModifyDialogState();
}

class _VoucherModifyDialogState extends State<VoucherModifyDialog> {
  final TextEditingController _vchNoCtrl = TextEditingController();
  final FocusNode _vchNoFocus = FocusNode();
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _vchNoCtrl.dispose();
    _vchNoFocus.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    final folderPath = widget.company['folderPath']?.toString();
    final fy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

    if (folderPath != null) {
      final loaded = await StorageService.loadVouchers(
        folderPath: folderPath,
        financialYear: fy,
        voucherType: widget.voucherType,
      );

      final matching = loaded.where((v) {
        return (v['voucherType'] ?? '').toString().toLowerCase() ==
            widget.voucherType.toLowerCase();
      }).toList();

      if (mounted) {
        setState(() {
          _vouchers = matching;
          _isLoading = false;
          if (_vouchers.isNotEmpty) {
            _vchNoCtrl.text = (_vouchers.last['voucherNumber'] ?? '').toString();
            _vchNoCtrl.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _vchNoCtrl.text.length,
            );
          }
        });
      }
    }
  }

  void _openEditForVoucherNumber(String vchNo) {
    final query = vchNo.trim().toLowerCase();
    final match = _vouchers.where((v) {
      return (v['voucherNumber'] ?? '').toString().trim().toLowerCase() == query;
    }).firstOrNull;

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher "$vchNo" not found.'),
          backgroundColor: const Color(0xFFEE4343),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Capture parent navigator BEFORE popping dialog
    final navigator = Navigator.of(context);
    final onUpdatedCallback = widget.onVoucherUpdated;

    navigator.pop(); // Close modify dialog

    navigator.push(
      MaterialPageRoute(
        builder: (ctx) => VoucherEntryScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          voucherToEdit: match,
          isEdit: true,
          keyboardSettings: KeyboardShortcutSettings.defaults(),
          onClose: () {
            Navigator.of(ctx).pop();
            onUpdatedCallback();
          },
        ),
      ),
    );
  }

  void _openManageList() {
    // Capture parent navigator BEFORE popping dialog
    final navigator = Navigator.of(context);
    final onUpdatedCallback = widget.onVoucherUpdated;

    navigator.pop(); // Close modify dialog

    navigator.push(
      MaterialPageRoute(
        builder: (ctx) => VoucherManageListScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          onClose: () {
            Navigator.of(ctx).pop();
            onUpdatedCallback();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F62FE), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Modify ${widget.voucherType}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101C38)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Voucher No.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                : TextField(
                    controller: _vchNoCtrl,
                    focusNode: _vchNoFocus,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Enter Voucher Number',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2EAF5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) => _openEditForVoucherNumber(val),
                  ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openManageList,
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: const Text('List', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F62FE),
                      side: const BorderSide(color: Color(0xFF0F62FE)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openEditForVoucherNumber(_vchNoCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}