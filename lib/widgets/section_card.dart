import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final Color firstColor;
  final Color secondColor;
  final Color borderColor;

  const SectionCard({
    super.key,
    required this.child,
    required this.firstColor,
    required this.secondColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            firstColor,
            secondColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}