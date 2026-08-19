import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/admin_router.dart';
import 'core/theme/brightness_provider.dart';
import 'core/theme/theme.dart';
import 'core/theme/tokens.dart';

/// Root of the admin app — a separate binary from the student app
/// (`app.dart`/`main.dart`), sharing the theme/widget/API layers but with its
/// own router and no student-facing routes at all.
class RoostAdminApp extends ConsumerWidget {
  const RoostAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    RoostColors.setBrightness(brightness);
    final router = ref.watch(adminRouterProvider);
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
        title: 'Roost Admin — FUTO Hostels',
        debugShowCheckedModeBanner: false,
        theme: RoostTheme.build(brightness),
        routerConfig: router,
      ),
    );
  }
}
