import 'comment_model.dart';

enum PostType { discussion, question, assignment }

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
    this.likeCount = 0,
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
  final int likeCount;
  final bool likedByMe;
  final bool bookmarked;

  /// Loaded comments, oldest first. Online posts only load these while the
  /// post is open; use [totalComments] for counts.
  final List<CommentModel> comments;

  /// Stored comment count, when [comments] isn't fully loaded.
  final int? commentCount;
  final DateTime createdAt;

  int get totalComments => commentCount ?? comments.length;

  PostModel copyWith({
    int? likeCount,
    bool? likedByMe,
    bool? bookmarked,
    List<CommentModel>? comments,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorSubtitle: authorSubtitle,
      communityId: communityId,
      type: type,
      title: title,
      body: body,
      tags: tags,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      bookmarked: bookmarked ?? this.bookmarked,
      comments: comments ?? this.comments,
      commentCount: commentCount,
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
    'likeCount': likeCount,
    'likedByMe': likedByMe,
    'bookmarked': bookmarked,
    'comments': comments.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory PostModel.fromJson(Map<String, dynamic> json) {
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
      likeCount: json['likeCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      bookmarked: json['bookmarked'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
