import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RecentCompaniesPanel extends StatelessWidget {
  final List<Map<String, dynamic>> companies;

  const RecentCompaniesPanel({
    super.key,
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    final displayCompanies = companies.take(3).toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Recent Companies',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayCompanies.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                'No recent companies yet.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < displayCompanies.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _buildCompanyItem(displayCompanies[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyItem(Map<String, dynamic> company) {
    final folder = company['companyId'] ?? company['folderName'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.business_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  company['companyName'] ?? 'Untitled Company',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${company['city'] ?? ''}, ${company['state'] ?? ''} • $folder',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
}