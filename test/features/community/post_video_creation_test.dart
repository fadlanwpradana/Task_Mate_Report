import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_mate_v4/core/app_scope.dart';
import 'package:task_mate_v4/core/services/locale_controller.dart';
import 'package:task_mate_v4/core/services/storage_service.dart';
import 'package:task_mate_v4/features/chat/services/local_chat_repository.dart';
import 'package:task_mate_v4/features/community/screens/create_post_screen.dart';
import 'package:task_mate_v4/features/community/services/cloudinary_service.dart';
import 'package:task_mate_v4/features/community/services/firestore_community_repository.dart';
import 'package:task_mate_v4/features/community/services/post_video_service.dart';
import 'package:task_mate_v4/features/intro/services/onboarding_controller.dart';
import 'package:task_mate_v4/features/profile/services/profile_settings.dart';
import 'package:task_mate_v4/features/tasks/services/task_repository.dart';
import 'package:task_mate_v4/features/tasks/services/task_store.dart';
import 'package:task_mate_v4/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

const _videoUrl = 'https://res.cloudinary.com/mr5ddhj5/video/upload/clip.mp4';

class _Fixture {
  _Fixture({required this.services, required this.firestore});

  final AppServices services;
  final FakeFirebaseFirestore firestore;

  void dispose() {
    services.tasks.dispose();
    services.profile.dispose();
    services.community.dispose();
    services.chat.dispose();
    services.locale.dispose();
    services.onboarding.dispose();
  }
}

class _SelectedVideoService extends PostVideoService {
  _SelectedVideoService(this.selectedVideo);

  final SelectedPostVideo selectedVideo;

  @override
  Future<SelectedPostVideo?> pickAndValidateFromGallery() async =>
      selectedVideo;
}

class _CloudinaryStub extends CloudinaryService {
  _CloudinaryStub({this.uploadError});

  final Object? uploadError;

  @override
  Future<String> uploadVideo({
    required XFile file,
    required Duration duration,
    required int expectedSizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    final error = uploadError;
    if (error != null) throw error;
    onProgress?.call(1);
    return _videoUrl;
  }
}

Future<_Fixture> _fixture() async {
  final storage = StorageService();
  final firestore = FakeFirebaseFirestore();
  final community = FirestoreCommunityRepository(firestore: firestore)
    ..signIn('alice');
  final services = AppServices(
    tasks: TaskRepository.withStore(EmptyTaskStore()),
    profile: ProfileSettings(storage),
    community: community,
    chat: LocalChatRepository(storage),
    locale: LocaleController(storage),
    onboarding: OnboardingController(storage),
    currentUserId: 'alice',
    online: true,
  )..currentUserName = 'Ari';
  return _Fixture(services: services, firestore: firestore);
}

Widget _app(_Fixture fixture, {required Object? uploadError}) => AppScope(
  services: fixture.services,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreatePostScreen(
                videoService: _SelectedVideoService(_selectedVideo()),
                cloudinaryService: _CloudinaryStub(uploadError: uploadError),
              ),
            ),
          ),
          child: const Text('Open create post'),
        ),
      ),
    ),
  ),
);

SelectedPostVideo _selectedVideo() {
  final controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl))
    ..value = VideoPlayerValue(
      duration: const Duration(seconds: 8),
      size: const Size(640, 360),
      isInitialized: true,
    );
  return SelectedPostVideo(
    file: XFile.fromData(Uint8List.fromList([0]), name: 'clip.mp4'),
    sizeBytes: 1,
    duration: const Duration(seconds: 8),
    controller: controller,
  );
}

Future<void> _fillPostAndChooseVideo(WidgetTester tester) async {
  await tester.tap(find.text('Open create post'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'A study clip');
  await tester.enterText(find.byType(TextFormField).at(1), 'Video details');
  await tester.tap(find.text('Choose video'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Post'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('publishes a video post after Cloudinary returns its URL', (
    tester,
  ) async {
    final fixture = await _fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_app(fixture, uploadError: null));

    await _fillPostAndChooseVideo(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    final posts = await fixture.firestore.collection('posts').get();
    expect(posts.docs, hasLength(1));
    expect(posts.docs.single.data()['title'], 'A study clip');
    expect(posts.docs.single.data()['mediaType'], 'video');
    expect(posts.docs.single.data()['videoUrl'], _videoUrl);
    expect(find.text('Open create post'), findsOneWidget);
    expect(find.text('Post published'), findsOneWidget);
  });

  testWidgets('keeps the draft and creates no post when upload fails', (
    tester,
  ) async {
    final fixture = await _fixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      _app(
        fixture,
        uploadError: const CloudinaryUploadException(400, 'MP4 is not allowed'),
      ),
    );

    await _fillPostAndChooseVideo(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(
      await fixture.firestore.collection('posts').get().then((q) => q.docs),
      isEmpty,
    );
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('A study clip'), findsOneWidget);
    expect(find.text('Video details'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Remove video'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byTooltip('Remove video'), findsOneWidget);
    expect(find.textContaining('MP4 is not allowed'), findsOneWidget);
  });
}
