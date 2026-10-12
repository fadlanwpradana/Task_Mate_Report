import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_mate_v4/app.dart';
import 'package:task_mate_v4/core/app_scope.dart';
import 'package:task_mate_v4/core/services/storage_service.dart';
import 'package:task_mate_v4/features/intro/widgets/intro_overlay.dart';

/// A signed-in Firebase user, for routing tests.
class _FakeUser implements User {
  @override
  String get uid => 'raka';

  @override
  String? get displayName => 'Raka Pratama';

  @override
  String? get email => 'raka@campus.ac.id';

  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppServices> _servicesWith({required bool onboardingSeen}) async {
  SharedPreferences.setMockInitialValues({});
  final services = AppServices.fromStorage(
    StorageService(await SharedPreferences.getInstance()),
  );
  if (onboardingSeen) await services.onboarding.complete();
  return services;
}

void main() {
  testWidgets('Animated intro plays at startup, then shows the app', (
    tester,
  ) async {
    await tester.pumpWidget(const TaskMateApp(offlineMode: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(IntroScreen), findsOneWidget);

    // Still animating halfway through.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(IntroScreen), findsOneWidget);

    // After the entrance (2.4 s) and fade-out, only the app remains.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsNothing);
    expect(find.text('Stay on top of every task'), findsOneWidget);
  });

  testWidgets('First launch: welcome carousel, then Register', (tester) async {
    final services = await _servicesWith(onboardingSeen: false);
    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();

    expect(find.text('Stay on top of every task'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Learn together'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Chat with classmates'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(services.onboarding.seen, isTrue);

    // Register sits on top of Login; going back lands on Login.
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Stay on top of every task'), findsNothing);
  });

  testWidgets('"Skip" and "I already have an account" lead to Login', (
    tester,
  ) async {
    final services = await _servicesWith(onboardingSeen: false);
    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    // Login is the first page now: no back arrow.
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('Later launches skip the carousel and open Login', (
    tester,
  ) async {
    final services = await _servicesWith(onboardingSeen: true);
    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();

    expect(find.text('Stay on top of every task'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Demo login and logout return to Login, not the carousel', (
    tester,
  ) async {
    final services = await _servicesWith(onboardingSeen: true);
    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Student 👋'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Stay on top of every task'), findsNothing);
  });

  testWidgets('Signed-out account: Login, with Google sign-in', (tester) async {
    final services = await _servicesWith(onboardingSeen: true);
    await tester.pumpWidget(
      TaskMateApp(
        offlineMode: false,
        firebaseInitializer: () async {},
        authStateChanges: Stream<User?>.value(null),
        services: services,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Signed-in account opens straight to Home', (tester) async {
    final services = await _servicesWith(onboardingSeen: true);
    await tester.pumpWidget(
      TaskMateApp(
        offlineMode: false,
        firebaseInitializer: () async {},
        authStateChanges: Stream<User?>.value(_FakeUser()),
        services: services,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Raka 👋'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('Offline demo has no Google sign-in', (tester) async {
    final services = await _servicesWith(onboardingSeen: true);
    await tester.pumpWidget(TaskMateApp(offlineMode: true, services: services));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });
}
