import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/comment_model.dart';
import '../../../models/community_model.dart';
import '../../../models/post_model.dart';
import 'community_repository.dart';

typedef _Sub = StreamSubscription<QuerySnapshot<Map<String, dynamic>>>;

/// Shared community data in Firestore (see firestore.rules):
///
/// * `communities/{id}`: details, memberCount, postCount;
///   `communities/{id}/members/{uid}` marks membership.
/// * `posts/{id}`: post fields, `visibility` ("public", or "private" for
///   posts in private communities, readable by members only), `likedBy`,
///   likeCount, viewCount, commentCount. Comments and unique viewer records
///   live in `posts/{id}/comments` and `posts/{id}/views/{uid}`.
/// * `users/{uid}/joined/{communityId}` and `users/{uid}/bookmarks/{postId}`:
///   the user's own memberships and saved posts.
class FirestoreCommunityRepository extends CommunityRepository {
  FirestoreCommunityRepository({this._firestore});

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static const _feedLimit = 100;
  static const _privateFeedLimit = 50;

  String? _uid;
  final _subs = <_Sub>[];
  final _privateFeedSubs = <String, _Sub>{};
  final _commentSubs = <String, _Sub>{};

  final _communities = <String, Map<String, dynamic>>{};
  final _publicPosts = <String, Map<String, dynamic>>{};
  final _privatePosts = <String, Map<String, Map<String, dynamic>>>{};
  final _comments = <String, List<CommentModel>>{};
  var _joined = <String>{};
  var _bookmarks = <String>{};

