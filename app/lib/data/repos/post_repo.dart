import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';
import '../../utils/content_type_utils.dart';

class PostRepo {
  PostRepo(this._db);

  final AppDatabase _db;

  Stream<List<Post>> watchPosts({String? projectId}) {
    final query = _db.select(_db.posts);
    if (projectId != null && projectId.trim().isNotEmpty) {
      query.where((t) => t.projectId.equals(projectId.trim()));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  Future<Post?> getPostById(String postId) {
    final query = _db.select(_db.posts)..where((t) => t.id.equals(postId));
    return query.getSingleOrNull();
  }

  Future<Post?> getLatestPost() {
    final query = _db.select(_db.posts)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<String> createPost({
    required String title,
    required String contentType,
    String? goal,
    String? audience,
    String? projectId,
    String status = 'active',
  }) async {
    final id = generateEntityId();
    final now = DateTime.now().toUtc();
    await _db.into(_db.posts).insert(
          PostsCompanion.insert(
            id: id,
            projectId: Value(
              projectId?.trim().isEmpty ?? true ? null : projectId?.trim(),
            ),
            title: title.trim(),
            contentType: Value(normalizeContentType(contentType)),
            goal: Value(goal?.trim().isEmpty ?? true ? null : goal?.trim()),
            audience: Value(
                audience?.trim().isEmpty ?? true ? null : audience?.trim()),
            status: Value(status),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
    return id;
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String contentType,
    String? goal,
    String? audience,
    String? projectId,
    String? status,
  }) async {
    await (_db.update(_db.posts)..where((t) => t.id.equals(postId))).write(
      PostsCompanion(
        title: Value(title.trim()),
        contentType: Value(normalizeContentType(contentType)),
        goal: Value(goal?.trim().isEmpty ?? true ? null : goal?.trim()),
        audience:
            Value(audience?.trim().isEmpty ?? true ? null : audience?.trim()),
        projectId:
            Value(projectId?.trim().isEmpty ?? true ? null : projectId?.trim()),
        status: status == null ? const Value.absent() : Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> deletePost(String postId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      await _db.into(_db.syncTombstones).insertOnConflictUpdate(
            SyncTombstonesCompanion.insert(
              id: 'posts:$postId',
              entityType: 'posts',
              entityId: postId,
              createdAt: Value(now),
            ),
          );

      await (_db.update(_db.sourceItems)..where((t) => t.postId.equals(postId)))
          .write(
        SourceItemsCompanion(
          postId: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('dirty'),
        ),
      );
      await (_db.update(_db.drafts)..where((t) => t.postId.equals(postId)))
          .write(
        DraftsCompanion(
          postId: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('dirty'),
        ),
      );
      await (_db.update(_db.publishLogs)..where((t) => t.postId.equals(postId)))
          .write(
        PublishLogsCompanion(
          postId: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('dirty'),
        ),
      );
      await (_db.update(_db.scheduledPosts)
            ..where((t) => t.postId.equals(postId)))
          .write(
        ScheduledPostsCompanion(
          postId: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('dirty'),
        ),
      );
      await (_db.update(_db.bundles)..where((t) => t.postId.equals(postId)))
          .write(
        BundlesCompanion(
          postId: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('dirty'),
        ),
      );
      await (_db.delete(_db.posts)..where((t) => t.id.equals(postId))).go();
    });
  }
}
