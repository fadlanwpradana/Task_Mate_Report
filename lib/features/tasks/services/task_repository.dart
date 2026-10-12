import 'package:flutter/material.dart' show ChangeNotifier, DateUtils;

import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/priority_utils.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../models/subtask_model.dart';
import '../../../models/task_model.dart';
import 'task_store.dart';

/// The user's tasks, plus priority, filtering, and reminder logic. Where the
/// tasks are saved is up to the [TaskStore]: on the device for the offline
/// demo, or the user's private Firestore collection when signed in.
class TaskRepository extends ChangeNotifier {
  TaskRepository(StorageService storage, {ReminderScheduler? reminders})
    : this.withStore(
        LocalTaskStore(storage, samples: _sampleTasks),
        reminders: reminders,
      );

  TaskRepository.withStore(TaskStore store, {ReminderScheduler? reminders})
    : _reminders = reminders ?? NoopReminderScheduler() {
    _attach(store);
  }

  final ReminderScheduler _reminders;
  late TaskStore _store;
  late List<TaskModel> _tasks;

  /// Switches to another store, e.g. the signed-in user's cloud tasks, and
  /// reschedules reminders for the new list.
  void switchStore(TaskStore store) {
    _store.dispose();
    _attach(store);
    notifyListeners();
    syncReminders();
  }

