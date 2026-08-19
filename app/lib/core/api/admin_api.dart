import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../admin/admin_models.dart';
import '../config/app_config.dart';
import '../demo/hostel_data.dart' show Gender, Hostel, Room;
import 'roost_api.dart' show ApiException;

class AdminAuthResult {
  AdminAuthResult(this.token, this.admin);
  final String token;
  final AdminUser admin;
}

/// The admin-side counterpart to [RoostApi] — same wire format
/// (`{ error: { code, message } }`), separate token, `/admin/*` + admin auth.
class AdminApi {
  AdminApi(this._client);
  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  static const _timeout = Duration(seconds: 60); // Render free tier can cold-start

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return base;
    final q = <String, String>{};
    query.forEach((k, v) {
      if (v != null) q[k] = '$v';
    });
    return base.replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final res = await _client.get(_uri(path, query), headers: _headers).timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> _post(String path, [Object? body]) async {
    final res = await _client
        .post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> _patch(String path, [Object? body]) async {
    final res = await _client
        .patch(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<void> _delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers).timeout(_timeout);
    _decode(res);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {/* non-JSON body */}
    }
    if (ok) return body;
    final err = (body is Map && body['error'] is Map) ? body['error'] as Map : null;
    throw ApiException(
      err?['code']?.toString() ?? 'HTTP_${res.statusCode}',
      err?['message']?.toString() ?? _friendly(res.statusCode),
      res.statusCode,
    );
  }

  String _friendly(int code) => switch (code) {
        400 || 422 => 'Please check the details and try again.',
        401 => 'Wrong credentials, or your session expired.',
        403 => 'You do not have access to this.',
        404 => 'Not found.',
        409 => 'That conflicts with the current data.',
        >= 500 => 'The server had a problem. Please try again.',
        _ => 'Something went wrong (HTTP $code).',
      };

  // ---- auth ----
  Future<AdminAuthResult> login(String email, String password) async {
    final j = await _post('/auth/admin/login', {'email': email, 'password': password}) as Map<String, dynamic>;
    return AdminAuthResult(j['token'] as String, AdminUser.fromJson(j['admin'] as Map<String, dynamic>));
  }

  // ---- stats ----
  Future<OccupancyStats> occupancyStats() async {
    final j = await _get('/admin/stats/occupancy') as Map<String, dynamic>;
    return OccupancyStats.fromJson(j);
  }

  // ---- reservations ----
  Future<List<AdminReservation>> reservations({String? status}) async {
    final j = await _get('/admin/reservations', status == null ? null : {'status': status}) as List<dynamic>;
    return j.map((e) => AdminReservation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminReservation> allocate(String reservationId, {required String roomId, required int bed}) async {
    final j = await _post('/admin/reservations/$reservationId/allocate', {'roomId': roomId, 'bed': bed})
        as Map<String, dynamic>;
    return AdminReservation.fromJson(j);
  }

  // ---- hostels ----
  Future<List<Hostel>> hostels() async {
    final j = await _get('/admin/hostels') as List<dynamic>;
    return j.map((e) => Hostel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Hostel> hostel(String id) async {
    final j = await _get('/admin/hostels/$id') as Map<String, dynamic>;
    return Hostel.fromJson(j);
  }

  Future<Hostel> createHostel({
    required String id,
    required String name,
    required String code,
    required String funder,
    required Gender gender,
    required int price,
    required int capacity,
    required String blurb,
    required double lat,
    required double lng,
    required int coverA,
    required int coverB,
  }) async {
    final j = await _post('/admin/hostels', {
      'id': id, 'name': name, 'code': code, 'funder': funder, 'gender': _genderStr(gender),
      'price': price, 'capacity': capacity, 'blurb': blurb, 'lat': lat, 'lng': lng,
      'coverA': coverA, 'coverB': coverB,
    }) as Map<String, dynamic>;
    return Hostel.fromJson(j);
  }

  Future<Hostel> updateHostel(String id, Map<String, dynamic> patch) async {
    final j = await _patch('/admin/hostels/$id', patch) as Map<String, dynamic>;
    return Hostel.fromJson(j);
  }

  Future<void> deleteHostel(String id) => _delete('/admin/hostels/$id');

  // ---- rooms ---- (capacity is fixed per-hostel now — a room only needs hostelId)
  Future<List<Room>> rooms({String? hostelId}) async {
    final j = await _get('/admin/rooms', hostelId == null ? null : {'hostelId': hostelId}) as List<dynamic>;
    return j.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Room> createRoom({required String hostelId}) async {
    final j = await _post('/admin/rooms', {'hostelId': hostelId}) as Map<String, dynamic>;
    return Room.fromJson(j);
  }

  Future<void> deleteRoom(String id) => _delete('/admin/rooms/$id');

  String _genderStr(Gender g) => switch (g) {
        Gender.male => 'male',
        Gender.female => 'female',
        Gender.mixed => 'mixed',
        Gender.postgrad => 'postgrad',
      };
}

/// Persists the admin JWT + a lightweight profile snapshot (there's no
/// `GET /admin/me` to re-fetch the signed-in admin's name/email from a bare
/// token, so we cache what login already returned to restore sessions).
class AdminTokenStore {
  const AdminTokenStore();
  static const _tokenKey = 'roost_admin_jwt';
  static const _profileKey = 'roost_admin_profile';
  static const _storage = FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<AdminUser?> readProfile() async {
    final raw = await _storage.read(key: _profileKey);
    if (raw == null) return null;
    try {
      return AdminUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(AdminUser admin) =>
      _storage.write(key: _profileKey, value: jsonEncode(admin.toJson()));
  Future<void> clearProfile() => _storage.delete(key: _profileKey);
}

final adminApiProvider = Provider<AdminApi>((ref) {
  final api = AdminApi(http.Client());
  ref.onDispose(api._client.close);
  return api;
});

final adminTokenStoreProvider = Provider<AdminTokenStore>((ref) => const AdminTokenStore());
