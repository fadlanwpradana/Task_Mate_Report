import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_mate_v4/features/community/services/cloudinary_service.dart';
import 'package:task_mate_v4/features/community/services/post_image_service.dart';
import 'package:task_mate_v4/features/community/services/post_video_service.dart';
import 'package:task_mate_v4/models/post_model.dart';

void main() {
  group('Post video validation', () {
    test('accepts a valid MP4 up to 15 seconds and 50 MB', () async {
      final file = await _testFile();

      expect(
        await PostVideoService.validateFile(
          file,
          duration: const Duration(seconds: 15),
        ),
        12,
      );
    });

    test('rejects videos longer than 15 seconds', () {
      expect(
        () => PostVideoService.validateDuration(const Duration(seconds: 16)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            PostVideoService.durationErrorMessage,
          ),
        ),
      );
    });

    test(
      'rejects files larger than 50 MB before reading their format',
      () async {
        final file = await _testFile(
          sizeBytes: PostVideoService.maxFileSizeBytes + 1,
        );

        await expectLater(
          PostVideoService.validateFile(file),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              PostVideoService.fileSizeErrorMessage,
            ),
          ),
        );
      },
    );

    test('rejects unsupported extensions and non-MP4 file headers', () async {
      await expectLater(
        PostVideoService.validateFile(await _testFile(name: 'clip.mov')),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        PostVideoService.validateFile(await _testFile(validHeader: false)),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not allow image and video media together', () {
      expect(
        () => PostVideoService.ensureExclusiveMedia(
          imageCount: 1,
          hasVideo: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            PostVideoService.mediaConflictMessage,
          ),
        ),
      );
      expect(
        () => PostVideoService.ensureExclusiveMedia(
          imageCount: 0,
          hasVideo: true,
        ),
        returnsNormally,
      );
      expect(
        () => PostVideoService.ensureExclusiveMedia(
          imageCount: PostImageService.maxImages,
          hasVideo: false,
        ),
        returnsNormally,
      );
      expect(
        () => PostVideoService.ensureExclusiveMedia(
          imageCount: PostImageService.maxImages + 1,
          hasVideo: false,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('uploads MP4 using the unsigned video endpoint and returns secure URL', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url.path,
        '/v1_1/${CloudinaryService.cloudName}/video/upload',
      );
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('upload_preset'));
      expect(body, contains(CloudinaryService.uploadPreset));
      expect(body, contains('folder'));
      expect(body, contains(CloudinaryService.folder));
      return http.Response(
        jsonEncode({
          'secure_url':
              'https://res.cloudinary.com/${CloudinaryService.cloudName}/video/upload/clip.mp4',
        }),
        200,
      );
    });
    final file = await _testFile();
    final service = CloudinaryService(client: client);
    final progress = <double>[];

    final url = await service.uploadVideo(
      file: file,
      duration: const Duration(seconds: 12),
      expectedSizeBytes: await file.length(),
      onProgress: progress.add,
    );
    client.close();

    expect(
      url,
      'https://res.cloudinary.com/${CloudinaryService.cloudName}/video/upload/clip.mp4',
    );
    expect(progress.first, 0);
    expect(progress.last, 1);
  });

  test(
    'does not return a URL when Cloudinary rejects a video upload',
    () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"error":{"message":"MP4 is not allowed"}}', 400),
      );
      final service = CloudinaryService(client: client);

      await expectLater(
        service.uploadVideo(
          file: await _testFile(),
          duration: const Duration(seconds: 5),
          expectedSizeBytes: 12,
        ),
        throwsA(
          isA<CloudinaryUploadException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.message, 'message', contains('MP4')),
        ),
      );
      client.close();
    },
  );

  test('rejects video posts without a secure URL or with image URLs', () {
    expect(
      () => PostVideoService.validatePostMedia(
        imageUrls: const [],
        mediaType: PostMediaType.video,
        videoUrl: null,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PostVideoService.validatePostMedia(
        imageUrls: const ['https://example.test/image.jpg'],
        mediaType: PostMediaType.video,
        videoUrl: 'https://res.cloudinary.com/mr5ddhj5/video/upload/clip.mp4',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<XFile> _testFile({
  String name = 'clip.mp4',
  int sizeBytes = 12,
  bool validHeader = true,
}) async {
  const mp4Header = [
    0,
    0,
    0,
    12,
    0x66,
    0x74,
    0x79,
    0x70,
    0x6d,
    0x70,
    0x34,
    0x32,
  ];
  final directory = await Directory.systemTemp.createTemp('taskmate-video-');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}\\$name');
  await file.writeAsBytes(validHeader ? mp4Header : List<int>.filled(12, 0));
  if (sizeBytes > mp4Header.length) {
    final handle = await file.open(mode: FileMode.append);
    await handle.truncate(sizeBytes);
    await handle.close();
  }
  return XFile(file.path);
}
