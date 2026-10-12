import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/core/services/notification_service.dart';
import 'package:task_mate_v4/features/community/services/firestore_community_repository.dart';
import 'package:task_mate_v4/features/tasks/services/task_repository.dart';
import 'package:task_mate_v4/features/tasks/services/task_store.dart';
import 'package:task_mate_v4/models/comment_model.dart';
import 'package:task_mate_v4/models/community_model.dart';
import 'package:task_mate_v4/models/post_model.dart';
import 'package:task_mate_v4/models/task_model.dart';

class _RecordingReminders extends ReminderScheduler {
  final synced = <List<String>>[];

  @override
  Future<void> syncTask(TaskModel task) async {}

  @override
  Future<void> cancelTask(String taskId) async {}

  @override
  Future<void> syncAll(Iterable<TaskModel> tasks) async =>
      synced.add([for (final t in tasks) t.id]);
}

TaskModel _task(String id, String title) => TaskModel(
  id: id,
  title: title,
  deadline: DateTime.now().add(const Duration(days: 2)),
  createdAt: DateTime.now(),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('Tasks in Firestore', () {
    test('are private per account and sync across devices', () async {
      // Alice on two devices, Bob on one.
      final phone = TaskRepository.withStore(
        FirestoreTaskStore('alice', firestore: db),
      );
      final tablet = TaskRepository.withStore(
        FirestoreTaskStore('alice', firestore: db),
      );
      final bob = TaskRepository.withStore(
        FirestoreTaskStore('bob', firestore: db),
      );
      addTearDown(() {
        phone.dispose();
        tablet.dispose();
        bob.dispose();
      });

      await phone.add(_task('t1', 'Finish ERD'));
      await phone.add(_task('t2', 'Read chapter 4'));
      await _settle();
      expect(tablet.tasks.map((t) => t.title), contains('Finish ERD'));
      expect(tablet.tasks, hasLength(2));
      expect(bob.tasks, isEmpty);

      await tablet.setCompleted('t1', true);
      await tablet.delete('t2');
      await _settle();
      expect(phone.byId('t1')!.isCompleted, isTrue);
      expect(phone.byId('t1')!.completedAt, isNotNull);
      expect(phone.byId('t2'), isNull);
    });

    test('switching accounts swaps tasks and reminders', () async {
      final reminders = _RecordingReminders();
      final tasks = TaskRepository.withStore(
        FirestoreTaskStore('alice', firestore: db),
        reminders: reminders,
      );
      addTearDown(tasks.dispose);
      await tasks.add(_task('a1', 'Alice task'));
      await db
          .collection('users/bob/tasks')
          .doc('b1')
          .set(_task('b1', 'Bob task').toJson());

      tasks.switchStore(FirestoreTaskStore('bob', firestore: db));
      await _settle();
      expect(tasks.tasks.map((t) => t.id), ['b1']);
      expect(reminders.synced.last, ['b1']);

      // Signed out: no tasks, no reminders left scheduled.
      tasks.switchStore(EmptyTaskStore());
      await _settle();
      expect(tasks.tasks, isEmpty);
      expect(reminders.synced.last, isEmpty);
    });
  });

  group('Community in Firestore', () {
    late FirestoreCommunityRepository alice;
    late FirestoreCommunityRepository bob;

    setUp(() {
      alice = FirestoreCommunityRepository(firestore: db)..signIn('alice');
      bob = FirestoreCommunityRepository(firestore: db)..signIn('bob');
    });

    tearDown(() {
      alice.dispose();
      bob.dispose();
    });

    CommunityModel community(String id, {bool isPrivate = false}) =>
        CommunityModel(
          id: id,
          name: id,
          isPrivate: isPrivate,
          createdAt: DateTime.now(),
        );

    PostModel post(String title, {String? communityId}) => PostModel(
      id: 'local',
      authorName: 'Alice Tan',
      communityId: communityId,
      type: PostType.question,
      title: title,
      body: 'Body of $title',
      createdAt: DateTime.now(),
    );

    test('communities, joining, and counts are shared', () async {
      await alice.addCommunity(community('flutter'));
      await _settle();
      final forBob = bob.communityById('flutter')!;
      expect(forBob.memberCount, 1);
      expect(forBob.joined, isFalse);
      expect(alice.communityById('flutter')!.joined, isTrue);

      await bob.toggleJoin('flutter');
      await _settle();
      expect(alice.communityById('flutter')!.memberCount, 2);
      expect(bob.communityById('flutter')!.joined, isTrue);

      await bob.toggleJoin('flutter');
      await _settle();
      expect(alice.communityById('flutter')!.memberCount, 1);
      expect(bob.communityById('flutter')!.joined, isFalse);
    });

    test('posts, likes, and comments reach everyone', () async {
      await alice.addCommunity(community('flutter'));
      await alice.addPost(
        post('How do I use Riverpod?', communityId: 'flutter'),
      );
      await _settle();

      final seen = bob.posts.single;
      expect(seen.title, 'How do I use Riverpod?');
      expect(seen.authorId, 'alice');
      expect(bob.postCount('flutter'), 1);
      expect(bob.postsIn('flutter'), hasLength(1));

      await bob.toggleLike(seen.id);
      await _settle();
      expect(alice.postById(seen.id)!.likeCount, 1);
      expect(alice.postById(seen.id)!.likedByMe, isFalse);
      expect(bob.postById(seen.id)!.likedByMe, isTrue);
      await bob.toggleLike(seen.id);
      await _settle();
      expect(alice.postById(seen.id)!.likeCount, 0);

      // Comments load while the post is open.
      alice.openPost(seen.id);
      await bob.addComment(
        seen.id,
        CommentModel(
          id: 'local',
          authorName: 'Bob Lee',
          body: 'Start with Provider first.',
          createdAt: DateTime.now(),
        ),
      );
      await _settle();
      final withComments = alice.postById(seen.id)!;
      expect(withComments.totalComments, 1);
      expect(withComments.comments.single.authorId, 'bob');
      expect(withComments.comments.single.body, 'Start with Provider first.');

      await alice.toggleCommentLike(seen.id, withComments.comments.single.id);
      await _settle();
      expect(alice.postById(seen.id)!.comments.single.likedByMe, isTrue);
      alice.closePost(seen.id);
    });

    test('bookmarks are personal', () async {
      await alice.addPost(post('Exam tips'));
      await _settle();
      final id = alice.posts.single.id;
      await bob.toggleBookmark(id);
      await _settle();
      expect(bob.postById(id)!.bookmarked, isTrue);
      expect(alice.postById(id)!.bookmarked, isFalse);
    });

    test('private community posts only reach members', () async {
      await alice.addCommunity(community('secret', isPrivate: true));
      await alice.addPost(post('Members only', communityId: 'secret'));
      await alice.addPost(post('Hello everyone'));
      await _settle();

      expect(alice.posts.map((p) => p.title), contains('Members only'));
      // Bob's public feed never includes it.
      expect(bob.posts.map((p) => p.title), ['Hello everyone']);

      await bob.toggleJoin('secret');
      await _settle();
      expect(bob.posts.map((p) => p.title), contains('Members only'));
      expect(bob.followingPosts.map((p) => p.title), ['Members only']);
    });

    test('signing out clears the previous user’s view', () async {
      await alice.addCommunity(community('flutter'));
      await _settle();
      bob.signOut();
      expect(bob.communities, isEmpty);
      expect(bob.posts, isEmpty);
    });
  });
}
