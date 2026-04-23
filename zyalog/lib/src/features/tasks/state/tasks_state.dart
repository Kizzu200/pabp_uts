import '../models/task_model.dart';

enum TaskFilter {
  all,
  pending,
  completed,
}

class TasksState {
  const TasksState({
    required this.tasks,
    required this.isLoading,
    this.errorMessage,
    this.filter = TaskFilter.all,
  });

  const TasksState.initial()
      : tasks = const [],
        isLoading = false,
        errorMessage = null,
        filter = TaskFilter.all;

  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  final TaskFilter filter;

  List<TaskModel> get filteredTasks {
    switch (filter) {
      case TaskFilter.pending:
        return tasks.where((task) => !task.completed).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.completed).toList();
      case TaskFilter.all:
        return tasks;
    }
  }

  int get totalTasks => tasks.length;

  int get completedTasks => tasks.where((task) => task.completed).length;

  double get completionProgress {
    if (tasks.isEmpty) {
      return 0;
    }
    return completedTasks / tasks.length;
  }

  TasksState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    TaskFilter? filter,
    bool clearError = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}
