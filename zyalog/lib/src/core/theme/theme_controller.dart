import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeModeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);

    if (raw == 'light') {
      state = ThemeMode.light;
      return;
    }

    if (raw == 'dark') {
      state = ThemeMode.dark;
      return;
    }

    state = ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();

    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await prefs.setString(_themeModeKey, value);
  }

  Future<void> toggleLightDark() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
      return;
    }

    await setThemeMode(ThemeMode.dark);
  }
}
