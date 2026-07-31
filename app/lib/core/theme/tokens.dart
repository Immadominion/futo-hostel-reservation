/// Roost design tokens — the single source of truth for colour, type, radius,
/// spacing and motion. Built on our in-house design system and rebranded to
/// FUTO **royal blue**: white surfaces + one blue accent, with green reserved
/// for "available / paid", amber for "limited", red for "full / cancelled".
library;

import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// An immutable colour set. Two exist — [_light] (default) and [_dark] — and
/// exactly one is active at a time (see [RoostColors]). Field names match across
/// both so every widget reads `RoostColors.surface1` etc. and re-themes for free.
class RoostPalette {
  const RoostPalette({
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.surfaceInput,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentSubtle,
    required this.positive,
    required this.positiveSubtle,
    required this.negative,
    required this.negativeSubtle,
    required this.warning,
    required this.warningSubtle,
  });

  final Color surface0, surface1, surface2, surface3, surfaceInput;
  final Color borderSubtle, borderDefault, borderStrong;
  final Color textPrimary, textSecondary, textTertiary, textDisabled;
  final Color accent, accentSubtle;
  final Color positive, positiveSubtle, negative, negativeSubtle, warning, warningSubtle;
}

/// Light: white + one royal blue. The default.
const RoostPalette _light = RoostPalette(
  surface0: Color(0xFFF4F4F4), // page canvas (very light grey)
  surface1: Color(0xFFFFFFFF), // cards
  surface2: Color(0xFFF9FAFB), // nested / elevated
  surface3: Color(0xFFFFFFFF), // highest
  surfaceInput: Color(0xFFF3F4F6),
  borderSubtle: Color(0xFFF0F1F3),
  borderDefault: Color(0xFFE5E7EB),
  borderStrong: Color(0xFFD1D5DB),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF6B7280),
  textTertiary: Color(0xFF9CA3AF),
  textDisabled: Color(0xFFD1D5DB),
  accent: Color(0xFF2563EB), // FUTO royal blue
  accentSubtle: Color(0xFFDBEAFE),
  positive: Color(0xFF059669), // available / paid
  positiveSubtle: Color(0xFFD1FAE5),
  negative: Color(0xFFDC2626), // full / cancelled / error
  negativeSubtle: Color(0xFFFEE2E2),
  warning: Color(0xFFD97706), // limited
  warningSubtle: Color(0xFFFEF3C7),
);

/// Dark: near-black canvas with the bright blue accent.
const RoostPalette _dark = RoostPalette(
  surface0: Color(0xFF0A0A0A),
  surface1: Color(0xFF141414),
  surface2: Color(0xFF1E1E1E),
  surface3: Color(0xFF2A2A2A),
  surfaceInput: Color(0xFF1A1A1A),
  borderSubtle: Color(0xFF1E1E1E),
  borderDefault: Color(0xFF2E2E2E),
  borderStrong: Color(0xFF3E3E3E),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFA1A1AA),
  textTertiary: Color(0xFF52525B),
  textDisabled: Color(0xFF3F3F46),
  accent: Color(0xFF3B82F6),
  accentSubtle: Color(0xFF1E3A5F),
  positive: Color(0xFF22C55E),
  positiveSubtle: Color(0xFF14532D),
  negative: Color(0xFFEF4444),
  negativeSubtle: Color(0xFF450A0A),
  warning: Color(0xFFF59E0B),
  warningSubtle: Color(0xFF1C1400),
);

/// The semantic colour API every widget reads. Backed by a single active
/// [RoostPalette] that [setBrightness] swaps; rebuild the app afterwards and
/// every getter resolves to the new mode. Defaults to **light**.
///
/// Because these are getters (not `const`), colour-bearing widgets can't be
/// `const` — the deliberate trade for a live light/dark toggle.
class RoostColors {
  RoostColors._();

  static RoostPalette _active = _light;
  static Brightness get brightness => _active == _light ? Brightness.light : Brightness.dark;
  static bool get isLight => _active == _light;
  static void setBrightness(Brightness b) => _active = b == Brightness.light ? _light : _dark;

  /// Content that sits on the bright blue accent / gradient (CTA text, header
  /// icons). White reads cleanly on royal blue in both themes.
  static const Color onAccent = Color(0xFFFFFFFF);

  static Color get surface0 => _active.surface0;
  static Color get surface1 => _active.surface1;
  static Color get surface2 => _active.surface2;
  static Color get surface3 => _active.surface3;
  static Color get surfaceInput => _active.surfaceInput;
  static Color get borderSubtle => _active.borderSubtle;
  static Color get borderDefault => _active.borderDefault;
  static Color get borderStrong => _active.borderStrong;
  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get textTertiary => _active.textTertiary;
  static Color get textDisabled => _active.textDisabled;
  static Color get accent => _active.accent;
  static Color get accentSubtle => _active.accentSubtle;
  static Color get positive => _active.positive;
  static Color get positiveSubtle => _active.positiveSubtle;
  static Color get negative => _active.negative;
  static Color get negativeSubtle => _active.negativeSubtle;
  static Color get warning => _active.warning;
  static Color get warningSubtle => _active.warningSubtle;
}

class RoostRadius {
  static const double none = 0;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32; // floating sheets, hero cards
  static const double pill = 999;
  static const double squircleSmoothing = 0.6;
}

/// Gradients — a gradient CTA and a gradient sheet header, kept inside the
/// single blue accent (a gentle lightening of blue, never a second hue).
class RoostGradients {
  /// Diagonal fill for the primary CTA.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  /// Vertical fill for the signature wavy sheet header.
  static const LinearGradient accentHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
  );

  /// Calm neutral header for utility sheets (settings, filters) so the blue
  /// accent stays reserved for the confirming moments.
  static LinearGradient get graphiteHeader => RoostColors.isLight
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F4F6), Color(0xFFE6E8EB)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        );
}

/// Soft, even shadows — on white they hug the card's corners (the "float"
/// look); on the dark canvas they read as a faint deepening. The one hero
/// element per screen may add the blue [accentGlow].
class RoostShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14111827), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14111827), blurRadius: 28, offset: Offset(0, 8), spreadRadius: -4),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(color: Color(0x262563EB), blurRadius: 40, offset: Offset(0, 14), spreadRadius: -10),
  ];

  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 44, offset: Offset(0, 14), spreadRadius: -4),
  ];

  static const List<BoxShadow> ctaGlow = [
    BoxShadow(color: Color(0x332563EB), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -6),
  ];
}

class RoostSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class RoostHeights {
  static const double button = 52;
  static const double input = 52;
  static const double listRow = 68;
  static const double pill = 26;
}

class RoostMotion {
  static const Duration page = Duration(milliseconds: 280);
  static const Duration modalEnter = Duration(milliseconds: 240);
  static const Duration modalExit = Duration(milliseconds: 180);
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration celebration = Duration(milliseconds: 600);
}
