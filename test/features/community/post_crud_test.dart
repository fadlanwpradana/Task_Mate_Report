import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/features/community/services/firestore_community_repository.dart';
import 'package:task_mate_v4/features/community/services/local_community_repository.dart';
import 'package:task_mate_v4/core/services/storage_service.dart';
import 'package:task_mate_v4/models/post_model.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

PostModel _post(String id, {List<String> imageUrls = const []}) => PostModel(
  id: id,
  authorName: 'Ari',
  type: PostType.discussion,
  title: 'Original title',
  body: 'Original body',
  imageUrls: imageUrls,
  createdAt: DateTime.utc(2026),
);

void main() {
  group('Firestore community post CRUD (fake Firestore)', () {
    test(
      'creates text-only and photo posts with stable document IDs',
      () async {
        final db = FakeFirebaseFirestore();
        final repository = FirestoreCommunityRepository(firestore: db)
          ..signIn('alice');
        addTearDown(repository.dispose);

        await repository.addPost(_post('text-post'), postId: 'text-post');
        await repository.addPost(
          _post('photo-post', imageUrls: const ['https://example.test/p.jpg']),
          postId: 'photo-post',
        );

        final text = await db.collection('posts').doc('text-post').get();
        final photo = await db.collection('posts').doc('photo-post').get();
        expect(text.exists, isTrue);
        expect(text.data()?['imageUrls'], isEmpty);
        expect(photo.data()?['imageUrls'], ['https://example.test/p.jpg']);
        expect(photo.data()?['authorId'], 'alice');
      },
    );

    test(
      'creates and deletes a video post without affecting other posts',
      () async {
        final db = FakeFirebaseFirestore();
        final repository = FirestoreCommunityRepository(firestore: db)
          ..signIn('alice');
        addTearDown(repository.dispose);
        final videoPost = PostModel(
          id: 'video-post',
          authorName: 'Ari',
          authorId: 'original-author',
          type: PostType.discussion,
          title: 'A video post',
          body: 'Video details',
          mediaType: PostMediaType.video,
          videoUrl: 'https://res.cloudinary.com/demo/video/upload/clip.mp4',
          createdAt: DateTime.utc(2026),
          likeCount: 2,
          viewCount: 3,
        );

        await repository.addPost(videoPost, postId: videoPost.id);
        await repository.addPost(
          _post('unrelated-post'),
          postId: 'unrelated-post',
        );

        final storedVideo = await db
            .collection('posts')
            .doc(videoPost.id)
            .get();
        expect(storedVideo.data()?['mediaType'], 'video');
        expect(storedVideo.data()?['videoUrl'], videoPost.videoUrl);
        expect(storedVideo.data()?['imageUrls'], isEmpty);
        expect(storedVideo.data()?['authorId'], 'alice');
        expect(storedVideo.data()?['likeCount'], 0);

        await repository.deletePost(videoPost.id);

        expect(
          (await db.collection('posts').doc(videoPost.id).get()).exists,
          isFalse,
        );
        expect(
          (await db.collection('posts').doc('unrelated-post').get()).exists,
          isTrue,
        );
      },
    );

    test('rejects another user deleting a post', () async {
      final db = FakeFirebaseFirestore();
      final alice = FirestoreCommunityRepository(firestore: db)
        ..signIn('alice');
      final bob = FirestoreCommunityRepository(firestore: db)..signIn('bob');
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await alice.addPost(_post('owned-post'), postId: 'owned-post');
      await _settle();

      await expectLater(
        bob.deletePost('owned-post'),
        throwsA(isA<StateError>()),
      );
      expect(
        (await db.collection('posts').doc('owned-post').get()).exists,
        isTrue,
      );
    });

    test('owner deletes the requested Firestore document', () async {
      final db = FakeFirebaseFirestore();
      final repository = FirestoreCommunityRepository(firestore: db)
        ..signIn('alice');
      addTearDown(repository.dispose);
      await repository.addPost(_post('delete-post'), postId: 'delete-post');
      await _settle();

      await repository.deletePost('delete-post');

      expect(
        (await db.collection('posts').doc('delete-post').get()).exists,
        isFalse,
      );
      expect(repository.postById('delete-post'), isNull);
    });
  });

  test('local repository deletes only locally authored posts', () async {
    final repository = LocalCommunityRepository(StorageService());
    addTearDown(repository.dispose);
    final local = _post('local-post');
    await repository.addPost(local);
    await expectLater(
      repository.deletePost('post-firebase-auth'),
      throwsA(isA<StateError>()),
    );
    await repository.deletePost('local-post');
    expect(repository.postById('local-post'), isNull);
  });
}
