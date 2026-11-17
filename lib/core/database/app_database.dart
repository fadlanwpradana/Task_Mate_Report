import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.path})
    : _factory = factory ?? databaseFactory;

  static const databaseName = 'task_mate.db';
  static const databaseVersion = 2;

  final DatabaseFactory _factory;
  final String? path;
  Database? _instance;
  Future<Database>? _opening;

  @visibleForTesting
  static String? testDatabasePathOverride;

  Future<Database> get instance {
    final existing = _instance;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final path =
          this.path ??
          testDatabasePathOverride ??
          p.join(await getDatabasesPath(), databaseName);
      final opened = await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE cached_community_posts (
              user_id TEXT NOT NULL,
              post_id TEXT NOT NULL,
              post_json TEXT NOT NULL,
              PRIMARY KEY (user_id, post_id)
            )
          ''');
            await db.execute(
              'CREATE INDEX cached_community_posts_user '
              'ON cached_community_posts(user_id)',
            );
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute(
                'CREATE INDEX cached_community_posts_user '
                'ON cached_community_posts(user_id)',
              );
            }
          },
        ),
      );
      _instance = opened;
      return opened;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final opened = _instance ?? await _opening;
    _instance = null;
    _opening = null;
    await opened?.close();
  }
}
