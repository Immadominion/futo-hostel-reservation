library phosphor_flutter;

import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// LOCAL PATCH (Roost / SOE-510)
//
// Upstream phosphor_flutter 2.1.0 declares `class PhosphorIconData extends
// IconData`. Newer Flutter marks `IconData` as a `final class`, which can no
// longer be extended outside its own library — so the published package fails
// to compile ("The class 'IconData' can't be extended ... it's a final class").
// No fixed version has been released on pub.dev yet.
//
// Fix: the per-style icon getters now produce plain `const IconData` values
// (see the generated phosphor_icons_*.dart files). These typedefs keep the
// original public type names valid for any code that still references them.
// ---------------------------------------------------------------------------

typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
typedef PhosphorDuotoneIconData = IconData;
