import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'edits the original post and preserves owner, time, and counters',
      () async {
        final db = FakeFirebaseFirestore();
        final repository = FirestoreCommunityRepository(firestore: db)
          ..signIn('alice');
        addTearDown(repository.dispose);
        await repository.addPost(_post('edit-post'), postId: 'edit-post');
        await _settle();
        await db.collection('posts').doc('edit-post').update({
          'likeCount': 7,
          'viewCount': 11,
          'commentCount': 4,
        });
        await _settle();
        final original = repository.postById('edit-post')!;

        await repository.updatePost(
          original.copyWith(
            title: 'Updated title',
            body: 'Updated body',
            imageUrls: const ['https://example.test/new.jpg'],
          ),
        );

        final saved = (await db.collection('posts').doc('edit-post').get())
            .data()!;
        expect(saved['title'], 'Updated title');
        expect(saved['body'], 'Updated body');
        expect(saved['imageUrls'], ['https://example.test/new.jpg']);
        expect(saved['authorId'], 'alice');
        expect((saved['createdAt']! as Timestamp).toDate(), original.createdAt);
        expect(saved['likeCount'], 7);
        expect(saved['viewCount'], 11);
        expect(saved['commentCount'], 4);
        expect((await db.collection('posts').get()).docs, hasLength(1));
      },
    );

    test('rejects another user editing or deleting a post', () async {
      final db = FakeFirebaseFirestore();
      final alice = FirestoreCommunityRepository(firestore: db)
        ..signIn('alice');
      final bob = FirestoreCommunityRepository(firestore: db)..signIn('bob');
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await alice.addPost(_post('owned-post'), postId: 'owned-post');
      await _settle();
      final visibleToBob = bob.postById('owned-post')!;

      await expectLater(
        bob.updatePost(visibleToBob.copyWith(title: 'Not allowed')),
        throwsA(isA<StateError>()),
      );
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

  test(
    'local repository edits and deletes only locally authored posts',
    () async {
      final repository = LocalCommunityRepository(StorageService());
      addTearDown(repository.dispose);
      final local = _post('local-post');
      await repository.addPost(local);
      final created = repository.postById('local-post')!;

      await repository.updatePost(
        created.copyWith(
          title: 'Updated offline',
          imageUrls: const ['https://example.test/local.jpg'],
        ),
      );
      expect(repository.postById('local-post')!.title, 'Updated offline');
      expect(repository.postById('local-post')!.imageUrls, [
        'https://example.test/local.jpg',
      ]);

      await expectLater(
        repository.updatePost(_post('post-firebase-auth')),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.deletePost('post-firebase-auth'),
        throwsA(isA<StateError>()),
      );
      await repository.deletePost('local-post');
      expect(repository.postById('local-post'), isNull);
    },
  );
}
