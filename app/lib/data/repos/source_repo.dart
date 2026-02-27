import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class SourceRepo {
  SourceRepo(this._db);

  final AppDatabase _db;

  Stream<List<SourceItem>> watchSourceItems({
    String? postId,
    String? projectId,
    bool includeGlobal = true,
    bool includeProject = true,
  }) {
    final query = _db.select(_db.sourceItems);
    query.where(
      (t) => _scopePredicate(
        t,
        postId: postId,
        projectId: projectId,
        includeGlobal: includeGlobal,
        includeProject: includeProject,
      ),
    );
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<SourceItem?> getLatestUnbundledSource({
    String? postId,
    String? projectId,
    bool includeGlobal = true,
    bool includeProject = true,
  }) {
    final query = _db.select(_db.sourceItems)
      ..where((t) => t.bundleId.isNull())
      ..where(
        (t) => _scopePredicate(
          t,
          postId: postId,
          projectId: projectId,
          includeGlobal: includeGlobal,
          includeProject: includeProject,
        ),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
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
    String? projectId,
    bool includeGlobal = true,
    bool includeProject = true,
  }) {
    final query = _db.select(_db.sourceItems)
      ..where(
        (t) => _scopePredicate(
          t,
          postId: postId,
          projectId: projectId,
          includeGlobal: includeGlobal,
          includeProject: includeProject,
        ),
      )
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
    String? projectId,
  }) async {
    final now = DateTime.now().toUtc();
    final id = generateEntityId();
    final normalizedTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final normalizedPostId = _normalizeNullable(postId);
    final resolvedProjectId = await _resolveProjectId(
      postId: normalizedPostId,
      projectId: projectId,
    );

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
            projectId: Value(resolvedProjectId),
            postId: Value(normalizedPostId),
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
    String? projectId,
    bool updateScope = false,
  }) async {
    final normalizedTags = tags
        ?.map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    final normalizedPostId = _normalizeNullable(postId);
    final resolvedProjectId = await _resolveProjectId(
      postId: normalizedPostId,
      projectId: projectId,
    );

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
        postId: updateScope ? Value(normalizedPostId) : const Value.absent(),
        projectId:
            updateScope ? Value(resolvedProjectId) : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> assignScope({
    required String sourceId,
    String? postId,
    String? projectId,
  }) async {
    final normalizedPostId = _normalizeNullable(postId);
    final resolvedProjectId = await _resolveProjectId(
      postId: normalizedPostId,
      projectId: projectId,
    );

    await (_db.update(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
        .write(
      SourceItemsCompanion(
        postId: Value(normalizedPostId),
        projectId: Value(resolvedProjectId),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }

  Future<void> assignPost({
    required String sourceId,
    String? postId,
    String? projectId,
  }) async {
    await assignScope(
      sourceId: sourceId,
      postId: postId,
      projectId: projectId,
    );
  }

  Future<void> deleteSourceItemById(String sourceId) async {
    await _db.transaction(() async {
      await _db.into(_db.syncTombstones).insertOnConflictUpdate(
            SyncTombstonesCompanion.insert(
              id: 'source_items:$sourceId',
              entityType: 'source_items',
              entityId: sourceId,
              createdAt: Value(DateTime.now().toUtc()),
            ),
          );
      await (_db.delete(_db.sourceItems)..where((t) => t.id.equals(sourceId)))
          .go();
    });
  }

  Expression<bool> _scopePredicate(
    $SourceItemsTable t, {
    required String? postId,
    required String? projectId,
    required bool includeGlobal,
    required bool includeProject,
  }) {
    final normalizedPostId = _normalizeNullable(postId);
    final normalizedProjectId = _normalizeNullable(projectId);

    Expression<bool>? condition;

    void add(Expression<bool> next) {
      condition = condition == null ? next : condition! | next;
    }

    if (normalizedPostId != null) {
      add(t.postId.equals(normalizedPostId));
    }

    if (includeProject && normalizedProjectId != null) {
      add(t.postId.isNull() & t.projectId.equals(normalizedProjectId));
    }

    if (includeGlobal) {
      add(t.postId.isNull() & t.projectId.isNull());
    }

    if (normalizedPostId == null &&
        normalizedProjectId == null &&
        includeGlobal &&
        includeProject) {
      return const Constant(true);
    }

    return condition ?? const Constant(false);
  }

  String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<String?> _resolveProjectId({
    required String? postId,
    required String? projectId,
  }) async {
    final normalizedProjectId = _normalizeNullable(projectId);
    if (normalizedProjectId != null) {
      return normalizedProjectId;
    }
    if (postId == null) {
      return null;
    }
    final post = await (_db.select(_db.posts)
          ..where((t) => t.id.equals(postId)))
        .getSingleOrNull();
    return _normalizeNullable(post?.projectId);
  }
}
