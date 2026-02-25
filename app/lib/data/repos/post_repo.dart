import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

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
            contentType: Value(contentType.trim().isEmpty
                ? 'general_post'
                : contentType.trim()),
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
        contentType: Value(
            contentType.trim().isEmpty ? 'general_post' : contentType.trim()),
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
}
