import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/chat_widgets.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart';

/// All chats, most recent first.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChat() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const NewChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chats)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newChat,
        onPressed: _openNewChat,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat_rounded),
      ),
      body: ListenableBuilder(
        listenable: chat,
        builder: (context, _) {
          final query = _searchController.text.trim().toLowerCase();
          final conversations = chat.conversations
              .where(
                (c) =>
                    query.isEmpty ||
                    ChatText.title(chat, c).toLowerCase().contains(query),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
            children: [
              if (chat.isDemo) const ChatDemoNotice(),
              const SizedBox(height: 12),
              SearchField(
                hint: l10n.searchChatsHint,
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (conversations.isEmpty)
                EmptyState(
                  title: query.isEmpty ? l10n.noChats : l10n.noResults,
                  description: query.isEmpty ? l10n.noChatsDescription : null,
                  icon: Icons.chat_bubble_outline_rounded,
                )
              else
                for (final conversation in conversations)
                  _ConversationTile(conversation: conversation),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    final unread = chat.unreadCount(conversation);
    final typingId = chat.typingIn(conversation.id);
    final preview = typingId == null
        ? ChatText.preview(context, conversation)
        : conversation.isGroup
        ? l10n.userTyping(ChatText.firstName(chat, conversation, typingId))
        : l10n.typing;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatRoomScreen(conversationId: conversation.id),
        ),
      ),
      leading: ConversationAvatar(conversation: conversation),
      title: Text(
        ChatText.title(chat, conversation),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: typingId != null
              ? AppColors.sageGreen
              : unread > 0
              ? AppColors.navy
              : AppColors.secondaryText,
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            ChatText.listTime(context, conversation.lastActivity),
            style: TextStyle(
              fontSize: 12,
              color: unread > 0 ? AppColors.skyBlue : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.skyBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }
}
