import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/models/post_model.dart';

void main() {
  group('PostModel image compatibility', () {
    test('old JSON without imageUrls defaults to an empty list', () {
      final post = PostModel.fromJson({
        'id': 'post-1',
        'authorName': 'Ari',
        'type': 'discussion',
        'title': 'Study notes',
        'body': 'Notes from today',
        'createdAt': DateTime.utc(2026).toIso8601String(),
      });

      expect(post.imageUrls, isEmpty);
      expect(post.totalComments, 0);
    });

    test('round-trips image URLs and the stored comment count', () {
      final post = PostModel(
        id: 'post-2',
        authorName: 'Ari',
        type: PostType.question,
        title: 'Question',
        body: 'Details',
        imageUrls: const ['https://example.test/a.jpg'],
        commentCount: 3,
        createdAt: DateTime.utc(2026),
      );

      final restored = PostModel.fromJson(post.toJson());

      expect(restored.id, post.id);
      expect(restored.imageUrls, post.imageUrls);
      expect(restored.totalComments, 3);
    });

    test(
      'infers image media type for posts created before the media field',
      () {
        final post = PostModel.fromJson({
          'id': 'legacy-image',
          'authorName': 'Ari',
          'type': 'discussion',
          'title': 'Photo',
          'body': 'A legacy photo post',
          'imageUrls': ['https://example.test/a.jpg'],
          'createdAt': DateTime.utc(2026).toIso8601String(),
        });

        expect(post.resolvedMediaType, PostMediaType.image);
      },
    );

    test('round-trips video media fields', () {
      final post = PostModel(
        id: 'video-post',
        authorName: 'Ari',
        type: PostType.discussion,
        title: 'Video',
        body: 'A short video',
        mediaType: PostMediaType.video,
        videoUrl: 'https://res.cloudinary.com/demo/video/upload/clip.mp4',
        createdAt: DateTime.utc(2026),
      );

      final restored = PostModel.fromJson(post.toJson());

      expect(restored.resolvedMediaType, PostMediaType.video);
      expect(restored.videoUrl, post.videoUrl);
      expect(restored.imageUrls, isEmpty);
    });
  });
}
