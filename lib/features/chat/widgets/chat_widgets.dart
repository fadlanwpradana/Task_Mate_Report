import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/task_date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/chat_repository.dart';

abstract final class ChatText {
  static String name(ChatRepository chat, Conversation c, String userId) =>
      chat.nameOf(c, userId);

  static String firstName(ChatRepository chat, Conversation c, String id) =>
      name(chat, c, id).split(' ').first;

  /// Group name, or the other person's name.
  static String title(ChatRepository chat, Conversation conversation) {
    if (conversation.isGroup) return conversation.title;
    if (conversation.memberIds.isEmpty) return '';
    return name(chat, conversation, conversation.memberIds.first);
  }

  /// Last message for the chat list, prefixed with who sent it.
  static String preview(BuildContext context, Conversation conversation) {
    final l10n = AppLocalizations.of(context);
    final chat = AppScope.of(context).chat;
    final last = conversation.latest;
    if (last == null) {
      return conversation.isGroup ? l10n.groupCreatedNote : '';
    }
    if (last.senderId == chat.meId) return l10n.youPrefix(last.text);
    if (conversation.isGroup) {
      return l10n.senderPrefix(
        firstName(chat, conversation, last.senderId),
        last.text,
      );
    }
    return last.text;
  }

  /// "14.05", "Yesterday", or "12 Oct" for the chat list.
  static String listTime(BuildContext context, DateTime time) {
    final offset = TaskDateUtils.calendarDayOffset(time);
    if (offset == 0) return TaskDateUtils.time(context, time);
    if (offset == -1) return AppLocalizations.of(context).yesterday;
    return DateFormat(
      'd MMM',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(time);
  }

  /// Date separator inside a chat: "Today", "Yesterday", or a full date.
  static String dayLabel(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context);
    final offset = TaskDateUtils.calendarDayOffset(time);
    if (offset == 0) return l10n.today;
    if (offset == -1) return l10n.yesterday;
    return DateFormat(
      'd MMMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(time);
  }
}

class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    required this.conversation,
    this.radius = 24,
    super.key,
  });

  final Conversation conversation;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!conversation.isGroup) {
      return InitialsAvatar(
        name: ChatText.title(AppScope.of(context).chat, conversation),
        radius: radius,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.skyBlue.withValues(alpha: 0.2),
      child: Icon(Icons.groups_rounded, color: AppColors.skyBlue, size: radius),
    );
  }
}

/// Small notice that replies are simulated (offline demo only).
class ChatDemoNotice extends StatelessWidget {
  const ChatDemoNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mediumPriority.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).chatDemoNotice,
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
