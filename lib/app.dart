import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/screens/firebase_setup_screen.dart';
import 'core/services/firebase_service.dart';
import 'core/services/locale_controller.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/intro/screens/onboarding_screen.dart';
import 'features/intro/widgets/brand_background.dart';
import 'features/intro/widgets/intro_overlay.dart';
import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/profile/services/profile_settings.dart';
import 'features/tasks/screens/task_detail_screen.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/task_mate_logo.dart';

class TaskMateApp extends StatefulWidget {
  const TaskMateApp({
    super.key,
    this.offlineMode = const bool.fromEnvironment(
      'TASK_MATE_OFFLINE',
      defaultValue: false,
    ),
    this.firebaseInitializer,
    this.authStateChanges,
    this.services,
    this.notifications,
    this.showIntro = true,
  });

  final bool offlineMode;
  final Future<void> Function()? firebaseInitializer;
  final Stream<User?>? authStateChanges;

  /// App repositories. When omitted, data is kept in memory only.
  final AppServices? services;

  /// Device reminders; tapping one opens its task.
  final NotificationService? notifications;

  /// Plays the animated intro at startup (off in tests).
  final bool showIntro;

  @override
  State<TaskMateApp> createState() => _TaskMateAppState();
}

class _TaskMateAppState extends State<TaskMateApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late Future<void> _firebaseInitialization;

  /// Created once; `userChanges` also fires when the display name is set
  /// right after registering.
  Stream<User?>? _authChanges;
  late final AppServices _services =
      widget.services ?? AppServices.fromStorage(StorageService());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _services.profile.addListener(_applyAppearance);
    AppColors.setDark(_wantsDark());
    if (!widget.offlineMode) {
      _initializeFirebase();
    }
    final notifications = widget.notifications;
    if (notifications != null) {
      notifications.onOpenTask = _openTask;
      final launchTaskId = notifications.takeLaunchTaskId();
      if (launchTaskId != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openTask(launchTaskId),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _services.profile.removeListener(_applyAppearance);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _applyAppearance();

  bool _wantsDark() {
    return switch (_services.profile.appearance) {
      AppAppearance.light => false,
      AppAppearance.dark => true,
      AppAppearance.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
  }

  /// Switches light/dark. Many widgets read [AppColors] directly (including
  /// const ones Flutter would otherwise skip), so rebuild every element.
  void _applyAppearance() {
    final dark = _wantsDark();
    if (dark == AppColors.isDark || !mounted) return;
    AppColors.setDark(dark);
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
    setState(() {});
  }

  void _openTask(String taskId) {
    if (_services.tasks.byId(taskId) == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskId: taskId)),
    );
  }

  void _initializeFirebase() {
    _firebaseInitialization =
        widget.firebaseInitializer?.call() ?? FirebaseService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: ValueListenableBuilder<Locale>(
        valueListenable: _services.locale,
        builder: (context, locale, _) => _buildApp(locale),
      ),
    );
  }

  Widget _buildApp(Locale locale) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: widget.showIntro
          ? (context, child) => IntroGate(child: child!)
          : null,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(dark: AppColors.isDark),
      locale: locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: widget.offlineMode
          ? const _SignedOutHome(offlineMode: true)
          : FutureBuilder<void>(
              future: _firebaseInitialization,
              builder: (context, initialization) {
                if (initialization.hasError) {
                  return FirebaseSetupScreen(
                    error: initialization.error!,
                    onRetry: () => setState(_initializeFirebase),
                  );
                }
                if (initialization.connectionState != ConnectionState.done) {
                  return const _StartupLoadingScreen();
                }
                return StreamBuilder<User?>(
                  stream: _authChanges ??=
                      widget.authStateChanges ??
                      FirebaseAuth.instance.userChanges(),
                  builder: (context, auth) {
                    if (auth.hasError) {
                      return FirebaseSetupScreen(
                        error: auth.error!,
                        onRetry: () => setState(_initializeFirebase),
                      );
                    }
                    if (auth.connectionState == ConnectionState.waiting) {
                      return const _StartupLoadingScreen();
                    }
                    if (auth.data == null) {
                      return const _SignedOutHome();
                    }
                    return MainNavigationScreen(user: auth.data!);
                  },
                );
              },
            ),
    );
  }
}

/// Signed out: the welcome carousel the first time, Login after that.
class _SignedOutHome extends StatelessWidget {
  const _SignedOutHome({this.offlineMode = false});

  final bool offlineMode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppScope.of(context).onboarding,
      builder: (context, seen, _) => seen
          ? LoginScreen(offlineMode: offlineMode)
          : OnboardingScreen(offlineMode: offlineMode),
    );
  }
}

/// Shown while Firebase starts or the sign-in state loads; matches the end
/// of the intro so the hand-off is seamless.
class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BrandBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaskMateLogo(size: 96),
              SizedBox(height: 32),
              LoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}
