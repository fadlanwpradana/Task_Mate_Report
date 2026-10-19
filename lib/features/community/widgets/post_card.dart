import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../screens/post_detail_screen.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, super.key});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PostDetailScreen(postId: post.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PostHeader(post: post),
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4),
              ),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                TagWrap(tags: post.tags),
              ],
              PostActions(post: post),
            ],
          ),
        ),
      ),
    );
  }
}

/// Author avatar, name, community/time, and post type badge.
class PostHeader extends StatelessWidget {
  const PostHeader({required this.post, super.key});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final community = AppScope.of(context).community
        .communityById(post.communityId);
    final source = community?.name ?? post.authorSubtitle;
    final time = FormatUtils.timeAgo(context, post.createdAt);
    return Row(
      children: [
        InitialsAvatar(name: post.authorName),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                source.isEmpty ? time : '$source · $time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: FormatUtils.postType(l10n, post.type),
          color: FormatUtils.postTypeColor(post.type),
        ),
      ],
    );
  }
}

class TagWrap extends StatelessWidget {
  const TagWrap({required this.tags, super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Like, comment count, and bookmark buttons.
class PostActions extends StatelessWidget {
  const PostActions({required this.post, super.key});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => repository.toggleLike(post.id),
          style: TextButton.styleFrom(
            foregroundColor: post.likedByMe
                ? Colors.red.shade400
                : AppColors.secondaryText,
          ),
          icon: Icon(
            post.likedByMe
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 20,
            semanticLabel: l10n.like,
          ),
          label: Text('${post.likeCount}'),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 19,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          '${post.totalComments}',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.visibility_outlined,
          size: 19,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          '${post.viewCount}',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        const Spacer(),
        IconButton(
          tooltip: post.bookmarked ? l10n.removeBookmark : l10n.bookmark,
          onPressed: () => repository.toggleBookmark(post.id),
          icon: Icon(
            post.bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: post.bookmarked ? AppColors.navy : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
