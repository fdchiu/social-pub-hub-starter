import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class ScheduledPostRepo {
  ScheduledPostRepo(this._db);

  final AppDatabase _db;

  Stream<List<ScheduledPost>> watchScheduledPosts() {
    final query = _db.select(_db.scheduledPosts)
      ..orderBy([
        (t) => OrderingTerm.asc(t.scheduledFor),
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch();
  }

  Future<String> createScheduledPost({
    String? variantId,
    String? postId,
    required String platform,
    required String content,
    required DateTime scheduledFor,
  }) async {
    final now = DateTime.now().toUtc();
    final id = generateEntityId();
    final resolvedPostId = await _resolvePostId(
      variantId: variantId,
      postId: postId,
    );
    await _db.into(_db.scheduledPosts).insert(
          ScheduledPostsCompanion.insert(
            id: id,
            variantId: Value(variantId),
            postId: Value(resolvedPostId),
            platform: platform,
            content: content,
            scheduledFor: scheduledFor,
            status: const Value('queued'),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
    return id;
  }

  Future<String?> _resolvePostId({
    String? variantId,
    String? postId,
  }) async {
    final normalizedPostId = postId?.trim();
    if (normalizedPostId != null && normalizedPostId.isNotEmpty) {
      return normalizedPostId;
    }
    final normalizedVariantId = variantId?.trim();
    if (normalizedVariantId == null || normalizedVariantId.isEmpty) {
      return null;
    }
    final variant = await (_db.select(_db.variants)
          ..where((t) => t.id.equals(normalizedVariantId)))
        .getSingleOrNull();
    if (variant == null) {
      return null;
    }
    final draft = await (_db.select(_db.drafts)
          ..where((t) => t.id.equals(variant.draftId)))
        .getSingleOrNull();
    return draft?.postId;
  }

  Future<void> markPosted({
    required String scheduledPostId,
    String? externalUrl,
  }) async {
    await (_db.update(_db.scheduledPosts)
          ..where((t) => t.id.equals(scheduledPostId)))
        .write(
      ScheduledPostsCompanion(
        status: const Value('posted'),
        externalUrl: Value(externalUrl),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> markCanceled(String scheduledPostId) async {
    await (_db.update(_db.scheduledPosts)
          ..where((t) => t.id.equals(scheduledPostId)))
        .write(
      ScheduledPostsCompanion(
        status: const Value('canceled'),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> reschedule({
    required String scheduledPostId,
    required DateTime scheduledFor,
  }) async {
    await (_db.update(_db.scheduledPosts)
          ..where((t) => t.id.equals(scheduledPostId)))
        .write(
      ScheduledPostsCompanion(
        scheduledFor: Value(scheduledFor),
        status: const Value('queued'),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }
}
