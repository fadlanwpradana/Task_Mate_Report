import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // As with the phone's "remove animations" setting, endless decorative
  // animations (the intro background, loading dots) stand still, so tests
  // can wait for the UI to settle.
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  await testMain();
}