  void _attach(TaskStore store) {
    _store = store;
    _tasks = store.initial ?? [];
    store.listen((tasks) {
      _tasks = tasks;
      notifyListeners();
      syncReminders();
    });
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  /// All tasks, newest first.
  List<TaskModel> get tasks =>
      [..._tasks]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  int get activeCount => _tasks.where((t) => !t.isCompleted).length;

  /// Active tasks due within the next 7 days.
  int get dueThisWeekCount {
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    return _tasks
        .where(
          (t) =>
              !t.isCompleted &&
              t.deadline.isAfter(now) &&
              t.deadline.isBefore(weekAhead),
        )
        .length;
  }

  /// The single most pressing task, chosen by [PriorityUtils].
  TaskModel? get priorityTask => PriorityUtils.selectPriorityTask(_tasks);

  /// Active tasks due today, earliest first.
  List<TaskModel> get todayActiveTasks {
    final now = DateTime.now();
    return _tasks.where((t) => !t.isCompleted && t.isDueOn(now)).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  /// Every task due on [day], earliest first.
  List<TaskModel> tasksDueOn(DateTime day) {
    return _tasks
        .where((t) => TaskDateUtils.isSameDay(t.deadline, day))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  TaskModel? byId(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  // Changes apply to the in-memory list right away (so the UI updates
  // instantly, even offline) and are then saved to the store.

  Future<void> add(TaskModel task) async {
    _tasks = [..._tasks, task];
    notifyListeners();
    await _reminders.syncTask(task);
    await _store.save(task, _tasks);
  }

  Future<void> update(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks = [..._tasks]..[index] = task;
    notifyListeners();
    await _reminders.syncTask(task);
    await _store.save(task, _tasks);
  }

  Future<void> delete(String id) async {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _reminders.cancelTask(id);
    await _store.delete(id, _tasks);
  }

  Future<void> setCompleted(String id, bool completed) => _change(
    id,
    (t) => t.copyWith(
      isCompleted: completed,
      completedAt: () => completed ? DateTime.now() : null,
    ),
  );

  /// Consecutive days, up to today, on which at least one task was
  /// completed. A streak stays alive until the end of the day after the
  /// last completion.
  int currentStreak({DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final days = {
      for (final t in _tasks)
        if (t.isCompleted && t.completedAt != null)
          DateUtils.dateOnly(t.completedAt!),
    };
    var day = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  Future<void> toggleReminder(String id) =>
      _change(id, (t) => t.copyWith(reminderEnabled: !t.reminderEnabled));

  /// Checking subtasks updates progress but never completes the task; that is
  /// always a deliberate "Mark Complete".
  Future<void> toggleSubtask(String taskId, String subtaskId) {
    return _change(
      taskId,
      (t) => t.copyWith(
        subtasks: [
          for (final s in t.subtasks)
            s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s,
        ],
      ),
    );
  }

  Future<void> addSubtask(String taskId, String title) {
    return _change(
      taskId,
      (t) => t.copyWith(
        subtasks: [
          ...t.subtasks,
          SubtaskModel(id: generateId(), title: title),
        ],
      ),
    );
  }

  Future<void> removeSubtask(String taskId, String subtaskId) {
    return _change(
      taskId,
      (t) => t.copyWith(
        subtasks: t.subtasks.where((s) => s.id != subtaskId).toList(),
      ),
    );
  }

  Future<void> moveSubtask(String taskId, int oldIndex, int newIndex) {
    return _change(taskId, (t) {
      final subtasks = [...t.subtasks];
      final moved = subtasks.removeAt(oldIndex);
      subtasks.insert(newIndex, moved);
      return t.copyWith(subtasks: subtasks);
    });
  }

  /// Reschedules every reminder, e.g. at startup or after a language change.
  Future<void> syncReminders() => _reminders.syncAll(_tasks);

  Future<void> _change(String id, TaskModel Function(TaskModel) change) async {
    final task = byId(id);
    if (task != null) await update(change(task));
  }

  static List<TaskModel> _sampleTasks() {
    final now = DateTime.now();
    DateTime at(int dayOffset, int hour, int minute) {
      final day = now.add(Duration(days: dayOffset));
      return DateTime(day.year, day.month, day.day, hour, minute);
    }

    var age = 0;
    TaskModel task({
      required String title,
      required String description,
      required String category,
      required DateTime deadline,
      required TaskPriority priority,
      required List<String> subtasks,
      int done = 0,
    }) {
      return TaskModel(
        id: generateId(),
        title: title,
        description: description,
        category: category,
        deadline: deadline,
        priority: priority,
        createdAt: now.subtract(Duration(seconds: ++age)),
        subtasks: [
          for (var i = 0; i < subtasks.length; i++)
            SubtaskModel(
              id: generateId(),
              title: subtasks[i],
              isDone: i < done,
            ),
        ],
      );
    }

    return [
      task(
        title: 'Psychology research outlines',
        description: 'Plan and draft the research outline for PSY 214.',
        category: 'PSY 214 · Assignment',
        deadline: at(0, 16, 0),
        priority: TaskPriority.high,
        subtasks: [
          'Review assignment brief',
          'Collect five peer-reviewed sources',
          'Create thesis statement',
          'Draft section headings',
          'Write introduction',
        ],
        done: 3,
      ),
      task(
        title: 'Calculus problem set 6',
        description: 'Complete the assigned calculus problem sets.',
        category: 'MATH 201 · Problem Set',
        deadline: at(1, 10, 0),
        priority: TaskPriority.medium,
        subtasks: [
          'Review the chapter examples',
          'Solve the first five questions',
          'Double-check the final answers',
        ],
      ),
      task(
        title: 'Student society budget',
        description: 'Prepare the student society budget summary.',
        category: 'Campus Life · Treasurer',
        deadline: at(2, 18, 0),
        priority: TaskPriority.low,
        subtasks: [
          'Collect student reimbursement requests',
          'Review event spending totals',
          'Prepare summary for committee',
        ],
      ),
      task(
        title: 'Literature response journal',
        description: 'Write a response journal entry for this week’s reading.',
        category: 'LIT 110 · Reading',
        deadline: at(4, 23, 59),
        priority: TaskPriority.medium,
        subtasks: [
          'Read the assigned chapter',
          'Note three key arguments',
          'Write the reflection paragraph',
        ],
      ),
      task(
        title: 'DSA Assignment 2',
        description: 'Implement and analyse the sorting algorithms.',
        category: 'CS 202 · Assignment',
        deadline: at(6, 23, 59),
        priority: TaskPriority.high,
        subtasks: [
          'Implement merge sort',
          'Implement quick sort',
          'Write the complexity analysis',
        ],
      ),
    ];
  }
}
