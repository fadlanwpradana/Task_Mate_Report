import 'package:flutter/foundation.dart';

import '../../../models/chat_model.dart';

enum StartChatError { invalidEmail, notFound, self }

/// Why a chat couldn't be started from an email address.
class StartChatException implements Exception {
  const StartChatException(this.error);

  final StartChatError error;
}

/// One-on-one and group chat. Implemented by [FirestoreChatRepository] for
/// real accounts and [LocalChatRepository] for the offline demo; screens only
/// use this API.
///
/// Privacy: there is no way to list users. Chats start from someone's exact
/// email address.
abstract class ChatRepository extends ChangeNotifier {
  /// Id of the signed-in user, used as the sender of their messages.
  String get meId;

  /// True when replies are simulated (no server).
  bool get isDemo;

  /// Conversations, most recent activity first.
  List<Conversation> get conversations;

  Conversation? byId(String id);

  /// Messages from others the user hasn't seen yet.
  int unreadCount(Conversation conversation);

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + unreadCount(c));

  /// Id of someone currently typing in [conversationId], if any.
  String? typingIn(String conversationId);

  String nameOf(Conversation conversation, String userId) =>
      conversation.memberNames[userId] ?? userId;

  /// The user registered with exactly [email], or null.
  Future<ChatUser?> findUserByEmail(String email);

  /// Starts (or reuses) a one-on-one chat with the owner of [email] and sends
  /// [firstMessage]. Returns the conversation id.
  ///
  /// Throws [StartChatException] when the email is invalid, unknown, or the
  /// user's own.
  Future<String> startChat({
    required String email,
    required String firstMessage,
  });

  /// Creates a group with [members] and sends [firstMessage]. Returns the
  /// conversation id.
  Future<String> createGroup({
    required String name,
    required List<ChatUser> members,
    required String firstMessage,
  });

  /// Opens (or creates) the one-on-one chat with [userId].
  Future<String> directChatWith(String userId);

  Future<void> send(String conversationId, String text);

  /// Marks everything in the chat as seen by the user.
  Future<void> markRead(String conversationId);

  /// Called while the user types, to show "typing…" to others.
  void setTyping(String conversationId) {}

  /// Start / stop loading the full message list for a chat on screen.
  void openRoom(String conversationId) {}
  void closeRoom(String conversationId) {}

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}
