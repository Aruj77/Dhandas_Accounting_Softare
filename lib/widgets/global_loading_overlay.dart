import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/loading_service.dart';

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
                          color: const Color(0x350A1329),
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
                                color: const Color(0xFFDCE6F5),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1E0D1B3E),
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
                                        Color(0xFF2E7CF6),
                                        Color(0xFF0F62FE),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x350F62FE),
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
                                    color: Color(0xFF0F1B38),
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
                                    color: Color(0xFF6B7B9A),
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