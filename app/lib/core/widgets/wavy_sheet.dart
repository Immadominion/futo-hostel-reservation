import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The product's signature surface — a floating sheet whose coloured header
/// dips into the content with a scalloped wave edge. The white content waves
/// up into the accent band. Floats (side margins + big squircle + shadow),
/// never pinned flush to the edge.
class RoostWavySheet extends StatelessWidget {
  const RoostWavySheet({
    super.key,
    required this.header,
    required this.child,
    this.headerHeight = 168,
    this.headerGradient = RoostGradients.accentHeader,
    this.headerForeground = RoostColors.onAccent,
  });

  final Widget header;
  final Widget child;
  final double headerHeight;
  final Gradient headerGradient;
  final Color headerForeground;

  static const _shape = SmoothRectangleBorder(
    borderRadius: SmoothBorderRadius.all(
      SmoothRadius(cornerRadius: RoostRadius.xl, cornerSmoothing: RoostRadius.squircleSmoothing),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: ShapeDecoration(
          color: RoostColors.surface1,
          shape: _shape,
          shadows: RoostShadows.sheet,
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: _shape),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: headerHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(decoration: BoxDecoration(gradient: headerGradient)),
                    ),
                    Positioned(
                      left: 0, right: 0, bottom: -1,
                      child: SizedBox(
                        height: 46,
                        child: CustomPaint(painter: _WavePainter(RoostColors.surface1)),
                      ),
                    ),
                    Positioned(
                      top: 12, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: headerForeground.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Center(child: header),
                    ),
                  ],
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 9; // scallops across the width
    const amp = 6.0;
    const topY = 18.0;
    final seg = size.width / n;
    final path = Path()..moveTo(0, topY);
    for (var i = 0; i < n; i++) {
      final ex = (i + 1) * seg;
      final mx = i * seg + seg / 2;
      final cy = i.isEven ? topY - amp : topY + amp;
      path.quadraticBezierTo(mx, cy, ex, topY);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.color != color;
}

/// Present a [RoostWavySheet] as a floating modal: side margins, barrier dim,
/// slide-up + fade in. Content the caller passes manages its own scrolling.
Future<T?> showRoostWavySheet<T>({
  required BuildContext context,
  required Widget header,
  required Widget child,
  double headerHeight = 168,
  Gradient headerGradient = RoostGradients.accentHeader,
  Color headerForeground = RoostColors.onAccent,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'sheet',
    barrierColor: const Color(0x73000000),
    transitionDuration: RoostMotion.modalEnter,
    pageBuilder: (ctx, _, _) {
      return Align(
        alignment: Alignment.bottomCenter,
        // Builder so viewInsets is read reactively: when a field is focused the
        // sheet lifts above the keyboard and caps its height to the space left,
        // instead of the keyboard covering the content.
        child: Builder(
          builder: (ctx) {
            final mq = MediaQuery.of(ctx);
            final keyboard = mq.viewInsets.bottom;
            final maxH = (mq.size.height - keyboard) * 0.92;
            return Padding(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: 14 + keyboard),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: RoostWavySheet(
                    headerHeight: headerHeight,
                    headerGradient: headerGradient,
                    headerForeground: headerForeground,
                    header: header,
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutQuart);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
