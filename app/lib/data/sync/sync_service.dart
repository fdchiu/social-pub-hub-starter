import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_db.dart';
import '../../utils/content_type_utils.dart';

class SyncSummary {
  const SyncSummary({
    required this.cursor,
    required this.pushedSourceItems,
    required this.pushedProjects,
    required this.pushedPosts,
    required this.pushedBundles,
    required this.pushedDrafts,
    required this.pushedVariants,
    required this.pushedPublishLogs,
    required this.pushedStyleProfiles,
    required this.pushedScheduledPosts,
    required this.pushedDeletedSourceItems,
    required this.pushedDeletedProjects,
    required this.pushedDeletedPosts,
    required this.pushedDeletedBundles,
    required this.pushedDeletedDrafts,
    required this.pushedDeletedVariants,
    required this.pushedDeletedPublishLogs,
    required this.pushedDeletedStyleProfiles,
    required this.pushedDeletedScheduledPosts,
    required this.pulledSourceItems,
    required this.pulledProjects,
    required this.pulledPosts,
    required this.pulledBundles,
    required this.pulledDrafts,
    required this.pulledVariants,
    required this.pulledPublishLogs,
    required this.pulledStyleProfiles,
    required this.pulledScheduledPosts,
    required this.deletedSourceItems,
    required this.deletedProjects,
    required this.deletedPosts,
    required this.deletedBundles,
    required this.deletedDrafts,
    required this.deletedVariants,
    required this.deletedPublishLogs,
    required this.deletedStyleProfiles,
    required this.deletedScheduledPosts,
    required this.detectedConflicts,
  });

  final int cursor;
  final int pushedSourceItems;
  final int pushedProjects;
  final int pushedPosts;
  final int pushedBundles;
  final int pushedDrafts;
  final int pushedVariants;
  final int pushedPublishLogs;
  final int pushedStyleProfiles;
  final int pushedScheduledPosts;
  final int pushedDeletedSourceItems;
  final int pushedDeletedProjects;
  final int pushedDeletedPosts;
  final int pushedDeletedBundles;
  final int pushedDeletedDrafts;
  final int pushedDeletedVariants;
  final int pushedDeletedPublishLogs;
  final int pushedDeletedStyleProfiles;
  final int pushedDeletedScheduledPosts;
  final int pulledSourceItems;
  final int pulledProjects;
  final int pulledPosts;
  final int pulledBundles;
  final int pulledDrafts;
  final int pulledVariants;
  final int pulledPublishLogs;
  final int pulledStyleProfiles;
  final int pulledScheduledPosts;
  final int deletedSourceItems;
  final int deletedProjects;
  final int deletedPosts;
  final int deletedBundles;
  final int deletedDrafts;
  final int deletedVariants;
  final int deletedPublishLogs;
  final int deletedStyleProfiles;
  final int deletedScheduledPosts;
  final int detectedConflicts;
}

class SyncService {
  SyncService({
    required AppDatabase db,
    required http.Client client,
    required String baseUrl,
  })  : _db = db,
        _client = client,
        _baseUrl = baseUrl;

  static const String _cursorKey = 'sync.cursor';

  final AppDatabase _db;
  final http.Client _client;
  final String _baseUrl;
  int _detectedConflictsInRun = 0;

