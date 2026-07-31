import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A hostel's square mark — a squircle tile with the block's short code
/// (e.g. "A", "ND", "TF", "PG"). A hostel is a *thing*, not a person, so it
/// gets a squircle, not a circle. Pass [accent] for the selected one.
class HostelGlyph extends StatelessWidget {
  const HostelGlyph({super.key, required this.code, this.size = 44, this.accent = false});

  final String code;
  final double size;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // depend on theme so const instances re-theme on flip
    final glyph = code.characters.take(2).toString().toUpperCase();
    final fg = accent ? RoostColors.accent : RoostColors.textPrimary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RoostColors.surface3, RoostColors.surface2],
        ),
        shape: SmoothRectangleBorder(
          side: BorderSide(
            color: accent ? RoostColors.accent.withValues(alpha: 0.5) : RoostColors.borderDefault,
            width: accent ? 1.5 : 1,
          ),
          borderRadius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: RoostRadius.sm, cornerSmoothing: RoostRadius.squircleSmoothing),
          ),
        ),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          color: fg, fontWeight: FontWeight.w800, fontSize: size * 0.30, letterSpacing: -0.3,
        ),
      ),
    );
  }
}
