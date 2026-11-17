import 'dart:convert';

import 'package:http/http.dart' as http;

import 'post_image_service.dart';

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

      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
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
        throw const FormatException(
          'Cloudinary did not return a valid secure image URL.',
        );
      }
      final secureUri = Uri.tryParse(secureUrl);
      if (secureUri == null ||
          secureUri.scheme != 'https' ||
          secureUri.host.isEmpty) {
        throw const FormatException(
          'Cloudinary did not return a valid secure image URL.',
        );
      }
      urls.add(secureUrl);
      onProgress?.call((index + 1) / images.length);
    }

    return urls;
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Cloudinary upload failed ($statusCode): $message';
}
