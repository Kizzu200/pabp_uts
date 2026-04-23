import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/session_storage.dart';
import '../models/user_model.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;
}

class AuthRepository {
  AuthRepository(this._dio, this._sessionStorage);

  final Dio _dio;
  final SessionStorage _sessionStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    return _mapAndPersistAuthResponse(response.data);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    return _mapAndPersistAuthResponse(response.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.logout);
    } catch (_) {
      // Keep local cleanup as source of truth on logout action.
    } finally {
      await _sessionStorage.clearSession();
    }
  }

  Future<UserModel?> getSavedUser() {
    return _sessionStorage.getUser();
  }

  Future<String?> getSavedAccessToken() {
    return _sessionStorage.getAccessToken();
  }

  Future<void> clearSession() {
    return _sessionStorage.clearSession();
  }

  Future<AuthSession> _mapAndPersistAuthResponse(
    Map<String, dynamic>? body,
  ) async {
    final data = body ?? <String, dynamic>{};
    final userMap = (data['user'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final user = UserModel.fromJson(userMap);
    final accessToken = (data['accessToken'] ?? '').toString();
    final refreshToken = (data['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Token tidak valid dari server.',
      );
    }

    await _sessionStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );

    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
