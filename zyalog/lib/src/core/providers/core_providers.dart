import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_event_bus.dart';
import '../network/api_client.dart';
import '../storage/session_storage.dart';

final authEventBusProvider = Provider<AuthEventBus>((ref) {
  final bus = AuthEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(flutterSecureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return ApiClient.create(
    sessionStorage: ref.watch(sessionStorageProvider),
    authEventBus: ref.watch(authEventBusProvider),
  );
});
