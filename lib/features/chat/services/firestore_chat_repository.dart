import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/user_directory.dart';
import '../../../models/chat_model.dart';
import 'chat_repository.dart';

/// Realtime chat backed by Firestore.
///
/// Data layout (see firestore.rules):
/// * `conversations/{id}`: memberIds, memberNames, isGroup, title,
///   lastMessage, updatedAt, and per-member `unread`, `lastReadAt`, `typing`
///   maps. One-on-one chats use the id `direct_<uidA>_<uidB>` (sorted) so
///   there is only ever one per pair.
/// * `conversations/{id}/messages/{id}`: senderId, text, sentAt.
class FirestoreChatRepository extends ChatRepository {
  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    UserDirectory? directory,
  }) : _firestore = firestore,
       _directory = directory ?? UserDirectory(firestore);

  final FirebaseFirestore? _firestore;
  final UserDirectory _directory;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('conversations');

  /// How long a "typing" signal stays visible.
  static const _typingWindow = Duration(seconds: 6);
  static const _typingThrottle = Duration(seconds: 4);

  String? _uid;
  String _myName = '';
  String _myEmail = '';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _listSub;
  final _roomSubs =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
  final _docs = <String, Map<String, dynamic>>{};
  var _order = <String>[];
  final _messages = <String, List<ChatMessage>>{};
  final _lastTypingSent = <String, DateTime>{};
  Timer? _typingRefresh;

  /// Starts listening to [uid]'s conversations.
  void signIn({
    required String uid,
    required String name,
    required String email,
  }) {
    _myName = name;
    _myEmail = ChatRepository.normalizeEmail(email);
    if (_uid == uid) return;
    signOut();
    _uid = uid;
    _listSub = _chats
        .where('memberIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _docs
              ..clear()
              ..addEntries(snapshot.docs.map((d) => MapEntry(d.id, d.data())));
            _order = [for (final d in snapshot.docs) d.id];
            _scheduleTypingRefresh();
            notifyListeners();
          },
          onError: (Object error) =>
              debugPrint('Chat list unavailable: $error'),
        );
  }

  /// Stops all listeners, e.g. on sign out.
  void signOut() {
    _listSub?.cancel();
    _listSub = null;
    for (final sub in _roomSubs.values) {
      sub.cancel();
    }
    _roomSubs.clear();
    _docs.clear();
    _order = [];
    _messages.clear();
    _typingRefresh?.cancel();
    _uid = null;
    notifyListeners();
  }

  @override
  void dispose() {
    signOut();
    super.dispose();
  }

  @override
  String get meId => _uid ?? '';

  @override
  bool get isDemo => false;

  @override
  List<Conversation> get conversations => [
    for (final id in _order)
      if (_docs[id] case final data?) _toConversation(id, data),
  ];

  @override
  Conversation? byId(String id) {
    final data = _docs[id];
    return data == null ? null : _toConversation(id, data);
  }

  @override
  int unreadCount(Conversation conversation) {
    final unread = _docs[conversation.id]?['unread'];
    if (unread is! Map) return 0;
    return (unread[meId] as num?)?.toInt() ?? 0;
  }

  @override
  String? typingIn(String conversationId) {
    final typing = _docs[conversationId]?['typing'];
    if (typing is! Map) return null;
    final now = DateTime.now();
    for (final entry in typing.entries) {
      if (entry.key == meId) continue;
      final at = _time(entry.value);
      if (at != null && now.difference(at) < _typingWindow) {
        return entry.key as String;
      }
    }
    return null;
  }

  @override
  Future<ChatUser?> findUserByEmail(String email) => _directory.lookup(email);

  @override
  Future<String> startChat({
    required String email,
    required String firstMessage,
  }) async {
    if (!ChatRepository.isValidEmail(email)) {
      throw const StartChatException(StartChatError.invalidEmail);
    }
    if (ChatRepository.normalizeEmail(email) == _myEmail) {
      throw const StartChatException(StartChatError.self);
    }
    final user = await _directory.lookup(email);
    if (user == null) throw const StartChatException(StartChatError.notFound);
    if (user.id == meId) throw const StartChatException(StartChatError.self);
    final id = await _openDirect(user.id, user.name);
    await send(id, firstMessage);
    return id;
  }

  @override
  Future<String> directChatWith(String userId) async {
    final name = await _directory.nameOf(userId) ?? userId;
    return _openDirect(userId, name);
  }

  Future<String> _openDirect(String otherId, String otherName) async {
    final ids = [meId, otherId]..sort();
    final ref = _chats.doc('direct_${ids.join('_')}');
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set(
        _newConversation(
          memberIds: ids,
          names: {meId: _myName, otherId: otherName},
          isGroup: false,
          title: '',
        ),
      );
    }
    return ref.id;
  }

  @override
  Future<String> createGroup({
    required String name,
    required List<ChatUser> members,
    required String firstMessage,
  }) async {
    final ref = _chats.doc();
    await ref.set(
      _newConversation(
        memberIds: [meId, for (final m in members) m.id],
        names: {meId: _myName, for (final m in members) m.id: m.name},
        isGroup: true,
        title: name.trim(),
      ),
    );
    if (firstMessage.trim().isNotEmpty) await send(ref.id, firstMessage);
    return ref.id;
  }

  Map<String, dynamic> _newConversation({
    required List<String> memberIds,
    required Map<String, String> names,
    required bool isGroup,
    required String title,
  }) {
    return {
      'memberIds': memberIds,
      'memberNames': names,
      'isGroup': isGroup,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread': {for (final id in memberIds) id: 0},
      'lastReadAt': <String, dynamic>{},
      'typing': <String, dynamic>{},
    };
  }

  @override
  Future<void> send(String conversationId, String text) async {
    final trimmed = text.trim();
    final members = _membersOf(conversationId);
    if (trimmed.isEmpty || meId.isEmpty) return;
    final ref = _chats.doc(conversationId);
    final batch = _db.batch()
      ..set(ref.collection('messages').doc(), {
        'senderId': meId,
        'text': trimmed,
        'sentAt': FieldValue.serverTimestamp(),
      })
      ..update(ref, {
        'lastMessage': {
          'senderId': meId,
          'text': trimmed,
          'sentAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
        // Replying means everything above has been seen.
        'unread.$meId': 0,
        'lastReadAt.$meId': FieldValue.serverTimestamp(),
        'typing.$meId': FieldValue.delete(),
        for (final id in members)
          if (id != meId) 'unread.$id': FieldValue.increment(1),
      });
    _lastTypingSent.remove(conversationId);
    await batch.commit();
  }

  @override
  Future<void> markRead(String conversationId) async {
    final conversation = byId(conversationId);
    if (conversation == null || unreadCount(conversation) == 0) return;
    await _chats.doc(conversationId).update({
      'unread.$meId': 0,
      'lastReadAt.$meId': FieldValue.serverTimestamp(),
    });
  }

  @override
  void setTyping(String conversationId) {
    final now = DateTime.now();
    final last = _lastTypingSent[conversationId];
    if (last != null && now.difference(last) < _typingThrottle) return;
    _lastTypingSent[conversationId] = now;
    _chats
        .doc(conversationId)
        .update({'typing.$meId': FieldValue.serverTimestamp()})
        .catchError((Object e) => debugPrint('Typing update failed: $e'));
  }

  @override
  void openRoom(String conversationId) {
    if (_roomSubs.containsKey(conversationId)) return;
    _roomSubs[conversationId] = _chats
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt')
        .limitToLast(300)
        .snapshots()
        .listen(
          (snapshot) {
            _messages[conversationId] = [
              for (final doc in snapshot.docs)
                ChatMessage(
                  id: doc.id,
                  senderId: doc.data()['senderId'] as String? ?? '',
                  text: doc.data()['text'] as String? ?? '',
                  // Pending server timestamps are null until confirmed.
                  sentAt: _time(doc.data()['sentAt']) ?? DateTime.now(),
                ),
            ];
            notifyListeners();
          },
          onError: (Object error) => debugPrint('Messages unavailable: $error'),
        );
  }

  @override
  void closeRoom(String conversationId) {
    _roomSubs.remove(conversationId)?.cancel();
    _messages.remove(conversationId);
  }

  List<String> _membersOf(String conversationId) =>
      (_docs[conversationId]?['memberIds'] as List<dynamic>? ?? [])
          .cast<String>();

  Conversation _toConversation(String id, Map<String, dynamic> data) {
    final all = (data['memberIds'] as List<dynamic>? ?? []).cast<String>();
    final others = [
      for (final m in all)
        if (m != meId) m,
    ];
    final readMap = data['lastReadAt'] is Map
        ? (data['lastReadAt'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    // A message of mine is read once every other member has read past it.
    bool readByOthers(DateTime sentAt) =>
        others.isNotEmpty &&
        others.every((o) {
          final at = _time(readMap[o]);
          return at != null && !at.isBefore(sentAt);
        });

    final last = data['lastMessage'];
    return Conversation(
      id: id,
      isGroup: data['isGroup'] as bool? ?? false,
      title: data['title'] as String? ?? '',
      memberIds: others,
      memberNames: (data['memberNames'] as Map? ?? {}).cast<String, String>(),
      createdAt: _time(data['createdAt']) ?? DateTime.now(),
      updatedAt: _time(data['updatedAt']),
      lastReadAt: _time(readMap[meId]),
      lastMessage: last is Map
          ? ChatMessage(
              id: 'last',
              senderId: last['senderId'] as String? ?? '',
              text: last['text'] as String? ?? '',
              sentAt: _time(last['sentAt']) ?? DateTime.now(),
            )
          : null,
      messages: [
        for (final m in _messages[id] ?? const <ChatMessage>[])
          m.senderId == meId && readByOthers(m.sentAt) ? m.markRead() : m,
      ],
    );
  }

  /// Re-notifies when someone's "typing…" signal expires.
  void _scheduleTypingRefresh() {
    _typingRefresh?.cancel();
    if (_docs.keys.any((id) => typingIn(id) != null)) {
      _typingRefresh = Timer(_typingWindow, notifyListeners);
    }
  }

  static DateTime? _time(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
