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
    Bundles,
    Projects,
    Posts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(drafts, drafts.syncStatus);
            await m.addColumn(variants, variants.syncStatus);
            await m.addColumn(publishLogs, publishLogs.updatedAt);
            await m.addColumn(publishLogs, publishLogs.syncStatus);
            await m.addColumn(styleProfiles, styleProfiles.syncStatus);
          }
          if (from < 3) {
            await m.createTable(syncConflicts);
          }
          if (from < 4) {
            await m.createTable(bundles);
          }
          if (from < 5) {
            await m.addColumn(sourceItems, sourceItems.bundleId);
          }
          if (from < 6) {
            await m.addColumn(bundles, bundles.canonicalDraftId);
          }
          if (from < 7) {
            await m.createTable(scheduledPosts);
          }
          if (from < 8) {
            await m.createTable(projects);
            await m.createTable(posts);
            await m.addColumn(sourceItems, sourceItems.postId);
            await m.addColumn(drafts, drafts.postId);
            await m.addColumn(drafts, drafts.contentType);
            await m.addColumn(styleProfiles, styleProfiles.personalTraits);
            await m.addColumn(
                styleProfiles, styleProfiles.differentiationPoints);
            await m.addColumn(styleProfiles, styleProfiles.customPrompt);
          }
          if (from >= 8 && from < 9) {
            await m.addColumn(projects, projects.syncStatus);
            await m.addColumn(posts, posts.syncStatus);
          }
          if (from < 10) {
            await m.addColumn(publishLogs, publishLogs.postId);
            await m.addColumn(scheduledPosts, scheduledPosts.postId);
          }
          if (from < 11) {
            await m.addColumn(bundles, bundles.postId);
          }
          if (from < 12) {
            await m.addColumn(bundles, bundles.syncStatus);
          }
          if (from < 13) {
            await m.addColumn(sourceItems, sourceItems.syncStatus);
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
