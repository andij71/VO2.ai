// lib/core/constants.dart

import 'dart:ui';

class PaceColors {
  // Backgrounds
  static const background = Color(0xFF080809);
  static const cardBg = Color.fromRGBO(255, 255, 255, 0.055);
  static const cardBorder = Color.fromRGBO(255, 255, 255, 0.12);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color.fromRGBO(255, 255, 255, 0.45);
  static const textTertiary = Color.fromRGBO(255, 255, 255, 0.35);
  static const textMuted = Color.fromRGBO(255, 255, 255, 0.25);

  // Session types
  static const easy = Color(0xFF6BF0A0);
  static const tempo = Color(0xFFFF8C42);
  static const long = Color(0xFFBF5FFF);
  static const rest = Color.fromRGBO(255, 255, 255, 0.25);
  static const interval = Color(0xFF00E5FF);
}

/// Editorial brand palette — used on the "pre-functional" screens
/// (Disclaimer, Welcome). Matches the public landing page typography
/// and the wordmark asset (`app_logo_full.png`).
///
/// Once the user enters /auth, the dark `PaceColors` palette takes over.
class BrandPalette {
  /// Paper background — matches the cream of `app_logo_full.png`.
  static const paper = Color(0xFFF2EBE0);

  /// Slightly sunken paper for inset cards / scroll panels.
  static const paperSunk = Color(0xFFEDE5D7);

  /// Hairline border on paper (≈ 8% ink).
  static const paperBorder = Color(0x141F1B16);

  /// Primary text on paper.
  static const ink = Color(0xFF1F1B16);

  /// Secondary / supporting text on paper.
  static const muted = Color(0xFF6B6258);

  /// Disabled / fineprint text on paper.
  static const subtle = Color(0xFF9A9388);

  /// Coral accent — used sparingly (logo dot, key word in tagline).
  static const accent = Color(0xFFC96442);
}

class AccentPreset {
  final Color primary;
  final Color glow;
  final Color dim;

  const AccentPreset({
    required this.primary,
    required this.glow,
    required this.dim,
  });

  static const volt = AccentPreset(
    primary: Color(0xFFC8FF00),
    glow: Color.fromRGBO(200, 255, 0, 0.25),
    dim: Color.fromRGBO(200, 255, 0, 0.1),
  );

  static const violet = AccentPreset(
    primary: Color(0xFFBF5FFF),
    glow: Color.fromRGBO(191, 95, 255, 0.25),
    dim: Color.fromRGBO(191, 95, 255, 0.1),
  );

  static const cyan = AccentPreset(
    primary: Color(0xFF00E5FF),
    glow: Color.fromRGBO(0, 229, 255, 0.25),
    dim: Color.fromRGBO(0, 229, 255, 0.1),
  );

  static AccentPreset fromName(String name) => switch (name) {
    'violet' => violet,
    'cyan' => cyan,
    _ => volt,
  };
}

class PaceRadii {
  static const card = 24.0;
  static const button = 16.0;
  static const pill = 99.0;
}

class PaceDurations {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 450);
}
