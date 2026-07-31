import 'dart:ui' show Brightness;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tokens.dart';

/// The app's active appearance. Defaults to **light**; the settings sheet flips
/// it and the whole UI re-themes via [RoostColors].
///
/// The palette is applied *inside* the controller so it's live before any
/// watcher rebuilds — screens watch this provider so a flip repaints the entire
/// navigation stack, not just the visible route.
class BrightnessController extends Notifier<Brightness> {
  @override
  Brightness build() {
    RoostColors.setBrightness(Brightness.light);
    return Brightness.light;
  }

  void set(Brightness b) {
    RoostColors.setBrightness(b);
    state = b;
  }

  void toggle() => set(state == Brightness.light ? Brightness.dark : Brightness.light);
}

final brightnessProvider =
    NotifierProvider<BrightnessController, Brightness>(BrightnessController.new);
