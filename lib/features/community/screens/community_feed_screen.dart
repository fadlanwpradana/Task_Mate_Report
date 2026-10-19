import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../services/community_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/post_view_observer.dart';
import 'search_screen.dart';

/// Body of the Community tab: For You / Following / Trending feeds.
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  PostType? _typeFilter;
  final _scrollChanges = ValueNotifier(0);

  @override
  void dispose() {
    _scrollChanges.dispose();
    super.dispose();
  }

  Future<void> _chooseTypeFilter() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<({PostType? type})>(
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
                l10n.filterPosts,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final type in [null, ...PostType.values])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  type == null
                      ? l10n.allTypes
                      : FormatUtils.postType(l10n, type),
                ),
                trailing: type == _typeFilter
                    ? Icon(Icons.check_rounded, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.of(context).pop((type: type)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _typeFilter = selected.type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.navy,
            dividerColor: AppColors.border,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: l10n.forYou),
              Tab(text: l10n.following),
              Tab(text: l10n.trending),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: SearchField(
              hint: l10n.searchCommunityHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
              ),
              trailing: IconButton(
                tooltip: l10n.filterPosts,
                onPressed: _chooseTypeFilter,
                icon: Badge(
                  isLabelVisible: _typeFilter != null,
                  smallSize: 8,
                  backgroundColor: AppColors.skyBlue,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: repository,
              builder: (context, _) {
                return NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    _scrollChanges.value++;
                    return false;
                  },
                  child: TabBarView(
                    children: [
                      _PostList(
                        posts: _filtered(repository.posts),
                        repository: repository,
                        scrollChanges: _scrollChanges,
                        emptyTitle: l10n.noPostsTitle,
                        emptyDescription: l10n.noPostsDescription,
                      ),
                      _PostList(
                        posts: _filtered(repository.followingPosts),
                        repository: repository,
                        scrollChanges: _scrollChanges,
                        emptyTitle: l10n.noPostsTitle,
                        emptyDescription: l10n.noFollowingPosts,
                      ),
                      _PostList(
                        posts: _filtered(repository.trendingPosts),
                        repository: repository,
                        scrollChanges: _scrollChanges,
                        emptyTitle: l10n.noPostsTitle,
                        emptyDescription: l10n.noPostsDescription,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PostModel> _filtered(List<PostModel> posts) => _typeFilter == null
      ? posts
      : posts.where((p) => p.type == _typeFilter).toList();
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.posts,
    required this.repository,
    required this.scrollChanges,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  final List<PostModel> posts;
  final CommunityRepository repository;
  final ValueListenable<int> scrollChanges;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: Icons.forum_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostViewObserver(
          key: ValueKey(post.id),
          postId: post.id,
          onView: () => repository.recordView(post.id),
          scrollChanges: scrollChanges,
          child: PostCard(post: post),
        );
      },
    );
  }
}
