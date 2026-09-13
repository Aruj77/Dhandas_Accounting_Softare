import 'package:flutter/material.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08092B60),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Icon(
                Icons.access_time_rounded,
                color: Color(0xFF0F62FE),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Recent Companies',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101C3A),
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
                  color: Color(0xFF8695AF),
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
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.business_rounded,
            color: Color(0xFF0F62FE),
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
                    color: Color(0xFF111D3B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${company['city'] ?? ''}, ${company['state'] ?? ''} • $folder',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7585A2),
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