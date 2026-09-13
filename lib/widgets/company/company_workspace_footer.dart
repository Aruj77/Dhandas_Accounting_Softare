import 'package:flutter/material.dart';

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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
        boxShadow: [
          BoxShadow(color: Color(0x06092B60), blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          // LOGO / BUILDING ICON
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF5FF), Color(0xFFDBE9FE)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
            ),
            child: const Icon(Icons.apartment_rounded, color: Color(0xFF0F62FE), size: 22),
          ),
          const SizedBox(width: 14),

          // COMPANY NAME & FOLDER ID
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF101C38)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDCE5F2)),
                    ),
                    child: Text(
                      folderId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('GSTIN: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9A))),
                  Text(
                    gstin,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: gstin == 'Unregistered' ? const Color(0xFF94A3B8) : const Color(0xFF0F62FE),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          // FINANCIAL YEAR BADGE
          InkWell(
            onTap: onChangeFy,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF15803D)),
                  const SizedBox(width: 6),
                  Text(
                    'F.Y. $activeFy',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF15803D)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // BRANDING
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2ECF8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: Color(0xFF0FA75D)),
                SizedBox(width: 6),
                Text(
                  'FinPro Accounting Engine Active',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}