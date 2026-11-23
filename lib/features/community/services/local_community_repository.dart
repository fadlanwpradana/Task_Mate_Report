import 'package:flutter/foundation.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/comment_model.dart';
import '../../../models/community_model.dart';
import '../../../models/post_model.dart';
import 'community_repository.dart';
import 'post_video_service.dart';

/// Offline demo community stored on the device, with sample posts written
/// by the demo chat users.
class LocalCommunityRepository extends CommunityRepository {
  LocalCommunityRepository(this._storage, {this.database}) {
    final savedCommunities = _storage.readList(_communitiesKey);
    final savedPosts = _storage.readList(_postsKey);
    final savedViews = _storage.readList(_viewedPostsKey);
    _viewedPostAt = {
      for (final item in savedViews ?? const [])
        if (item['id'] is String)
          item['id'] as String: _readViewTime(item['viewedAt']),
    };
    _communities = savedCommunities == null
        ? _sampleCommunities()
        : savedCommunities.map(CommunityModel.fromJson).toList();
    _posts = savedPosts == null
        ? _samplePosts()
        : savedPosts.map(PostModel.fromJson).toList();
    _postsReady = database == null ? Future<void>.value() : _restorePosts();
  }

  static const _communitiesKey = 'communities';
  static const _postsKey = 'posts';
  static const _viewedPostsKey = 'community_viewed_posts';

  /// Author id of posts written on this device (matches the demo chat).
  static const meId = 'me';

  final StorageService _storage;
  final DatabaseHelper? database;
  late final Future<void> _postsReady;
  late List<CommunityModel> _communities;
  late List<PostModel> _posts;
  late Map<String, DateTime> _viewedPostAt;
  var _postsMutated = false;

  @override
  List<PostModel> get allPosts => [..._posts];

  @override
  List<CommunityModel> get communities => [..._communities];

  @override
  int postCount(String communityId) =>
      _posts.where((p) => p.communityId == communityId).length;

  @override
  String newPostId() => generateId();

