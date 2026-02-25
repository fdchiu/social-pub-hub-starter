import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class DraftRepo {
  DraftRepo(this._db);

  final AppDatabase _db;

  Future<Draft?> getLatestDraft({String? postId}) async {
    final query = _db.select(_db.drafts);
    if (postId != null && postId.trim().isNotEmpty) {
      query.where((t) => t.postId.equals(postId.trim()));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<Draft?> getDraftById(String id) {
    final query = _db.select(_db.drafts)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Stream<Draft?> watchDraftById(String id) {
    final query = _db.select(_db.drafts)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  Stream<List<Draft>> watchRecentDrafts({
    int limit = 50,
    String? postId,
  }) {
    final query = _db.select(_db.drafts);
    if (postId != null && postId.trim().isNotEmpty) {
      query.where((t) => t.postId.equals(postId.trim()));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit);
    return query.watch();
  }

  Stream<List<Draft>> watchAllDrafts({String? postId}) {
    final query = _db.select(_db.drafts);
    if (postId != null && postId.trim().isNotEmpty) {
      query.where((t) => t.postId.equals(postId.trim()));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  Future<String> createDraft({
    String? id,
    String canonicalMarkdown = '',
    String? intent,
    double? tone,
    double? punchiness,
    String? emojiLevel,
    String? audience,
    String? postId,
    String? contentType,
  }) async {
    final draftId = id ?? generateEntityId();
    final now = DateTime.now().toUtc();

    await _db.into(_db.drafts).insert(
          DraftsCompanion.insert(
            id: draftId,
            canonicalMarkdown: Value(canonicalMarkdown),
            intent: Value(intent),
            tone: Value(tone),
            punchiness: Value(punchiness),
            emojiLevel: Value(emojiLevel),
            audience: Value(audience),
            postId: Value(postId),
            contentType: Value(contentType),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
          mode: InsertMode.insertOrReplace,
        );

    return draftId;
  }

  Future<void> updateCanonicalMarkdown({
    required String draftId,
    required String canonicalMarkdown,
  }) async {
    await (_db.update(_db.drafts)..where((t) => t.id.equals(draftId))).write(
      DraftsCompanion(
        canonicalMarkdown: Value(canonicalMarkdown),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> deleteDraftById(String draftId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final linkedVariants = await (_db.select(_db.variants)
            ..where((t) => t.draftId.equals(draftId)))
          .get();
      final variantIds = linkedVariants.map((row) => row.id).toSet();

      await _db.into(_db.syncTombstones).insertOnConflictUpdate(
            SyncTombstonesCompanion.insert(
              id: 'drafts:$draftId',
              entityType: 'drafts',
              entityId: draftId,
              createdAt: Value(now),
            ),
          );
      for (final variantId in variantIds) {
        await _db.into(_db.syncTombstones).insertOnConflictUpdate(
              SyncTombstonesCompanion.insert(
                id: 'variants:$variantId',
                entityType: 'variants',
                entityId: variantId,
                createdAt: Value(now),
              ),
            );
      }

      if (variantIds.isNotEmpty) {
        await (_db.update(_db.publishLogs)
              ..where((t) => t.variantId.isIn(variantIds)))
            .write(
          PublishLogsCompanion(
            variantId: const Value(null),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
        await (_db.update(_db.scheduledPosts)
              ..where((t) => t.variantId.isIn(variantIds)))
            .write(
          ScheduledPostsCompanion(
            variantId: const Value(null),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
      }

      final bundles = await _db.select(_db.bundles).get();
      for (final bundle in bundles) {
        final updatedVariantIds = bundle.relatedVariantIds
            .where((id) => !variantIds.contains(id))
            .toList(growable: false);
        final relatedChanged =
            updatedVariantIds.length != bundle.relatedVariantIds.length;
        final canonicalChanged = bundle.canonicalDraftId == draftId;
        if (!relatedChanged && !canonicalChanged) {
          continue;
        }
        await (_db.update(_db.bundles)..where((t) => t.id.equals(bundle.id)))
            .write(
          BundlesCompanion(
            relatedVariantIds: Value(updatedVariantIds),
            canonicalDraftId:
                canonicalChanged ? const Value(null) : const Value.absent(),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
      }

      await (_db.delete(_db.variants)..where((t) => t.draftId.equals(draftId)))
          .go();
      await (_db.delete(_db.drafts)..where((t) => t.id.equals(draftId))).go();
    });
  }
}
