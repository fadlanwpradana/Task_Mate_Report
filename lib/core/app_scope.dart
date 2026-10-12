import 'package:flutter/widgets.dart';

import '../features/chat/services/chat_repository.dart';
import '../features/chat/services/firestore_chat_repository.dart';
import '../features/chat/services/local_chat_repository.dart';
import '../features/community/services/community_repository.dart';
import '../features/community/services/firestore_community_repository.dart';
import '../features/community/services/local_community_repository.dart';
import '../features/intro/services/onboarding_controller.dart';
import '../features/profile/services/profile_settings.dart';
import '../features/tasks/services/task_repository.dart';
import '../features/tasks/services/task_store.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

class AppServices {
  AppServices({
    required this.tasks,
    required this.profile,
    required this.community,
    required this.chat,
    required this.locale,
    required this.onboarding,
    this.online = false,
  });

  factory AppServices.fromStorage(
    StorageService storage, {
    ReminderScheduler? reminders,
    bool online = false,
    Duration chatReplyDelay = const Duration(milliseconds: 2200),
  }) {
    final locale = LocaleController(storage);
    return AppServices(
      // Online, tasks load from the signed-in user's account.
      tasks: online
          ? TaskRepository.withStore(EmptyTaskStore(), reminders: reminders)
          : TaskRepository(storage, reminders: reminders),
      profile: ProfileSettings(storage),
      // Real accounts use Firestore; offline mode uses the on-device demo.
      community: online
          ? FirestoreCommunityRepository()
          : LocalCommunityRepository(storage),
      chat: online
          ? FirestoreChatRepository()
          : LocalChatRepository(
              storage,
              replyDelay: chatReplyDelay,
              languageCode: () => locale.value.languageCode,
            ),
      locale: locale,
      onboarding: OnboardingController(storage),
      online: online,
    );
  }

  final TaskRepository tasks;
  final ProfileSettings profile;
  final CommunityRepository community;
  final ChatRepository chat;
  final LocaleController locale;
  final OnboardingController onboarding;

  /// Whether tasks, community, and chat use Firestore.
  final bool online;

  /// Display name of the signed-in user, used as the author of new posts and
  /// comments. Set by the main navigation screen.
  String currentUserName = '';
}

/// Makes the app's repositories available to every screen, including pushed
/// routes. Screens rebuild by listening to the repositories directly.
class AppScope extends InheritedWidget {
  const AppScope({required this.services, required super.child, super.key});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
