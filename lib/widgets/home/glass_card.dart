import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ModernGlassCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color glowColor;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ModernGlassCard({
    super.key,
    required this.gradientColors,
    required this.borderColor,
    required this.glowColor,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors.first.withValues(alpha: 0.92),
                  gradientColors.last.withValues(alpha: 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomeCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> badgeGradient;
  final String illustrationAsset;

  const HomeCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeGradient,
    required this.illustrationAsset,
  });

  @override
Widget build(BuildContext context) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: badgeGradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: badgeGradient.last.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary, 
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
      Positioned(
        top: -10,  
        right: -10,
        child: IgnorePointer( 
          child: Image.asset(
            illustrationAsset,
            width: 170,  
            height: 170, 
            fit: BoxFit.contain,
          ),
        ),
      ),
    ],
  );
}
}