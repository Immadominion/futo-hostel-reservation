import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/admin_session_controller.dart';
import '../../../core/theme/tokens.dart';

/// First screen on launch. Silently checks for a stored admin session while
/// showing the brand, then routes to Home (restored) or Login (not signed in
/// / expired token). A short minimum display time keeps it from reading as a
/// glitchy flash when the check resolves instantly.
class AdminSplashPage extends ConsumerStatefulWidget {
  const AdminSplashPage({super.key});

  @override
  ConsumerState<AdminSplashPage> createState() => _AdminSplashPageState();
}

class _AdminSplashPageState extends ConsumerState<AdminSplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final results = await Future.wait([
      ref.read(adminSessionProvider.notifier).restoreSession(),
      Future.delayed(const Duration(milliseconds: 700)),
    ]);
    if (!mounted) return;
    final restored = results[0] as bool;
    context.go(restored ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoostColors.accent,
      body: const DecoratedBox(
        decoration: BoxDecoration(gradient: RoostGradients.accent),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Wordmark(),
                SizedBox(height: RoostSpacing.sm),
                Text(
                  'Hostel Officer Admin',
                  style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: RoostSpacing.xxxl),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Montserrat', fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: Colors.white,
        ),
        children: [
          TextSpan(text: 'Roost'),
          TextSpan(text: ' Admin', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
