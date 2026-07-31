import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../demo/hostel_data.dart';
import '../theme/tokens.dart';
import 'status_pill.dart';

/// The hostel browse card. An on-brand gradient cover (seeded per hostel) with
/// a building glyph + funder/status chips, over a white label block with the
/// name, gender · room size, and price. Looks designed, never like a missing
/// image — and a real photo can drop straight into the cover later.
class HostelCard extends StatelessWidget {
  const HostelCard({super.key, required this.hostel, this.onTap});

  final Hostel hostel;
  final VoidCallback? onTap;

  static const _shape = SmoothRectangleBorder(
    borderRadius: SmoothBorderRadius.all(
      SmoothRadius(cornerRadius: RoostRadius.lg, cornerSmoothing: RoostRadius.squircleSmoothing),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: ShapeDecoration(
          color: RoostColors.surface1,
          shape: _shape,
          shadows: RoostShadows.card,
        ),
        foregroundDecoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            side: BorderSide(color: RoostColors.borderSubtle, width: 0.5),
            borderRadius: const SmoothBorderRadius.all(
              SmoothRadius(cornerRadius: RoostRadius.lg, cornerSmoothing: RoostRadius.squircleSmoothing),
            ),
          ),
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: _shape),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cover(),
              Padding(
                padding: const EdgeInsets.all(RoostSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hostel.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text('${hostel.gender.label}  ·  ${hostel.roomSize}',
                              style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(hostel.priceFull,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RoostColors.accent, letterSpacing: -0.3)),
                        Text('per session', style: TextStyle(fontSize: 11, color: RoostColors.textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    return SizedBox(
      height: 124,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(hostel.coverA), Color(hostel.coverB)],
              ),
            ),
          ),
          // soft highlight for depth
          const Positioned(
            top: -40, right: -30,
            child: _Glow(),
          ),
          Center(
            child: Icon(PhosphorIcons.buildings(), size: 52, color: Colors.white.withValues(alpha: 0.92)),
          ),
          Positioned(
            left: RoostSpacing.md, top: RoostSpacing.md,
            child: _FunderChip(hostel.funder),
          ),
          Positioned(
            right: RoostSpacing.md, top: RoostSpacing.md,
            child: StatusPill(hostel.status),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)]),
      ),
    );
  }
}

class _FunderChip extends StatelessWidget {
  const _FunderChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.pill, cornerSmoothing: 1)),
        ),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
    );
  }
}
