import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/company_model.dart';
import '../../../models/voucher_model.dart';
import '../../../pages/company/voucher/voucher_entry_screen.dart';
import '../../../pages/company/voucher/voucher_list_screen.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/keyboard_shortcut_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';

class VoucherModifyDialog extends StatefulWidget {
  final CompanyModel company;
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
  List<VoucherModel> _vouchers = [];
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
    await LoadingService.wrap(() async {
      final folderPath = widget.company.folderPath;
      final fy = widget.company.activeFinancialYear;

      if (folderPath.isNotEmpty) {
        final rawLoaded = await StorageService.loadVouchers(
          folderPath: folderPath,
          financialYear: fy,
          voucherType: widget.voucherType,
        );

        final loaded = rawLoaded.map(VoucherModel.fromJson).toList();
        final target = widget.voucherType.toLowerCase();
        
        final matching = loaded.where((v) {
          return v.voucherType.toLowerCase() == target ||
              v.voucherType.toLowerCase().contains(target) ||
              target.contains(v.voucherType.toLowerCase());
        }).toList();

        if (mounted) {
          setState(() {
            _vouchers = matching;
            _isLoading = false;
            if (_vouchers.isNotEmpty) {
              _vchNoCtrl.text = _vouchers.last.voucherNumber;
              _vchNoCtrl.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _vchNoCtrl.text.length,
              );
            }
          });
        }
      }
    }, message: 'Loading Vouchers...');
  }

  void _openEditForVoucherNumber(String vchNo) {
    final query = vchNo.trim().toLowerCase();
    final match = _vouchers.where((v) {
      return v.voucherNumber.trim().toLowerCase() == query;
    }).firstOrNull;

    if (match == null) {
      NotificationService.show(
        context,
        message: 'Voucher "$vchNo" not found.',
        type: NotificationType.error,
      );
      return;
    }

    final navigator = Navigator.of(context);
    final onUpdatedCallback = widget.onVoucherUpdated;

    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (ctx) => VoucherEntryScreen(
          company: widget.company,
          voucherType: widget.voucherType,
          voucherToEdit: match, // Pass typed VoucherModel directly
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
    final navigator = Navigator.of(context);
    final onUpdatedCallback = widget.onVoucherUpdated;

    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (ctx) => VoucherListScreen(
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
    return AutoScreenFocus(
      screen: FocusTargetScreen.voucherModifyDialog,
      nodeMap: {
        FocusFieldNode.voucherNumberField: _vchNoFocus,
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Modify ${widget.voucherType}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Voucher No.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  : TextField(
                      controller: _vchNoCtrl,
                      focusNode: _vchNoFocus,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'Enter Voucher Number',
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
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
      ),
    );
  }
}