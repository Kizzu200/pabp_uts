import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.status == AuthStatus.loading ||
          authState.status == AuthStatus.initial;
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (state.matchedLocation == '/splash' || isAuthRoute) {
        return '/home';
      }

      return null;
    },
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
