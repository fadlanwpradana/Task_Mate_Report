import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Saves app data on the device. Without [SharedPreferences] (for example in
/// widget tests) data only lives in memory for the current session.
class StorageService {
  StorageService([this._prefs]);

  final SharedPreferences? _prefs;

  static Future<StorageService> open() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  List<Map<String, dynamic>>? readList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } on FormatException {
      return null;
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    await _prefs?.setString(key, jsonEncode(items));
  }

  String? readString(String key) => _prefs?.getString(key);

  Future<void> writeString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
}

int _idCounter = 0;

String generateId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
