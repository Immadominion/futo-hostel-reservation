import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Circular identity avatar — a raised disc with the person's initials.
/// Avatars are the one place a *circle* is allowed: people read as round.
/// Everything structural (cards, tiles, sheets, buttons) stays squircle.
class RoostAvatar extends StatelessWidget {
  const RoostAvatar({super.key, required this.label, this.size = 48, this.accent = false, this.ring});

  final String label;
  final double size;
  final bool accent;
  final Color? ring;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // depend on theme so const instances re-theme on flip
    final fg = accent ? RoostColors.accent : RoostColors.textPrimary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RoostColors.surface3, RoostColors.surface2],
        ),
        border: Border.all(
          color: accent ? RoostColors.accent.withValues(alpha: 0.5) : RoostColors.borderDefault,
          width: accent ? 1.5 : 1,
        ),
        boxShadow: ring == null ? null : [BoxShadow(color: ring!, blurRadius: 0, spreadRadius: size * 0.05)],
      ),
      child: Text(
        _initials,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.36, letterSpacing: -0.5),
      ),
    );
  }
}
