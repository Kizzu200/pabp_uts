import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      repository: ref.watch(authRepositoryProvider),
      sessionStorage: ref.watch(sessionStorageProvider),
      authEventBus: ref.watch(authEventBusProvider),
    );
  },
);
