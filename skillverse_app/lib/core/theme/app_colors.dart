import 'package:flutter/material.dart';

/// Single source of truth for SkillVerse colors.
/// Values are unchanged from the approved UI — do not alter.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF17181A);
  static const Color surfaceElevated = Color(0xFF1F2022);
  static const Color surfaceSunken = Color(0xFF131415);

  static const Color primary = Color(0xFF00E676);
  static const Color primaryDark = Color(0xFF00B85C);

  static const Color gold = Color(0xFFFFC107);
  static const Color blue = Color(0xFF42A5F5);
  static const Color orange = Color(0xFFFF7043);

  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color error = Color(0xFFFF5252);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
