import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tasks_repository.dart';
import '../models/task_model.dart';
import 'tasks_state.dart';

class TasksController extends StateNotifier<TasksState> {
  TasksController(this._repository) : super(const TasksState.initial()) {
    loadTasks();
  }

  final TasksRepository _repository;

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repository.getTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: items,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.createTask(
        title: title,
        description: description,
        deadline: deadline,
      );
      await loadTasks();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> updateTask(TaskModel task) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateTask(task);
      await loadTasks();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> toggleCompleted(TaskModel task, bool completed) async {
    await updateTask(task.copyWith(completed: completed));
  }

  Future<void> deleteTask(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    return 'Gagal memuat data tugas.';
  }
}
