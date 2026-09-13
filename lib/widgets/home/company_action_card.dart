import 'package:flutter/material.dart';
import '../action_button.dart';
import 'glass_card.dart';

class CompanyActionCard extends StatelessWidget {
  final VoidCallback onOpenCompany;
  final VoidCallback onCreateCompany;

  const CompanyActionCard({
    super.key,
    required this.onOpenCompany,
    required this.onCreateCompany,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      gradientColors: const [
        Color(0xFFEFF5FF),
        Color(0xFFDCEBFF),
      ],
      borderColor: const Color(0xFFC3DCFF),
      glowColor: const Color(0x180F62FE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.apartment_rounded,
            title: 'Company',
            subtitle: 'Create a new business or access an existing one',
            badgeGradient: [
              Color(0xFF4C93F5),
              Color(0xFF0F62FE),
            ],
            illustrationAsset: 'assets/images/company_illustration.png',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.folder_open_rounded,
                  title: 'Open Company',
                  subtitle: 'Open an existing workspace',
                  iconColor: const Color(0xFF0F62FE),
                  iconBackground: const Color(0xFFE5EFFF),
                  onTap: onOpenCompany,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Create Company',
                  subtitle: 'Set up a new organization',
                  iconColor: const Color(0xFF0FA75D),
                  iconBackground: const Color(0xFFE2F8ED),
                  onTap: onCreateCompany,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}