import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'converters/string_list_converter.dart';
import 'tables/drafts.dart';
import 'tables/publish_logs.dart';
import 'tables/source_items.dart';
import 'tables/style_profiles.dart';
import 'tables/variants.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    SourceItems,
    Drafts,
    Variants,
    PublishLogs,
    StyleProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
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
