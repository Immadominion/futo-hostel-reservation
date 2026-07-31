import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_shell.dart';
import '../../features/hostel_detail/hostel_detail_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/reserve/reserve_page.dart';

/// Flat routes, no auth redirect — "login" simply navigates to /home (the demo
/// keeps gating skippable for simplicity). The bottom-nav tabs live inside
/// HomeShell; hostel detail and reserve are pushed on top.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: '/home',
        builder: (_, state) => HomeShell(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/hostel/:id',
        builder: (_, state) => HostelDetailPage(hostelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/hostel/:id/reserve',
        builder: (_, state) => ReservePage(hostelId: state.pathParameters['id']!),
      ),
    ],
  );
});
