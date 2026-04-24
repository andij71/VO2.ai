// lib/core/theme.dart

import 'package:flutter/material.dart';
import 'constants.dart';

class PaceTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PaceColors.background,
      fontFamily: '.SF Pro Display',
      colorScheme: const ColorScheme.dark(
        surface: PaceColors.background,
        primary: Color(0xFFC8FF00),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: PaceColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PaceColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PaceColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: PaceColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: PaceColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: PaceColors.textTertiary,
        ),
      ),
    );
  }
}
