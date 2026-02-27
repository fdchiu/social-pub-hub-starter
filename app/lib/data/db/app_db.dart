import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'converters/json_map_converter.dart';
import 'converters/string_list_converter.dart';
import 'tables/bundles.dart';
import 'tables/drafts.dart';
import 'tables/publish_logs.dart';
import 'tables/projects.dart';
import 'tables/posts.dart';
import 'tables/scheduled_posts.dart';
import 'tables/source_items.dart';
import 'tables/style_profiles.dart';
import 'tables/sync_conflicts.dart';
import 'tables/sync_tombstones.dart';
import 'tables/variants.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    SourceItems,
    Drafts,
    Variants,
    PublishLogs,
    ScheduledPosts,
    StyleProfiles,
    SyncConflicts,
    SyncTombstones,
    Bundles,
    Projects,
    Posts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          Future<void> addColumnIfMissing({
            required String tableName,
            required String columnName,
            required Future<void> Function() addColumn,
          }) async {
            final tableInfo =
                await customSelect('PRAGMA table_info("$tableName")').get();
            final exists =
                tableInfo.any((row) => row.data['name'] == columnName);
            if (exists) {
              return;
            }
            await addColumn();
          }

          if (from < 2) {
            await addColumnIfMissing(
              tableName: 'drafts',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(drafts, drafts.syncStatus),
            );
            await addColumnIfMissing(
              tableName: 'variants',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(variants, variants.syncStatus),
            );
            await addColumnIfMissing(
              tableName: 'publish_logs',
              columnName: 'updated_at',
              addColumn: () => m.addColumn(publishLogs, publishLogs.updatedAt),
            );
            await addColumnIfMissing(
              tableName: 'publish_logs',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(publishLogs, publishLogs.syncStatus),
            );
            await addColumnIfMissing(
              tableName: 'style_profiles',
              columnName: 'sync_status',
              addColumn: () =>
                  m.addColumn(styleProfiles, styleProfiles.syncStatus),
            );
          }
          if (from < 3) {
            await m.createTable(syncConflicts);
          }
          if (from < 4) {
            await m.createTable(bundles);
          }
          if (from < 5) {
            await addColumnIfMissing(
              tableName: 'source_items',
              columnName: 'bundle_id',
              addColumn: () => m.addColumn(sourceItems, sourceItems.bundleId),
            );
          }
          if (from < 6) {
            await addColumnIfMissing(
              tableName: 'bundles',
              columnName: 'canonical_draft_id',
              addColumn: () => m.addColumn(bundles, bundles.canonicalDraftId),
            );
          }
          if (from < 7) {
            await m.createTable(scheduledPosts);
          }
          if (from < 8) {
            await m.createTable(projects);
            await m.createTable(posts);
            await addColumnIfMissing(
              tableName: 'source_items',
              columnName: 'post_id',
              addColumn: () => m.addColumn(sourceItems, sourceItems.postId),
            );
            await addColumnIfMissing(
              tableName: 'drafts',
              columnName: 'post_id',
              addColumn: () => m.addColumn(drafts, drafts.postId),
            );
            await addColumnIfMissing(
              tableName: 'drafts',
              columnName: 'content_type',
              addColumn: () => m.addColumn(drafts, drafts.contentType),
            );
            await addColumnIfMissing(
              tableName: 'style_profiles',
              columnName: 'personal_traits',
              addColumn: () =>
                  m.addColumn(styleProfiles, styleProfiles.personalTraits),
            );
            await addColumnIfMissing(
              tableName: 'style_profiles',
              columnName: 'differentiation_points',
              addColumn: () => m.addColumn(
                  styleProfiles, styleProfiles.differentiationPoints),
            );
            await addColumnIfMissing(
              tableName: 'style_profiles',
              columnName: 'custom_prompt',
              addColumn: () =>
                  m.addColumn(styleProfiles, styleProfiles.customPrompt),
            );
          }
          if (from >= 8 && from < 9) {
            await addColumnIfMissing(
              tableName: 'projects',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(projects, projects.syncStatus),
            );
            await addColumnIfMissing(
              tableName: 'posts',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(posts, posts.syncStatus),
            );
          }
          if (from < 10) {
            await addColumnIfMissing(
              tableName: 'publish_logs',
              columnName: 'post_id',
              addColumn: () => m.addColumn(publishLogs, publishLogs.postId),
            );
            await addColumnIfMissing(
              tableName: 'scheduled_posts',
              columnName: 'post_id',
              addColumn: () =>
                  m.addColumn(scheduledPosts, scheduledPosts.postId),
            );
          }
          if (from < 11) {
            await addColumnIfMissing(
              tableName: 'bundles',
              columnName: 'post_id',
              addColumn: () => m.addColumn(bundles, bundles.postId),
            );
          }
          if (from < 12) {
            await addColumnIfMissing(
              tableName: 'bundles',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(bundles, bundles.syncStatus),
            );
          }
          if (from < 13) {
            await addColumnIfMissing(
              tableName: 'source_items',
              columnName: 'sync_status',
              addColumn: () => m.addColumn(sourceItems, sourceItems.syncStatus),
            );
          }
          if (from < 14) {
            await m.createTable(syncTombstones);
          }
          if (from < 15) {
            await addColumnIfMissing(
              tableName: 'posts',
              columnName: 'cover_image_url',
              addColumn: () => m.addColumn(posts, posts.coverImageUrl),
            );
            await addColumnIfMissing(
              tableName: 'posts',
              columnName: 'cover_image_data_uri',
              addColumn: () => m.addColumn(posts, posts.coverImageDataUri),
            );
            await addColumnIfMissing(
              tableName: 'posts',
              columnName: 'cover_image_prompt',
              addColumn: () => m.addColumn(posts, posts.coverImagePrompt),
            );
          }
          if (from < 16) {
            await addColumnIfMissing(
              tableName: 'source_items',
              columnName: 'project_id',
              addColumn: () => m.addColumn(sourceItems, sourceItems.projectId),
            );
            await customStatement('''
              UPDATE source_items
              SET project_id = (
                SELECT posts.project_id
                FROM posts
                WHERE posts.id = source_items.post_id
              )
              WHERE post_id IS NOT NULL
                AND (project_id IS NULL OR project_id = '')
            ''');
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'social_pub_hub',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationDocumentsDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
