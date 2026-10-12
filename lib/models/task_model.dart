import 'subtask_model.dart';

enum TaskPriority { high, medium, low }

/// Built-in task categories. Stored by [name] and translated for display.
enum TaskCategory {
  academic,
  project,
  meeting,
  presentation,
  personal,
  quiz,
  examination,
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.deadline,
    required this.createdAt,
    this.description = '',
    this.category = 'academic',
    this.priority = TaskPriority.medium,
    this.reminderEnabled = true,
    this.subtasks = const [],
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;

  /// A [TaskCategory] name, or free text entered when editing a task.
  final String category;
  final DateTime deadline;
  final TaskPriority priority;
  final bool reminderEnabled;
  final List<SubtaskModel> subtasks;
  final bool isCompleted;

  /// When the task was last marked complete; used for the study streak.
  final DateTime? completedAt;
  final DateTime createdAt;

  int get completedSubtasks => subtasks.where((s) => s.isDone).length;

  /// Share of subtasks checked off. Completing a task does not change it.
  double get progress =>
      subtasks.isEmpty ? 0 : completedSubtasks / subtasks.length;

  bool isOverdueAt(DateTime now) => !isCompleted && now.isAfter(deadline);

  bool get isOverdue => isOverdueAt(DateTime.now());

  bool isDueOn(DateTime day) =>
      deadline.year == day.year &&
      deadline.month == day.month &&
      deadline.day == day.day;

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? deadline,
    TaskPriority? priority,
    bool? reminderEnabled,
    List<SubtaskModel>? subtasks,
    bool? isCompleted,
    DateTime? Function()? completedAt,
  }) {
    return TaskModel(
      id: id,
      createdAt: createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt == null ? this.completedAt : completedAt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'deadline': deadline.toIso8601String(),
    'priority': priority.name,
    'reminderEnabled': reminderEnabled,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      // `notes` and `subject` are the field names used by earlier builds.
      description: (json['description'] ?? json['notes'] ?? '') as String,
      category: (json['category'] ?? json['subject'] ?? 'academic') as String,
      deadline: DateTime.parse(json['deadline'] as String),
      priority: TaskPriority.values.byName(json['priority'] as String),
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
