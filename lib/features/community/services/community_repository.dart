import 'package:flutter/foundation.dart';

import '../../../models/comment_model.dart';
import '../../../models/community_model.dart';
import '../../../models/post_model.dart';

/// Communities, posts, and comments for online and offline repositories.
abstract class CommunityRepository extends ChangeNotifier {
  List<PostModel> get allPosts;
  List<CommunityModel> get communities;

  int postCount(String communityId);

  String newPostId();
  Future<void> addPost(PostModel post, {String? postId});
  Future<void> deletePost(String postId);
  Future<void> toggleLike(String postId);
  Future<void> recordView(String postId);
  Future<void> toggleBookmark(String postId);
  Future<void> addComment(String postId, CommentModel comment);
  Future<void> toggleCommentLike(String postId, String commentId);
  Future<void> addCommunity(CommunityModel community);
  Future<void> toggleJoin(String communityId);

  void openPost(String postId) {}
  void closePost(String postId) {}

  List<PostModel> get posts =>
      [...allPosts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<PostModel> get trendingPosts => [...allPosts]
    ..sort(
      (a, b) => (b.likeCount + b.totalComments * 2).compareTo(
        a.likeCount + a.totalComments * 2,
      ),
    );

  List<PostModel> get followingPosts {
    final joinedIds = {
      for (final community in communities)
        if (community.joined) community.id,
    };
    return posts.where((post) => joinedIds.contains(post.communityId)).toList();
  }

  List<PostModel> postsIn(String communityId) =>
      posts.where((post) => post.communityId == communityId).toList();

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
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    return posts.where((post) {
      final community = communityById(post.communityId)?.name ?? '';
      return [
        post.title,
        post.body,
        post.authorName,
        community,
        ...post.tags,
      ].any((text) => text.toLowerCase().contains(normalized));
    }).toList();
  }

  List<CommunityModel> searchCommunities(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    return communities
        .where(
          (community) => [
            community.name,
            community.description,
            community.topic,
          ].any((text) => text.toLowerCase().contains(normalized)),
        )
        .toList();
  }
}
