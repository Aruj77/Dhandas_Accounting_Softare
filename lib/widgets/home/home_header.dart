import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                  children: [
                    TextSpan(text: 'Welcome to '),
                    TextSpan(
                      text: 'Dhandas',
                      style: TextStyle(
                        color: AppColors.primary,
                                             ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your companies, data and settings — all in one place.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '“ ',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 0.9,
              ),
            ),
            Text(
              'Good accounting is the foundation\nof a better tomorrow.”',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}