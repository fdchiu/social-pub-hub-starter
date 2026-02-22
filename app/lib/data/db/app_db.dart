import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'converters/json_map_converter.dart';
import 'converters/string_list_converter.dart';
import 'tables/drafts.dart';
import 'tables/publish_logs.dart';
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
    StyleProfiles,
    SyncConflicts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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
