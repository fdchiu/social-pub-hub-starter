import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class SourceRepo {
  SourceRepo(this._db);

  final AppDatabase _db;

  Stream<List<SourceItem>> watchSourceItems() {
    final query = _db.select(_db.sourceItems)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<String> createSourceItem({
    required String type,
    String? url,
    String? title,
    String? userNote,
    List<String> tags = const <String>[],
  }) async {
    final now = DateTime.now().toUtc();
    final id = generateEntityId();
    final normalizedTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    await _db.into(_db.sourceItems).insert(
          SourceItemsCompanion.insert(
            id: id,
            type: type,
            url: Value(url?.trim().isEmpty ?? true ? null : url?.trim()),
            title: Value(title?.trim().isEmpty ?? true ? null : title?.trim()),
            userNote: Value(
                userNote?.trim().isEmpty ?? true ? null : userNote?.trim()),
            tags: Value(normalizedTags),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }
}
