import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/auth/admin_login_page.dart';
import '../../features/admin/home/admin_home_shell.dart';
import '../../features/admin/hostels/admin_hostel_detail_page.dart';
import '../../features/admin/splash/admin_splash_page.dart';

/// Separate router for the admin app (`main_admin.dart`) — its own routes,
/// nothing shared with the student router.
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AdminSplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const AdminLoginPage()),
      GoRoute(
        path: '/home',
        builder: (_, state) => AdminHomeShell(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/hostel/:id',
        builder: (_, state) => AdminHostelDetailPage(hostelId: state.pathParameters['id']!),
      ),
    ],
  );
});
