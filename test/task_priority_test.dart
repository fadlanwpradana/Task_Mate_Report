import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/core/services/notification_service.dart';
import 'package:task_mate_v4/core/utils/priority_utils.dart';
import 'package:task_mate_v4/core/utils/task_date_utils.dart';
import 'package:task_mate_v4/l10n/app_localizations_en.dart';
import 'package:task_mate_v4/l10n/app_localizations_id.dart';
import 'package:task_mate_v4/models/subtask_model.dart';
import 'package:task_mate_v4/models/task_model.dart';

final _now = DateTime(2026, 10, 10, 8);

TaskModel _task(
  String title, {
  required Duration dueIn,
  TaskPriority priority = TaskPriority.medium,
  List<bool> subtasks = const [],
  bool completed = false,
  bool reminder = true,
}) {
  return TaskModel(
    id: title,
    title: title,
    deadline: _now.add(dueIn),
    createdAt: _now,
    priority: priority,
    isCompleted: completed,
    reminderEnabled: reminder,
    subtasks: [
      for (var i = 0; i < subtasks.length; i++)
        SubtaskModel(id: '$title-$i', title: 'Step $i', isDone: subtasks[i]),
    ],
  );
}

void main() {
  group('PriorityUtils.score', () {
    test('matches the approved formula', () {
      // High, 3 days left, no subtasks: 11.25 + 30 + 7.5
      final high = _task(
        'high',
        dueIn: const Duration(days: 3),
        priority: TaskPriority.high,
      );
      expect(PriorityUtils.score(high, now: _now), closeTo(48.75, 0.01));

      // Low, due tomorrow: 22.5 + 8 + 7.5
      final low = _task(
        'low',
        dueIn: const Duration(days: 1),
        priority: TaskPriority.low,
      );
      expect(PriorityUtils.score(low, now: _now), closeTo(38, 0.01));

      // Remaining work: 3 of 4 subtasks done leaves 15 × 0.25.
      final mostlyDone = _task(
        'work',
        dueIn: const Duration(days: 1),
        subtasks: [true, true, true, false],
      );
      expect(PriorityUtils.workPoints(mostlyDone), closeTo(3.75, 0.01));
    });

    test('is not purely by priority or purely by deadline', () {
      final highLater = _task(
        'High in 3 days',
        dueIn: const Duration(days: 3),
        priority: TaskPriority.high,
      );
      final lowTomorrow = _task(
        'Low tomorrow',
        dueIn: const Duration(days: 1),
        priority: TaskPriority.low,
      );
      final lowInSixHours = _task(
        'Low in 6 hours',
        dueIn: const Duration(hours: 6),
        priority: TaskPriority.low,
      );

      final ranked = PriorityUtils.rank([
        lowTomorrow,
        highLater,
        lowInSixHours,
      ], now: _now).map((t) => t.title);
      expect(ranked, ['Low in 6 hours', 'High in 3 days', 'Low tomorrow']);
    });

    test('completed tasks score 0 and are never the priority task', () {
      final done = _task(
        'done',
        dueIn: const Duration(hours: 1),
        priority: TaskPriority.high,
        completed: true,
      );
      expect(PriorityUtils.score(done, now: _now), 0);
      expect(PriorityUtils.selectPriorityTask([done], now: _now), isNull);
    });
  });

  group('Overdue tasks', () {
    test('always rank above tasks that are still on time', () {
      final overdueLow = _task(
        'Overdue low',
        dueIn: const Duration(minutes: -5),
        priority: TaskPriority.low,
      );
      final highDueSoon = _task(
        'High due in 1 hour',
        dueIn: const Duration(hours: 1),
        priority: TaskPriority.high,
      );
      expect(
        PriorityUtils.selectPriorityTask([
          highDueSoon,
          overdueLow,
        ], now: _now)?.title,
        'Overdue low',
      );
    });

    test('are ordered by priority + work, then longest overdue', () {
      final oldLow = _task(
        'Old low',
        dueIn: const Duration(days: -5),
        priority: TaskPriority.low,
      );
      final recentHigh = _task(
        'Recent high',
        dueIn: const Duration(days: -1),
        priority: TaskPriority.high,
      );
      final olderHigh = _task(
        'Older high',
        dueIn: const Duration(days: -3),
        priority: TaskPriority.high,
      );
      final ranked = PriorityUtils.rank([
        oldLow,
        recentHigh,
        olderHigh,
      ], now: _now).map((t) => t.title);
      expect(ranked, ['Older high', 'Recent high', 'Old low']);
    });
  });

  group('TaskDateUtils.countdown', () {
    final en = AppLocalizationsEn();
    final id = AppLocalizationsId();

    test('formats time left', () {
      expect(
        TaskDateUtils.countdown(
          en,
          _now.add(const Duration(hours: 8, minutes: 24)),
          now: _now,
        ),
        '08h 24m left',
      );
      expect(
        TaskDateUtils.countdown(
          en,
          _now.add(const Duration(days: 2, hours: 3)),
          now: _now,
        ),
        '2 days left',
      );
      expect(
        TaskDateUtils.countdown(
          id,
          _now.add(const Duration(days: 2, hours: 3)),
          now: _now,
        ),
        '2 hari lagi',
      );
    });

    test('formats overdue time', () {
      expect(
        TaskDateUtils.countdown(
          en,
          _now.subtract(const Duration(days: 3)),
          now: _now,
        ),
        '3 days overdue',
      );
      expect(
        TaskDateUtils.countdown(
          en,
          _now.subtract(const Duration(hours: 1)),
          now: _now,
        ),
        '1 hour overdue',
      );
      expect(
        TaskDateUtils.countdown(
          id,
          _now.subtract(const Duration(seconds: 20)),
          now: _now,
        ),
        'Terlambat 1 menit',
      );
    });
  });

  group('ReminderTimes.upcoming', () {
    test('schedules 1 day and 1 hour before the deadline', () {
      final task = _task('t', dueIn: const Duration(days: 3));
      expect(ReminderTimes.upcoming(task, now: _now), [
        task.deadline.subtract(const Duration(days: 1)),
        task.deadline.subtract(const Duration(hours: 1)),
      ]);
    });

    test('skips reminder times that already passed', () {
      final task = _task('t', dueIn: const Duration(hours: 5));
      expect(ReminderTimes.upcoming(task, now: _now), [
        task.deadline.subtract(const Duration(hours: 1)),
      ]);
    });

    test('has none when the reminder is off or the task is done', () {
      expect(
        ReminderTimes.upcoming(
          _task('off', dueIn: const Duration(days: 3), reminder: false),
          now: _now,
        ),
        isEmpty,
      );
      expect(
        ReminderTimes.upcoming(
          _task('done', dueIn: const Duration(days: 3), completed: true),
          now: _now,
        ),
        isEmpty,
      );
    });
  });

  test('reads tasks saved by the previous version', () {
    final task = TaskModel.fromJson({
      'id': 'old',
      'title': 'Old task',
      'subject': 'Database Systems',
      'notes': 'Normalize to 3NF',
      'priority': 'high',
      'deadline': '2026-10-12T23:59:00.000',
      'startMinutes': 540,
      'endMinutes': 600,
      'isCompleted': false,
      'reminderEnabled': true,
      'subtasks': <Map<String, dynamic>>[],
      'createdAt': '2026-10-10T08:00:00.000',
    });
    expect(task.category, 'Database Systems');
    expect(task.description, 'Normalize to 3NF');
  });
}
