// lib/core/storage.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper untuk SharedPreferences — mengelola sesi pengguna & preferensi.
class AppStorage {
  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyUserEmail = 'userEmail';
  static const _keyUserName = 'userName';
  static const _keyUserId = 'userId';
  static const _keyTheme = 'theme';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ── Token ────────────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final p = await _prefs;
    await p.setString(_keyAccessToken, accessToken);
    await p.setString(_keyRefreshToken, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final p = await _prefs;
    return p.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final p = await _prefs;
    return p.getString(_keyRefreshToken);
  }

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<void> saveUser({
    required String id,
    required String email,
    String? name,
  }) async {
    final p = await _prefs;
    await p.setString(_keyUserId, id);
    await p.setString(_keyUserEmail, email);
    if (name != null && name.isNotEmpty) {
      await p.setString(_keyUserName, name);
    } else {
      await p.remove(_keyUserName);
    }
  }

  static Future<String?> getUserId() async {
    final p = await _prefs;
    return p.getString(_keyUserId);
  }

  static Future<String?> getUserEmail() async {
    final p = await _prefs;
    return p.getString(_keyUserEmail);
  }

  static Future<String?> getUserName() async {
    final p = await _prefs;
    return p.getString(_keyUserName);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  static Future<void> saveTheme(String theme) async {
    final p = await _prefs;
    await p.setString(_keyTheme, theme);
  }

  static Future<String> getTheme() async {
    final p = await _prefs;
    return p.getString(_keyTheme) ?? 'dark';
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  static Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_keyAccessToken);
    await p.remove(_keyRefreshToken);
    await p.remove(_keyUserEmail);
    await p.remove(_keyUserName);
    await p.remove(_keyUserId);
  }

  // ── Snapshot (sync) untuk initial state ──────────────────────────────────

  static Future<Map<String, String?>> loadSession() async {
    final p = await _prefs;
    return {
      'accessToken': p.getString(_keyAccessToken),
      'refreshToken': p.getString(_keyRefreshToken),
      'userEmail': p.getString(_keyUserEmail),
      'userName': p.getString(_keyUserName),
      'userId': p.getString(_keyUserId),
    };
  }
}
