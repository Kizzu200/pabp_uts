import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/schedules_repository.dart';
import 'schedules_controller.dart';
import 'schedules_state.dart';

final schedulesRepositoryProvider = Provider<SchedulesRepository>((ref) {
  return SchedulesRepository(ref.watch(dioProvider));
});

final schedulesControllerProvider =
    StateNotifierProvider.autoDispose<SchedulesController, SchedulesState>((ref) {
  return SchedulesController(ref.watch(schedulesRepositoryProvider));
});