  Future<SyncSummary> syncNow() async {
    _detectedConflictsInRun = 0;
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt(_cursorKey) ?? 0;
    final pushBatch = await _buildPushBatch();

    final pushResponse = await _client.post(
      Uri.parse('$_baseUrl/sync/push'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(pushBatch.payload),
    );
    if (pushResponse.statusCode < 200 || pushResponse.statusCode >= 300) {
      throw Exception('Sync push failed: ${pushResponse.statusCode}');
    }

    final pushBody = jsonDecode(pushResponse.body) as Map<String, dynamic>;
    final pushCursor = (pushBody['cursor'] as num?)?.toInt() ?? since;

    await _markPushedRowsClean(pushBatch);

    final changesResponse = await _client.get(
      Uri.parse('$_baseUrl/sync/changes?since=$since'),
    );
    if (changesResponse.statusCode < 200 || changesResponse.statusCode >= 300) {
      throw Exception('Sync pull failed: ${changesResponse.statusCode}');
    }

    final changes = jsonDecode(changesResponse.body) as Map<String, dynamic>;
    final pullCursor = (changes['cursor'] as num?)?.toInt() ?? since;

    final upserts = (changes['upserts'] as Map<String, dynamic>? ?? const {});
    final deletes = (changes['deletes'] as Map<String, dynamic>? ?? const {});

    final pulledSourceItems = _asMapList(upserts['source_items']);
    final pulledProjects = _asMapList(upserts['projects']);
    final pulledPosts = _asMapList(upserts['posts']);
    final pulledBundles = _asMapList(upserts['bundles']);
    final pulledDrafts = _asMapList(upserts['drafts']);
    final pulledVariants = _asMapList(upserts['variants']);
    final pulledPublishLogs = _asMapList(upserts['publish_logs']);
    final pulledStyleProfiles = _asMapList(upserts['style_profiles']);
    final pulledScheduledPosts = _asMapList(upserts['scheduled_posts']);

    final deletedSourceItems = _asStringList(deletes['source_items']);
    final deletedProjects = _asStringList(deletes['projects']);
    final deletedPosts = _asStringList(deletes['posts']);
    final deletedBundles = _asStringList(deletes['bundles']);
    final deletedDrafts = _asStringList(deletes['drafts']);
    final deletedVariants = _asStringList(deletes['variants']);
    final deletedPublishLogs = _asStringList(deletes['publish_logs']);
    final deletedStyleProfiles = _asStringList(deletes['style_profiles']);
    final deletedScheduledPosts = _asStringList(deletes['scheduled_posts']);

    await _db.transaction(() async {
      await _applySourceItemUpserts(pulledSourceItems);
      await _applyProjectUpserts(pulledProjects);
      await _applyPostUpserts(pulledPosts);
      await _applyBundleUpserts(pulledBundles);
      await _applyDraftUpserts(pulledDrafts);
      await _applyVariantUpserts(pulledVariants);
      await _applyPublishLogUpserts(pulledPublishLogs);
      await _applyStyleProfileUpserts(pulledStyleProfiles);
      await _applyScheduledPostUpserts(pulledScheduledPosts);
      await _applyDeletes(
        deletedSourceItems: deletedSourceItems,
        deletedProjects: deletedProjects,
        deletedPosts: deletedPosts,
        deletedBundles: deletedBundles,
        deletedDrafts: deletedDrafts,
        deletedVariants: deletedVariants,
        deletedPublishLogs: deletedPublishLogs,
        deletedStyleProfiles: deletedStyleProfiles,
        deletedScheduledPosts: deletedScheduledPosts,
      );
    });

    final nextCursor = max(pushCursor, pullCursor);
    await prefs.setInt(_cursorKey, nextCursor);

    return SyncSummary(
      cursor: nextCursor,
      pushedSourceItems: pushBatch.sourceItemIds.length,
      pushedProjects: pushBatch.projectIds.length,
      pushedPosts: pushBatch.postIds.length,
      pushedBundles: pushBatch.bundleIds.length,
      pushedDrafts: pushBatch.draftIds.length,
      pushedVariants: pushBatch.variantIds.length,
      pushedPublishLogs: pushBatch.publishLogIds.length,
      pushedStyleProfiles: pushBatch.styleProfileIds.length,
      pushedScheduledPosts: pushBatch.scheduledPostIds.length,
      pushedDeletedSourceItems: pushBatch.deletedSourceItems,
      pushedDeletedProjects: pushBatch.deletedProjects,
      pushedDeletedPosts: pushBatch.deletedPosts,
      pushedDeletedBundles: pushBatch.deletedBundles,
      pushedDeletedDrafts: pushBatch.deletedDrafts,
      pushedDeletedVariants: pushBatch.deletedVariants,
      pushedDeletedPublishLogs: pushBatch.deletedPublishLogs,
      pushedDeletedStyleProfiles: pushBatch.deletedStyleProfiles,
      pushedDeletedScheduledPosts: pushBatch.deletedScheduledPosts,
      pulledSourceItems: pulledSourceItems.length,
      pulledProjects: pulledProjects.length,
      pulledPosts: pulledPosts.length,
      pulledBundles: pulledBundles.length,
      pulledDrafts: pulledDrafts.length,
      pulledVariants: pulledVariants.length,
      pulledPublishLogs: pulledPublishLogs.length,
      pulledStyleProfiles: pulledStyleProfiles.length,
      pulledScheduledPosts: pulledScheduledPosts.length,
      deletedSourceItems: deletedSourceItems.length,
      deletedProjects: deletedProjects.length,
      deletedPosts: deletedPosts.length,
      deletedBundles: deletedBundles.length,
      deletedDrafts: deletedDrafts.length,
      deletedVariants: deletedVariants.length,
      deletedPublishLogs: deletedPublishLogs.length,
      deletedStyleProfiles: deletedStyleProfiles.length,
      deletedScheduledPosts: deletedScheduledPosts.length,
      detectedConflicts: _detectedConflictsInRun,
    );
  }

  Future<_PushBatch> _buildPushBatch() async {
    final sourceItems = await (_db.select(_db.sourceItems)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final projects = await (_db.select(_db.projects)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final posts = await (_db.select(_db.posts)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final bundles = await (_db.select(_db.bundles)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final drafts = await (_db.select(_db.drafts)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final variants = await (_db.select(_db.variants)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final publishLogs = await (_db.select(_db.publishLogs)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final styleProfiles = await (_db.select(_db.styleProfiles)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final scheduledPosts = await (_db.select(_db.scheduledPosts)
          ..where((t) => t.syncStatus.equals('dirty')))
        .get();
    final tombstones = await (_db.select(_db.syncTombstones)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    final deletesByEntityType = <String, List<String>>{
      'source_items': <String>[],
      'projects': <String>[],
      'posts': <String>[],
      'bundles': <String>[],
      'drafts': <String>[],
      'variants': <String>[],
      'publish_logs': <String>[],
      'style_profiles': <String>[],
      'scheduled_posts': <String>[],
    };
    final pushedTombstoneIds = <String>[];
    for (final tombstone in tombstones) {
      final entityDeletes = deletesByEntityType[tombstone.entityType];
      if (entityDeletes == null) {
        continue;
      }
      entityDeletes.add(tombstone.entityId);
      pushedTombstoneIds.add(tombstone.id);
    }
    final pushedDeletedSourceItems =
        deletesByEntityType['source_items']!.length;
    final pushedDeletedProjects = deletesByEntityType['projects']!.length;
    final pushedDeletedPosts = deletesByEntityType['posts']!.length;
    final pushedDeletedBundles = deletesByEntityType['bundles']!.length;
    final pushedDeletedDrafts = deletesByEntityType['drafts']!.length;
    final pushedDeletedVariants = deletesByEntityType['variants']!.length;
    final pushedDeletedPublishLogs =
        deletesByEntityType['publish_logs']!.length;
    final pushedDeletedStyleProfiles =
        deletesByEntityType['style_profiles']!.length;
    final pushedDeletedScheduledPosts =
        deletesByEntityType['scheduled_posts']!.length;

    final payload = {
      'upserts': {
        'source_items': sourceItems
            .map(
              (row) => {
                'id': row.id,
                'type': row.type,
                'url': row.url,
                'title': row.title,
                'user_note': row.userNote,
                'tags': row.tags,
                'bundle_id': row.bundleId,
                'post_id': row.postId,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'projects': projects
            .map(
              (row) => {
                'id': row.id,
                'name': row.name,
                'description': row.description,
                'status': row.status,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'posts': posts
            .map(
              (row) => {
                'id': row.id,
                'project_id': row.projectId,
                'title': row.title,
                'content_type': row.contentType,
                'goal': row.goal,
                'audience': row.audience,
                'cover_image_url': row.coverImageUrl,
                'cover_image_data_uri': row.coverImageDataUri,
                'cover_image_prompt': row.coverImagePrompt,
                'status': row.status,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'bundles': bundles
            .map(
              (row) => {
                'id': row.id,
                'name': row.name,
                'anchor_type': row.anchorType,
                'anchor_ref': row.anchorRef,
                'canonical_draft_id': row.canonicalDraftId,
                'post_id': row.postId,
                'related_variant_ids': row.relatedVariantIds,
                'notes': row.notes,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'drafts': drafts
            .map(
              (row) => {
                'id': row.id,
                'canonical_markdown': row.canonicalMarkdown,
                'intent': row.intent,
                'tone': row.tone,
                'punchiness': row.punchiness,
                'emoji_level': row.emojiLevel,
                'audience': row.audience,
                'post_id': row.postId,
                'content_type': row.contentType,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'variants': variants
            .map(
              (row) => {
                'id': row.id,
                'draft_id': row.draftId,
                'platform': row.platform,
                'text': row.body,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'publish_logs': publishLogs
            .map(
              (row) => {
                'id': row.id,
                'variant_id': row.variantId,
                'post_id': row.postId,
                'platform': row.platform,
                'mode': row.mode,
                'status': row.status,
                'external_url': row.externalUrl,
                'posted_at': row.postedAt?.toIso8601String(),
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'style_profiles': styleProfiles
            .map(
              (row) => {
                'id': row.id,
                'voice_name': row.voiceName,
                'casual_formal': row.casualFormal,
                'punchiness': row.punchiness,
                'emoji_level': row.emojiLevel,
                'banned_phrases': row.bannedPhrases,
                'personal_traits': row.personalTraits,
                'differentiation_points': row.differentiationPoints,
                'custom_prompt': row.customPrompt,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'scheduled_posts': scheduledPosts
            .map(
              (row) => {
                'id': row.id,
                'variant_id': row.variantId,
                'post_id': row.postId,
                'platform': row.platform,
                'content': row.content,
                'scheduled_for': row.scheduledFor.toIso8601String(),
                'status': row.status,
                'external_url': row.externalUrl,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      },
      'deletes': deletesByEntityType,
    };

    return _PushBatch(
      payload: payload,
      sourceItemIds: sourceItems.map((r) => r.id).toList(growable: false),
      projectIds: projects.map((r) => r.id).toList(growable: false),
      postIds: posts.map((r) => r.id).toList(growable: false),
      bundleIds: bundles.map((r) => r.id).toList(growable: false),
      draftIds: drafts.map((r) => r.id).toList(growable: false),
      variantIds: variants.map((r) => r.id).toList(growable: false),
      publishLogIds: publishLogs.map((r) => r.id).toList(growable: false),
      styleProfileIds: styleProfiles.map((r) => r.id).toList(growable: false),
      scheduledPostIds: scheduledPosts.map((r) => r.id).toList(growable: false),
      tombstoneIds: pushedTombstoneIds,
      deletedSourceItems: pushedDeletedSourceItems,
      deletedProjects: pushedDeletedProjects,
      deletedPosts: pushedDeletedPosts,
      deletedBundles: pushedDeletedBundles,
      deletedDrafts: pushedDeletedDrafts,
      deletedVariants: pushedDeletedVariants,
      deletedPublishLogs: pushedDeletedPublishLogs,
      deletedStyleProfiles: pushedDeletedStyleProfiles,
      deletedScheduledPosts: pushedDeletedScheduledPosts,
    );
  }

  Future<void> _markPushedRowsClean(_PushBatch batch) async {
    await _db.transaction(() async {
      if (batch.sourceItemIds.isNotEmpty) {
        await (_db.update(_db.sourceItems)
              ..where((t) => t.id.isIn(batch.sourceItemIds)))
            .write(const SourceItemsCompanion(syncStatus: Value('clean')));
      }
      if (batch.projectIds.isNotEmpty) {
        await (_db.update(_db.projects)
              ..where((t) => t.id.isIn(batch.projectIds)))
            .write(const ProjectsCompanion(syncStatus: Value('clean')));
      }
      if (batch.postIds.isNotEmpty) {
        await (_db.update(_db.posts)..where((t) => t.id.isIn(batch.postIds)))
            .write(const PostsCompanion(syncStatus: Value('clean')));
      }
      if (batch.bundleIds.isNotEmpty) {
        await (_db.update(_db.bundles)
              ..where((t) => t.id.isIn(batch.bundleIds)))
            .write(const BundlesCompanion(syncStatus: Value('clean')));
      }
      if (batch.draftIds.isNotEmpty) {
        await (_db.update(_db.drafts)..where((t) => t.id.isIn(batch.draftIds)))
            .write(const DraftsCompanion(syncStatus: Value('clean')));
      }
      if (batch.variantIds.isNotEmpty) {
        await (_db.update(_db.variants)
              ..where((t) => t.id.isIn(batch.variantIds)))
            .write(const VariantsCompanion(syncStatus: Value('clean')));
      }
      if (batch.publishLogIds.isNotEmpty) {
        await (_db.update(_db.publishLogs)
              ..where((t) => t.id.isIn(batch.publishLogIds)))
            .write(const PublishLogsCompanion(syncStatus: Value('clean')));
      }
      if (batch.styleProfileIds.isNotEmpty) {
        await (_db.update(_db.styleProfiles)
              ..where((t) => t.id.isIn(batch.styleProfileIds)))
            .write(const StyleProfilesCompanion(syncStatus: Value('clean')));
      }
      if (batch.scheduledPostIds.isNotEmpty) {
        await (_db.update(_db.scheduledPosts)
              ..where((t) => t.id.isIn(batch.scheduledPostIds)))
            .write(const ScheduledPostsCompanion(syncStatus: Value('clean')));
      }
      if (batch.tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.syncTombstones)
              ..where((t) => t.id.isIn(batch.tombstoneIds)))
            .go();
      }
    });
  }

  Future<void> resolveConflictKeepRemote(String conflictId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.syncConflicts)..where((t) => t.id.equals(conflictId)))
        .write(
      SyncConflictsCompanion(
        resolvedAt: Value(now),
        resolution: const Value('remote'),
      ),
    );
  }

  Future<void> resolveConflictUseLocal(String conflictId) async {
    final conflict = await (_db.select(_db.syncConflicts)
          ..where((t) => t.id.equals(conflictId)))
        .getSingleOrNull();
    if (conflict == null) {
      return;
    }

    final payload = conflict.localPayload;
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      switch (conflict.entityType) {
        case 'source_items':
          await _db.into(_db.sourceItems).insertOnConflictUpdate(
                SourceItemsCompanion(
                  id: Value(conflict.entityId),
                  type: Value((payload['type'] as String?) ?? 'note'),
                  url: Value(payload['url'] as String?),
                  title: Value(payload['title'] as String?),
                  userNote: Value(payload['user_note'] as String?),
                  tags: Value(_asStringList(payload['tags'])),
                  bundleId: Value(payload['bundle_id'] as String?),
                  postId: Value(payload['post_id'] as String?),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'projects':
          await _db.into(_db.projects).insertOnConflictUpdate(
                ProjectsCompanion(
                  id: Value(conflict.entityId),
                  name:
                      Value((payload['name'] as String?) ?? 'Untitled project'),
                  description: Value(payload['description'] as String?),
                  status: Value((payload['status'] as String?) ?? 'active'),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'posts':
          await _db.into(_db.posts).insertOnConflictUpdate(
                PostsCompanion(
                  id: Value(conflict.entityId),
                  projectId: Value(payload['project_id'] as String?),
                  title:
                      Value((payload['title'] as String?) ?? 'Untitled post'),
                  contentType: Value(
                      normalizeContentType(payload['content_type'] as String?)),
                  goal: Value(payload['goal'] as String?),
                  audience: Value(payload['audience'] as String?),
                  coverImageUrl: Value(payload['cover_image_url'] as String?),
                  coverImageDataUri:
                      Value(payload['cover_image_data_uri'] as String?),
                  coverImagePrompt:
                      Value(payload['cover_image_prompt'] as String?),
                  status: Value((payload['status'] as String?) ?? 'active'),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'bundles':
          await _db.into(_db.bundles).insertOnConflictUpdate(
                BundlesCompanion(
                  id: Value(conflict.entityId),
                  name:
                      Value((payload['name'] as String?) ?? 'Untitled bundle'),
                  anchorType:
                      Value((payload['anchor_type'] as String?) ?? 'youtube'),
                  anchorRef: Value(payload['anchor_ref'] as String?),
                  canonicalDraftId:
                      Value(payload['canonical_draft_id'] as String?),
                  postId: Value(payload['post_id'] as String?),
                  relatedVariantIds:
                      Value(_asStringList(payload['related_variant_ids'])),
                  notes: Value(payload['notes'] as String?),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'drafts':
          await _db.into(_db.drafts).insertOnConflictUpdate(
                DraftsCompanion(
                  id: Value(conflict.entityId),
                  canonicalMarkdown:
                      Value((payload['canonical_markdown'] as String?) ?? ''),
                  intent: Value(payload['intent'] as String?),
                  tone: Value(_asDouble(payload['tone'])),
                  punchiness: Value(_asDouble(payload['punchiness'])),
                  emojiLevel: Value(payload['emoji_level'] as String?),
                  audience: Value(payload['audience'] as String?),
                  postId: Value(payload['post_id'] as String?),
                  contentType: Value(
                      normalizeContentType(payload['content_type'] as String?)),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'variants':
          final draftId = payload['draft_id'] as String?;
          if (draftId == null || draftId.isEmpty) {
            break;
          }
          await _db.into(_db.variants).insertOnConflictUpdate(
                VariantsCompanion(
                  id: Value(conflict.entityId),
                  draftId: Value(draftId),
                  platform: Value((payload['platform'] as String?) ?? ''),
                  body: Value((payload['text'] as String?) ?? ''),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'publish_logs':
          await _db.into(_db.publishLogs).insertOnConflictUpdate(
                PublishLogsCompanion(
                  id: Value(conflict.entityId),
                  variantId: Value(payload['variant_id'] as String?),
                  postId: Value(payload['post_id'] as String?),
                  platform: Value((payload['platform'] as String?) ?? ''),
                  mode: Value((payload['mode'] as String?) ?? 'assisted'),
                  status: Value((payload['status'] as String?) ?? 'draft'),
                  externalUrl: Value(payload['external_url'] as String?),
                  postedAt: Value(_asDateTime(payload['posted_at'])),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'style_profiles':
          await _db.into(_db.styleProfiles).insertOnConflictUpdate(
                StyleProfilesCompanion(
                  id: Value(conflict.entityId),
                  voiceName:
                      Value((payload['voice_name'] as String?) ?? 'David'),
                  casualFormal:
                      Value(_asDouble(payload['casual_formal']) ?? 0.6),
                  punchiness: Value(_asDouble(payload['punchiness']) ?? 0.7),
                  emojiLevel:
                      Value((payload['emoji_level'] as String?) ?? 'light'),
                  bannedPhrases:
                      Value(_asStringList(payload['banned_phrases'])),
                  personalTraits:
                      Value(_asStringList(payload['personal_traits'])),
                  differentiationPoints:
                      Value(_asStringList(payload['differentiation_points'])),
                  customPrompt: Value(payload['custom_prompt'] as String?),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
        case 'scheduled_posts':
          await _db.into(_db.scheduledPosts).insertOnConflictUpdate(
                ScheduledPostsCompanion(
                  id: Value(conflict.entityId),
                  variantId: Value(payload['variant_id'] as String?),
                  postId: Value(payload['post_id'] as String?),
                  platform: Value((payload['platform'] as String?) ?? ''),
                  content: Value((payload['content'] as String?) ?? ''),
                  scheduledFor:
                      Value(_asDateTime(payload['scheduled_for']) ?? now),
                  status: Value((payload['status'] as String?) ?? 'queued'),
                  externalUrl: Value(payload['external_url'] as String?),
                  createdAt: Value(_asDateTime(payload['created_at']) ?? now),
                  updatedAt: Value(now),
                  syncStatus: const Value('dirty'),
                ),
              );
          break;
      }

      await (_db.update(_db.syncConflicts)
            ..where((t) => t.id.equals(conflictId)))
          .write(
        SyncConflictsCompanion(
          resolvedAt: Value(now),
          resolution: const Value('local'),
        ),
      );
    });
  }

  Future<void> _applySourceItemUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.sourceItems)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'source_items',
            entityId: id,
            localPayload: _sourceItemToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.sourceItems).insertOnConflictUpdate(
            SourceItemsCompanion(
              id: Value(id),
              type: Value((row['type'] as String?) ?? 'note'),
              url: Value(row['url'] as String?),
              title: Value(row['title'] as String?),
              userNote: Value(row['user_note'] as String?),
              tags: Value(_asStringList(row['tags'])),
              bundleId: Value(row['bundle_id'] as String?),
              postId: Value(row['post_id'] as String?),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyProjectUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.projects)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'projects',
            entityId: id,
            localPayload: _projectToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.projects).insertOnConflictUpdate(
            ProjectsCompanion(
              id: Value(id),
              name: Value((row['name'] as String?) ?? 'Untitled project'),
              description: Value(row['description'] as String?),
              status: Value((row['status'] as String?) ?? 'active'),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyPostUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.posts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'posts',
            entityId: id,
            localPayload: _postToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.posts).insertOnConflictUpdate(
            PostsCompanion(
              id: Value(id),
              projectId: Value(row['project_id'] as String?),
              title: Value((row['title'] as String?) ?? 'Untitled post'),
              contentType:
                  Value(normalizeContentType(row['content_type'] as String?)),
              goal: Value(row['goal'] as String?),
              audience: Value(row['audience'] as String?),
              coverImageUrl: Value(row['cover_image_url'] as String?),
              coverImageDataUri: Value(row['cover_image_data_uri'] as String?),
              coverImagePrompt: Value(row['cover_image_prompt'] as String?),
              status: Value((row['status'] as String?) ?? 'active'),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyBundleUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.bundles)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'bundles',
            entityId: id,
            localPayload: _bundleToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.bundles).insertOnConflictUpdate(
            BundlesCompanion(
              id: Value(id),
              name: Value((row['name'] as String?) ?? 'Untitled bundle'),
              anchorType: Value((row['anchor_type'] as String?) ?? 'youtube'),
              anchorRef: Value(row['anchor_ref'] as String?),
              canonicalDraftId: Value(row['canonical_draft_id'] as String?),
              postId: Value(row['post_id'] as String?),
              relatedVariantIds:
                  Value(_asStringList(row['related_variant_ids'])),
              notes: Value(row['notes'] as String?),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyDraftUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.drafts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'drafts',
            entityId: id,
            localPayload: _draftToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.drafts).insertOnConflictUpdate(
            DraftsCompanion(
              id: Value(id),
              canonicalMarkdown:
                  Value((row['canonical_markdown'] as String?) ?? ''),
              intent: Value(row['intent'] as String?),
              tone: Value(_asDouble(row['tone'])),
              punchiness: Value(_asDouble(row['punchiness'])),
              emojiLevel: Value(row['emoji_level'] as String?),
              audience: Value(row['audience'] as String?),
              postId: Value(row['post_id'] as String?),
              contentType:
                  Value(normalizeContentType(row['content_type'] as String?)),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyVariantUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      final draftId = row['draft_id'] as String?;
      if (id == null || id.isEmpty || draftId == null || draftId.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.variants)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'variants',
            entityId: id,
            localPayload: _variantToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.variants).insertOnConflictUpdate(
            VariantsCompanion(
              id: Value(id),
              draftId: Value(draftId),
              platform: Value((row['platform'] as String?) ?? ''),
              body: Value((row['text'] as String?) ?? ''),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyPublishLogUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.publishLogs)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'publish_logs',
            entityId: id,
            localPayload: _publishLogToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.publishLogs).insertOnConflictUpdate(
            PublishLogsCompanion(
              id: Value(id),
              variantId: Value(row['variant_id'] as String?),
              postId: Value(row['post_id'] as String?),
              platform: Value((row['platform'] as String?) ?? ''),
              mode: Value((row['mode'] as String?) ?? 'assisted'),
              status: Value((row['status'] as String?) ?? 'draft'),
              externalUrl: Value(row['external_url'] as String?),
              postedAt: Value(_asDateTime(row['posted_at'])),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyStyleProfileUpserts(
      List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.styleProfiles)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'style_profiles',
            entityId: id,
            localPayload: _styleProfileToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.styleProfiles).insertOnConflictUpdate(
            StyleProfilesCompanion(
              id: Value(id),
              voiceName: Value((row['voice_name'] as String?) ?? 'David'),
              casualFormal: Value(_asDouble(row['casual_formal']) ?? 0.6),
              punchiness: Value(_asDouble(row['punchiness']) ?? 0.7),
              emojiLevel: Value((row['emoji_level'] as String?) ?? 'light'),
              bannedPhrases: Value(_asStringList(row['banned_phrases'])),
              personalTraits: Value(_asStringList(row['personal_traits'])),
              differentiationPoints:
                  Value(_asStringList(row['differentiation_points'])),
              customPrompt: Value(row['custom_prompt'] as String?),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyScheduledPostUpserts(
      List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      final incomingUpdatedAt = _asDateTime(row['updated_at']) ?? now;
      final existing = await (_db.select(_db.scheduledPosts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.syncStatus == 'dirty') {
        if (incomingUpdatedAt.isAfter(existing.updatedAt)) {
          await _recordConflict(
            entityType: 'scheduled_posts',
            entityId: id,
            localPayload: _scheduledPostToPayload(existing),
            remotePayload: row,
          );
        } else {
          continue;
        }
      }

      await _db.into(_db.scheduledPosts).insertOnConflictUpdate(
            ScheduledPostsCompanion(
              id: Value(id),
              variantId: Value(row['variant_id'] as String?),
              postId: Value(row['post_id'] as String?),
              platform: Value((row['platform'] as String?) ?? ''),
              content: Value((row['content'] as String?) ?? ''),
              scheduledFor: Value(_asDateTime(row['scheduled_for']) ?? now),
              status: Value((row['status'] as String?) ?? 'queued'),
              externalUrl: Value(row['external_url'] as String?),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(incomingUpdatedAt),
              syncStatus: const Value('clean'),
            ),
          );
    }
  }

  Future<void> _applyDeletes({
    required List<String> deletedSourceItems,
    required List<String> deletedProjects,
    required List<String> deletedPosts,
    required List<String> deletedBundles,
    required List<String> deletedDrafts,
    required List<String> deletedVariants,
    required List<String> deletedPublishLogs,
    required List<String> deletedStyleProfiles,
    required List<String> deletedScheduledPosts,
  }) async {
    final removedVariantIds = <String>{};
    final removedDraftIds = <String>{};

    if (deletedSourceItems.isNotEmpty) {
      await (_db.delete(_db.sourceItems)
            ..where((t) => t.id.isIn(deletedSourceItems)))
          .go();
    }

    if (deletedPosts.isNotEmpty) {
      await (_db.update(_db.sourceItems)
            ..where((t) => t.postId.isIn(deletedPosts)))
          .write(const SourceItemsCompanion(postId: Value(null)));
      await (_db.update(_db.drafts)..where((t) => t.postId.isIn(deletedPosts)))
          .write(const DraftsCompanion(postId: Value(null)));
      await (_db.update(_db.publishLogs)
            ..where((t) => t.postId.isIn(deletedPosts)))
          .write(const PublishLogsCompanion(postId: Value(null)));
      await (_db.update(_db.scheduledPosts)
            ..where((t) => t.postId.isIn(deletedPosts)))
          .write(const ScheduledPostsCompanion(postId: Value(null)));
      await (_db.update(_db.bundles)..where((t) => t.postId.isIn(deletedPosts)))
          .write(const BundlesCompanion(postId: Value(null)));
      await (_db.delete(_db.posts)..where((t) => t.id.isIn(deletedPosts))).go();
    }

    if (deletedProjects.isNotEmpty) {
      await (_db.update(_db.posts)
            ..where((t) => t.projectId.isIn(deletedProjects)))
          .write(const PostsCompanion(projectId: Value(null)));
      await (_db.delete(_db.projects)..where((t) => t.id.isIn(deletedProjects)))
          .go();
    }

    if (deletedBundles.isNotEmpty) {
      await (_db.update(_db.sourceItems)
            ..where((t) => t.bundleId.isIn(deletedBundles)))
          .write(const SourceItemsCompanion(bundleId: Value(null)));
      await (_db.delete(_db.bundles)..where((t) => t.id.isIn(deletedBundles)))
          .go();
    }

    if (deletedScheduledPosts.isNotEmpty) {
      await (_db.delete(_db.scheduledPosts)
            ..where((t) => t.id.isIn(deletedScheduledPosts)))
          .go();
    }

    if (deletedPublishLogs.isNotEmpty) {
      await (_db.delete(_db.publishLogs)
            ..where((t) => t.id.isIn(deletedPublishLogs)))
          .go();
    }

    if (deletedVariants.isNotEmpty) {
      removedVariantIds.addAll(deletedVariants);
      await (_db.update(_db.publishLogs)
            ..where((t) => t.variantId.isIn(deletedVariants)))
          .write(const PublishLogsCompanion(variantId: Value(null)));
      await (_db.update(_db.scheduledPosts)
            ..where((t) => t.variantId.isIn(deletedVariants)))
          .write(const ScheduledPostsCompanion(variantId: Value(null)));
      await (_db.delete(_db.variants)..where((t) => t.id.isIn(deletedVariants)))
          .go();
    }

    if (deletedDrafts.isNotEmpty) {
      removedDraftIds.addAll(deletedDrafts);
      final linkedVariants = await (_db.select(_db.variants)
            ..where((t) => t.draftId.isIn(deletedDrafts)))
          .get();
      final linkedVariantIds = linkedVariants.map((v) => v.id).toList();
      if (linkedVariantIds.isNotEmpty) {
        removedVariantIds.addAll(linkedVariantIds);
        await (_db.update(_db.publishLogs)
              ..where((t) => t.variantId.isIn(linkedVariantIds)))
            .write(const PublishLogsCompanion(variantId: Value(null)));
        await (_db.update(_db.scheduledPosts)
              ..where((t) => t.variantId.isIn(linkedVariantIds)))
            .write(const ScheduledPostsCompanion(variantId: Value(null)));
        await (_db.delete(_db.variants)
              ..where((t) => t.id.isIn(linkedVariantIds)))
            .go();
      }
      await (_db.delete(_db.drafts)..where((t) => t.id.isIn(deletedDrafts)))
          .go();
    }

    if (removedVariantIds.isNotEmpty || removedDraftIds.isNotEmpty) {
      final now = DateTime.now().toUtc();
      final bundles = await _db.select(_db.bundles).get();
      for (final bundle in bundles) {
        final nextRelatedIds = bundle.relatedVariantIds
            .where((id) => !removedVariantIds.contains(id))
            .toList(growable: false);
        final relatedChanged =
            nextRelatedIds.length != bundle.relatedVariantIds.length;
        final canonicalChanged = bundle.canonicalDraftId != null &&
            removedDraftIds.contains(bundle.canonicalDraftId!);
        if (!relatedChanged && !canonicalChanged) {
          continue;
        }
        await (_db.update(_db.bundles)..where((t) => t.id.equals(bundle.id)))
            .write(
          BundlesCompanion(
            relatedVariantIds: Value(nextRelatedIds),
            canonicalDraftId:
                canonicalChanged ? const Value(null) : const Value.absent(),
            updatedAt: Value(now),
            syncStatus: const Value('clean'),
          ),
        );
      }
    }

    if (deletedStyleProfiles.isNotEmpty) {
      await (_db.delete(_db.styleProfiles)
            ..where((t) => t.id.isIn(deletedStyleProfiles)))
          .go();
    }
  }

  Future<void> _recordConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> remotePayload,
  }) async {
    _detectedConflictsInRun += 1;
    final now = DateTime.now().toUtc();
    final conflictId = 'conflict:$entityType:$entityId';
    await _db.into(_db.syncConflicts).insertOnConflictUpdate(
          SyncConflictsCompanion(
            id: Value(conflictId),
            entityType: Value(entityType),
            entityId: Value(entityId),
            localPayload: Value(localPayload),
            remotePayload: Value(remotePayload),
            detectedAt: Value(now),
            resolvedAt: const Value(null),
            resolution: const Value(null),
          ),
        );
  }

  Map<String, dynamic> _sourceItemToPayload(SourceItem row) {
    return {
      'id': row.id,
      'type': row.type,
      'url': row.url,
      'title': row.title,
      'user_note': row.userNote,
      'tags': row.tags,
      'bundle_id': row.bundleId,
      'post_id': row.postId,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _projectToPayload(Project row) {
    return {
      'id': row.id,
      'name': row.name,
      'description': row.description,
      'status': row.status,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _postToPayload(Post row) {
    return {
      'id': row.id,
      'project_id': row.projectId,
      'title': row.title,
      'content_type': row.contentType,
      'goal': row.goal,
      'audience': row.audience,
      'cover_image_url': row.coverImageUrl,
      'cover_image_data_uri': row.coverImageDataUri,
      'cover_image_prompt': row.coverImagePrompt,
      'status': row.status,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _bundleToPayload(Bundle row) {
    return {
      'id': row.id,
      'name': row.name,
      'anchor_type': row.anchorType,
      'anchor_ref': row.anchorRef,
      'canonical_draft_id': row.canonicalDraftId,
      'post_id': row.postId,
      'related_variant_ids': row.relatedVariantIds,
      'notes': row.notes,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _draftToPayload(Draft row) {
    return {
      'id': row.id,
      'canonical_markdown': row.canonicalMarkdown,
      'intent': row.intent,
      'tone': row.tone,
      'punchiness': row.punchiness,
      'emoji_level': row.emojiLevel,
      'audience': row.audience,
      'post_id': row.postId,
      'content_type': row.contentType,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _variantToPayload(Variant row) {
    return {
      'id': row.id,
      'draft_id': row.draftId,
      'platform': row.platform,
      'text': row.body,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _publishLogToPayload(PublishLog row) {
    return {
      'id': row.id,
      'variant_id': row.variantId,
      'post_id': row.postId,
      'platform': row.platform,
      'mode': row.mode,
      'status': row.status,
      'external_url': row.externalUrl,
      'posted_at': row.postedAt?.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _styleProfileToPayload(StyleProfile row) {
    return {
      'id': row.id,
      'voice_name': row.voiceName,
      'casual_formal': row.casualFormal,
      'punchiness': row.punchiness,
      'emoji_level': row.emojiLevel,
      'banned_phrases': row.bannedPhrases,
      'personal_traits': row.personalTraits,
      'differentiation_points': row.differentiationPoints,
      'custom_prompt': row.customPrompt,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _scheduledPostToPayload(ScheduledPost row) {
    return {
      'id': row.id,
      'variant_id': row.variantId,
      'post_id': row.postId,
      'platform': row.platform,
      'content': row.content,
      'scheduled_for': row.scheduledFor.toIso8601String(),
      'status': row.status,
      'external_url': row.externalUrl,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}

class _PushBatch {
  const _PushBatch({
    required this.payload,
    required this.sourceItemIds,
    required this.projectIds,
    required this.postIds,
    required this.bundleIds,
    required this.draftIds,
    required this.variantIds,
    required this.publishLogIds,
    required this.styleProfileIds,
    required this.scheduledPostIds,
    required this.tombstoneIds,
    required this.deletedSourceItems,
    required this.deletedProjects,
    required this.deletedPosts,
    required this.deletedBundles,
    required this.deletedDrafts,
    required this.deletedVariants,
    required this.deletedPublishLogs,
    required this.deletedStyleProfiles,
    required this.deletedScheduledPosts,
  });

  final Map<String, dynamic> payload;
  final List<String> sourceItemIds;
  final List<String> projectIds;
  final List<String> postIds;
  final List<String> bundleIds;
  final List<String> draftIds;
  final List<String> variantIds;
  final List<String> publishLogIds;
  final List<String> styleProfileIds;
  final List<String> scheduledPostIds;
  final List<String> tombstoneIds;
  final int deletedSourceItems;
  final int deletedProjects;
  final int deletedPosts;
  final int deletedBundles;
  final int deletedDrafts;
  final int deletedVariants;
  final int deletedPublishLogs;
  final int deletedStyleProfiles;
  final int deletedScheduledPosts;
}
