import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../provider/company_provider.dart';
import '../../services/gstr2b_reconciliation_service.dart';
import '../../services/storage_service.dart';
import '../../utils/extensions.dart';

class Gstr2bReconciliationScreen extends ConsumerStatefulWidget {
  const Gstr2bReconciliationScreen({super.key});

  @override
  ConsumerState<Gstr2bReconciliationScreen> createState() =>
      _Gstr2bReconciliationScreenState();
}

class _Gstr2bReconciliationScreenState
    extends ConsumerState<Gstr2bReconciliationScreen> {
  bool _isAnalyzing = false;
  ReconciliationResult? _result;
  String? _fileName;

  Future<void> _pickAndReconcile() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select GSTR-2B JSON Export',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null || picked.files.single.path == null) return;

    setState(() {
      _isAnalyzing = true;
      _fileName = picked.files.single.name;
    });

    try {
      final file = File(picked.files.single.path!);
      final content = await file.readAsString();

      final activeCompany = ref.read(activeCompanyProvider);
      if (activeCompany == null) {
        throw Exception('No active company workspace selected.');
      }

      final folderPath = (activeCompany['folderPath'] ?? '').toString();
      final fy = (activeCompany['activeFinancialYear'] ?? '2026-27').toString();

      // Load purchase vouchers through StorageService to query partitioned series databases
      // and avoid multiple database instantiation conflicts
      final localPurchases = await StorageService.loadVouchers(
        folderPath: folderPath,
        financialYear: fy,
        voucherType: 'purchase',
      );

      final res = await Gstr2bReconciliationService.reconcile(
        localPurchases: localPurchases,
        gstr2bJsonString: content,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconciliation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GSTR-2B & IMS Intelligent Matching',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Automated Input Tax Credit (ITC) audit and vendor mismatch detection',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _pickAndReconcile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  _fileName != null
                      ? 'Change File ($_fileName)'
                      : 'Upload GSTR-2B JSON',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isAnalyzing)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_result == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rule_folder_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No GSTR-2B file uploaded yet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload your monthly GSTR-2B JSON download to auto-audit tax credits and IMS actions.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMetricCard(
                        'Portal Invoices',
                        '${_result!.totalPortalInvoices}',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Fully Matched',
                        '${_result!.matchedCount}',
                        AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Value Mismatches',
                        '${_result!.mismatchedCount}',
                        AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Missing in Books',
                        '${_result!.missingInBooksCount}',
                        AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'Missing in Portal (IMS)',
                        '${_result!.missingInPortalCount}',
                        AppColors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Audit Discrepancies & Action Items',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _result!.discrepancies.isEmpty
                          ? const Center(
                              child: Text(
                                'All purchase invoices match perfectly with GSTR-2B portal data!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _result!.discrepancies.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final item = _result!.discrepancies[index];
                                final issue = item['issue'].toString();
                                final isMissingBooks =
                                    issue.contains('Missing in Local Books');
                                final isMissingPortal =
                                    issue.contains('GSTR-2B Portal');

                                Color badgeColor = AppColors.warningLight;
                                Color textColor = AppColors.warning;
                                IconData badgeIcon = Icons.difference_rounded;

                                if (isMissingBooks) {
                                  badgeColor = AppColors.errorLight;
                                  textColor = AppColors.error;
                                  badgeIcon = Icons.warning_amber_rounded;
                                } else if (isMissingPortal) {
                                  badgeColor = AppColors.purpleLight;
                                  textColor = AppColors.purple;
                                  badgeIcon = Icons.cloud_off_rounded;
                                }

                                final portalVal = (item['portalValue'] as num?)?.toDouble() ?? 0.0;
                                final localVal = (item['localValue'] as num?)?.toDouble() ?? 0.0;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: badgeColor,
                                    child: Icon(
                                      badgeIcon,
                                      color: textColor,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    'Invoice #${item['invoiceNo']} (GSTIN: ${item['gstin']})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Issue: $issue',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Portal: ${portalVal.toINR()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Books: ${localVal.toINR()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}