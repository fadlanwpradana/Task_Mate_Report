import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/community_tile.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({required this.communityId, super.key});

  final String communityId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final community = repository.communityById(communityId);
        if (community == null) return Scaffold(appBar: AppBar());
        final posts = repository.postsIn(communityId);
        final canSeePosts = !community.isPrivate || community.joined;
        return Scaffold(
          appBar: AppBar(title: Text(community.name)),
          floatingActionButton: community.joined
              ? FloatingActionButton(
                  tooltip: l10n.createPost,
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CreatePostScreen(initialCommunityId: communityId),
                    ),
                  ),
                  child: const Icon(Icons.edit_rounded),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      CommunityIcon(community: community, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        community.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          FormatUtils.category(l10n, community.category),
                          if (community.topic.isNotEmpty) community.topic,
                          community.isPrivate
                              ? l10n.visibilityPrivate
                              : l10n.visibilityPublic,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      if (community.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          community.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${l10n.membersCount(community.memberCount)} · '
                        '${l10n.postsCount(repository.postCount(community.id))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      JoinButton(community: community),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!canSeePosts)
                EmptyState(
                  title: l10n.visibilityPrivate,
                  description: l10n.visibilityPrivateDescription,
                  icon: Icons.lock_outline_rounded,
                )
              else if (posts.isEmpty)
                EmptyState(
                  title: l10n.communityNoPosts,
                  icon: Icons.forum_outlined,
                )
              else
                for (final post in posts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PostCard(post: post),
                  ),
            ],
          ),
        );
      },
    );
  }
}
