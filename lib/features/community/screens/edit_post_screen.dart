import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/cloudinary_service.dart';
import '../services/post_image_service.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({required this.postId, super.key});

  final String postId;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageService = PostImageService();
  final _existingImageUrls = <String>[];
  final _newImages = <SelectedPostImage>[];

  PostModel? _post;
  String? _error;
  var _loading = true;
  var _saving = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPost());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _loadPost() {
    final services = AppScope.of(context);
    if (_post?.communityId != null &&
        services.community.communityById(_post!.communityId)?.isPrivate ==
            true) {
      _showError(
        AppLocalizations.of(context).privateCommunityPhotosUnavailable,
      );
      return;
    }
    final post = services.community.postById(widget.postId);
    if (post == null) {
      setState(() {
        _error = AppLocalizations.of(context).postNotAvailable;
        _loading = false;
      });
      return;
    }
    if (post.authorId == null || post.authorId != services.currentUserId) {
      setState(() {
        _error = AppLocalizations.of(context).editOwnPostOnly;
        _loading = false;
      });
      return;
    }
    setState(() {
      _post = post;
      _titleController.text = post.title;
      _bodyController.text = post.body;
      _existingImageUrls.addAll(post.imageUrls);
      _loading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectImages({required bool useCamera}) async {
    final services = AppScope.of(context);
    if (!services.online || services.currentUserId == null) {
      _showError(AppLocalizations.of(context).photoUploadRequiresSignIn);
      return;
    }
    final count = _existingImageUrls.length + _newImages.length;
    try {
      if (useCamera) {
        final image = await _imageService.captureFromCamera(
          currentCount: count,
        );
        if (image != null && mounted) {
          setState(() => _newImages.add(image));
        }
      } else {
        final images = await _imageService.pickFromGallery(currentCount: count);
        if (mounted && images.isNotEmpty) {
          setState(() => _newImages.addAll(images));
        }
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _save() async {
    final original = _post;
    if (_saving || original == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _uploadProgress = 0;
    });
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var uploadedUrls = <String>[];
    try {
      if (_newImages.isNotEmpty) {
        final userId = services.currentUserId;
        if (userId == null || !services.online) {
          throw StateError(
            'Photo uploads require an authenticated Firebase account.',
          );
        }
        uploadedUrls = await CloudinaryService().uploadImages(
          images: _newImages,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }
      final updated = original.copyWith(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrls: [..._existingImageUrls, ...uploadedUrls],
      );
      await services.community.updatePost(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.postUpdated)));
    } catch (error) {
      final message = l10n.postSaveFailed(error.toString());
      if (mounted) _showError(message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error case final error?) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editPost)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editPost)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            FieldLabel(l10n.postTitleLabel),
            TextFormField(
              controller: _titleController,
              maxLength: 200,
              validator: _requiredText,
              textCapitalization: TextCapitalization.sentences,
            ),
            FieldLabel(l10n.descriptionLabel),
            TextFormField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 10,
              maxLength: 5000,
              validator: _requiredText,
              textCapitalization: TextCapitalization.sentences,
            ),
            FieldLabel(l10n.postPhotos),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _existingImageUrls.length; index++)
                  _ExistingPhoto(
                    url: _existingImageUrls[index],
                    onRemove: _saving
                        ? null
                        : () => setState(
                            () => _existingImageUrls.removeAt(index),
                          ),
                  ),
                for (var index = 0; index < _newImages.length; index++)
                  _NewPhoto(
                    image: _newImages[index],
                    onRemove: _saving
                        ? null
                        : () => setState(() => _newImages.removeAt(index)),
                  ),
                if (_existingImageUrls.length + _newImages.length <
                    PostImageService.maxImages)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _selectImages(useCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.gallery),
                  ),
                if (_existingImageUrls.length + _newImages.length <
                    PostImageService.maxImages)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _selectImages(useCamera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.camera),
                  ),
              ],
            ),
            if (_saving && _newImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(l10n.uploadingPhotos((_uploadProgress * 100).round())),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: _saving ? l10n.savingPost : l10n.savePostChanges,
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }
}

class _ExistingPhoto extends StatelessWidget {
  const _ExistingPhoto({required this.url, required this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => _PhotoFrame(
    onRemove: onRemove,
    child: Image.network(
      url,
      width: 84,
      height: 84,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const SizedBox.square(
              dimension: 84,
              child: Center(child: CircularProgressIndicator()),
            ),
      errorBuilder: (context, error, stackTrace) => const SizedBox.square(
        dimension: 84,
        child: Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}

class _NewPhoto extends StatelessWidget {
  const _NewPhoto({required this.image, required this.onRemove});

  final SelectedPostImage image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => _PhotoFrame(
    onRemove: onRemove,
    child: Image.memory(image.bytes, width: 84, height: 84, fit: BoxFit.cover),
  );
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
      Positioned(
        top: 2,
        right: 2,
        child: IconButton.filledTonal(
          tooltip: AppLocalizations.of(context).removePhoto,
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, size: 16),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ],
  );
}
