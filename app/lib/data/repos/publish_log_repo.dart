import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class PublishLogRepo {
  PublishLogRepo(this._db);

  final AppDatabase _db;

  Stream<List<PublishLog>> watchPublishLogs() {
    final query = _db.select(_db.publishLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<String> createPublishLog({
    String? variantId,
    required String platform,
    required String mode,
    required String status,
    String? externalUrl,
    DateTime? postedAt,
  }) async {
    final id = generateEntityId();
    final now = DateTime.now().toUtc();

    await _db.into(_db.publishLogs).insert(
          PublishLogsCompanion.insert(
            id: id,
            platform: platform,
            mode: mode,
            status: Value(status),
            variantId: Value(variantId),
            externalUrl: Value(externalUrl),
            postedAt: Value(postedAt),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );

    return id;
  }
}
