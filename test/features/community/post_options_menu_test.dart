import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/core/app_scope.dart';
import 'package:task_mate_v4/core/services/locale_controller.dart';
import 'package:task_mate_v4/core/services/storage_service.dart';
import 'package:task_mate_v4/features/chat/services/local_chat_repository.dart';
import 'package:task_mate_v4/features/community/services/local_community_repository.dart';
import 'package:task_mate_v4/features/community/widgets/post_options_menu.dart';
import 'package:task_mate_v4/features/intro/services/onboarding_controller.dart';
import 'package:task_mate_v4/features/profile/services/profile_settings.dart';
import 'package:task_mate_v4/features/tasks/services/task_repository.dart';
import 'package:task_mate_v4/features/tasks/services/task_store.dart';
import 'package:task_mate_v4/l10n/app_localizations.dart';
import 'package:task_mate_v4/models/post_model.dart';

class _Fixture {
  _Fixture(this.services, this.repository, this.post);

  final AppServices services;
  final LocalCommunityRepository repository;
  final PostModel post;

  void dispose() {
    services.tasks.dispose();
    services.profile.dispose();
    services.community.dispose();
    services.chat.dispose();
    services.locale.dispose();
    services.onboarding.dispose();
  }
}

Future<_Fixture> _fixture({String currentUserId = 'me'}) async {
  final storage = StorageService();
  final repository = LocalCommunityRepository(storage);
  final post = PostModel(
    id: 'post-id',
    authorId: LocalCommunityRepository.meId,
    authorName: 'Ari',
    type: PostType.discussion,
    title: 'Post title',
    body: 'Post body',
    createdAt: DateTime.utc(2026),
  );
  await repository.addPost(post, postId: post.id);
  final services = AppServices(
    tasks: TaskRepository.withStore(EmptyTaskStore()),
    profile: ProfileSettings(storage),
    community: repository,
    chat: LocalChatRepository(storage),
    locale: LocaleController(storage),
    onboarding: OnboardingController(storage),
    currentUserId: currentUserId,
    online: false,
  );
  return _Fixture(services, repository, post);
}

Widget _app(_Fixture fixture) => AppScope(
  services: fixture.services,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListenableBuilder(
        listenable: fixture.repository,
        builder: (context, _) {
          final post = fixture.repository.postById(fixture.post.id);
          if (post == null) return const Text('No posts');
          return Column(
            children: [
              Text(post.title),
              PostOptionsMenu(post: post),
            ],
          );
        },
      ),
    ),
  ),
);

void main() {
  testWidgets('owner can confirm deletion from the only post menu action', (
    tester,
  ) async {
    final fixture = await _fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_app(fixture));

    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete post?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(fixture.repository.postById(fixture.post.id), isNull);
    expect(find.text('No posts'), findsOneWidget);
    expect(find.text('Post deleted'), findsOneWidget);
    expect(find.text('Post has been deleted successfully.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('non-owner cannot access the post options menu', (tester) async {
    final fixture = await _fixture(currentUserId: 'another-user');
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_app(fixture));

    expect(find.byTooltip('Post options'), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });
}
