import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RegisterHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;

  const RegisterHeaderCell(
    this.text, {
    super.key,
    required this.width,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class RegisterDataCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;
  final bool isBold;
  final bool isMuted;
  final Color? color;

  const RegisterDataCell(
    this.text, {
    super.key,
    required this.width,
    this.textAlign = TextAlign.left,
    this.isBold = false,
    this.isMuted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? (isMuted ? AppColors.textMuted : const Color(0xFF1E293B)),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class RegisterFooterCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign textAlign;
  final bool highlight;

  const RegisterFooterCell(
    this.text, {
    super.key,
    required this.width,
    this.textAlign = TextAlign.left,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: highlight ? AppColors.primary : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}