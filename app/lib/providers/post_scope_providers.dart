import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import 'repo_providers.dart';

final activeProjectIdProvider = StateProvider<String?>((ref) => null);

final activePostIdProvider = StateProvider<String?>((ref) => null);

final includeGlobalSourcesProvider = StateProvider<bool>((ref) => true);

final includeProjectSourcesProvider = StateProvider<bool>((ref) => true);

final activeProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsStreamProvider).valueOrNull;
  if (projects == null || projects.isEmpty) {
    return null;
  }
  final selectedId = ref.watch(activeProjectIdProvider);
  if (selectedId == null || selectedId.isEmpty) {
    return projects.first;
  }
  for (final project in projects) {
    if (project.id == selectedId) {
      return project;
    }
  }
  return projects.first;
});

final scopedPostsStreamProvider = StreamProvider<List<Post>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) {
    return Stream<List<Post>>.value(const <Post>[]);
  }
  return ref.watch(postRepoProvider).watchPosts(projectId: project.id);
});

final activePostProvider = Provider<Post?>((ref) {
  final posts = ref.watch(scopedPostsStreamProvider).valueOrNull;
  if (posts == null || posts.isEmpty) {
    return null;
  }
  final selectedId = ref.watch(activePostIdProvider);
  if (selectedId == null || selectedId.isEmpty) {
    return posts.first;
  }
  for (final post in posts) {
    if (post.id == selectedId) {
      return post;
    }
  }
  return posts.first;
});

final scopedSourceItemsStreamProvider = StreamProvider<List<SourceItem>>((ref) {
  final activeProject = ref.watch(activeProjectProvider);
  final activePost = ref.watch(activePostProvider);
  final includeGlobal = ref.watch(includeGlobalSourcesProvider);
  final includeProject = ref.watch(includeProjectSourcesProvider);
  return ref.watch(sourceRepoProvider).watchSourceItems(
        postId: activePost?.id,
        projectId: activeProject?.id,
        includeGlobal: includeGlobal,
        includeProject: includeProject,
      );
});

final scopedDraftsStreamProvider = StreamProvider<List<Draft>>((ref) {
  final activePost = ref.watch(activePostProvider);
  return ref
      .watch(draftRepoProvider)
      .watchRecentDrafts(postId: activePost?.id, limit: 50);
});
