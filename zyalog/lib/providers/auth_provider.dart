// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';

import '../core/storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  ThemeMode _themeMode = ThemeMode.dark;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  ThemeMode get themeMode => _themeMode;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final session = await AppStorage.loadSession();
    final themeStr = await AppStorage.getTheme();
    _themeMode = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;

    if (session['accessToken'] != null && session['userEmail'] != null) {
      _user = UserModel(
        id: session['userId'] ?? '',
        email: session['userEmail']!,
        name: session['userName'],
      );
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login / Register ──────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.login(email: email, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.register(
          name: name, email: email, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  // ── Theme ──────────────────────────────────────────────────────────────────

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppStorage.saveTheme(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
