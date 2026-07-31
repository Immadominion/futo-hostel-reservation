library phosphor_flutter;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// LOCAL PATCH (Roost / SOE-510)
//
// Duotone icons are now plain `IconData` (see phosphor_icon_data.dart), so the
// original `PhosphorDuotoneIconData.secondary` overlay branch no longer applies.
// `PhosphorIcon` stays as a thin `Icon` subclass to preserve the public API;
// the duotone overlay parameters are kept for source compatibility but are inert.
// ---------------------------------------------------------------------------

class PhosphorIcon extends Icon {
  const PhosphorIcon(
    IconData icon, {
    Key? key,
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
    String? semanticLabel,
    TextDirection? textDirection,
    this.duotoneSecondaryOpacity = 0.20,
    this.duotoneSecondaryColor,
  }) : super(
          icon,
          color: color,
          fill: fill,
          grade: grade,
          key: key,
          opticalSize: opticalSize,
          semanticLabel: semanticLabel,
          shadows: shadows,
          size: size,
          textDirection: textDirection,
          weight: weight,
        );

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;
}
