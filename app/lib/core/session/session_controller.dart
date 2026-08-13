import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/roost_api.dart';
import '../config/app_config.dart';
import '../demo/hostel_data.dart';

/// Holds the signed-in [Student] (null = signed out) and owns the auth flow.
///
/// On a successful sign-in it **bootstraps** the app: fetches the hostels (and
/// their room detail) into [HostelData] and the student's reservations into
/// [reservationsProvider], so the rest of the app keeps reading synchronously.
/// Every network step is non-fatal — if the backend is slow/asleep the app
/// degrades to the built-in static data rather than failing to sign in.
class SessionController extends Notifier<Student?> {
  @override
  Student? build() => null;

  /// Returns null on success, or a user-facing error message on failure.
  Future<String?> signIn({
    required String identifier,
    required String password,
    bool register = false,
  }) async {
    if (AppConfig.useDemoData) {
      state = Student.demo();
      return null;
    }
    try {
      final api = ref.read(roostApiProvider);
      final auth = register
          ? await api.register(identifier, password)
          : await api.login(identifier, password);
      api.setToken(auth.token);
      await ref.read(tokenStoreProvider).save(auth.token);
      state = auth.student;
      await _bootstrap();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Check your connection and try again.';
    }
  }

  /// Restore a previous session after biometric unlock. Returns false if there
  /// is no stored token or it is no longer valid (caller should ask for a
  /// password sign-in). Always true in demo mode.
  Future<bool> restoreSession() async {
    if (AppConfig.useDemoData) {
      state = Student.demo();
      return true;
    }
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null || token.isEmpty) return false;
    final api = ref.read(roostApiProvider)..setToken(token);
    try {
      state = await api.me();
      await _bootstrap();
      return true;
    } catch (_) {
      api.setToken(null);
      await ref.read(tokenStoreProvider).clear();
      return false;
    }
  }

  Future<void> signOut() async {
    if (!AppConfig.useDemoData) {
      final api = ref.read(roostApiProvider);
      try {
        await api.logout();
      } catch (_) {/* best effort */}
      api.setToken(null);
      await ref.read(tokenStoreProvider).clear();
    }
    state = null;
  }

  /// Fill [HostelData] + [reservationsProvider] from the backend. Non-throwing:
  /// any failed step leaves the existing (static) data in place.
  Future<void> _bootstrap() async {
    final api = ref.read(roostApiProvider);
    try {
      final list = await api.hostels();
      final details = await Future.wait(list.map((h) async {
        try {
          return await api.hostel(h.id); // full detail: rooms + occupiedBeds + blurb
        } catch (_) {
          return h; // fall back to the list-level hostel (no rooms)
        }
      }));
      HostelData.replaceHostels(details);
    } catch (_) {/* keep static hostels */}
    try {
      ref.read(reservationsProvider.notifier).setAll(await api.reservations());
    } catch (_) {/* keep empty */}
  }
}

final sessionProvider =
    NotifierProvider<SessionController, Student?>(SessionController.new);
