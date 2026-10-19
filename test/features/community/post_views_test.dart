import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/features/community/services/firestore_community_repository.dart';
import 'package:task_mate_v4/features/community/widgets/post_view_observer.dart';
import 'package:task_mate_v4/models/post_model.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('PostViewObserver', () {
    testWidgets('records only after remaining at least half visible for 1s', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var viewCount = 0;

      Widget buildHarness() => MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              PostViewObserver(
                postId: 'post-1',
                onView: () async {
                  viewCount++;
                },
                child: const SizedBox(height: 100),
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pump();
      controller.jumpTo(51);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(viewCount, 0);

      controller.jumpTo(50);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(viewCount, 0);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(viewCount, 1);

      await tester.pumpWidget(const SizedBox());
    });
  });

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
  });
}
