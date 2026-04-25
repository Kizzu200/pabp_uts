// lib/services/task_service.dart

import '../core/api_client.dart';
import '../models/task.dart';

class TaskService {
  /// GET /api/tasks
  static Future<List<TaskModel>> fetchAll() async {
    final data = await ApiClient.get('/api/tasks') as List<dynamic>;
    return data
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/tasks
  static Future<TaskModel> create({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    final data = await ApiClient.post('/api/tasks', {
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
    }) as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  /// PUT /api/tasks/:id
  static Future<TaskModel> update({
    required String id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? completed,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline.toIso8601String();
    if (completed != null) body['completed'] = completed;

    final data = await ApiClient.put('/api/tasks/$id', body) as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  /// DELETE /api/tasks/:id
  static Future<void> delete(String id) async {
    await ApiClient.delete('/api/tasks/$id');
  }
}
