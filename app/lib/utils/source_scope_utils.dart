import '../data/db/app_db.dart';

enum SourceScopeLevel {
  global,
  project,
  post,
}

SourceScopeLevel sourceScopeForItem(SourceItem item) {
  final postId = item.postId?.trim();
  if (postId != null && postId.isNotEmpty) {
    return SourceScopeLevel.post;
  }
  final projectId = item.projectId?.trim();
  if (projectId != null && projectId.isNotEmpty) {
    return SourceScopeLevel.project;
  }
  return SourceScopeLevel.global;
}

String sourceScopeKey(SourceScopeLevel scope) {
  return switch (scope) {
    SourceScopeLevel.global => 'global',
    SourceScopeLevel.project => 'project',
    SourceScopeLevel.post => 'post',
  };
}

String sourceScopeLabel(SourceScopeLevel scope) {
  return switch (scope) {
    SourceScopeLevel.global => 'Global',
    SourceScopeLevel.project => 'Project',
    SourceScopeLevel.post => 'Post',
  };
}

class SourceScopeAssignment {
  const SourceScopeAssignment({
    required this.scope,
    required this.projectId,
    required this.postId,
  });

  final SourceScopeLevel scope;
  final String? projectId;
  final String? postId;
}
