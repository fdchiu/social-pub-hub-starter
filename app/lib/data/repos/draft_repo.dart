import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class DraftRepo {
  DraftRepo(this._db);

  final AppDatabase _db;

  Future<Draft?> getLatestDraft() async {
    final query = _db.select(_db.drafts)
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

  Future<String> createDraft({
    String canonicalMarkdown = '',
    String? intent,
    double? tone,
    double? punchiness,
    String? emojiLevel,
    String? audience,
  }) async {
    final id = generateEntityId();
    final now = DateTime.now().toUtc();

    await _db.into(_db.drafts).insert(
          DraftsCompanion.insert(
            id: id,
            canonicalMarkdown: Value(canonicalMarkdown),
            intent: Value(intent),
            tone: Value(tone),
            punchiness: Value(punchiness),
            emojiLevel: Value(emojiLevel),
            audience: Value(audience),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  Future<void> updateCanonicalMarkdown({
    required String draftId,
    required String canonicalMarkdown,
  }) async {
    await (_db.update(_db.drafts)..where((t) => t.id.equals(draftId))).write(
      DraftsCompanion(
        canonicalMarkdown: Value(canonicalMarkdown),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
