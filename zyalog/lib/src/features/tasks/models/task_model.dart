class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.completed,
  });

  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool completed;

  bool get isOverdue {
    return !completed && deadline.isBefore(DateTime.now());
  }

  bool get isDueSoon {
    final diff = deadline.difference(DateTime.now());
    return !completed && !isOverdue && diff.inHours <= 24;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completed'];
    return TaskModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      deadline: DateTime.tryParse((json['deadline'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completed: completedRaw == true ||
          completedRaw == 1 ||
          completedRaw.toString().toLowerCase() == 'true',
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'completed': completed,
    };
  }
}
