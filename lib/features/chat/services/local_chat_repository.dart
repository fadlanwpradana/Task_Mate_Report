import 'dart:async';
import 'dart:math';

import '../../../core/services/storage_service.dart';
import '../../../models/chat_model.dart';
import 'chat_repository.dart';

/// Offline demo chat stored on the device. Other people are sample users
/// whose replies are simulated: after the user sends a message, a
/// participant "types" and answers.
class LocalChatRepository extends ChatRepository {
  LocalChatRepository(
    this._storage, {
    this.replyDelay = const Duration(milliseconds: 2200),
    String Function()? languageCode,
    Random? random,
  }) : _languageCode = languageCode ?? (() => 'en'),
       _random = random ?? Random() {
    final saved = _storage.readList(_key);
    _conversations = saved == null
        ? _sampleConversations()
        : saved.map(Conversation.fromJson).toList();
  }

  static const _key = 'chats';
  static const _meId = 'me';

  /// How long a simulated reply takes. Shorten in tests.
  final Duration replyDelay;

  /// The signed-in user's email, so they can't start a chat with themselves.
  String myEmail = '';

  final StorageService _storage;
  final String Function() _languageCode;
  final Random _random;
  late List<Conversation> _conversations;
  final _typing = <String, String>{};
  final _timers = <Timer>{};

  /// Sample people, reachable by their demo email.
  static const users = [
    ChatUser(
      id: 'sari',
      name: 'Sari Dewi',
      email: 'sari@taskmate.demo',
      subtitle: 'Informatics · Year 2',
    ),
    ChatUser(
      id: 'budi',
      name: 'Budi Santoso',
      email: 'budi@taskmate.demo',
      subtitle: 'Information Systems · Year 3',
    ),
    ChatUser(
      id: 'andi',
      name: 'Andi Saputra',
      email: 'andi@taskmate.demo',
      subtitle: 'Informatics · Year 3',
    ),
    ChatUser(
      id: 'rina',
      name: 'Rina Oktavia',
      email: 'rina@taskmate.demo',
      subtitle: 'UI/UX · Year 2',
    ),
    ChatUser(
      id: 'raka',
      name: 'Raka Pratama',
      email: 'raka@taskmate.demo',
      subtitle: 'Informatics · Year 1',
    ),
    ChatUser(
      id: 'dewi',
      name: 'Dewi Lestari',
      email: 'dewi@taskmate.demo',
      subtitle: 'Mathematics · Year 2',
    ),
  ];

