import 'package:flutter/material.dart';
import 'glass_card.dart';

class DataActionCard extends StatelessWidget {
  final VoidCallback? onBackupData;
  final VoidCallback? onRestoreData;

  const DataActionCard({
    super.key,
    this.onBackupData,
    this.onRestoreData,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      gradientColors: const [
        Color(0xFFF6F0FF),
        Color(0xFFE9DAFF),
      ],
      borderColor: const Color(0xFFDCC8FF),
      glowColor: const Color(0x187034E6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HomeCardHeader(
            icon: Icons.dns_rounded,
            title: 'Data',
            subtitle: 'Backup and restore your local databases',
            badgeGradient: [
              Color(0xFF9065FD),
              Color(0xFF6732E6),
            ],
            illustrationAsset: 'assets/images/data_illustration.png',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GradientDataAction(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Backup Data',
                  subtitle: 'Export backup archives',
                  iconGradient: const [
                    Color(0xFF8E62FA),
                    Color(0xFF6732E6),
                  ],
                  onTap: onBackupData ?? () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GradientDataAction(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Restore Data',
                  subtitle: 'Load from a backup file',
                  iconGradient: const [
                    Color(0xFF8E62FA),
                    Color(0xFF6732E6),
                  ],
                  onTap: onRestoreData ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientDataAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> iconGradient;
  final VoidCallback onTap;

  const _GradientDataAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE9DCFF),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C190637),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.last.withOpacity(0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101C3A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7B9B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5A6C8C),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}