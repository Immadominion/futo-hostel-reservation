import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Roost's `ThemeData`. Defaults to **light** (white + royal blue); a dark
/// variant is swapped at runtime via [RoostColors.setBrightness] + the settings
/// toggle. [build] must be called *after* `setBrightness` so the text theme
/// picks up the right ink colour.
class RoostTheme {
  static ThemeData build(Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness, fontFamily: 'Montserrat');
    final scheme = ColorScheme(
      brightness: brightness,
      primary: RoostColors.accent,
      onPrimary: RoostColors.onAccent,
      secondary: RoostColors.positive,
      onSecondary: RoostColors.surface1,
      surface: RoostColors.surface1,
      onSurface: RoostColors.textPrimary,
      error: RoostColors.negative,
      onError: RoostColors.surface1,
    );
    return base.copyWith(
      scaffoldBackgroundColor: RoostColors.surface0,
      colorScheme: scheme,
      textTheme: _buildTextTheme(base.textTheme),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    const family = 'Montserrat'; // bundled in assets/fonts
    return base
        .copyWith(
          displayLarge: TextStyle(
            fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -2.16,
            color: RoostColors.textPrimary, height: 1.0,
          ),
          headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.64,
            color: RoostColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.24,
            color: RoostColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600,
            color: RoostColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w400,
            color: RoostColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w400,
            color: RoostColors.textSecondary,
          ),
          labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.12,
            color: RoostColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.30,
            color: RoostColors.textTertiary,
          ),
        )
        .apply(fontFamily: family);
  }
}
