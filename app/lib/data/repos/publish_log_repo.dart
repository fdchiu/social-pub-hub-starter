import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class PublishLogRepo {
  PublishLogRepo(this._db);

  final AppDatabase _db;

  Stream<List<PublishLog>> watchPublishLogs() {
    final query = _db.select(_db.publishLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<String> createPublishLog({
    String? variantId,
    String? postId,
    required String platform,
    required String mode,
    required String status,
    String? externalUrl,
    DateTime? postedAt,
  }) async {
    final id = generateEntityId();
    final now = DateTime.now().toUtc();
    final resolvedPostId = await _resolvePostId(
      variantId: variantId,
      postId: postId,
    );

    await _db.into(_db.publishLogs).insert(
          PublishLogsCompanion.insert(
            id: id,
            platform: platform,
            mode: mode,
            status: Value(status),
            variantId: Value(variantId),
            postId: Value(resolvedPostId),
            externalUrl: Value(externalUrl),
            postedAt: Value(postedAt),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );

    return id;
  }

  Future<void> deletePublishLog(String publishLogId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      await _db.into(_db.syncTombstones).insertOnConflictUpdate(
            SyncTombstonesCompanion.insert(
              id: 'publish_logs:$publishLogId',
              entityType: 'publish_logs',
              entityId: publishLogId,
              createdAt: Value(now),
            ),
          );
      await (_db.delete(_db.publishLogs)
            ..where((t) => t.id.equals(publishLogId)))
          .go();
    });
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
}
