import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../provider/company_provider.dart';

class TopBar extends ConsumerStatefulWidget {
  const TopBar({super.key});

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> {
  bool menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final activeCompany = ref.watch(activeCompanyProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      alignment: Alignment.centerRight,
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOCAL WORKSPACE STATUS BADGE
          if (activeCompany == null)
            _buildBadge(isOnline: false, label: 'No Active Workspace')
          else
            _buildBadge(isOnline: true, label: 'Local Engine Active'),
          const SizedBox(width: 16),

          // PROFILE TRIGGER
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => menuOpen = !menuOpen),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Aruj Bansal',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    menuOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required bool isOnline, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOnline ? AppColors.success : AppColors.warningText,
            ),
          ),
        ],
      ),
    );
  }
}