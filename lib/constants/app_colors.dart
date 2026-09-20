import 'package:flutter/material.dart';

class AppColors {
  // Brand & Primaries
  static const Color primary = Color(0xFF0F62FE);
  static const Color primaryDark = Color(0xFF101B3A);
  static const Color primaryLight = Color(0xFFEFF6FE);
  static const Color primarySemiLight = Color(0xFFA5CFE7);
  static const Color primaryAccent = Color(0xFF2563EB);

  // Success Greens
  static const Color success = Color(0xFF10A35B);
  static const Color successDark = Color(0xFF15803D);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  // Errors & Danger
  static const Color error = Color(0xFFEE4343);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);

  // Warning & Amber/Orange
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEF);
  static const Color warningBorder = Color(0xFFFED7AA);

  // Violet & Purples
  static const Color purple = Color(0xFF7034E6);
  static const Color purpleLight = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFE9D5FF);

  // Cyan & Teals (Registers, Indicators, Accents)
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Neutrals, Surfaces & Backgrounds
  static const Color background = Color(0xFFF1F5FB);
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFF8FAFD);
  static const Color border = Color(0xFFE2EAF5);
  static const Color borderLight = Color(0xFFF1F5FB);
  static const Color borderFocus = Color(0xFFD6E3F4);

  // Typography Tokens
  static const Color textPrimary = Color(0xFF101B38);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF90A1BA);

  // Specialized Voucher Entry Background Tints
  static const Color salesScreenBg = Color(0xFFFFF1D1);
  static const Color salesTopBarBg = Color(0xFFFFE8A9);
  static const Color generalScreenBg = Color(0xFFCEE7FF);
  static const Color generalTopBarBg = Color(0xFFEFF6FF);

  // Translucent Overlays & Badge Colors (for Dark Mode parity)
  static const Color overlayWhite10 = Color(0x1AFFFFFF);
  static const Color overlayWhite20 = Color(0x33FFFFFF);
  static const Color overlayWhite40 = Color(0x66FFFFFF);

  // Shadows
  static const Color shadowColor = Color(0x080F172A);
  static const Color shadowGlow = Color(0x386366F1);

  // Button Gradients
  static const LinearGradient aiScanGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Specific Directory & Accent Helpers
  static const Color folderAmberLight = Color(0xFFFBB323);
  static const Color folderAmber = Color(0xFFEB9500);
  static const Color folderShadow = Color(0x35F39E00);
  static const Color warningText = Color(0xFF7A5813);

  static const LinearGradient folderGradient = LinearGradient(
    colors: [folderAmberLight, folderAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral Tints & Hover States
  static const Color navHover = Color(0xFFF0F5FC);
  static const Color navHoverLight = Color(0xFFF6F9FE);
  static const Color borderSubtle = Color(0xFFD6E4FA);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Gradient Helpers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C7BF6), primary],
  );

  static const LinearGradient navSelectedGradient = LinearGradient(
    colors: [Color(0xFFE9F2FE), Color(0xFFF3F7FF)],
  );

  static const LinearGradient brandBadgeGradient = LinearGradient(
    colors: [Color(0xFFEFF5FF), Color(0xFFDBE9FE)],
  );

  static const LinearGradient companyGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF5FF), Color(0xFFDCEBFF)],
  );

  // Dialog Gradients & Glow Overlays
  static const Color dialogBgStart = Color(0xFFEBF2FD);
  static const Color dialogBgMiddle = Color(0xFFF7F9FD);
  static const Color badgeBlueFill = Color(0xD9DCEAFE);
  static const Color badgeYellowBg = Color(0xFFFEF3C7);
  static const Color badgeYellowBorder = Color(0xFFFDE68A);
  static const Color badgeYellowText = Color(0xFFB45309);

  // Banner & Warm Highlights
  static const Color bannerYellowStart = Color(0xFFFFFDF8);
  static const Color bannerYellowEnd = Color(0xFFFFF8EA);
  static const Color bannerYellowBorder = Color(0xFFFFE39E);
  static const Color bannerYellowShadow = Color(0x10E69800);
  static const Color bannerChevron = Color(0xFF3B4A6A);

  // Status & Badges
  static const Color statusWarningText = Color(0xFFB45309);

  // Calculator Display & Keypad
  static const Color calcKeypadBg = Color(0xFF101B3A);
  static const Color calcDisplayBg = Color(0xFF1E293B);
  static const Color calcKeyNumBg = Color(0xFF1E293B);
  static const Color calcKeyActionBg = Color(0xFF27354F);
  static const Color calcKeyOpBg = Color(0xFF2C3E5D);
  static const Color calcKeyOpFg = Color(0xFF60A5FA);

  // PDF Preview Palette
  static const Color pdfDarkText = Color(0xFF0F172A);
  static const Color pdfBodyText = Color(0xFF1E293B);
  static const Color pdfSlateText = Color(0xFF334155);
  static const Color pdfMutedText = Color(0xFF475569);
  static const Color pdfLightBorder = Color(0xFFCBD5E1);
  static const Color pdfLightBg = Color(0xFFF8FAFC);
  static const Color pdfRowAlt = Color(0xFFFAFAFC);

  // Dialog Elements & Accents
  static const Color dialogShadowLight = Color(0x33092B60);
  static const Color dialogShadowGlow = Color(0x552563EB);
  static const Color borderSubtleAlt = Color(0xFFD6E4FA);
  static const Color textDarkBlue = Color(0xFF274375);
}