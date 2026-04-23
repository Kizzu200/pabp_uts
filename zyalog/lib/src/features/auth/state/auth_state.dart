import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.pendingProfileSetup = false,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  final AuthStatus status;
  final bool pendingProfileSetup;
  final UserModel? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    bool? pendingProfileSetup,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      pendingProfileSetup: pendingProfileSetup ?? this.pendingProfileSetup,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
