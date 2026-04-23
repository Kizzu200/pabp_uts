import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_event_bus.dart';
import '../../../core/storage/session_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SessionStorage sessionStorage,
    required AuthEventBus authEventBus,
  })  : _repository = repository,
        _sessionStorage = sessionStorage,
        _authEventBus = authEventBus,
        super(const AuthState.initial()) {
    _authEventSubscription = _authEventBus.stream.listen((event) {
      if (event == AuthEvent.sessionExpired) {
        forceLogout(message: 'Sesi habis. Silakan login kembali.');
      }
    });

    initialize();
  }

  final AuthRepository _repository;
  final SessionStorage _sessionStorage;
  final AuthEventBus _authEventBus;

  StreamSubscription<AuthEvent>? _authEventSubscription;

  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final token = await _repository.getSavedAccessToken();
    final user = await _repository.getSavedUser();

    if (token != null && token.isNotEmpty && user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        pendingProfileSetup: false,
        user: user,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      pendingProfileSetup: false,
      clearUser: true,
      clearError: true,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final session = await _repository.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        pendingProfileSetup: false,
        user: session.user,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseErrorMessage(error),
        clearUser: true,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final session = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        pendingProfileSetup: false,
        user: session.user,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseErrorMessage(error),
        clearUser: true,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _repository.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      pendingProfileSetup: false,
      clearUser: true,
      clearError: true,
    );
  }

  Future<void> completeProfileSetup({
    required String name,
  }) async {
    final existingUser = state.user;
    if (existingUser == null) return;

    final updatedUser = existingUser.copyWith(name: name.trim());
    await _sessionStorage.updateUser(updatedUser);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      pendingProfileSetup: false,
      user: updatedUser,
      clearError: true,
    );
  }

  Future<void> forceLogout({String? message}) async {
    await _sessionStorage.clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      pendingProfileSetup: false,
      clearUser: true,
      errorMessage: message,
    );
  }

  String _parseErrorMessage(Object error) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final directMessage = data['message']?.toString();
        if (directMessage != null && directMessage.isNotEmpty) {
          return directMessage;
        }
      }

      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    return 'Terjadi kesalahan. Coba lagi.';
  }

  @override
  void dispose() {
    _authEventSubscription?.cancel();
    super.dispose();
  }
}
