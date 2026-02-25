import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class VariantRepo {
  VariantRepo(this._db);

  final AppDatabase _db;

  Stream<List<Variant>> watchVariantsForDraft(String draftId) {
    final query = _db.select(_db.variants)
      ..where((t) => t.draftId.equals(draftId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  Stream<List<Variant>> watchAllVariants() {
    final query = _db.select(_db.variants)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  Future<Variant?> getVariantById(String id) {
    final query = _db.select(_db.variants)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<String> createVariant({
    String? id,
    required String draftId,
    required String platform,
    required String body,
  }) async {
    final entityId = id ?? generateEntityId();
    final now = DateTime.now().toUtc();

    await _db.into(_db.variants).insert(
          VariantsCompanion.insert(
            id: entityId,
            draftId: draftId,
            platform: platform,
            body: body,
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
          mode: InsertMode.insertOrReplace,
        );

    return entityId;
  }

  Future<void> deleteVariantsForDraft(String draftId) async {
    final variants = await (_db.select(_db.variants)
          ..where((t) => t.draftId.equals(draftId)))
        .get();
    await _deleteVariantsByIds(variants.map((v) => v.id).toList());
  }

  Future<void> deleteVariantsForDraftPlatforms({
    required String draftId,
    required List<String> platforms,
  }) async {
    if (platforms.isEmpty) {
      return;
    }
    final variants = await (_db.select(_db.variants)
          ..where(
            (t) => t.draftId.equals(draftId) & t.platform.isIn(platforms),
          ))
        .get();
    await _deleteVariantsByIds(variants.map((v) => v.id).toList());
  }

  Future<void> deleteVariantById(String variantId) async {
    await _deleteVariantsByIds(<String>[variantId]);
  }

  Future<void> updateVariantBody({
    required String variantId,
    required String body,
  }) async {
    await (_db.update(_db.variants)..where((t) => t.id.equals(variantId)))
        .write(
      VariantsCompanion(
        body: Value(body),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> _deleteVariantsByIds(List<String> variantIds) async {
    if (variantIds.isEmpty) {
      return;
    }

    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
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
      await (_db.delete(_db.variants)..where((t) => t.id.isIn(variantIds)))
          .go();
    });
  }
}
