import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/comment_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../services/community_repository.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  late final CommunityRepository _community;

  @override
  void initState() {
    super.initState();
    // Load (and keep listening to) this post's comments while it's open.
    _community = AppScope.of(context).community..openPost(widget.postId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_recordView());
    });
  }

  Future<void> _recordView() async {
    try {
      await _community.recordView(widget.postId);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'community',
          context: ErrorDescription('while recording a post detail view'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _community.closePost(widget.postId);
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    final services = AppScope.of(context);
    _commentController.clear();
    FocusScope.of(context).unfocus();
    await services.community.addComment(
      widget.postId,
      CommentModel(
        id: generateId(),
        authorName: services.currentUserName,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _messageAuthor(String userId) async {
    final conversationId = await AppScope.of(context).chat
        .directChatWith(userId);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(conversationId: conversationId),
      ),
    );
  }

  void _replyTo(CommentModel comment) {
    _commentController.text = '@${comment.authorName} ';
    _commentController.selection = TextSelection.collapsed(
      offset: _commentController.text.length,
    );
    _commentFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final post = repository.postById(widget.postId);
        if (post == null) return Scaffold(appBar: AppBar());
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.post),
            actions: [
              if (post.authorId case final authorId?
                  when authorId != AppScope.of(context).chat.meId)
                IconButton(
                  tooltip: '${l10n.sendMessage} · ${post.authorName}',
                  onPressed: () => _messageAuthor(authorId),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              PostHeader(post: post),
              const SizedBox(height: 16),
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(post.body, style: const TextStyle(height: 1.5)),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                TagWrap(tags: post.tags),
              ],
              const SizedBox(height: 4),
              PostActions(post: post),
              const Divider(height: 24),
              Text(
                '${l10n.comments} (${post.totalComments})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (post.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noComments,
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              for (final comment in post.comments)
                _CommentTile(
                  comment: comment,
                  onLike: () =>
                      repository.toggleCommentLike(post.id, comment.id),
                  onReply: () => _replyTo(comment),
                ),
            ],
          ),
          bottomNavigationBar: _CommentInput(
            controller: _commentController,
            focusNode: _commentFocus,
            onSend: _sendComment,
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
  });

  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(name: comment.authorName, radius: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(comment.body, style: const TextStyle(height: 1.4)),
                Row(
                  children: [
                    Text(
                      FormatUtils.timeAgo(context, comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: onReply,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(l10n.reply),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onLike,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: comment.likedByMe
                            ? Colors.red.shade400
                            : AppColors.secondaryText,
                      ),
                      icon: Icon(
                        comment.likedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        semanticLabel: l10n.like,
                      ),
                      label: Text('${comment.likeCount}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        8,
        10 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.writeComment,
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
