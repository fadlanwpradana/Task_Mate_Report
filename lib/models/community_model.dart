enum CommunityCategory { course, major, general }

class CommunityModel {
  const CommunityModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description = '',
    this.topic = '',
    this.category = CommunityCategory.general,
    this.isPrivate = false,
    this.memberCount = 1,
    this.joined = false,
    this.colorValue = 0xFF6FA8DC,
    this.postCount,
  });

  final String id;
  final String name;
  final String description;
  final String topic;
  final CommunityCategory category;
  final bool isPrivate;
  final int memberCount;
  final bool joined;
  final int colorValue;
  final DateTime createdAt;

  /// Stored post count for online communities; null when posts are counted
  /// locally.
  final int? postCount;

  CommunityModel toggleJoin() => CommunityModel(
    id: id,
    name: name,
    description: description,
    topic: topic,
    category: category,
    isPrivate: isPrivate,
    memberCount: memberCount + (joined ? -1 : 1),
    joined: !joined,
    colorValue: colorValue,
    createdAt: createdAt,
    postCount: postCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'topic': topic,
    'category': category.name,
    'isPrivate': isPrivate,
    'memberCount': memberCount,
    'joined': joined,
    'colorValue': colorValue,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      category: CommunityCategory.values.byName(json['category'] as String),
      isPrivate: json['isPrivate'] as bool? ?? false,
      memberCount: json['memberCount'] as int? ?? 1,
      joined: json['joined'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFF6FA8DC,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
