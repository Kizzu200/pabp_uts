import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/user_model.dart';

class SessionStorage {
  SessionStorage(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> updateUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
