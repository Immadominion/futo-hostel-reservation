import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futo_hostel/app.dart';
import 'package:futo_hostel/core/config/app_config.dart';

void main() {
  AppConfig.useDemoData = true; // no network in widget tests

  testWidgets('launches to onboarding and lays out without exceptions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RoostApp()));
    await tester.pump(const Duration(milliseconds: 400)); // settle entrance

    // The screen rendered (no white-screen / hasSize crash).
    expect(tester.takeException(), isNull);
    expect(find.text('FUTO Hostel Reservation'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('lays out on a short viewport (scrolls instead of crashing)', (tester) async {
    tester.view.physicalSize = const Size(720, 1100); // short phone
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: RoostApp()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
