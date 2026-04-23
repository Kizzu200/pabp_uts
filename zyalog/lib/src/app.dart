import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_controller.dart';

class ZyaLogApp extends ConsumerWidget {
  const ZyaLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'ZyaLog',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0E7490),
        brightness: Brightness.light,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF22D3EE),
        brightness: Brightness.dark,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
      ),
      routerConfig: router,
    );
  }
}
