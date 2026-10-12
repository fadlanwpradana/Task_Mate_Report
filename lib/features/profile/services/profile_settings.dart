import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';

enum AppAppearance { system, light, dark }

/// Profile details and app preferences from the Profile tab, saved on the
/// device.
class ProfileSettings extends ChangeNotifier {
  ProfileSettings(this._storage) {
    final raw = _storage.readString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _name = json['name'] as String?;
      _studyProgram = json['studyProgram'] as String? ?? '';
      _taskReminders = json['taskReminders'] as bool? ?? true;
      _weeklyEncouragement = json['weeklyEncouragement'] as bool? ?? true;
      _groupUpdates = json['groupUpdates'] as bool? ?? false;
      _weekStartsMonday = json['weekStartsMonday'] as bool? ?? true;
      _appearance =
          AppAppearance.values.asNameMap()[json['appearance']] ??
          AppAppearance.system;
    } on FormatException {
      // Keep defaults if the saved value is unreadable.
    }
  }

  static const _key = 'profile';

  final StorageService _storage;

  String? _name;
  String _studyProgram = '';
  bool _taskReminders = true;
  bool _weeklyEncouragement = true;
  bool _groupUpdates = false;
  bool _weekStartsMonday = true;
  AppAppearance _appearance = AppAppearance.system;

  /// Name chosen in "Edit profile"; null means use the account name.
  String? get name => _name;
  String get studyProgram => _studyProgram;

  /// Master switch for deadline reminders.
  bool get taskReminders => _taskReminders;

  /// Weekly Sunday progress recap notification.
  bool get weeklyEncouragement => _weeklyEncouragement;

  /// Saved for when group tasks exist; has no effect yet.
  bool get groupUpdates => _groupUpdates;
  bool get weekStartsMonday => _weekStartsMonday;
  AppAppearance get appearance => _appearance;

  Future<void> updateProfile({
    required String name,
    required String studyProgram,
  }) {
    _name = name;
    _studyProgram = studyProgram;
    return _save();
  }

  /// Forgets the edited name (e.g. on sign out).
  Future<void> clearName() {
    _name = null;
    return _save();
  }

  Future<void> setTaskReminders(bool value) {
    _taskReminders = value;
    return _save();
  }

  Future<void> setWeeklyEncouragement(bool value) {
    _weeklyEncouragement = value;
    return _save();
  }

  Future<void> setGroupUpdates(bool value) {
    _groupUpdates = value;
    return _save();
  }

  Future<void> setWeekStartsMonday(bool value) {
    _weekStartsMonday = value;
    return _save();
  }

  Future<void> setAppearance(AppAppearance value) {
    _appearance = value;
    return _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _storage.writeString(
      _key,
      jsonEncode({
        'name': _name,
        'studyProgram': _studyProgram,
        'taskReminders': _taskReminders,
        'weeklyEncouragement': _weeklyEncouragement,
        'groupUpdates': _groupUpdates,
        'weekStartsMonday': _weekStartsMonday,
        'appearance': _appearance.name,
      }),
    );
  }
}
