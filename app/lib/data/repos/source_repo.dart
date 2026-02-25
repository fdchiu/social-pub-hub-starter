import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class SourceRepo {
  SourceRepo(this._db);

  final AppDatabase _db;

  Stream<List<SourceItem>> watchSourceItems({
    String? postId,
    bool includeGlobal = true,
  }) {
    final query = _db.select(_db.sourceItems);
    if (postId != null && postId.trim().isNotEmpty) {
      final normalizedPostId = postId.trim();
      if (includeGlobal) {
        query.where(
          (t) => t.postId.equals(normalizedPostId) | t.postId.isNull(),
        );
      } else {
        query.where((t) => t.postId.equals(normalizedPostId));
      }
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<SourceItem?> getLatestUnbundledSource({
    String? postId,
    bool includeGlobal = true,
  }) {
    final query = _db.select(_db.sourceItems)
      ..where((t) => t.bundleId.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    final normalizedPostId = postId?.trim();
    if (normalizedPostId != null && normalizedPostId.isNotEmpty) {
      query.where(
        includeGlobal
            ? (t) => t.postId.equals(normalizedPostId) | t.postId.isNull()
            : (t) => t.postId.equals(normalizedPostId),
      );
    }
    return query.getSingleOrNull();
  }

  Future<List<SourceItem>> getSourceItemsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <SourceItem>[];
    }
    final query = _db.select(_db.sourceItems)..where((t) => t.id.isIn(ids));
    final rows = await query.get();
    final order = <String, int>{
      for (var i = 0; i < ids.length; i++) ids[i]: i,
    };
    rows.sort((a, b) =>
        (order[a.id] ?? ids.length).compareTo(order[b.id] ?? ids.length));
    return rows;
  }

  Future<List<SourceItem>> getRecentSourceItems({int limit = 12}) {
    return getRecentSourceItemsForPost(limit: limit);
  }

  Future<List<SourceItem>> getRecentSourceItemsForPost({
    required int limit,
    String? postId,
    bool includeGlobal = true,
  }) {
    final query = _db.select(_db.sourceItems);
    if (postId != null && postId.trim().isNotEmpty) {
      final normalizedPostId = postId.trim();
      if (includeGlobal) {
        query.where(
          (t) => t.postId.equals(normalizedPostId) | t.postId.isNull(),
        );
      } else {
        query.where((t) => t.postId.equals(normalizedPostId));
      }
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit);
    return query.get();
  }

  Future<String> createSourceItem({
    required String type,
    String? url,
    String? title,
    String? userNote,
    List<String> tags = const <String>[],
    String? bundleId,
    String? postId,
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
            bundleId: Value(
                bundleId?.trim().isEmpty ?? true ? null : bundleId?.trim()),
            postId:
                Value(postId?.trim().isEmpty ?? true ? null : postId?.trim()),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );

    return id;
  }

  Future<void> assignBundle({
    required String sourceId,
    String? bundleId,
  }) async {
    await (_db.update(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
        .write(
      SourceItemsCompanion(
        bundleId: Value(bundleId),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> updateSourceItem({
    required String sourceId,
    required String type,
    String? url,
    String? title,
    String? userNote,
    List<String>? tags,
    String? postId,
  }) async {
    final normalizedTags = tags
        ?.map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    await (_db.update(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
        .write(
      SourceItemsCompanion(
        type: Value(type),
        url: Value(url?.trim().isEmpty ?? true ? null : url?.trim()),
        title: Value(title?.trim().isEmpty ?? true ? null : title?.trim()),
        userNote:
            Value(userNote?.trim().isEmpty ?? true ? null : userNote?.trim()),
        tags: normalizedTags == null
            ? const Value.absent()
            : Value(normalizedTags),
        postId: postId == null ? const Value.absent() : Value(postId),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> assignPost({
    required String sourceId,
    String? postId,
  }) async {
    await (_db.update(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
        .write(
      SourceItemsCompanion(
        postId: Value(postId),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> deleteSourceItemById(String sourceId) async {
    await (_db.delete(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
        .go();
  }
}
