import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class BundleRepo {
  BundleRepo(this._db);

  final AppDatabase _db;

  Stream<List<Bundle>> watchBundles() {
    final query = _db.select(_db.bundles)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
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
    List<String> relatedVariantIds = const <String>[],
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final id = generateEntityId();
    await _db.into(_db.bundles).insert(
          BundlesCompanion.insert(
            id: id,
            name: name.trim(),
            anchorType: Value(anchorType),
            anchorRef:
                Value(anchorRef?.trim().isEmpty ?? true ? null : anchorRef),
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
}
