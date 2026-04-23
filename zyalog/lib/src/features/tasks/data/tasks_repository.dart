import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/task_model.dart';

class TasksRepository {
  TasksRepository(this._dio);

  final Dio _dio;

  Future<List<TaskModel>> getTasks() async {
    final response = await _dio.get<dynamic>(ApiConstants.tasks);
    final list = _extractList(response.data, ['tasks', 'data']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.tasks,
      data: {
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
      },
    );

    final map = _extractMap(response.data, ['task', 'data']);
    return TaskModel.fromJson(map);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _dio.put<dynamic>(
      '${ApiConstants.tasks}/${task.id}',
      data: {
        'title': task.title,
        'description': task.description,
        'deadline': task.deadline.toIso8601String(),
        'completed': task.completed,
      },
    );

    final map = _extractMap(response.data, ['task', 'data']);
    return TaskModel.fromJson(map);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete<void>('${ApiConstants.tasks}/$id');
  }

  List<dynamic> _extractList(dynamic body, List<String> keys) {
    if (body is List) {
      return body;
    }

    if (body is Map<String, dynamic>) {
      for (final key in keys) {
        final dynamic value = body[key];
        if (value is List) {
          return value;
        }
      }
    }

    return <dynamic>[];
  }

  Map<String, dynamic> _extractMap(dynamic body, List<String> keys) {
    if (body is Map<String, dynamic>) {
      for (final key in keys) {
        final dynamic value = body[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }
      return body;
    }

    return <String, dynamic>{};
  }
}
