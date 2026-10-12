import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/community_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import 'community_detail_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  static const _colors = [
    AppColors.skyBlue,
    AppColors.brand,
    AppColors.sageGreen,
    AppColors.mediumPriority,
    AppColors.highPriority,
    Color(0xFF9B87D9),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  CommunityCategory _category = CommunityCategory.course;
  bool _isPrivate = false;
  Color _color = _colors.first;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final repository = AppScope.of(context).community;
    final messenger = ScaffoldMessenger.of(context);
    final community = CommunityModel(
      id: generateId(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      topic: _topicController.text.trim(),
      category: _category,
      isPrivate: _isPrivate,
      memberCount: 1,
      joined: true,
      colorValue: _color.toARGB32(),
      createdAt: DateTime.now(),
    );
    await repository.addCommunity(community);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CommunityDetailScreen(communityId: community.id),
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.communityCreated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = _nameController.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCommunity)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: initial.isEmpty
                    ? Icon(
                        Icons.groups_rounded,
                        size: 40,
                        color: Color.lerp(_color, AppColors.navy, 0.4),
                      )
                    : Text(
                        initial[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color.lerp(_color, AppColors.navy, 0.4),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.communityColor,
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                for (final color in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == _color
                              ? AppColors.navy
                              : Colors.transparent,
                          width: 3,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            FieldLabel(l10n.communityNameLabel),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: l10n.communityNameHint),
              validator: (value) => ValidationUtils.requiredText(
                value,
                l10n,
                label: l10n.communityNameLabel,
              ),
            ),
            FieldLabel(l10n.descriptionLabel),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.communityDescriptionHint,
              ),
            ),
            FieldLabel(l10n.topicLabel),
            TextFormField(
              controller: _topicController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: l10n.topicHint),
            ),
            FieldLabel(l10n.categoryLabel),
            SegmentedButton<CommunityCategory>(
              showSelectedIcon: false,
              segments: [
                for (final category in CommunityCategory.values)
                  ButtonSegment(
                    value: category,
                    label: Text(FormatUtils.category(l10n, category)),
                  ),
              ],
              selected: {_category},
              onSelectionChanged: (selection) =>
                  setState(() => _category = selection.first),
            ),
            const SizedBox(height: 12),
            RadioGroup<bool>(
              groupValue: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value!),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.visibilityPublic),
                    subtitle: Text(l10n.visibilityPublicDescription),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.visibilityPrivate),
                    subtitle: Text(l10n.visibilityPrivateDescription),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.createCommunity,
              icon: Icons.check_rounded,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }
}
