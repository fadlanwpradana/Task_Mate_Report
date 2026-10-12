import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';

/// Schedules device reminders for tasks.
abstract class ReminderScheduler {
  /// Replaces any reminders for [task] with ones matching its current state.
  Future<void> syncTask(TaskModel task);

  Future<void> cancelTask(String taskId);

  Future<void> syncAll(Iterable<TaskModel> tasks) async {
    for (final task in tasks) {
      await syncTask(task);
    }
  }
}

/// Used in tests and on platforms without notification support.
class NoopReminderScheduler extends ReminderScheduler {
  @override
  Future<void> syncTask(TaskModel task) async {}

  @override
  Future<void> cancelTask(String taskId) async {}
}

abstract final class ReminderTimes {
  /// Reminders fire 1 day and 1 hour before the deadline.
  static const offsets = [Duration(days: 1), Duration(hours: 1)];

  /// Reminder times for [task] that are still in the future.
  static List<DateTime> upcoming(TaskModel task, {DateTime? now}) {
    if (!task.reminderEnabled || task.isCompleted) return const [];
    final current = now ?? DateTime.now();
    return [
      for (final offset in offsets)
        if (task.deadline.subtract(offset).isAfter(current))
          task.deadline.subtract(offset),
    ];
  }
}

/// Local Android notifications for task reminders. Works offline; no server
/// is involved.
class NotificationService extends ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Language used for reminder text.
  Locale Function() localeOf = () => const Locale('en');

  /// Called with a task id when the user taps a reminder.
  void Function(String taskId)? onOpenTask;

  /// Profile switches: all deadline reminders, and the weekly recap.
  bool Function() taskRemindersEnabled = () => true;
  bool Function() weeklyRecapEnabled = () => false;

  /// Weekly recap: Sundays at 19:00.
  static const _recapId = 0x40000000;
  static const _recapHour = 19;

  bool _ready = false;
  bool _permissionRequested = false;
  String? _launchTaskId;

  static const _channelId = 'task_reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      tz_data.initializeTimeZones();
      await initializeDateFormatting();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final taskId = response.payload;
          if (taskId != null) onOpenTask?.call(taskId);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchTaskId = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
    }
  }

  /// The task whose reminder launched the app, if any. Returned once.
  String? takeLaunchTaskId() {
    final id = _launchTaskId;
    _launchTaskId = null;
    return id;
  }

  @override
  Future<void> syncTask(TaskModel task) async {
    if (!_ready) return;
    try {
      await cancelTask(task.id);
      if (!taskRemindersEnabled()) return;
      final times = ReminderTimes.upcoming(task);
      if (times.isEmpty) return;
      await _ensurePermission();

      final locale = localeOf();
      final l10n = lookupAppLocalizations(locale);
      final deadlineTime = DateFormat.jm(locale.toLanguageTag())
          .format(task.deadline);
      final details = _details(l10n);
      final mode = await _scheduleMode();

      for (var i = 0; i < ReminderTimes.offsets.length; i++) {
        final time = task.deadline.subtract(ReminderTimes.offsets[i]);
        if (!times.contains(time)) continue;
        await _plugin.zonedSchedule(
          id: _notificationId(task.id, i),
          // A one-off reminder only needs the right instant, so UTC works
          // regardless of the device time zone.
          scheduledDate: tz.TZDateTime.from(time, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
          title: task.title,
          body: i == 0
              ? l10n.reminderDayBody(deadlineTime)
              : l10n.reminderHourBody(deadlineTime),
          payload: task.id,
        );
      }
    } catch (error) {
      debugPrint('Could not schedule reminder for ${task.id}: $error');
    }
  }

  @override
  Future<void> cancelTask(String taskId) async {
    if (!_ready) return;
    for (var i = 0; i < ReminderTimes.offsets.length; i++) {
      await _plugin.cancel(id: _notificationId(taskId, i));
    }
  }

  /// Clears every scheduled notification and schedules them again from the
  /// current tasks and Profile switches.
  @override
  Future<void> syncAll(Iterable<TaskModel> tasks) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Could not clear reminders: $error');
    }
    await super.syncAll(tasks);
    await _syncWeeklyRecap();
  }

  Future<void> _syncWeeklyRecap() async {
    try {
      await _plugin.cancel(id: _recapId);
      if (!weeklyRecapEnabled()) return;
      await _ensurePermission();
      final l10n = lookupAppLocalizations(localeOf());
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day, _recapHour);
      while (next.weekday != DateTime.sunday || !next.isAfter(now)) {
        next = DateTime(next.year, next.month, next.day + 1, _recapHour);
      }
      await _plugin.zonedSchedule(
        id: _recapId,
        scheduledDate: tz.TZDateTime.from(next, tz.UTC),
        notificationDetails: _details(l10n),
        androidScheduleMode: await _scheduleMode(),
        title: l10n.weeklyRecapTitle,
        body: l10n.weeklyRecapBody,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (error) {
      debugPrint('Could not schedule the weekly recap: $error');
    }
  }

  NotificationDetails _details(AppLocalizations l10n) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    return await _android?.canScheduleExactNotifications() == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    await _android?.requestNotificationsPermission();
  }

  /// Stable id per task and reminder slot (String.hashCode is not stable
  /// across app launches, so use FNV-1a).
  static int _notificationId(String taskId, int slot) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    // Stays below [_recapId].
    return (hash & 0x1FFFFFFF) * ReminderTimes.offsets.length + slot;
  }
}
