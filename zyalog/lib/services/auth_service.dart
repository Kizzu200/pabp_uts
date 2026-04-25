// lib/services/auth_service.dart

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthResult {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthService {
  /// Login dengan email + password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.postPublic('/api/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final result = AuthResult(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    // Simpan ke storage
    await AppStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await AppStorage.saveUser(
      id: result.user.id,
      email: result.user.email,
      name: result.user.name,
    );

    return result;
  }

  /// Register akun baru
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.postPublic('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final result = AuthResult(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    await AppStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await AppStorage.saveUser(
      id: result.user.id,
      email: result.user.email,
      name: result.user.name,
    );

    return result;
  }

  /// Logout — beritahu server lalu hapus sesi lokal
  static Future<void> logout() async {
    try {
      await ApiClient.post('/api/auth/logout', {});
    } catch (_) {
      // Lanjutkan meskipun server error
    }
    await AppStorage.clearSession();
  }
}
