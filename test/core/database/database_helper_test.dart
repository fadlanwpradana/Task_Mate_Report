import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_mate_v4/core/database/app_database.dart';
import 'package:task_mate_v4/core/database/database_helper.dart';
import 'package:task_mate_v4/models/post_model.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('inserts, reads, updates, and deletes cached posts', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final helper = DatabaseHelper(database: database);
    addTearDown(database.close);
    final post = PostModel(
      id: 'post-1',
      authorName: 'Ari',
      type: PostType.discussion,
      title: 'Original',
      body: 'Cached body',
      createdAt: DateTime.utc(2026),
    );

    await helper.upsertCachedPost('alice', post);
    expect((await helper.readCachedPosts('alice')).single.title, 'Original');
    expect(await helper.readCachedPosts('bob'), isEmpty);

    await helper.upsertCachedPost('alice', post.copyWith(title: 'Updated'));
    expect((await helper.readCachedPosts('alice')).single.title, 'Updated');

    await helper.deleteCachedPost('alice', post.id);
    expect(await helper.readCachedPosts('alice'), isEmpty);
  });
}
