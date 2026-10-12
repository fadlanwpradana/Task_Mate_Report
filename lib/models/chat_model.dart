/// Someone the user can chat with.
class ChatUser {
  const ChatUser({
    required this.id,
    required this.name,
    this.email = '',
    this.subtitle = '',
  });

  final String id;
  final String name;
  final String email;

  /// Short description, e.g. study program.
  final String subtitle;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  /// For the user's own messages: whether the other side has read it.
  final bool isRead;

  ChatMessage markRead() => ChatMessage(
    id: id,
    senderId: senderId,
    text: text,
    sentAt: sentAt,
    isRead: true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    'isRead': isRead,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// A one-on-one chat or a group chat.
class Conversation {
  const Conversation({
    required this.id,
    required this.memberIds,
    required this.createdAt,
    this.isGroup = false,
    this.title = '',
    this.memberNames = const {},
    this.messages = const [],
    this.lastMessage,
    this.updatedAt,
    this.lastReadAt,
  });

  final String id;
  final bool isGroup;

  /// Group name; empty for one-on-one chats.
  final String title;

  /// Other participants (the current user is implied).
  final List<String> memberIds;

  /// Display names by user id, as stored with the chat.
  final Map<String, String> memberNames;

  /// Loaded messages, oldest first. Online chats only load these while the
  /// chat is open; use [latest] for list previews.
  final List<ChatMessage> messages;

  /// Summary of the newest message when [messages] isn't loaded.
  final ChatMessage? lastMessage;
  final DateTime? updatedAt;

  /// When the current user last opened the chat.
  final DateTime? lastReadAt;
  final DateTime createdAt;

  ChatMessage? get latest => messages.isNotEmpty ? messages.last : lastMessage;

  DateTime get lastActivity => latest?.sentAt ?? updatedAt ?? createdAt;

  Conversation copyWith({List<ChatMessage>? messages, DateTime? lastReadAt}) {
    return Conversation(
      id: id,
      isGroup: isGroup,
      title: title,
      memberIds: memberIds,
      memberNames: memberNames,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      lastMessage: lastMessage,
      updatedAt: updatedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isGroup': isGroup,
    'title': title,
    'memberIds': memberIds,
    'memberNames': memberNames,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastReadAt': lastReadAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      memberIds: (json['memberIds'] as List<dynamic>).cast<String>(),
      memberNames: (json['memberNames'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      lastReadAt: DateTime.tryParse(json['lastReadAt'] as String? ?? ''),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
