import 'package:dio/dio.dart';

import '../auth/auth_event_bus.dart';
import '../constants/api_constants.dart';
import '../storage/session_storage.dart';

class ApiClient {
  static Dio create({
    required SessionStorage sessionStorage,
    required AuthEventBus authEventBus,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      _AuthInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        sessionStorage: sessionStorage,
        authEventBus: authEventBus,
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );

    return dio;
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required SessionStorage sessionStorage,
    required AuthEventBus authEventBus,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _sessionStorage = sessionStorage,
        _authEventBus = authEventBus;

  final Dio _dio;
  final Dio _refreshDio;
  final SessionStorage _sessionStorage;
  final AuthEventBus _authEventBus;

  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (skipAuth) {
      return handler.next(options);
    }

    final token = await _sessionStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = requestOptions.path == ApiConstants.refresh;
    final alreadyRetried = requestOptions.extra['retried'] == true;

    if (!isUnauthorized || isRefreshEndpoint || alreadyRetried) {
      return handler.next(err);
    }

    try {
      _refreshFuture ??= _refreshToken();
      final newAccessToken = await _refreshFuture;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return handler.next(err);
      }

      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['retried'] = true;

      final response = await _dio.fetch<dynamic>(requestOptions);
      return handler.resolve(response);
    } catch (refreshError) {
      return handler.next(err);
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _refreshToken() async {
    final currentRefreshToken = await _sessionStorage.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      await _sessionStorage.clearSession();
      _authEventBus.emit(AuthEvent.sessionExpired);
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': currentRefreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data ?? <String, dynamic>{};
      final newAccessToken = (body['accessToken'] ?? '').toString();
      final newRefreshToken = (body['refreshToken'] ?? '').toString();

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        await _sessionStorage.clearSession();
        _authEventBus.emit(AuthEvent.sessionExpired);
        return null;
      }

      await _sessionStorage.updateTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return newAccessToken;
    } catch (_) {
      await _sessionStorage.clearSession();
      _authEventBus.emit(AuthEvent.sessionExpired);
      return null;
    }
  }
}
