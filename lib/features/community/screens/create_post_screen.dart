import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/cloudinary_service.dart';
import '../services/post_image_service.dart';

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
  final _imageService = PostImageService();
  PostType _type = PostType.question;
  final List<String> _tags = [];
  final List<SelectedPostImage> _images = [];
  var _publishing = false;
  double _uploadProgress = 0;
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

  Future<void> _selectImages({required bool useCamera}) async {
    final services = AppScope.of(context);
    if (services.community.communityById(_communityId)?.isPrivate == true) {
      _showError(
        AppLocalizations.of(context).privateCommunityPhotosUnavailable,
      );
      return;
    }
    if (!services.online || services.currentUserId == null) {
      _showError(AppLocalizations.of(context).photoUploadRequiresSignIn);
      return;
    }
    try {
      if (useCamera) {
        final image = await _imageService.captureFromCamera(
          currentCount: _images.length,
        );
        if (image != null && mounted) {
          setState(() => _images.add(image));
        }
      } else {
        final images = await _imageService.pickFromGallery(
          currentCount: _images.length,
        );
        if (mounted && images.isNotEmpty) {
          setState(() => _images.addAll(images));
        }
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publish() async {
    if (_publishing || !_formKey.currentState!.validate()) return;
    _addTag();
    final l10n = AppLocalizations.of(context);
    setState(() {
      _publishing = true;
      _uploadProgress = 0;
    });
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final postId = services.community.newPostId();
    var uploadedUrls = <String>[];
    try {
      if (_images.isNotEmpty) {
        if (services.community.communityById(_communityId)?.isPrivate == true) {
          throw StateError(l10n.privateCommunityPhotosUnavailable);
        }
        final userId = services.currentUserId;
        if (userId == null || !services.online) {
          throw StateError(
            'Photo uploads require an authenticated Firebase account.',
          );
        }
        uploadedUrls = await CloudinaryService().uploadImages(
          images: _images,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }
      await services.community.addPost(
        PostModel(
          id: postId,
          authorName: services.currentUserName,
          communityId: _communityId,
          type: _type,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: [..._tags],
          imageUrls: uploadedUrls,
          createdAt: DateTime.now(),
        ),
        postId: postId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.postPublished)));
    } catch (error) {
      final message = l10n.postPublishFailed(error.toString());
      if (mounted) _showError(message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
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
            FieldLabel(l10n.postPhotos),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _images.length; index++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _images[index].bytes,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton.filledTonal(
                          tooltip: l10n.removePhoto,
                          onPressed: _publishing
                              ? null
                              : () => setState(() => _images.removeAt(index)),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                if (_images.length < PostImageService.maxImages)
                  TextButton.icon(
                    onPressed: _publishing
                        ? null
                        : () => _selectImages(useCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.gallery),
                  ),
                if (_images.length < PostImageService.maxImages)
                  TextButton.icon(
                    onPressed: _publishing
                        ? null
                        : () => _selectImages(useCamera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.camera),
                  ),
              ],
            ),
            if (_publishing && _images.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(l10n.uploadingPhotos((_uploadProgress * 100).round())),
            ],
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
              label: _publishing ? l10n.publishingPost : l10n.publish,
              icon: Icons.send_rounded,
              onPressed: _publishing ? null : _publish,
            ),
          ],
        ),
      ),
    );
  }
}
