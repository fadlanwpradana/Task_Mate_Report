import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/core/services/user_directory.dart';
import 'package:task_mate_v4/features/chat/services/chat_repository.dart';
import 'package:task_mate_v4/features/chat/services/firestore_chat_repository.dart';

/// Two people using the app against the same (in-memory) Firestore.
void main() {
  late FakeFirebaseFirestore db;
  late FirestoreChatRepository alice;
  late FirestoreChatRepository bob;

  Future<void> register(String uid, String name, String email) async {
    await db.collection('users').doc(uid).set({'name': name});
    await db.collection('emailIndex').doc(email).set({
      'uid': uid,
      'name': name,
    });
  }

  FirestoreChatRepository repoFor(String uid, String name, String email) {
    return FirestoreChatRepository(firestore: db, directory: UserDirectory(db))
      ..signIn(uid: uid, name: name, email: email);
  }

  // Lets snapshot listeners deliver.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    db = FakeFirebaseFirestore();
    await register('alice', 'Alice Tan', 'alice@campus.ac.id');
    await register('bob', 'Bob Lee', 'bob@campus.ac.id');
    await register('carol', 'Carol Ng', 'carol@campus.ac.id');
    alice = repoFor('alice', 'Alice Tan', 'alice@campus.ac.id');
    bob = repoFor('bob', 'Bob Lee', 'bob@campus.ac.id');
  });

  tearDown(() {
    alice.dispose();
    bob.dispose();
  });

  test('starting a chat needs an exact, registered, other email', () async {
    Future<StartChatError?> errorFor(String email) async {
      try {
        await alice.startChat(email: email, firstMessage: 'hi');
        return null;
      } on StartChatException catch (e) {
        return e.error;
      }
    }

    expect(await errorFor('not an email'), StartChatError.invalidEmail);
    expect(await errorFor('nobody@campus.ac.id'), StartChatError.notFound);
    expect(await errorFor('Alice@Campus.ac.id'), StartChatError.self);
    // Partial emails don't match anyone.
    expect(await errorFor('bob@campus.ac'), StartChatError.notFound);
  });

  test('a first message reaches the other person in real time', () async {
    final id = await alice.startChat(
      email: ' BOB@campus.ac.id ',
      firstMessage: 'Hi Bob, it’s Alice from Databases 👋',
    );
    expect(id, 'direct_alice_bob');
    await settle();

    // Bob's chat list updates without him doing anything.
    final chat = bob.conversations.single;
    expect(chat.isGroup, isFalse);
    expect(chat.memberIds, ['alice']);
    expect(bob.nameOf(chat, 'alice'), 'Alice Tan');
    expect(chat.latest?.text, 'Hi Bob, it’s Alice from Databases 👋');
    expect(bob.unreadCount(chat), 1);
    expect(bob.totalUnread, 1);
    expect(alice.unreadCount(alice.conversations.single), 0);

    // Bob opens the chat: messages load and the badge clears.
    bob.openRoom(id);
    await settle();
    expect(bob.byId(id)!.messages.single.senderId, 'alice');
    await bob.markRead(id);
    await settle();
    expect(bob.totalUnread, 0);

    // Alice's message now shows as read.
    alice.openRoom(id);
    await settle();
    expect(alice.byId(id)!.messages.single.isRead, isTrue);
  });

  test('starting again reuses the same one-on-one chat', () async {
    final first = await alice.startChat(
      email: 'bob@campus.ac.id',
      firstMessage: 'one',
    );
    final second = await alice.startChat(
      email: 'bob@campus.ac.id',
      firstMessage: 'two',
    );
    // Bob starting from his side lands in the same chat.
    final fromBob = await bob.startChat(
      email: 'alice@campus.ac.id',
      firstMessage: 'three',
    );
    expect(second, first);
    expect(fromBob, first);
    final messages = await db.collection('conversations/$first/messages').get();
    expect(messages.size, 3);
  });

  test('replies update unread counts and read receipts both ways', () async {
    final id = await alice.startChat(
      email: 'bob@campus.ac.id',
      firstMessage: 'Did you finish the ERD?',
    );
    await bob.send(id, 'Almost!');
    await bob.send(id, 'Sending it tonight.');
    await settle();

    expect(alice.unreadCount(alice.byId(id)!), 2);
    alice.openRoom(id);
    bob.openRoom(id);
    await settle();

    // Bob's replies aren't read until Alice opens the chat.
    Iterable<bool> bobsReceipts() => bob
        .byId(id)!
        .messages
        .where((m) => m.senderId == 'bob')
        .map((m) => m.isRead);
    expect(bobsReceipts(), [false, false]);
    await alice.markRead(id);
    await settle();
    expect(bobsReceipts(), [true, true]);
  });

  test('typing shows for the other person only', () async {
    final id = await alice.startChat(
      email: 'bob@campus.ac.id',
      firstMessage: 'hey',
    );
    alice.setTyping(id);
    await settle();
    expect(bob.typingIn(id), 'alice');
    expect(alice.typingIn(id), isNull);

    // Sending clears it.
    await alice.send(id, 'done typing');
    await settle();
    expect(bob.typingIn(id), isNull);
  });

  test('group chats reach every member', () async {
    final carol = repoFor('carol', 'Carol Ng', 'carol@campus.ac.id');
    addTearDown(carol.dispose);

    final bobUser = await alice.findUserByEmail('bob@campus.ac.id');
    final carolUser = await alice.findUserByEmail('carol@campus.ac.id');
    final id = await alice.createGroup(
      name: 'ERD squad',
      members: [bobUser!, carolUser!],
      firstMessage: 'Welcome!',
    );
    await carol.send(id, 'Thanks!');
    await settle();

    final forBob = bob.byId(id)!;
    expect(forBob.isGroup, isTrue);
    expect(forBob.title, 'ERD squad');
    expect(forBob.memberIds, unorderedEquals(['alice', 'carol']));
    expect(bob.unreadCount(forBob), 2);
    expect(alice.unreadCount(alice.byId(id)!), 1);
    expect(carol.unreadCount(carol.byId(id)!), 0);
  });

  test('signing out stops showing the previous user’s chats', () async {
    await alice.startChat(email: 'bob@campus.ac.id', firstMessage: 'hi');
    await settle();
    expect(bob.conversations, isNotEmpty);
    bob.signOut();
    expect(bob.conversations, isEmpty);
    expect(bob.totalUnread, 0);
  });
}
