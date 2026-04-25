// lib/models/task.dart

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool completed;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.completed,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deadline: DateTime.parse(json['deadline'] as String),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'completed': completed,
      };

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? completed,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      completed: completed ?? this.completed,
    );
  }

  /// Apakah tugas deadline dalam N jam ke depan
  bool isWithinNextHours(int hours) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    return !completed && diff.inSeconds > 0 && diff.inHours < hours;
  }
}
