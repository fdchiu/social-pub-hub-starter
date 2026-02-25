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
}
