import '../../../core/services/storage_service.dart';
import '../../../models/comment_model.dart';
import '../../../models/community_model.dart';
import '../../../models/post_model.dart';
import 'community_repository.dart';

/// Offline demo community stored on the device, with sample posts written
/// by the demo chat users.
class LocalCommunityRepository extends CommunityRepository {
  LocalCommunityRepository(this._storage) {
    final savedCommunities = _storage.readList(_communitiesKey);
    final savedPosts = _storage.readList(_postsKey);
    if (savedCommunities == null || savedPosts == null) {
      _communities = _sampleCommunities();
      _posts = _samplePosts();
    } else {
      _communities = savedCommunities.map(CommunityModel.fromJson).toList();
      _posts = savedPosts.map(PostModel.fromJson).toList();
    }
  }

  static const _communitiesKey = 'communities';
  static const _postsKey = 'posts';

  /// Author id of posts written on this device (matches the demo chat).
  static const meId = 'me';

  final StorageService _storage;
  late List<CommunityModel> _communities;
  late List<PostModel> _posts;

  @override
  List<PostModel> get allPosts => [..._posts];

  @override
  List<CommunityModel> get communities => [..._communities];

  @override
  int postCount(String communityId) =>
      _posts.where((p) => p.communityId == communityId).length;

  @override
  Future<void> addPost(PostModel post) async {
    _posts.add(
      PostModel(
        id: post.id,
        authorId: post.authorId ?? meId,
        authorName: post.authorName,
        authorSubtitle: post.authorSubtitle,
        communityId: post.communityId,
        type: post.type,
        title: post.title,
        body: post.body,
        tags: post.tags,
        createdAt: post.createdAt,
      ),
    );
    await _save();
  }

  @override
  Future<void> toggleLike(String postId) async {
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
  Future<void> toggleBookmark(String postId) async {
    _updatePost(postId, (p) => p.copyWith(bookmarked: !p.bookmarked));
    await _save();
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    _updatePost(postId, (p) => p.copyWith(comments: [...p.comments, comment]));
    await _save();
  }

  @override
  Future<void> toggleCommentLike(String postId, String commentId) async {
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
    _communities.add(community);
    await _save();
  }

  @override
  Future<void> toggleJoin(String communityId) async {
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
    notifyListeners();
    await _storage.writeList(
      _communitiesKey,
      _communities.map((c) => c.toJson()).toList(),
    );
    await _storage.writeList(_postsKey, _posts.map((p) => p.toJson()).toList());
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
