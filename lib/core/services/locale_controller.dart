import 'package:flutter/material.dart';

import 'storage_service.dart';

class LocaleController extends ValueNotifier<Locale> {
  LocaleController(this._storage)
    : super(Locale(_storage.readString(_key) ?? 'en'));

  static const supportedLocales = [Locale('en'), Locale('id')];
  static const _key = 'locale';

  final StorageService _storage;

  Future<void> setLocale(Locale locale) async {
    value = locale;
    await _storage.writeString(_key, locale.languageCode);
  }
}
