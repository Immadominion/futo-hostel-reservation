import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Semantic status chip. All-caps, squircle-pill, height 26, weight 700, 12px.
/// Blue = the student's own booking states; green = available/paid; amber =
/// limited; neutral = full/pending; red = cancelled.
enum RoostStatus { available, limited, full, reserved, pending, paid, cancelled }

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.label});

  final RoostStatus status;
  final String? label;

  ({Color fg, Color bg, String text, bool dot}) get _spec => switch (status) {
        RoostStatus.available => (fg: RoostColors.positive, bg: RoostColors.positiveSubtle, text: 'AVAILABLE', dot: true),
        RoostStatus.limited => (fg: RoostColors.warning, bg: RoostColors.warningSubtle, text: 'LIMITED', dot: false),
        RoostStatus.full => (fg: RoostColors.textTertiary, bg: RoostColors.surface2, text: 'FULL', dot: false),
        RoostStatus.reserved => (fg: RoostColors.accent, bg: RoostColors.accentSubtle, text: 'RESERVED', dot: true),
        RoostStatus.pending => (fg: RoostColors.textSecondary, bg: RoostColors.surface2, text: 'PENDING', dot: false),
        RoostStatus.paid => (fg: RoostColors.positive, bg: RoostColors.positiveSubtle, text: 'PAID', dot: false),
        RoostStatus.cancelled => (fg: RoostColors.negative, bg: RoostColors.negativeSubtle, text: 'CANCELLED', dot: false),
      };

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // depend on theme so const instances re-theme on flip
    final s = _spec;
    return Container(
      height: RoostHeights.pill,
      padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.md),
      decoration: ShapeDecoration(
        color: s.bg,
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.pill, cornerSmoothing: 1)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.dot) ...[
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: s.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: RoostSpacing.sm),
          ],
          Text(
            label ?? s.text,
            style: TextStyle(
              color: s.fg, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
