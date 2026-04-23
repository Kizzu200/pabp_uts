import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/tasks_repository.dart';
import 'tasks_controller.dart';
import 'tasks_state.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(dioProvider));
});

final tasksControllerProvider =
    StateNotifierProvider.autoDispose<TasksController, TasksState>((ref) {
  return TasksController(ref.watch(tasksRepositoryProvider));
});
