import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futo_hostel/app.dart';
import 'package:futo_hostel/core/config/app_config.dart';
import 'package:futo_hostel/core/widgets/hostel_card.dart';

/// Drives the core journey on a 360px-wide phone (the common Android width)
/// and asserts every screen lays out with no exceptions / overflow.
void main() {
  // Drive the journey against the built-in demo data (no network).
  AppConfig.useDemoData = true;

  testWidgets('core flow renders cleanly on a 360px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: RoostApp()));
    await tester.pumpAndSettle();

    // sign in
    await tester.enterText(find.byType(TextField).at(0), '20211234567');
    await tester.enterText(find.byType(TextField).at(1), 'futo2026');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Find your space'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // bottom-nav tabs
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();

    // hostel detail
    await tester.tap(find.byType(HostelCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Rooms'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // reserve screen
    await tester.tap(find.text('Reserve a bed'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a room'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // select a room -> bed grid renders
    await tester.tap(find.text('8-bed room').first);
    await tester.pumpAndSettle();
    expect(find.text('Pick a bed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
