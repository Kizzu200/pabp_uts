// lib/providers/task_provider.dart

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';

enum TaskFilter { all, pending, done }

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  bool _loading = false;
  String? _error;

  List<TaskModel> get allTasks => _tasks;
  TaskFilter get filter => _filter;
  bool get loading => _loading;
  String? get error => _error;

  List<TaskModel> get filteredTasks {
    List<TaskModel> filtered;
    switch (_filter) {
      case TaskFilter.pending:
        filtered = _tasks.where((t) => !t.completed).toList();
        break;
      case TaskFilter.done:
        filtered = _tasks.where((t) => t.completed).toList();
        break;
      case TaskFilter.all:
        filtered = List.from(_tasks);
    }
    filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
    return filtered;
  }

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;
  int get pendingCount => _tasks.where((t) => !t.completed).length;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  List<TaskModel> get urgentTasks =>
      _tasks.where((t) => t.isWithinNextHours(24)).toList();

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchTasks() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await TaskService.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<bool> addTask({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    try {
      final task = await TaskService.create(
        title: title,
        description: description,
        deadline: deadline,
      );
      _tasks.add(task);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? completed,
  }) async {
    try {
      final updated = await TaskService.update(
        id: id,
        title: title,
        description: description,
        deadline: deadline,
        completed: completed,
      );
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) _tasks[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleCompleted(String id) async {
    final task = _tasks.firstWhere((t) => t.id == id);
    // Optimistic update
    final idx = _tasks.indexWhere((t) => t.id == id);
    _tasks[idx] = task.copyWith(completed: !task.completed);
    notifyListeners();
    try {
      await TaskService.update(id: id, completed: !task.completed);
    } catch (_) {
      // Rollback
      _tasks[idx] = task;
      notifyListeners();
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    final backup = List<TaskModel>.from(_tasks);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    try {
      await TaskService.delete(id);
    } catch (_) {
      _tasks = backup;
      notifyListeners();
    }
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void setFilter(TaskFilter f) {
    _filter = f;
    notifyListeners();
  }

  void clear() {
    _tasks = [];
    _error = null;
    _filter = TaskFilter.all;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
