class CommentModel {
  const CommentModel({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorId,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String? authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  CommentModel toggleLike() => CommentModel(
    id: id,
    authorId: authorId,
    authorName: authorName,
    body: body,
    createdAt: createdAt,
    likeCount: likeCount + (likedByMe ? -1 : 1),
    likedByMe: !likedByMe,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'likeCount': likeCount,
    'likedByMe': likedByMe,
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
    );
  }
}
