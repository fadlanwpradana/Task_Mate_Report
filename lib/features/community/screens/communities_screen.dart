import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/community_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/community_tile.dart';
import 'create_community_screen.dart';

enum _CommunityFilter { all, popular, joined, course, major }

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final _searchController = TextEditingController();
  _CommunityFilter _filter = _CommunityFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityModel> _visible(List<CommunityModel> communities) {
    final query = _searchController.text.trim().toLowerCase();
    final result = communities.where((c) {
      final matchesFilter = switch (_filter) {
        _CommunityFilter.all || _CommunityFilter.popular => true,
        _CommunityFilter.joined => c.joined,
        _CommunityFilter.course => c.category == CommunityCategory.course,
        _CommunityFilter.major => c.category == CommunityCategory.major,
      };
      final matchesQuery =
          query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.topic.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    if (_filter == _CommunityFilter.popular) {
      result.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communities),
        actions: [
          IconButton(
            tooltip: l10n.createCommunity,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateCommunityScreen(),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final communities = _visible(repository.communities);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              SearchField(
                hint: l10n.searchCommunitiesHint,
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              ChoiceChipRow<_CommunityFilter>(
                values: _CommunityFilter.values,
                selected: _filter,
                labelOf: (filter) => switch (filter) {
                  _CommunityFilter.all => l10n.filterAll,
                  _CommunityFilter.popular => l10n.filterPopular,
                  _CommunityFilter.joined => l10n.filterJoined,
                  _CommunityFilter.course => l10n.categoryCourse,
                  _CommunityFilter.major => l10n.categoryMajor,
                },
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 14),
              if (communities.isEmpty)
                EmptyState(
                  title: l10n.noCommunities,
                  icon: Icons.groups_2_outlined,
                )
              else
                for (final community in communities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommunityTile(community: community),
                  ),
            ],
          );
        },
      ),
    );
  }
}
