import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/loading_service.dart';
import '../constants/app_colors.dart';

class GlobalLoadingOverlay extends StatelessWidget {
  final Widget child;

  const GlobalLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<LoadingStatus>(
          valueListenable: LoadingService.statusNotifier,
          builder: (context, status, _) {
            if (!status.isLoading) return const SizedBox.shrink();

            return Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, animValue, _) {
                    return Opacity(
                      opacity: animValue,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 5.0 * animValue,
                          sigmaY: 5.0 * animValue,
                        ),
                        child: Container(
                          color: AppColors.overlayWhite10,
                          alignment: Alignment.center,
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowColor,
                                  blurRadius: 36,
                                  offset: Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadowGlow,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  status.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Please wait a moment',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}