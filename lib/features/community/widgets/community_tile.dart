import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/community_model.dart';
import '../screens/community_detail_screen.dart';

class CommunityIcon extends StatelessWidget {
  const CommunityIcon({required this.community, this.size = 46, super.key});

  final CommunityModel community;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(community.colorValue);
    final initial = community.name.trim().isEmpty
        ? '?'
        : community.name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Color.lerp(color, AppColors.navy, 0.4),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class JoinButton extends StatelessWidget {
  const JoinButton({required this.community, super.key});

  final CommunityModel community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
    if (community.joined) {
      return OutlinedButton(
        style: style,
        onPressed: () => repository.toggleJoin(community.id),
        child: Text(l10n.joined),
      );
    }
    return FilledButton(
      style: style.copyWith(
        backgroundColor: const WidgetStatePropertyAll(AppColors.brand),
      ),
      onPressed: () => repository.toggleJoin(community.id),
      child: Text(l10n.join),
    );
  }
}

class CommunityTile extends StatelessWidget {
  const CommunityTile({required this.community, super.key});

  final CommunityModel community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final postCount = AppScope.of(context).community.postCount(community.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CommunityDetailScreen(communityId: community.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CommunityIcon(community: community),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            community.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (community.isPrivate) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${l10n.membersCount(community.memberCount)} · '
                      '${l10n.postsCount(postCount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      FormatUtils.category(l10n, community.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              JoinButton(community: community),
            ],
          ),
        ),
      ),
    );
  }
}
