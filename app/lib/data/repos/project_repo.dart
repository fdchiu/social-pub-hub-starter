import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class ProjectRepo {
  ProjectRepo(this._db);

  final AppDatabase _db;

  Stream<List<Project>> watchProjects() {
    final query = _db.select(_db.projects)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  Future<Project?> getProjectById(String projectId) {
    final query = _db.select(_db.projects)
      ..where((t) => t.id.equals(projectId));
    return query.getSingleOrNull();
  }

  Future<String> createProject({
    required String name,
    String? description,
    String status = 'active',
  }) async {
    final id = generateEntityId();
    final now = DateTime.now().toUtc();
    await _db.into(_db.projects).insert(
          ProjectsCompanion.insert(
            id: id,
            name: name.trim(),
            description: Value(description?.trim().isEmpty ?? true
                ? null
                : description?.trim()),
            status: Value(status),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );
    return id;
  }

  Future<void> updateProject({
    required String projectId,
    required String name,
    String? description,
    String? status,
  }) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(projectId)))
        .write(
      ProjectsCompanion(
        name: Value(name.trim()),
        description: Value(
          description?.trim().isEmpty ?? true ? null : description?.trim(),
        ),
        status: status == null ? const Value.absent() : Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }
}
