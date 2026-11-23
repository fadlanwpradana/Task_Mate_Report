import 'comment_model.dart';

enum PostType { discussion, question, assignment }

enum PostMediaType { image, video }

class PostModel {
  const PostModel({
    required this.id,
    required this.authorName,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.authorId,
    this.authorSubtitle = '',
    this.communityId,
    this.tags = const [],
    this.imageUrls = const [],
    this.mediaType,
    this.videoUrl,
    this.likeCount = 0,
    this.viewCount = 0,
    this.likedByMe = false,
    this.bookmarked = false,
    this.comments = const [],
    this.commentCount,
  });

  final String id;

  /// Account that wrote the post; used to start a chat with them.
  final String? authorId;
  final String authorName;
  final String authorSubtitle;
  final String? communityId;
  final PostType type;
  final String title;
  final String body;
  final List<String> tags;
  final List<String> imageUrls;
  final PostMediaType? mediaType;
  final String? videoUrl;
  final int likeCount;
  final int viewCount;
  final bool likedByMe;
  final bool bookmarked;

  /// Loaded comments, oldest first. Online posts only load these while the
  /// post is open; use [totalComments] for counts.
  final List<CommentModel> comments;

  /// Stored comment count, when [comments] isn't fully loaded.
  final int? commentCount;
  final DateTime createdAt;

  int get totalComments => commentCount ?? comments.length;

  PostMediaType? get resolvedMediaType {
    if (mediaType != null) return mediaType;
    if (videoUrl?.isNotEmpty == true) return PostMediaType.video;
    if (imageUrls.isNotEmpty) return PostMediaType.image;
    return null;
  }

  PostModel copyWith({
    int? likeCount,
    int? viewCount,
    bool? likedByMe,
    bool? bookmarked,
    List<CommentModel>? comments,
    int? commentCount,
    String? title,
    String? body,
    List<String>? tags,
    List<String>? imageUrls,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorSubtitle: authorSubtitle,
      communityId: communityId,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      mediaType: mediaType,
      videoUrl: videoUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      bookmarked: bookmarked ?? this.bookmarked,
      comments: comments ?? this.comments,
      commentCount:
          commentCount ??
          (comments == null ? this.commentCount : comments.length),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorSubtitle': authorSubtitle,
    'communityId': communityId,
    'type': type.name,
    'title': title,
    'body': body,
    'tags': tags,
    'imageUrls': imageUrls,
    if (resolvedMediaType != null) 'mediaType': resolvedMediaType!.name,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'likeCount': likeCount,
    'viewCount': viewCount,
    'likedByMe': likedByMe,
    'bookmarked': bookmarked,
    'comments': comments.map((c) => c.toJson()).toList(),
    'commentCount': totalComments,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = (json['imageUrls'] as List<dynamic>? ?? [])
        .cast<String>();
    final videoUrl = json['videoUrl'] as String?;
    return PostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String,
      authorSubtitle: json['authorSubtitle'] as String? ?? '',
      communityId: json['communityId'] as String?,
      type: PostType.values.byName(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      imageUrls: imageUrls,
      mediaType: readMediaType(
        json['mediaType'],
        imageUrls: imageUrls,
        videoUrl: videoUrl,
      ),
      videoUrl: videoUrl,
      likeCount: json['likeCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      bookmarked: json['bookmarked'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      commentCount: json['commentCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static PostMediaType? readMediaType(
    Object? value, {
    required List<String> imageUrls,
    required String? videoUrl,
  }) {
    if (value == PostMediaType.image.name) return PostMediaType.image;
    if (value == PostMediaType.video.name) return PostMediaType.video;
    if (videoUrl?.isNotEmpty == true) return PostMediaType.video;
    if (imageUrls.isNotEmpty) return PostMediaType.image;
    return null;
  }
}
