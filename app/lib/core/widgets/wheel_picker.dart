import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// An iOS-style snapping wheel list with a centred highlight band and a
/// top/bottom fade so rows dissolve into the sheet. Used for the filter sheet.
class RoostWheelList extends StatelessWidget {
  const RoostWheelList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onSelectedItemChanged,
    this.controller,
    this.itemExtent = 64,
    this.height = 320,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onSelectedItemChanged;
  final FixedExtentScrollController? controller;
  final double itemExtent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: RoostSpacing.lg),
            decoration: ShapeDecoration(
              color: RoostColors.surface2,
              shape: const SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius.all(
                  SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: RoostRadius.squircleSmoothing),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: itemExtent,
            perspective: 0.0022,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (ctx, i) => itemBuilder(ctx, i),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      RoostColors.surface1,
                      RoostColors.surface1.withValues(alpha: 0),
                      RoostColors.surface1.withValues(alpha: 0),
                      RoostColors.surface1,
                    ],
                    stops: const [0.0, 0.22, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
