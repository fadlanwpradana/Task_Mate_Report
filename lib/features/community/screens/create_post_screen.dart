import 'dart:async';

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
import '../services/post_video_service.dart';
import '../widgets/post_video_player.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    this.initialCommunityId,
    this.imageService,
    this.videoService,
    this.cloudinaryService,
    super.key,
  });

  final String? initialCommunityId;
  final PostImageService? imageService;
  final PostVideoService? videoService;
  final CloudinaryService? cloudinaryService;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  late final PostImageService _imageService;
  late final PostVideoService _videoService;
  late final CloudinaryService _cloudinaryService;
  PostType _type = PostType.question;
  final List<String> _tags = [];
  final List<SelectedPostImage> _images = [];
  SelectedPostVideo? _video;
  var _publishing = false;
  var _selectingImages = false;
  var _selectingVideo = false;
  double _uploadProgress = 0;
  late String? _communityId = widget.initialCommunityId;

  @override
  void initState() {
    super.initState();
    _imageService = widget.imageService ?? PostImageService();
    _videoService = widget.videoService ?? PostVideoService();
    _cloudinaryService = widget.cloudinaryService ?? CloudinaryService();
  }

  @override
  void dispose() {
    final video = _video;
    if (video != null) _disposeSelectedVideo(video);
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
    if (_publishing || _selectingImages || _selectingVideo) return;
    if (_video != null) {
      _showError(AppLocalizations.of(context).postMediaExclusive);
      return;
    }
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
    setState(() => _selectingImages = true);
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
      _showError(_selectionErrorMessage(error));
    } finally {
      if (mounted) setState(() => _selectingImages = false);
    }
  }

  Future<void> _selectVideo() async {
    if (_publishing || _selectingImages || _selectingVideo) return;
    if (_images.isNotEmpty) {
      _showError(AppLocalizations.of(context).postMediaExclusive);
      return;
    }
    if (_video != null) return;

    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    if (services.community.communityById(_communityId)?.isPrivate == true) {
      _showError(l10n.privateCommunityMediaUnavailable);
      return;
    }
    if (!services.online || services.currentUserId == null) {
      _showError(l10n.postMediaUploadRequiresSignIn);
      return;
    }

    setState(() => _selectingVideo = true);
    try {
      final selected = await _videoService.pickAndValidateFromGallery();
      if (!mounted) {
        if (selected != null) _disposeSelectedVideo(selected);
        return;
      }
      if (selected != null) setState(() => _video = selected);
    } catch (error) {
      if (mounted) {
        _showError(_videoValidationError(error, l10n) ?? error.toString());
      }
    } finally {
      if (mounted) setState(() => _selectingVideo = false);
    }
  }

  void _removeVideo() {
    final selected = _video;
    if (selected == null) return;
    setState(() => _video = null);
    _disposeSelectedVideo(selected);
  }

  void _disposeSelectedVideo(SelectedPostVideo video) {
    PostVideoPlaybackCoordinator.release(video.controller);
    unawaited(video.controller.dispose());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publish() async {
    if (_publishing || !_formKey.currentState!.validate()) return;
    _addTag();
    final l10n = AppLocalizations.of(context);
    try {
      PostVideoService.ensureExclusiveMedia(
        imageCount: _images.length,
        hasVideo: _video != null,
      );
    } on FormatException catch (error) {
      _showError(_videoValidationError(error, l10n) ?? error.message);
      return;
    }
    setState(() {
      _publishing = true;
      _uploadProgress = 0;
    });
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final postId = services.community.newPostId();
    var uploadedUrls = <String>[];
    String? uploadedVideoUrl;
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
        uploadedUrls = await _cloudinaryService.uploadImages(
          images: _images,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }
      final selectedVideo = _video;
      if (selectedVideo != null) {
        if (services.community.communityById(_communityId)?.isPrivate == true) {
          throw StateError(l10n.privateCommunityMediaUnavailable);
        }
        if (services.currentUserId == null || !services.online) {
          throw StateError(l10n.postMediaUploadRequiresSignIn);
        }
        uploadedVideoUrl = await _cloudinaryService.uploadVideo(
          file: selectedVideo.file,
          duration: selectedVideo.duration,
          expectedSizeBytes: selectedVideo.sizeBytes,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }
      final mediaType = uploadedVideoUrl != null
          ? PostMediaType.video
          : uploadedUrls.isNotEmpty
          ? PostMediaType.image
          : null;
      PostVideoService.validatePostMedia(
        imageUrls: uploadedUrls,
        mediaType: mediaType,
        videoUrl: uploadedVideoUrl,
      );
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
          mediaType: mediaType,
          videoUrl: uploadedVideoUrl,
          createdAt: DateTime.now(),
        ),
        postId: postId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.postPublished)));
    } catch (error) {
      final validationMessage = _videoValidationError(error, l10n);
      final message =
          validationMessage ?? l10n.postPublishFailed(error.toString());
      if (mounted) _showError(message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _selectionErrorMessage(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }

  String? _videoValidationError(Object error, AppLocalizations l10n) {
    if (error is! FormatException) return null;
    return switch (error.message) {
      PostVideoService.durationErrorMessage => l10n.videoDurationTooLong,
      PostVideoService.fileSizeErrorMessage => l10n.videoFileTooLarge,
      PostVideoService.formatErrorMessage => l10n.videoMp4Only,
      PostVideoService.mediaConflictMessage => l10n.postMediaExclusive,
      PostVideoService.durationUnknownMessage => l10n.videoDurationUnknown,
      _ => null,
    };
  }

  String _durationLabel(Duration duration) {
    final seconds = duration.inMilliseconds / Duration.millisecondsPerSecond;
    return '${seconds.toStringAsFixed(1)} sec';
  }

  String _sizeLabel(int sizeBytes) =>
      (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

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
            FieldLabel(l10n.postMedia),
            if (_video case final video?) ...[
              const SizedBox(height: 8),
              FieldLabel(l10n.postVideo),
              CommunityInlineVideo(controller: video.controller),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.videoDurationInfo(
                            _durationLabel(video.duration),
                          ),
                        ),
                        Text(
                          l10n.videoFileSizeInfo(_sizeLabel(video.sizeBytes)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.removeVideo,
                    onPressed: _publishing ? null : _removeVideo,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
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
                          onPressed: _publishing || _selectingImages
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
                    onPressed:
                        _publishing ||
                            _selectingImages ||
                            _selectingVideo ||
                            _video != null
                        ? null
                        : () => _selectImages(useCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.gallery),
                  ),
                if (_images.length < PostImageService.maxImages)
                  TextButton.icon(
                    onPressed:
                        _publishing ||
                            _selectingImages ||
                            _selectingVideo ||
                            _video != null
                        ? null
                        : () => _selectImages(useCamera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.camera),
                  ),
                TextButton.icon(
                  onPressed:
                      _publishing ||
                          _selectingImages ||
                          _selectingVideo ||
                          _video != null ||
                          _images.isNotEmpty
                      ? null
                      : _selectVideo,
                  icon: _selectingVideo
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.video_library_outlined),
                  label: Text(l10n.selectVideo),
                ),
              ],
            ),
            if (_images.isNotEmpty || _video != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.postMediaExclusive,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_publishing && (_images.isNotEmpty || _video != null)) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                _video != null
                    ? l10n.uploadingVideo((_uploadProgress * 100).round())
                    : l10n.uploadingPhotos((_uploadProgress * 100).round()),
              ),
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