  static ChatUser? _userById(String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  static Map<String, String> _namesFor(List<String> ids) => {
    for (final id in ids) id: _userById(id)?.name ?? id,
  };

  @override
  String get meId => _meId;

  @override
  bool get isDemo => true;

  @override
  List<Conversation> get conversations =>
      [..._conversations]
        ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

  @override
  Conversation? byId(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  @override
  int unreadCount(Conversation conversation) {
    final readAt = conversation.lastReadAt;
    return conversation.messages
        .where(
          (m) =>
              m.senderId != _meId &&
              (readAt == null || m.sentAt.isAfter(readAt)),
        )
        .length;
  }

  @override
  String? typingIn(String conversationId) => _typing[conversationId];

  @override
  String nameOf(Conversation conversation, String userId) =>
      conversation.memberNames[userId] ?? _userById(userId)?.name ?? userId;

  @override
  Future<ChatUser?> findUserByEmail(String email) async {
    final normalized = ChatRepository.normalizeEmail(email);
    for (final user in users) {
      if (user.email == normalized) return user;
    }
    return null;
  }

  @override
  Future<String> startChat({
    required String email,
    required String firstMessage,
  }) async {
    if (!ChatRepository.isValidEmail(email)) {
      throw const StartChatException(StartChatError.invalidEmail);
    }
    if (ChatRepository.normalizeEmail(email) ==
        ChatRepository.normalizeEmail(myEmail)) {
      throw const StartChatException(StartChatError.self);
    }
    final user = await findUserByEmail(email);
    if (user == null) throw const StartChatException(StartChatError.notFound);
    final id = await directChatWith(user.id);
    await send(id, firstMessage);
    return id;
  }

  @override
  Future<String> createGroup({
    required String name,
    required List<ChatUser> members,
    required String firstMessage,
  }) async {
    final ids = [for (final m in members) m.id];
    final conversation = Conversation(
      id: generateId(),
      isGroup: true,
      title: name,
      memberIds: ids,
      memberNames: _namesFor(ids),
      createdAt: DateTime.now(),
      lastReadAt: DateTime.now(),
    );
    _conversations.add(conversation);
    await _save();
    if (firstMessage.trim().isNotEmpty) {
      await send(conversation.id, firstMessage);
    }
    return conversation.id;
  }

  @override
  Future<String> directChatWith(String userId) async {
    for (final conversation in _conversations) {
      if (!conversation.isGroup &&
          conversation.memberIds.length == 1 &&
          conversation.memberIds.first == userId) {
        return conversation.id;
      }
    }
    final conversation = Conversation(
      id: generateId(),
      memberIds: [userId],
      memberNames: _namesFor([userId]),
      createdAt: DateTime.now(),
    );
    _conversations.add(conversation);
    await _save();
    return conversation.id;
  }

  @override
  Future<void> send(String conversationId, String text) async {
    final trimmed = text.trim();
    final conversation = byId(conversationId);
    if (trimmed.isEmpty || conversation == null) return;
    final now = DateTime.now();
    _replace(
      conversation.copyWith(
        messages: [
          ...conversation.messages,
          ChatMessage(
            id: generateId(),
            senderId: _meId,
            text: trimmed,
            sentAt: now,
          ),
        ],
        lastReadAt: now,
      ),
    );
    await _save();
    _simulateReply(conversationId);
  }

  @override
  Future<void> markRead(String conversationId) async {
    final conversation = byId(conversationId);
    if (conversation == null || unreadCount(conversation) == 0) return;
    _replace(conversation.copyWith(lastReadAt: DateTime.now()));
    await _save();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _simulateReply(String conversationId) {
    final conversation = byId(conversationId);
    if (conversation == null || conversation.memberIds.isEmpty) return;
    final responderId =
        conversation.memberIds[_random.nextInt(conversation.memberIds.length)];

    _after(replyDelay ~/ 3, () {
      _typing[conversationId] = responderId;
      notifyListeners();
    });
    _after(replyDelay, () async {
      _typing.remove(conversationId);
      final current = byId(conversationId);
      if (current == null) return notifyListeners();
      final replies = _languageCode() == 'id' ? _repliesId : _repliesEn;
      _replace(
        current.copyWith(
          messages: [
            // The responder has now read everything the user sent.
            for (final m in current.messages)
              m.senderId == _meId && !m.isRead ? m.markRead() : m,
            ChatMessage(
              id: generateId(),
              senderId: responderId,
              text: replies[_random.nextInt(replies.length)],
              sentAt: DateTime.now(),
            ),
          ],
        ),
      );
      await _save();
    });
  }

  void _after(Duration delay, void Function() action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      action();
    });
    _timers.add(timer);
  }

  void _replace(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) _conversations[index] = conversation;
  }

  Future<void> _save() async {
    notifyListeners();
    await _storage.writeList(
      _key,
      _conversations.map((c) => c.toJson()).toList(),
    );
  }

  static const _repliesEn = [
    'Sounds good! 👍',
    'Thanks for the info!',
    'Okay, I’ll check it tonight.',
    'Haha, same here 😅',
    'Let’s discuss it after class.',
    'Got it, see you tomorrow!',
    'Can you share your notes too?',
  ];

  static const _repliesId = [
    'Oke, siap! 👍',
    'Makasih infonya!',
    'Sip, nanti malam aku cek.',
    'Haha, sama 😅',
    'Kita bahas habis kelas ya.',
    'Oke, sampai ketemu besok!',
    'Boleh share catatanmu juga?',
  ];

  static List<Conversation> _sampleConversations() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    ChatMessage message(String sender, String text, Duration age) =>
        ChatMessage(
          id: generateId(),
          senderId: sender,
          text: text,
          sentAt: ago(age),
          isRead: true,
        );

    return [
      Conversation(
        id: 'chat-sari',
        memberIds: const ['sari'],
        memberNames: _namesFor(['sari']),
        createdAt: ago(const Duration(days: 2)),
        lastReadAt: ago(const Duration(hours: 1)),
        messages: [
          message(
            _meId,
            'Hi Sari! Did you finish the Firebase setup?',
            const Duration(hours: 3),
          ),
          message(
            'sari',
            'Almost! The auth part is still confusing 😅',
            const Duration(hours: 2, minutes: 50),
          ),
          message(
            'sari',
            'Could you send me your notes later?',
            const Duration(minutes: 20),
          ),
        ],
      ),
      Conversation(
        id: 'chat-database-group',
        isGroup: true,
        title: 'Database Study Group',
        memberIds: const ['budi', 'andi', 'rina'],
        memberNames: _namesFor(['budi', 'andi', 'rina']),
        createdAt: ago(const Duration(days: 5)),
        lastReadAt: ago(const Duration(days: 1)),
        messages: [
          message(
            'budi',
            'Reminder: the ERD is due on Friday!',
            const Duration(days: 1, hours: 2),
          ),
          message(
            _meId,
            'Thanks! I’ll finish my part tonight.',
            const Duration(days: 1, hours: 1),
          ),
          message(
            'andi',
            'I’ve uploaded the normalization draft.',
            const Duration(hours: 5),
          ),
        ],
      ),
    ];
  }
}
