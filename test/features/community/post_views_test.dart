import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/features/community/services/firestore_community_repository.dart';
import 'package:task_mate_v4/models/post_model.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('Community post views in Firestore', () {
    test(
      'increments once per user even when the user records it repeatedly',
      () async {
        final db = FakeFirebaseFirestore();
        final alice = FirestoreCommunityRepository(firestore: db)
          ..signIn('alice');
        final bob = FirestoreCommunityRepository(firestore: db)..signIn('bob');
        addTearDown(alice.dispose);
        addTearDown(bob.dispose);

        await alice.addPost(
          PostModel(
            id: 'local-id',
            authorName: 'Alice',
            type: PostType.discussion,
            title: 'A post',
            body: 'Post body',
            createdAt: DateTime.now(),
          ),
        );
        await _settle();
        final postId = alice.posts.single.id;

        await alice.recordView(postId);
        await alice.recordView(postId);
        await _settle();
        expect(alice.postById(postId)!.viewCount, 1);

        await bob.recordView(postId);
        await _settle();
        expect(alice.postById(postId)!.viewCount, 2);
        expect(bob.postById(postId)!.viewCount, 2);
        final viewers = await db
            .collection('posts')
            .doc(postId)
            .collection('views')
            .get();
        expect(viewers.docs.map((doc) => doc.id).toSet(), {'alice', 'bob'});
      },
    );

    test('allows another view after the 24-hour window', () async {
      final db = FakeFirebaseFirestore();
      final alice = FirestoreCommunityRepository(firestore: db)
        ..signIn('alice');
      addTearDown(alice.dispose);

      await alice.addPost(
        PostModel(
          id: 'local-id',
          authorName: 'Alice',
          type: PostType.discussion,
          title: 'A post',
          body: 'Post body',
          createdAt: DateTime.now(),
        ),
      );
      await _settle();
      final postId = alice.posts.single.id;
      final viewRef = db
          .collection('posts')
          .doc(postId)
          .collection('views')
          .doc('alice');
      await viewRef.set({
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 25)),
        ),
      });

      await alice.recordView(postId);
      await _settle();

      expect(alice.postById(postId)!.viewCount, 1);
      expect((await viewRef.get()).data()!['createdAt'], isA<Timestamp>());
    });
  });
}