  @override
  Future<void> addPost(PostModel post, {String? postId}) async {
    await _postsReady;
    PostVideoService.validatePostMedia(
      imageUrls: post.imageUrls,
      mediaType: post.resolvedMediaType,
      videoUrl: post.videoUrl,
    );
    _posts.add(
      PostModel(
        id: postId ?? post.id,
        authorId: post.authorId ?? meId,
        authorName: post.authorName,
        authorSubtitle: post.authorSubtitle,
        communityId: post.communityId,
        type: post.type,
        title: post.title,
        body: post.body,
        tags: post.tags,
        imageUrls: post.imageUrls,
        mediaType: post.resolvedMediaType,
        videoUrl: post.videoUrl,
        createdAt: post.createdAt,
      ),
    );
    await _save();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _postsReady;
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index == -1) throw StateError('Post no longer exists.');
    if (_posts[index].authorId != meId) {
      throw StateError('You can only delete your own posts.');
    }
    _posts.removeAt(index);
    _viewedPostAt.remove(postId);
    await _save();
  }

  @override
  Future<void> toggleLike(String postId) async {
    await _postsReady;
    _updatePost(
      postId,
      (p) => p.copyWith(
        likedByMe: !p.likedByMe,
        likeCount: p.likeCount + (p.likedByMe ? -1 : 1),
      ),
    );
    await _save();
  }

  @override
  Future<void> recordView(String postId) async {
    await _postsReady;
    final now = DateTime.now();
    final previousView = _viewedPostAt[postId];
    if ((previousView != null &&
            now.difference(previousView) < const Duration(hours: 24)) ||
        !_posts.any((post) => post.id == postId)) {
      return;
    }
    _viewedPostAt[postId] = now;
    _updatePost(postId, (post) => post.copyWith(viewCount: post.viewCount + 1));
    await _save();
  }

  @override
  Future<void> toggleBookmark(String postId) async {
    await _postsReady;
    _updatePost(postId, (p) => p.copyWith(bookmarked: !p.bookmarked));
    await _save();
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    await _postsReady;
    _updatePost(postId, (p) => p.copyWith(comments: [...p.comments, comment]));
    await _save();
  }

  @override
  Future<void> toggleCommentLike(String postId, String commentId) async {
    await _postsReady;
    _updatePost(
      postId,
      (p) => p.copyWith(
        comments: [
          for (final c in p.comments) c.id == commentId ? c.toggleLike() : c,
        ],
      ),
    );
    await _save();
  }

  @override
  Future<void> addCommunity(CommunityModel community) async {
    await _postsReady;
    _communities.add(community);
    await _save();
  }

  @override
  Future<void> toggleJoin(String communityId) async {
    await _postsReady;
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index == -1) return;
    _communities[index] = _communities[index].toggleJoin();
    await _save();
  }

  void _updatePost(String id, PostModel Function(PostModel) change) {
    final index = _posts.indexWhere((p) => p.id == id);
    if (index != -1) _posts[index] = change(_posts[index]);
  }

  Future<void> _save() async {
    _postsMutated = true;
    notifyListeners();
    await _storage.writeList(
      _communitiesKey,
      _communities.map((c) => c.toJson()).toList(),
    );
    final postDatabase = database;
    if (postDatabase == null) {
      await _storage.writeList(
        _postsKey,
        _posts.map((post) => post.toJson()).toList(),
      );
    } else {
      await postDatabase.replaceCachedPosts(meId, _posts);
    }
    await _storage.writeList(
      _viewedPostsKey,
      _viewedPostAt.entries
          .map(
            (entry) => {
              'id': entry.key,
              'viewedAt': entry.value.toIso8601String(),
            },
          )
          .toList(),
    );
  }

  Future<void> _restorePosts() async {
    try {
      final postDatabase = database!;
      final cached = await postDatabase.readCachedPosts(meId);
      if (_postsMutated) return;
      if (cached.isNotEmpty) {
        _posts = cached;
      } else {
        await postDatabase.replaceCachedPosts(meId, _posts);
      }
      await _storage.remove(_postsKey);
      if (!_postsMutated) notifyListeners();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'community',
          context: ErrorDescription('while restoring local community posts'),
        ),
      );
    }
  }

  static DateTime _readViewTime(Object? value) {
    // Old demo records only stored the post id. Treat them as recent so an
    // upgrade cannot immediately manufacture another view.
    if (value is! String) return DateTime.now();
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static final _seedTime = DateTime.now();

  static List<CommunityModel> _sampleCommunities() {
    CommunityModel community(
      String id,
      String name,
      String topic,
      CommunityCategory category,
      int members,
      int color, {
      bool joined = false,
    }) {
      return CommunityModel(
        id: id,
        name: name,
        description: 'A place to discuss $topic with fellow students.',
        topic: topic,
        category: category,
        memberCount: members,
        joined: joined,
        colorValue: color,
        createdAt: _seedTime,
      );
    }

    return [
      community(
        'flutter',
        'Flutter Study Group',
        'Flutter',
        CommunityCategory.course,
        1200,
        0xFF6FA8DC,
        joined: true,
      ),
      community(
        'database',
        'Database Systems',
        'Database Systems',
        CommunityCategory.course,
        856,
        0xFF253858,
      ),
      community(
        'uiux',
        'UI/UX Design',
        'UI/UX',
        CommunityCategory.general,
        642,
        0xFFE6B85C,
      ),
      community(
        'math',
        'Basic Mathematics',
        'Mathematics',
        CommunityCategory.course,
        523,
        0xFF89BC9A,
      ),
      community(
        'informatics',
        'Informatics 2024',
        'Informatics',
        CommunityCategory.major,
        1100,
        0xFFE98989,
      ),
    ];
  }

  static List<PostModel> _samplePosts() {
    DateTime ago(Duration d) => _seedTime.subtract(d);
    return [
      PostModel(
        id: 'post-firebase-auth',
        authorId: 'sari',
        authorName: 'Sari Dewi',
        authorSubtitle: 'Flutter',
        communityId: 'flutter',
        type: PostType.question,
        title: 'How do I use Firebase Authentication in Flutter?',
        body:
            'I’m still confused about the integration part 🙏 '
            'Which packages do I need and where do I initialize Firebase?',
        tags: ['Flutter', 'Firebase', 'Programming'],
        likeCount: 12,
        createdAt: ago(const Duration(minutes: 10)),
        comments: [
          CommentModel(
            id: 'c1',
            authorId: 'andi',
            authorName: 'Andi Saputra',
            body:
                'Start by adding the firebase_core and firebase_auth '
                'packages to pubspec.yaml, then initialize Firebase in main.dart.',
            likeCount: 2,
            createdAt: ago(const Duration(minutes: 5)),
          ),
          CommentModel(
            id: 'c2',
            authorId: 'sari',
            authorName: 'Sari Dewi',
            body: 'Thanks! Could you share an example?',
            likeCount: 2,
            createdAt: ago(const Duration(minutes: 2)),
          ),
        ],
      ),
      PostModel(
        id: 'post-normalization',
        authorId: 'budi',
        authorName: 'Budi Santoso',
        authorSubtitle: 'Database',
        communityId: 'database',
        type: PostType.discussion,
        title: 'Database normalization summary (1NF, 2NF, 3NF, BCNF)',
        body:
            'Here is my summary of the normalization steps from this '
            'week’s lecture. Feel free to add anything I missed!',
        tags: ['Database', 'Normalization'],
        likeCount: 8,
        createdAt: ago(const Duration(minutes: 30)),
      ),
      PostModel(
        id: 'post-erd',
        authorId: 'raka',
        authorName: 'Raka Pratama',
        authorSubtitle: 'Informatics',
        communityId: 'informatics',
        type: PostType.assignment,
        title: 'ERD assignment: is a weak entity needed here?',
        body:
            'For the library case study, should "Loan Item" be a weak '
            'entity or a regular one with its own key?',
        tags: ['Database', 'ERD'],
        likeCount: 5,
        createdAt: ago(const Duration(hours: 2)),
      ),
      PostModel(
        id: 'post-figma',
        authorId: 'rina',
        authorName: 'Rina Oktavia',
        authorSubtitle: 'UI/UX',
        communityId: 'uiux',
        type: PostType.discussion,
        title: 'Favorite Figma plugins for student projects?',
        body: 'Share the plugins that save you the most time!',
        tags: ['UI/UX', 'Figma'],
        likeCount: 3,
        createdAt: ago(const Duration(hours: 5)),
      ),
    ];
  }
}
