import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.open();
  final notifications = NotificationService();
  await notifications.initialize();

  // Offline demo (no Firebase): --dart-define=TASK_MATE_OFFLINE=true
  const offline = bool.fromEnvironment('TASK_MATE_OFFLINE');
  final services = AppServices.fromStorage(
    storage,
    reminders: notifications,
    online: !offline,
  );
  notifications
    ..localeOf = (() => services.locale.value)
    ..taskRemindersEnabled = (() => services.profile.taskReminders)
    ..weeklyRecapEnabled = (() => services.profile.weeklyEncouragement);
  // Reschedule reminders when the language (reminder text) or the Profile
  // notification switches change.
  services.locale.addListener(services.tasks.syncReminders);
  var reminderSettings = _reminderSettings(services);
  services.profile.addListener(() {
    final current = _reminderSettings(services);
    if (current == reminderSettings) return;
    reminderSettings = current;
    services.tasks.syncReminders();
  });

  runApp(
    TaskMateApp(
      offlineMode: offline,
      services: services,
      notifications: notifications,
    ),
  );
  // After the first frame, so a permission prompt has a visible app behind it.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => services.tasks.syncReminders(),
  );
}

(bool, bool) _reminderSettings(AppServices services) =>
    (services.profile.taskReminders, services.profile.weeklyEncouragement);