  /// Starts listening as [uid].
  void signIn(String uid) {
    if (_uid == uid) return;
    signOut();
    _uid = uid;
    _listen(_db.collection('communities').limit(500), (snapshot) {
      _replace(_communities, snapshot);
      _syncPrivateFeeds();
    });
    _listen(_db.collection('users').doc(uid).collection('joined'), (snapshot) {
      _joined = {for (final d in snapshot.docs) d.id};
      _syncPrivateFeeds();
    });
    _listen(
      _db.collection('users').doc(uid).collection('bookmarks'),
      (snapshot) => _bookmarks = {for (final d in snapshot.docs) d.id},
    );
    _listen(
      _db
          .collection('posts')
          .where('visibility', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .limit(_feedLimit),
      (snapshot) => _replace(_publicPosts, snapshot),
    );
  }

  /// Stops all listeners and forgets the previous user's data.
  void signOut() {
    for (final sub in [
      ..._subs,
      ..._privateFeedSubs.values,
      ..._commentSubs.values,
    ]) {
      sub.cancel();
    }
    _subs.clear();
    _privateFeedSubs.clear();
    _commentSubs.clear();
    _communities.clear();
    _publicPosts.clear();
    _privatePosts.clear();
    _comments.clear();
    _joined = {};
    _bookmarks = {};
    _uid = null;
    notifyListeners();
  }

  @override
  void dispose() {
    signOut();
    super.dispose();
  }

  void _listen(
    Query<Map<String, dynamic>> query,
    void Function(QuerySnapshot<Map<String, dynamic>>) onData,
  ) {
    _subs.add(
      query.snapshots().listen((snapshot) {
        onData(snapshot);
        notifyListeners();
      }, onError: (Object e) => debugPrint('Community data unavailable: $e')),
    );
  }

  static void _replace(
    Map<String, Map<String, dynamic>> target,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    target
      ..clear()
      ..addEntries(snapshot.docs.map((d) => MapEntry(d.id, d.data())));
  }

  /// Private communities' posts are only readable by members, so each joined
  /// private community gets its own feed listener.
  void _syncPrivateFeeds() {
    final wanted = {
      for (final id in _joined)
        if (_communities[id]?['isPrivate'] == true) id,
    };
    for (final id in _privateFeedSubs.keys.toList()) {
      if (!wanted.contains(id)) {
        _privateFeedSubs.remove(id)?.cancel();
        _privatePosts.remove(id);
      }
    }
    for (final id in wanted) {
      _privateFeedSubs[id] ??= _db
          .collection('posts')
          .where('communityId', isEqualTo: id)
          .orderBy('createdAt', descending: true)
          .limit(_privateFeedLimit)
          .snapshots()
          .listen((snapshot) {
            _privatePosts[id] = {for (final d in snapshot.docs) d.id: d.data()};
            notifyListeners();
          }, onError: (Object e) => debugPrint('Private feed unavailable: $e'));
    }
  }

  @override
  List<PostModel> get allPosts {
    final merged = <String, Map<String, dynamic>>{
      ..._publicPosts,
      for (final feed in _privatePosts.values) ...feed,
    };
    return [
      for (final entry in merged.entries) _toPost(entry.key, entry.value),
    ];
  }

  @override
  List<CommunityModel> get communities {
    final list = [
      for (final entry in _communities.entries)
        _toCommunity(entry.key, entry.value),
    ];
    return list..sort((a, b) => b.memberCount.compareTo(a.memberCount));
  }

  @override
  int postCount(String communityId) =>
      (_communities[communityId]?['postCount'] as num?)?.toInt() ?? 0;

  @override
  Future<void> addPost(PostModel post) async {
    final uid = _requireUid();
    final community = post.communityId == null
        ? null
        : _communities[post.communityId];
    final ref = _db.collection('posts').doc();
    final batch = _db.batch()
      ..set(ref, {
        'authorId': uid,
        'authorName': post.authorName,
        'authorSubtitle': post.authorSubtitle,
        'communityId': post.communityId,
        'visibility': community?['isPrivate'] == true ? 'private' : 'public',
        'type': post.type.name,
        'title': post.title,
        'body': post.body,
        'tags': post.tags,
        'likedBy': <String>[],
        'likeCount': 0,
        'viewCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    if (post.communityId case final communityId?) {
      batch.update(_db.collection('communities').doc(communityId), {
        'postCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> toggleLike(String postId) {
    final post = postById(postId);
    if (post == null) return Future.value();
    return _db
        .collection('posts')
        .doc(postId)
        .update(_likeChange(post.likedByMe));
  }

  @override
  Future<void> recordView(String postId) async {
    final uid = _requireUid();
    final postRef = _db.collection('posts').doc(postId);
    final viewRef = postRef.collection('views').doc(uid);
    await _db.runTransaction((transaction) async {
      final view = await transaction.get(viewRef);
      if (view.exists) return;
      final post = await transaction.get(postRef);
      if (!post.exists) return;
      final viewCount = (post.data()?['viewCount'] as num?)?.toInt() ?? 0;
      transaction
        ..set(viewRef, {'createdAt': FieldValue.serverTimestamp()})
        ..update(postRef, {'viewCount': viewCount + 1});
    });
  }

  @override
  Future<void> toggleBookmark(String postId) {
    final ref = _db
        .collection('users')
        .doc(_requireUid())
        .collection('bookmarks')
        .doc(postId);
    return _bookmarks.contains(postId)
        ? ref.delete()
        : ref.set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    final uid = _requireUid();
    final post = _db.collection('posts').doc(postId);
    await (_db.batch()
          ..set(post.collection('comments').doc(), {
            'authorId': uid,
            'authorName': comment.authorName,
            'body': comment.body,
            'likedBy': <String>[],
            'likeCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..update(post, {'commentCount': FieldValue.increment(1)}))
        .commit();
  }

  @override
  Future<void> toggleCommentLike(String postId, String commentId) {
    final comment = _comments[postId]?.where((c) => c.id == commentId);
    if (comment == null || comment.isEmpty) return Future.value();
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update(_likeChange(comment.first.likedByMe));
  }

  Map<String, dynamic> _likeChange(bool likedNow) {
    final uid = _requireUid();
    return {
      'likedBy': likedNow
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      'likeCount': FieldValue.increment(likedNow ? -1 : 1),
    };
  }

  @override
  Future<void> addCommunity(CommunityModel community) async {
    final uid = _requireUid();
    final ref = _db.collection('communities').doc(community.id);
    await (_db.batch()
          ..set(ref, {
            'name': community.name,
            'description': community.description,
            'topic': community.topic,
            'category': community.category.name,
            'isPrivate': community.isPrivate,
            'colorValue': community.colorValue,
            'creatorId': uid,
            'memberCount': 1,
            'postCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(ref.collection('members').doc(uid), {
            'joinedAt': FieldValue.serverTimestamp(),
          })
          ..set(_joinedRef(uid, community.id), {
            'joinedAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }

  @override
  Future<void> toggleJoin(String communityId) async {
    final uid = _requireUid();
    final ref = _db.collection('communities').doc(communityId);
    final member = ref.collection('members').doc(uid);
    final batch = _db.batch();
    if (_joined.contains(communityId)) {
      batch
        ..delete(member)
        ..delete(_joinedRef(uid, communityId))
        ..update(ref, {'memberCount': FieldValue.increment(-1)});
    } else {
      batch
        ..set(member, {'joinedAt': FieldValue.serverTimestamp()})
        ..set(_joinedRef(uid, communityId), {
          'joinedAt': FieldValue.serverTimestamp(),
        })
        ..update(ref, {'memberCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _joinedRef(String uid, String id) =>
      _db.collection('users').doc(uid).collection('joined').doc(id);

  @override
  void openPost(String postId) {
    _commentSubs[postId] ??= _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(500)
        .snapshots()
        .listen((snapshot) {
          _comments[postId] = [
            for (final d in snapshot.docs) _toComment(d.id, d.data()),
          ];
          notifyListeners();
        }, onError: (Object e) => debugPrint('Comments unavailable: $e'));
  }

  @override
  void closePost(String postId) {
    _commentSubs.remove(postId)?.cancel();
    _comments.remove(postId);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  bool _likedByMe(Map<String, dynamic> data) =>
      (data['likedBy'] as List<dynamic>? ?? const []).contains(_uid);

  PostModel _toPost(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      authorId: data['authorId'] as String?,
      authorName: data['authorName'] as String? ?? '',
      authorSubtitle: data['authorSubtitle'] as String? ?? '',
      communityId: data['communityId'] as String?,
      type: PostType.values.asNameMap()[data['type']] ?? PostType.discussion,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const []).cast<String>(),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      likedByMe: _likedByMe(data),
      bookmarked: _bookmarks.contains(id),
      comments: _comments[id] ?? const [],
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      // Pending server timestamps are null until confirmed.
      createdAt: _time(data['createdAt']) ?? DateTime.now(),
    );
  }

  CommentModel _toComment(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      authorId: data['authorId'] as String?,
      authorName: data['authorName'] as String? ?? '',
      body: data['body'] as String? ?? '',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: _likedByMe(data),
      createdAt: _time(data['createdAt']) ?? DateTime.now(),
    );
  }

  CommunityModel _toCommunity(String id, Map<String, dynamic> data) {
    return CommunityModel(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      category:
          CommunityCategory.values.asNameMap()[data['category']] ??
          CommunityCategory.general,
      isPrivate: data['isPrivate'] as bool? ?? false,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      joined: _joined.contains(id),
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6FA8DC,
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      createdAt: _time(data['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _time(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
