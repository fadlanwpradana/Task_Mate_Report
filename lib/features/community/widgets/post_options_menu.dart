import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../screens/edit_post_screen.dart';

class PostOptionsMenu extends StatefulWidget {
  const PostOptionsMenu({
    required this.post,
    this.popAfterDelete = false,
    super.key,
  });

  final PostModel post;
  final bool popAfterDelete;

  @override
  State<PostOptionsMenu> createState() => _PostOptionsMenuState();
}

class _PostOptionsMenuState extends State<PostOptionsMenu> {
  var _deleting = false;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    if (widget.post.authorId == null ||
        widget.post.authorId != services.currentUserId) {
      return const SizedBox.shrink();
    }
    if (_deleting) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return PopupMenuButton<_PostAction>(
      tooltip: l10n.postOptions,
      onSelected: (action) {
        if (action == _PostAction.edit) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditPostScreen(postId: widget.post.id),
            ),
          );
        } else {
          _confirmDelete(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _PostAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text(l10n.edit),
          ),
        ),
        PopupMenuItem(
          value: _PostAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text(l10n.delete),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePostQuestion),
        content: Text(l10n.deletePostMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await services.community.deletePost(widget.post.id);
    } catch (error, stackTrace) {
      debugPrint(
        'Could not delete post ${widget.post.id}: $error\n$stackTrace',
      );
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.postDeleteFailed(error.toString()))),
        );
      }
      if (mounted) setState(() => _deleting = false);
      return;
    }

    if (widget.popAfterDelete && navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
    await _showDeletedAlert(navigator, l10n);
    if (mounted) setState(() => _deleting = false);
  }

  Future<void> _showDeletedAlert(
    NavigatorState navigator,
    AppLocalizations l10n,
  ) async {
    if (!navigator.mounted) return;
    var dialogOpen = true;
    final dialogFuture = showDialog<void>(
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.sageGreen,
          size: 42,
        ),
        title: Text(
          l10n.postDeletedTitle,
          textAlign: TextAlign.center,
          style: Theme.of(dialogContext).textTheme.titleLarge
              ?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
        ),
        content: Text(l10n.postDeletedMessage, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    unawaited(dialogFuture.then((_) => dialogOpen = false));
    await Future.any<void>([
      dialogFuture,
      Future<void>.delayed(const Duration(seconds: 4)),
    ]);
    if (dialogOpen && navigator.mounted) navigator.pop();
    await dialogFuture;
  }

}

enum _PostAction { edit, delete }
