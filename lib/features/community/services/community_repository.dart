import 'package:flutter/foundation.dart';

import '../../../models/comment_model.dart';
import '../../../models/community_model.dart';
import '../../../models/post_model.dart';

/// Communities, posts, and comments. Implemented by
/// [FirestoreCommunityRepository] for real accounts and
/// [LocalCommunityRepository] for the offline demo; screens only use this API.
abstract class CommunityRepository extends ChangeNotifier {
  /// Every loaded post, in no particular order.
  List<PostModel> get allPosts;

  /// Every community.
  List<CommunityModel> get communities;

  /// Number of posts in a community.
  int postCount(String communityId);

  /// Publishes [post]; the author fields are filled in for the signed-in
  /// user where needed.
  Future<void> addPost(PostModel post);

  Future<void> toggleLike(String postId);

  Future<void> toggleBookmark(String postId);

  Future<void> addComment(String postId, CommentModel comment);

  Future<void> toggleCommentLike(String postId, String commentId);

  /// Creates [community] with the signed-in user as its first member.
  Future<void> addCommunity(CommunityModel community);

  Future<void> toggleJoin(String communityId);

  /// Start / stop loading the comments of a post on screen.
  void openPost(String postId) {}
  void closePost(String postId) {}

  /// Newest posts first.
  List<PostModel> get posts =>
      [...allPosts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Most liked and discussed posts first.
  List<PostModel> get trendingPosts => [...allPosts]
    ..sort(
      (a, b) => (b.likeCount + b.totalComments * 2).compareTo(
        a.likeCount + a.totalComments * 2,
      ),
    );

  /// Posts from communities the user has joined.
  List<PostModel> get followingPosts {
    final joinedIds = {
      for (final c in communities)
        if (c.joined) c.id,
    };
    return posts.where((p) => joinedIds.contains(p.communityId)).toList();
  }

  List<PostModel> postsIn(String communityId) =>
      posts.where((p) => p.communityId == communityId).toList();

  CommunityModel? communityById(String? id) {
    if (id == null) return null;
    for (final community in communities) {
      if (community.id == id) return community;
    }
    return null;
  }

  PostModel? postById(String id) {
    for (final post in allPosts) {
      if (post.id == id) return post;
    }
    return null;
  }

  List<PostModel> searchPosts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return posts.where((p) {
      final community = communityById(p.communityId)?.name ?? '';
      return [
        p.title,
        p.body,
        p.authorName,
        community,
        ...p.tags,
      ].any((text) => text.toLowerCase().contains(q));
    }).toList();
  }

  List<CommunityModel> searchCommunities(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return communities
        .where(
          (c) => [
            c.name,
            c.description,
            c.topic,
          ].any((text) => text.toLowerCase().contains(q)),
        )
        .toList();
  }
}
