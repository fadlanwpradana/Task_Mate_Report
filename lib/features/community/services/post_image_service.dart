import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class SelectedPostImage {
  const SelectedPostImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class PostImageService {
  PostImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const maxImages = 4;
  static const maxFileSizeBytes = 20 * 1024 * 1024;
  static const maxDimension = 2048;

  final ImagePicker _picker;

  Future<List<SelectedPostImage>> pickFromGallery({
    int currentCount = 0,
  }) async {
    final files = await _picker.pickMultiImage();
    ensureCapacity(currentCount, files.length);
    return Future.wait(files.map(_readAndCompress));
  }

  Future<SelectedPostImage?> captureFromCamera({int currentCount = 0}) async {
    ensureCapacity(currentCount, 1);
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return _readAndCompress(file);
  }

  Future<SelectedPostImage> _readAndCompress(XFile file) async {
    return validateAndCompressBytes(await file.readAsBytes(), name: file.name);
  }

  SelectedPostImage validateAndCompressBytes(
    List<int> bytes, {
    String name = 'photo.jpg',
  }) {
    if (bytes.isEmpty || bytes.length > maxFileSizeBytes) {
      throw const FormatException('Choose an image smaller than 20 MB.');
    }
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const FormatException(
        'The selected file is not a supported image.',
      );
    }
    final oriented = img.bakeOrientation(decoded);
    final longestSide = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final compressed = longestSide > maxDimension
        ? img.copyResize(
            oriented,
            width: (oriented.width * maxDimension / longestSide).round(),
            height: (oriented.height * maxDimension / longestSide).round(),
          )
        : oriented;
    return SelectedPostImage(
      name: name,
      bytes: Uint8List.fromList(img.encodeJpg(compressed, quality: 82)),
    );
  }

  static void ensureCapacity(int currentCount, int additions) {
    if (currentCount < 0 ||
        additions < 0 ||
        currentCount + additions > maxImages) {
      throw const FormatException('A post can contain at most 4 photos.');
    }
  }
}
