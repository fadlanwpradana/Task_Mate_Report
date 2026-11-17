import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_mate_v4/core/database/app_database.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // As with the phone's "remove animations" setting, endless decorative
  // animations (the intro background, loading dots) stand still, so tests
  // can wait for the UI to settle.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.testDatabasePathOverride = inMemoryDatabasePath;
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  await testMain();
}
