import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CompanyWorkspaceFooter extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onChangeFy;

  const CompanyWorkspaceFooter({
    super.key,
    required this.company,
    this.onChangeFy,
  });

  @override
  Widget build(BuildContext context) {
    final companyName = (company['companyName'] ?? 'Untitled Company').toString();
    final gstin = (company['gstin'] != null && company['gstin'].toString().isNotEmpty)
        ? company['gstin'].toString()
        : 'Unregistered';
    final folderId = (company['companyId'] ?? company['folderName'] ?? 'FIN-0001').toString();
    final activeFy = (company['activeFinancialYear'] ?? '2026-27').toString();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.brandBadgeGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderFocus, width: 1.2),
            ),
            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      folderId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('GSTIN: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text(
                    gstin,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: gstin == 'Unregistered' ? AppColors.textMuted : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          InkWell(
            onTap: onChangeFy,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 16, color: AppColors.successDark),
                  const SizedBox(width: 6),
                  Text(
                    'F.Y. $activeFy',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.successDark),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.successDark),
                ],
              ),
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Dhandas Accounting Engine Active',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}