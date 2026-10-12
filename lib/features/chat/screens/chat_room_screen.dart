import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/chat_repository.dart';
import '../widgets/chat_widgets.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  late final ChatRepository _chat;

  @override
  void initState() {
    super.initState();
    // Load (and keep listening to) this chat's messages while it's open.
    _chat = AppScope.of(context).chat..openRoom(widget.conversationId);
  }

  @override
  void dispose() {
    _chat.closeRoom(widget.conversationId);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await AppScope.of(context).chat.send(widget.conversationId, text);
  }

  void _showMembers(Conversation conversation) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '${l10n.groupMembers} (${conversation.memberIds.length + 1})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: InitialsAvatar(
                name: AppScope.of(context).currentUserName,
              ),
              title: Text(l10n.you),
            ),
            for (final id in conversation.memberIds)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: InitialsAvatar(
                  name: ChatText.name(_chat, conversation, id),
                ),
                title: Text(ChatText.name(_chat, conversation, id)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final conversation = chat.byId(widget.conversationId);
        if (conversation == null) return Scaffold(appBar: AppBar());
        if (chat.unreadCount(conversation) > 0) {
          // Messages are visible now; clear the unread badge.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => chat.markRead(conversation.id),
          );
        }
        final typingId = chat.typingIn(conversation.id);
        final subtitle = typingId != null
            ? (conversation.isGroup
                  ? l10n.userTyping(
                      ChatText.firstName(chat, conversation, typingId),
                    )
                  : l10n.typing)
            : conversation.isGroup
            ? [
                l10n.you,
                for (final id in conversation.memberIds)
                  ChatText.firstName(chat, conversation, id),
              ].join(', ')
            : '';

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: InkWell(
              onTap: conversation.isGroup
                  ? () => _showMembers(conversation)
                  : null,
              child: Row(
                children: [
                  ConversationAvatar(conversation: conversation, radius: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ChatText.title(chat, conversation),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: typingId != null
                                ? AppColors.sageGreen
                                : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _MessageList(
                  conversation: conversation,
                  typingId: typingId,
                ),
              ),
              _MessageInput(controller: _messageController, onSend: _send),
            ],
          ),
        );
      },
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.conversation, required this.typingId});

  final Conversation conversation;
  final String? typingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    final messages = conversation.messages;
    if (messages.isEmpty && typingId == null) {
      return Center(
        child: Text(
          conversation.isGroup
              ? l10n.groupCreatedNote
              : l10n.sayHello(
                  ChatText.firstName(
                    chat,
                    conversation,
                    conversation.memberIds.first,
                  ),
                ),
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    // Built oldest-first, then reversed so the list starts at the bottom.
    final items = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previous = i == 0 ? null : messages[i - 1];
      if (previous == null ||
          !TaskDateUtils.isSameDay(previous.sentAt, message.sentAt)) {
        items.add(_DaySeparator(ChatText.dayLabel(context, message.sentAt)));
      }
      final mine = message.senderId == chat.meId;
      items.add(
        _Bubble(
          message: message,
          mine: mine,
          senderName:
              conversation.isGroup &&
                  !mine &&
                  previous?.senderId != message.senderId
              ? ChatText.name(chat, conversation, message.senderId)
              : null,
        ),
      );
    }
    if (typingId != null) items.add(const _TypingBubble());

    return ListView(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: items.reversed.toList(),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.senderName,
  });

  final ChatMessage message;
  final bool mine;

  /// Shown above the first message of a run in group chats.
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = mine ? Colors.white : AppColors.navy;
    final metaColor = mine
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.secondaryText;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(top: senderName != null ? 8 : 3, bottom: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? AppColors.brand : AppColors.white,
            border: mine ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    senderName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.skyBlue,
                    ),
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(color: textColor, height: 1.35),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TaskDateUtils.time(context, message.sentAt),
                    style: TextStyle(fontSize: 11, color: metaColor),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 15,
                      color: message.isRead
                          ? const Color(0xFF9CC6EC)
                          : metaColor,
                      semanticLabel: message.isRead
                          ? l10n.messageRead
                          : l10n.messageSent,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '• • •',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: l10n.send,
              onPressed: onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
