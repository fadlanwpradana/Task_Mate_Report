import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';

/// Remembers whether the welcome carousel has been shown on this device.
/// It shows once after install; after that, signed-out users go straight to
/// Login.
class OnboardingController extends ValueNotifier<bool> {
  OnboardingController(this._storage)
    : super(_storage.readString(_key) == 'true');

  static const _key = 'onboardingSeen';

  final StorageService _storage;

  bool get seen => value;

  Future<void> complete() async {
    value = true;
    await _storage.writeString(_key, 'true');
  }
}
