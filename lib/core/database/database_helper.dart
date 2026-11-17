import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/post_model.dart';
import 'app_database.dart';

/// Stores a per-account read-through cache; Firestore remains authoritative.
class DatabaseHelper {
  DatabaseHelper({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<List<PostModel>> readCachedPosts(String userId) async {
    final db = await _database.instance;
    final rows = await db.query(
      'cached_community_posts',
      columns: ['post_json'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return [
      for (final row in rows)
        PostModel.fromJson(
          jsonDecode(row['post_json']! as String) as Map<String, dynamic>,
        ),
    ];
  }

  Future<void> replaceCachedPosts(String userId, List<PostModel> posts) async {
    final db = await _database.instance;
    await db.transaction((transaction) async {
      await transaction.delete(
        'cached_community_posts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final batch = transaction.batch();
      for (final post in posts) {
        batch.insert('cached_community_posts', {
          'user_id': userId,
          'post_id': post.id,
          'post_json': jsonEncode(post.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertCachedPost(String userId, PostModel post) async {
    final db = await _database.instance;
    await db.insert('cached_community_posts', {
      'user_id': userId,
      'post_id': post.id,
      'post_json': jsonEncode(post.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCachedPost(String userId, String postId) async {
    final db = await _database.instance;
    await db.delete(
      'cached_community_posts',
      where: 'user_id = ? AND post_id = ?',
      whereArgs: [userId, postId],
    );
  }

  Future<void> clearCachedPosts(String userId) async {
    final db = await _database.instance;
    await db.delete(
      'cached_community_posts',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
