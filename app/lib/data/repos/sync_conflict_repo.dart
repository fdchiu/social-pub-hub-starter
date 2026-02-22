import 'package:drift/drift.dart';

import '../db/app_db.dart';

class SyncConflictRepo {
  SyncConflictRepo(this._db);

  final AppDatabase _db;

  Stream<List<SyncConflict>> watchOpenConflicts() {
    final query = _db.select(_db.syncConflicts)
      ..where((t) => t.resolvedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]);
    return query.watch();
  }

  Future<SyncConflict?> getById(String id) {
    final query = _db.select(_db.syncConflicts)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }
}
