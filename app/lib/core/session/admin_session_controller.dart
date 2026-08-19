import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_models.dart';
import '../api/admin_api.dart';
import '../api/roost_api.dart' show ApiException;

/// Holds the signed-in [AdminUser] (null = signed out). Separate from
/// [SessionController] on purpose — this is a different app (`main_admin.dart`)
/// with a different token and no student concepts (biometric, demo mode).
class AdminSessionController extends Notifier<AdminUser?> {
  @override
  AdminUser? build() => null;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      final api = ref.read(adminApiProvider);
      final auth = await api.login(email, password);
      api.setToken(auth.token);
      final store = ref.read(adminTokenStoreProvider);
      await store.saveToken(auth.token);
      await store.saveProfile(auth.admin);
      state = auth.admin;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Check your connection and try again.';
    }
  }

  /// Restore a previous session on app launch. Returns false if there's no
  /// stored token, or it's no longer valid (caller should show the login form).
  Future<bool> restoreSession() async {
    final store = ref.read(adminTokenStoreProvider);
    final token = await store.readToken();
    final profile = await store.readProfile();
    if (token == null || token.isEmpty || profile == null) return false;

    final api = ref.read(adminApiProvider)..setToken(token);
    try {
      await api.occupancyStats(); // cheap authenticated call, just to validate the token
      state = profile;
      return true;
    } catch (_) {
      api.setToken(null);
      await store.clearToken();
      await store.clearProfile();
      return false;
    }
  }

  Future<void> signOut() async {
    final api = ref.read(adminApiProvider);
    api.setToken(null);
    final store = ref.read(adminTokenStoreProvider);
    await store.clearToken();
    await store.clearProfile();
    state = null;
  }
}

final adminSessionProvider =
    NotifierProvider<AdminSessionController, AdminUser?>(AdminSessionController.new);
