import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/router.dart';
import 'core/theme/brightness_provider.dart';
import 'core/theme/theme.dart';
import 'core/theme/tokens.dart';

/// Root. Watches [brightnessProvider] so a light/dark flip re-themes the whole
/// navigation stack; applies the palette before building the theme.
class RoostApp extends ConsumerWidget {
  const RoostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    RoostColors.setBrightness(brightness); // live before the theme is built
    final router = ref.watch(routerProvider);
    final isLight = brightness == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: RoostColors.surface0,
        systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'Roost — FUTO Hostels',
        debugShowCheckedModeBanner: false,
        theme: RoostTheme.build(brightness),
        routerConfig: router,
      ),
    );
  }
}
