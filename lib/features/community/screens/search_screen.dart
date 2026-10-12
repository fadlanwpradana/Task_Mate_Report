import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/community_tile.dart';
import '../widgets/post_card.dart';

enum _SearchScope { all, posts, communities }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  _SearchScope _scope = _SearchScope.all;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    final query = _queryController.text;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.search)),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final showPosts = _scope != _SearchScope.communities;
          final showCommunities = _scope != _SearchScope.posts;
          final posts = showPosts ? repository.searchPosts(query) : const [];
          final communities = showCommunities
              ? repository.searchCommunities(query)
              : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              SearchField(
                hint: l10n.searchHint,
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              ChoiceChipRow<_SearchScope>(
                values: _SearchScope.values,
                selected: _scope,
                labelOf: (scope) => switch (scope) {
                  _SearchScope.all => l10n.filterAll,
                  _SearchScope.posts => l10n.posts,
                  _SearchScope.communities => l10n.communities,
                },
                onSelected: (scope) => setState(() => _scope = scope),
              ),
              const SizedBox(height: 8),
              if (query.trim().isEmpty)
                EmptyState(title: l10n.searchPrompt, icon: Icons.search_rounded)
              else if (posts.isEmpty && communities.isEmpty)
                EmptyState(
                  title: l10n.noResults,
                  icon: Icons.search_off_rounded,
                )
              else ...[
                if (posts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SectionHeader(title: l10n.posts),
                  const SizedBox(height: 8),
                  for (final post in posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(post: post),
                    ),
                ],
                if (communities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SectionHeader(title: l10n.communities),
                  const SizedBox(height: 8),
                  for (final community in communities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CommunityTile(community: community),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
