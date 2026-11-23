import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../models/post_model.dart';
import 'post_image_service.dart';
import 'post_video_controller_factory.dart';

typedef PostVideoControllerFactory = VideoPlayerController Function(
  String path,
);

class SelectedPostVideo {
  const SelectedPostVideo({
    required this.file,
    required this.sizeBytes,
    required this.duration,
    required this.controller,
  });

  final XFile file;
  final int sizeBytes;
  final Duration duration;
  final VideoPlayerController controller;
}

class PostVideoService {
  PostVideoService({
    ImagePicker? picker,
    PostVideoControllerFactory? controllerFactory,
  }) : _picker = picker ?? ImagePicker(),
       _controllerFactory = controllerFactory ?? createPostVideoController;

  static const maxDuration = Duration(seconds: 15);
  static const maxFileSizeBytes = 50 * 1024 * 1024;
  static const durationErrorMessage =
      'Video duration must not exceed 15 seconds.';
  static const fileSizeErrorMessage = 'Video file size must not exceed 50 MB.';
  static const formatErrorMessage = 'Only MP4 videos are supported.';
  static const mediaConflictMessage =
      'A post can contain up to 4 images or 1 video, not both.';
  static const durationUnknownMessage = 'Could not determine video duration.';

  final ImagePicker _picker;
  final PostVideoControllerFactory _controllerFactory;

  Future<SelectedPostVideo?> pickAndValidateFromGallery() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;

    final sizeBytes = await validateFile(file);
    final controller = _controllerFactory(file.path);
    try {
      await controller.initialize();
      validateDuration(controller.value.duration);
      return SelectedPostVideo(
        file: file,
        sizeBytes: sizeBytes,
        duration: controller.value.duration,
        controller: controller,
      );
    } catch (error, stackTrace) {
      await controller.dispose();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static Future<int> validateFile(XFile file, {Duration? duration}) async {
    if (!file.name.toLowerCase().endsWith('.mp4')) {
      throw const FormatException(formatErrorMessage);
    }

    final sizeBytes = await file.length();
    if (sizeBytes > maxFileSizeBytes) {
      throw const FormatException(fileSizeErrorMessage);
    }

    final header = <int>[];
    await for (final chunk in file.openRead(0, 12)) {
      header.addAll(chunk);
      if (header.length >= 12) break;
    }
    if (!_hasMp4FileTypeBox(header)) {
      throw const FormatException(formatErrorMessage);
    }

    if (duration != null) validateDuration(duration);
    return sizeBytes;
  }

  static void validateDuration(Duration duration) {
    if (duration > maxDuration) {
      throw const FormatException(durationErrorMessage);
    }
    if (duration <= Duration.zero) {
      throw const FormatException(durationUnknownMessage);
    }
  }

  static void ensureExclusiveMedia({
    required int imageCount,
    required bool hasVideo,
  }) {
    if (imageCount > 0 && hasVideo) {
      throw const FormatException(mediaConflictMessage);
    }
    PostImageService.ensureCapacity(0, imageCount);
  }

  static void validatePostMedia({
    required List<String> imageUrls,
    required PostMediaType? mediaType,
    required String? videoUrl,
  }) {
    ensureExclusiveMedia(
      imageCount: imageUrls.length,
      hasVideo: mediaType == PostMediaType.video || videoUrl != null,
    );

    if (mediaType == PostMediaType.video) {
      final uri = videoUrl == null ? null : Uri.tryParse(videoUrl);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.toString().isEmpty) {
        throw const FormatException('A valid video URL is required.');
      }
      return;
    }

    if (videoUrl != null ||
        (mediaType == PostMediaType.image && imageUrls.isEmpty)) {
      throw const FormatException(mediaConflictMessage);
    }
  }

  static bool _hasMp4FileTypeBox(List<int> header) {
    return header.length >= 12 &&
        String.fromCharCodes(header.sublist(4, 8)) == 'ftyp';
  }
}
