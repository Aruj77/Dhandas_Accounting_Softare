import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/focus_policy_service.dart';
import '../../services/storage_service.dart';
import '../../services/loading_service.dart';
import '../../services/notification_service.dart';

class AdministrationScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final ValueChanged<Map<String, dynamic>> onCompanyUpdated;

  const AdministrationScreen({
    super.key,
    required this.company,
    required this.onCompanyUpdated,
  });

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen> {
  late String _activeFy;
  late List<String> _allFys;
  final FocusNode _addFyBtnFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _activeFy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();
    _allFys = List<String>.from(widget.company['financialYears'] ?? ['2024-25', '2025-26', '2026-27']);
  }

  @override
  void dispose() {
    _addFyBtnFocusNode.dispose();
    super.dispose();
  }

  Future<void> _changeFy(String newFy) async {
    await LoadingService.wrap(() async {
      setState(() => _activeFy = newFy);
      final updated = Map<String, dynamic>.from(widget.company)..['activeFinancialYear'] = newFy;
      await StorageService.updateCompanyLocally(companyData: updated);
      widget.onCompanyUpdated(updated);

      if (mounted) {
        NotificationService.show(
          context,
          message: 'Switched Active Financial Year to F.Y. $newFy',
          type: NotificationType.success,
        );
      }
    }, message: 'Switching F.Y. to $newFy...');
   }

  void _showAddFyDialog() async {
    await LoadingService.wrap(() async {
      final controller = TextEditingController(text: '2027-28');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Financial Year', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'e.g. 2027-28',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isNotEmpty && !_allFys.contains(val)) {
                  setState(() => _allFys.add(val));
                  final updated = Map<String, dynamic>.from(widget.company)
                    ..['financialYears'] = _allFys
                    ..['activeFinancialYear'] = val;
                  await StorageService.updateCompanyLocally(companyData: updated);
                  widget.onCompanyUpdated(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Add & Activate'),
            ),
          ],
        ),
      );
    }, message: 'Adding Financial Year...');
  }

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.administration,
      nodeMap: {
        FocusFieldNode.firstField: _addFyBtnFocusNode,
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Administration',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage financial periods, accounting parameters, and data partitions.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // FINANCIAL YEAR MANAGEMENT
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Financial Year Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            Text('Select the current accounting year. All transactions will be isolated to this FY.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        focusNode: _addFyBtnFocusNode,
                        onPressed: _showAddFyDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add F.Y.'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _allFys.map((fy) {
                      final isCurrent = _activeFy == fy;
                      return InkWell(
                        onTap: () => _changeFy(fy),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primaryLight : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? AppColors.primary : AppColors.border,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                size: 18,
                                color: isCurrent ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'F.Y. $fy',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}