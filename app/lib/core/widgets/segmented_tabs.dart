import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Centred word-tabs: the active one in primary ink with a small accent dot,
/// the rest muted. No pill, no underline — typography does the work.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: RoostSpacing.lg),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: RoostMotion.micro,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: i == index ? RoostColors.textPrimary : RoostColors.textTertiary,
                  ),
                  child: Text(tabs[i]),
                ),
                const SizedBox(width: RoostSpacing.sm),
                AnimatedContainer(
                  duration: RoostMotion.micro,
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? RoostColors.accent : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
