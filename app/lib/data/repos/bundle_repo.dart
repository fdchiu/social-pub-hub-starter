import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class BundleRepo {
  BundleRepo(this._db);

  final AppDatabase _db;

  Stream<List<Bundle>> watchBundles({
    String? postId,
    bool includeUnscoped = true,
  }) {
    final query = _db.select(_db.bundles)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final normalizedPostId = postId?.trim();
    if (normalizedPostId != null && normalizedPostId.isNotEmpty) {
      if (includeUnscoped) {
        query.where(
          (t) => t.postId.equals(normalizedPostId) | t.postId.isNull(),
        );
      } else {
        query.where((t) => t.postId.equals(normalizedPostId));
      }
    }
    return query.watch();
  }

  Future<Bundle?> getBundleById(String bundleId) {
    final query = _db.select(_db.bundles)..where((t) => t.id.equals(bundleId));
    return query.getSingleOrNull();
  }

  Future<String> createBundle({
    required String name,
    required String anchorType,
    String? anchorRef,
    String? canonicalDraftId,
    List<String> relatedVariantIds = const <String>[],
    String? notes,
    String? postId,
  }) async {
    final now = DateTime.now().toUtc();
    final id = generateEntityId();
    final resolvedPostId = await _resolvePostId(
      postId: postId,
      canonicalDraftId: canonicalDraftId,
      relatedVariantIds: relatedVariantIds,
    );
    await _db.into(_db.bundles).insert(
          BundlesCompanion.insert(
            id: id,
            name: name.trim(),
            anchorType: Value(anchorType),
            anchorRef:
                Value(anchorRef?.trim().isEmpty ?? true ? null : anchorRef),
            canonicalDraftId: Value(
              canonicalDraftId?.trim().isEmpty ?? true
                  ? null
                  : canonicalDraftId,
            ),
            postId: Value(resolvedPostId),
            relatedVariantIds: Value(relatedVariantIds),
            notes: Value(notes?.trim().isEmpty ?? true ? null : notes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Future<void> addRelatedVariantIds({
    required String bundleId,
    required List<String> variantIds,
  }) async {
    if (variantIds.isEmpty) {
      return;
    }
    final bundle = await getBundleById(bundleId);
    if (bundle == null) {
      return;
    }
    final merged =
        <String>{...bundle.relatedVariantIds, ...variantIds}.toList();
    await (_db.update(_db.bundles)..where((t) => t.id.equals(bundleId))).write(
      BundlesCompanion(
        relatedVariantIds: Value(merged),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> removeRelatedVariantIds({
    required String bundleId,
    required List<String> variantIds,
  }) async {
    if (variantIds.isEmpty) {
      return;
    }
    final bundle = await getBundleById(bundleId);
    if (bundle == null) {
      return;
    }
    final filtered = bundle.relatedVariantIds
        .where((id) => !variantIds.contains(id))
        .toList(growable: false);
    await (_db.update(_db.bundles)..where((t) => t.id.equals(bundleId))).write(
      BundlesCompanion(
        relatedVariantIds: Value(filtered),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> setCanonicalDraftId({
    required String bundleId,
    String? draftId,
  }) async {
    await (_db.update(_db.bundles)..where((t) => t.id.equals(bundleId))).write(
      BundlesCompanion(
        canonicalDraftId: Value(draftId),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateBundle({
    required String bundleId,
    required String name,
    required String anchorType,
    String? anchorRef,
    String? notes,
    String? canonicalDraftId,
    String? postId,
  }) async {
    final bundle = await getBundleById(bundleId);
    final resolvedPostId = await _resolvePostId(
      postId: postId ?? bundle?.postId,
      canonicalDraftId: canonicalDraftId,
      relatedVariantIds: bundle?.relatedVariantIds ?? const <String>[],
    );
    await (_db.update(_db.bundles)..where((t) => t.id.equals(bundleId))).write(
      BundlesCompanion(
        name: Value(name.trim()),
        anchorType: Value(anchorType.trim().isEmpty ? 'youtube' : anchorType),
        anchorRef:
            Value(anchorRef?.trim().isEmpty ?? true ? null : anchorRef?.trim()),
        canonicalDraftId: Value(
          canonicalDraftId?.trim().isEmpty ?? true
              ? null
              : canonicalDraftId?.trim(),
        ),
        postId: Value(resolvedPostId),
        notes: Value(notes?.trim().isEmpty ?? true ? null : notes?.trim()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<String?> _resolvePostId({
    String? postId,
    String? canonicalDraftId,
    List<String> relatedVariantIds = const <String>[],
  }) async {
    final normalizedPostId = postId?.trim();
    if (normalizedPostId != null && normalizedPostId.isNotEmpty) {
      return normalizedPostId;
    }

    final normalizedDraftId = canonicalDraftId?.trim();
    if (normalizedDraftId != null && normalizedDraftId.isNotEmpty) {
      final draft = await (_db.select(_db.drafts)
            ..where((t) => t.id.equals(normalizedDraftId)))
          .getSingleOrNull();
      if (draft?.postId != null && draft!.postId!.trim().isNotEmpty) {
        return draft.postId!.trim();
      }
    }

    for (final rawVariantId in relatedVariantIds) {
      final variantId = rawVariantId.trim();
      if (variantId.isEmpty) {
        continue;
      }
      final variant = await (_db.select(_db.variants)
            ..where((t) => t.id.equals(variantId)))
          .getSingleOrNull();
      if (variant == null) {
        continue;
      }
      final draft = await (_db.select(_db.drafts)
            ..where((t) => t.id.equals(variant.draftId)))
          .getSingleOrNull();
      if (draft?.postId != null && draft!.postId!.trim().isNotEmpty) {
        return draft.postId!.trim();
      }
    }

    return null;
  }

  Future<void> deleteBundle(String bundleId) async {
    await _db.transaction(() async {
      await (_db.update(_db.sourceItems)
            ..where((t) => t.bundleId.equals(bundleId)))
          .write(
        SourceItemsCompanion(
          bundleId: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await (_db.delete(_db.bundles)..where((t) => t.id.equals(bundleId))).go();
    });
  }
}
