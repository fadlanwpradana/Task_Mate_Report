import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({this.initialCommunityId, super.key});

  final String? initialCommunityId;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  PostType _type = PostType.question;
  final List<String> _tags = [];
  late String? _communityId = widget.initialCommunityId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().replaceAll('#', '');
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    _addTag();
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await services.community.addPost(
      PostModel(
        id: generateId(),
        authorName: services.currentUserName,
        communityId: _communityId,
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        tags: [..._tags],
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.postPublished)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Private communities only accept posts from their members.
    final communities = AppScope.of(context).community.communities
        .where((c) => !c.isPrivate || c.joined)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createPost)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            ChoiceChipRow<PostType>(
              values: PostType.values,
              selected: _type,
              labelOf: (type) => FormatUtils.postType(l10n, type),
              onSelected: (type) => setState(() => _type = type),
            ),
            FieldLabel(l10n.postTitleLabel),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(hintText: l10n.postTitleHint),
              validator: (value) => ValidationUtils.requiredText(
                value,
                l10n,
                label: l10n.postTitleLabel,
              ),
            ),
            FieldLabel(l10n.descriptionLabel),
            TextFormField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.postDescriptionHint),
              validator: (value) => ValidationUtils.requiredText(
                value,
                l10n,
                label: l10n.descriptionLabel,
              ),
            ),
            FieldLabel(l10n.tags),
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      backgroundColor: AppColors.skyBlue.withValues(
                        alpha: 0.12,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _tagController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTag(),
              decoration: InputDecoration(
                hintText: l10n.tagHint,
                prefixIcon: const Icon(Icons.tag_rounded),
                suffixIcon: IconButton(
                  tooltip: l10n.addTag,
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            FieldLabel(l10n.communityOptional),
            DropdownButtonFormField<String?>(
              initialValue: _communityId,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noCommunity)),
                for (final community in communities)
                  DropdownMenuItem(
                    value: community.id,
                    child: Text(community.name),
                  ),
              ],
              onChanged: (value) => setState(() => _communityId = value),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: l10n.publish,
              icon: Icons.send_rounded,
              onPressed: _publish,
            ),
          ],
        ),
      ),
    );
  }
}
