import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'post_image_service.dart';
import 'post_video_service.dart';

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? _sharedClient;

  static const cloudName = 'mr5ddhj5';
  static const uploadPreset = 'taskmate_upload';
  static const folder = 'taskmate';
  static final http.Client _sharedClient = http.Client();

  final http.Client _client;

  Future<List<String>> uploadImages({
    required List<SelectedPostImage> images,
    void Function(double progress)? onProgress,
  }) async {
    PostImageService.ensureCapacity(0, images.length);
    final urls = <String>[];
    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );

    for (var index = 0; index < images.length; index++) {
      final request = http.MultipartRequest('POST', endpoint)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            images[index].bytes,
            filename: 'image-${index + 1}.jpg',
          ),
        );
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = response.body.isEmpty
            ? response.reasonPhrase ?? 'No error details were returned.'
            : response.body;
        throw CloudinaryUploadException(response.statusCode, message);
      }

      urls.add(_secureUrlFromResponse(response.body, mediaName: 'image'));
      onProgress?.call((index + 1) / images.length);
    }

    return urls;
  }

  Future<String> uploadVideo({
    required XFile file,
    required Duration duration,
    required int expectedSizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    final sizeBytes = await PostVideoService.validateFile(
      file,
      duration: duration,
    );
    if (sizeBytes != expectedSizeBytes) {
      throw const FormatException('The selected video file changed.');
    }

    var sentBytes = 0;
    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/video/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile(
          'file',
          file.openRead().map((chunk) {
            sentBytes += chunk.length;
            onProgress?.call(sentBytes / sizeBytes);
            return chunk;
          }),
          sizeBytes,
          filename: file.name,
        ),
      );
    onProgress?.call(0);
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isEmpty
          ? response.reasonPhrase ?? 'No error details were returned.'
          : response.body;
      throw CloudinaryUploadException(response.statusCode, message);
    }

    onProgress?.call(1);
    return _secureUrlFromResponse(response.body, mediaName: 'video');
  }

  String _secureUrlFromResponse(String body, {required String mediaName}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw FormatException(
        'Cloudinary returned invalid JSON: ${error.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Cloudinary returned an invalid upload response.',
      );
    }
    final secureUrl = decoded['secure_url'];
    if (secureUrl is! String) {
      throw FormatException(
        'Cloudinary did not return a valid secure $mediaName URL.',
      );
    }
    final secureUri = Uri.tryParse(secureUrl);
    if (secureUri == null ||
        secureUri.scheme != 'https' ||
        secureUri.host.isEmpty) {
      throw FormatException(
        'Cloudinary did not return a valid secure $mediaName URL.',
      );
    }
    return secureUrl;
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Cloudinary upload failed ($statusCode): $message';
}
