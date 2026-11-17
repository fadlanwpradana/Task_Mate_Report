import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:task_mate_v4/features/community/services/cloudinary_service.dart';
import 'package:task_mate_v4/features/community/services/post_image_service.dart';

void main() {
  group('Post image selection', () {
    test('accepts four photos and rejects a fifth', () {
      expect(() => PostImageService.ensureCapacity(0, 4), returnsNormally);
      expect(
        () => PostImageService.ensureCapacity(4, 1),
        throwsA(isA<FormatException>()),
      );
    });

    test('validates image bytes and compresses accepted images to JPEG', () {
      final source = img.encodePng(img.Image(width: 8, height: 8));
      final result = PostImageService().validateAndCompressBytes(
        source,
        name: 'study.png',
      );

      expect(result.name, 'study.png');
      expect(img.decodeJpg(result.bytes), isNotNull);
    });

    test('rejects empty or non-image files', () {
      final service = PostImageService();
      expect(
        () => service.validateAndCompressBytes(const <int>[]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.validateAndCompressBytes([1, 2, 3, 4]),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('uploads to configured Cloudinary folder and returns secure URLs', () async {
    var uploadCount = 0;
    final requestBodies = <String>[];
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.host, 'api.cloudinary.com');
      expect(
        request.url.path,
        '/v1_1/${CloudinaryService.cloudName}/image/upload',
      );
      requestBodies.add(latin1.decode(request.bodyBytes));
      uploadCount++;
      return http.Response(
        jsonEncode({
          'secure_url':
              'https://res.cloudinary.com/${CloudinaryService.cloudName}/image/upload/photo-$uploadCount.jpg',
        }),
        200,
      );
    });
    final progress = <double>[];
    final service = CloudinaryService(client: client);

    final urls = await service.uploadImages(
      images: [_image('first.jpg'), _image('second.jpg')],
      onProgress: progress.add,
    );
    client.close();

    expect(urls, [
      'https://res.cloudinary.com/${CloudinaryService.cloudName}/image/upload/photo-1.jpg',
      'https://res.cloudinary.com/${CloudinaryService.cloudName}/image/upload/photo-2.jpg',
    ]);
    expect(progress, [0.5, 1.0]);
    expect(requestBodies, hasLength(2));
    for (final body in requestBodies) {
      expect(body, contains('upload_preset'));
      expect(body, contains(CloudinaryService.uploadPreset));
      expect(body, contains('folder'));
      expect(body, contains(CloudinaryService.folder));
    }
  });

  test('fails explicitly when Cloudinary rejects the upload', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"error":{"message":"Upload preset is not configured"}}',
        400,
      ),
    );
    final service = CloudinaryService(client: client);

    await expectLater(
      service.uploadImages(images: [_image('photo.jpg')]),
      throwsA(
        isA<CloudinaryUploadException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having(
              (error) => error.message,
              'message',
              contains('Upload preset is not configured'),
            ),
      ),
    );
    client.close();
  });

  test('rejects more than four images before making a request', () async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response('{}', 200);
    });
    final service = CloudinaryService(client: client);

    await expectLater(
      service.uploadImages(images: List.filled(5, _image('photo.jpg'))),
      throwsA(isA<FormatException>()),
    );
    client.close();

    expect(requestCount, 0);
  });
}

SelectedPostImage _image(String name) => SelectedPostImage(
  name: name,
  bytes: Uint8List.fromList([1, 2, 3]),
);
