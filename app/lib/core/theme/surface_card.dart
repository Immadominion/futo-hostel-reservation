import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// The single sanctioned card primitive. A white squircle that lifts off the
/// canvas via a higher surface tier, a hairline border, and — for the one hero
/// card per screen — a faint blue glow.
class RoostSurfaceCard extends StatelessWidget {
  const RoostSurfaceCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.floating = false,
    this.glow = false,
    this.radius = RoostRadius.lg,
    this.padding = const EdgeInsets.all(RoostSpacing.xl),
    this.border = true,
    this.color,
    this.onTap,
  });

  final Widget child;

  /// Use the Level-2 surface (nested cards, active states).
  final bool elevated;

  /// Lift the card off the canvas with a soft drop shadow.
  final bool floating;

  /// Add the blue "confirmed" glow — at most one per screen.
  final bool glow;

  final double radius;
  final EdgeInsetsGeometry padding;
  final bool border;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shadows = <BoxShadow>[
      if (floating) ...RoostShadows.card,
      if (glow) ...RoostShadows.accentGlow,
    ];

    final card = Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: color ?? (elevated ? RoostColors.surface2 : RoostColors.surface1),
        shadows: shadows.isEmpty ? null : shadows,
        shape: SmoothRectangleBorder(
          side: border
              ? BorderSide(
                  color: glow
                      ? RoostColors.accent.withValues(alpha: 0.22)
                      : RoostColors.borderSubtle,
                  width: glow ? 1 : 0.5,
                )
              : BorderSide.none,
          borderRadius: SmoothBorderRadius(
            cornerRadius: radius,
            cornerSmoothing: RoostRadius.squircleSmoothing,
          ),
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}
