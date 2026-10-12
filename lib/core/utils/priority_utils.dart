import '../../models/task_model.dart';

/// Ranks tasks by a 0–90 priority score so the most pressing work comes first,
/// balancing deadline, chosen priority, and remaining subtasks:
///
/// * Urgency (0–45): `45 ÷ (1 + hours left ÷ 24)`, so 45 when due now,
///   22.5 one day out, 11.3 three days out.
/// * Priority (8–30): High 30, Medium 18, Low 8.
/// * Remaining work (0–15): share of unchecked subtasks × 15, or 7.5 when the
///   task has no subtasks.
///
/// Overdue tasks always rank above tasks that are still on time. Among
/// themselves they are ordered by priority + remaining work, then by how long
/// they have been overdue.
abstract final class PriorityUtils {
  static const maxUrgency = 45.0;
  static const _noSubtaskWork = 7.5;
  static const _maxWork = 15.0;

  static double urgencyPoints(TaskModel task, DateTime now) {
    final hoursLeft = task.deadline.difference(now).inMinutes / 60;
    if (hoursLeft <= 0) return maxUrgency;
    return maxUrgency / (1 + hoursLeft / 24);
  }

  static double priorityPoints(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 30,
      TaskPriority.medium => 18,
      TaskPriority.low => 8,
    };
  }

  static double workPoints(TaskModel task) {
    if (task.subtasks.isEmpty) return _noSubtaskWork;
    return _maxWork * (1 - task.progress);
  }

  /// The task's score at [now]. Completed tasks score 0.
  static double score(TaskModel task, {DateTime? now}) {
    if (task.isCompleted) return 0;
    final time = now ?? DateTime.now();
    return urgencyPoints(task, time) +
        priorityPoints(task.priority) +
        workPoints(task);
  }

  /// Sort comparator: overdue first, then by score, then earliest deadline.
  /// Completed tasks go last, earliest deadline first.
  static int compare(TaskModel a, TaskModel b, {DateTime? now}) {
    final time = now ?? DateTime.now();
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    if (a.isCompleted) return a.deadline.compareTo(b.deadline);

    final aOverdue = a.isOverdueAt(time);
    final bOverdue = b.isOverdueAt(time);
    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

    final byScore = aOverdue
        ? _baseScore(b).compareTo(_baseScore(a))
        : score(b, now: time).compareTo(score(a, now: time));
    if (byScore != 0) return byScore;
    return a.deadline.compareTo(b.deadline);
  }

  /// Active tasks, most pressing first.
  static List<TaskModel> rank(Iterable<TaskModel> tasks, {DateTime? now}) {
    final time = now ?? DateTime.now();
    return tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => compare(a, b, now: time));
  }

  /// The single task to work on next, or null when everything is done.
  static TaskModel? selectPriorityTask(
    Iterable<TaskModel> tasks, {
    DateTime? now,
  }) {
    final ranked = rank(tasks, now: now);
    return ranked.isEmpty ? null : ranked.first;
  }

  static double _baseScore(TaskModel task) =>
      priorityPoints(task.priority) + workPoints(task);
}
