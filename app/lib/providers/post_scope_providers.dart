import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import 'repo_providers.dart';

final activeProjectIdProvider = StateProvider<String?>((ref) => null);

final activePostIdProvider = StateProvider<String?>((ref) => null);

final includeGlobalSourcesProvider = StateProvider<bool>((ref) => true);

final activeProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsStreamProvider).valueOrNull;
  if (projects == null || projects.isEmpty) {
    return null;
  }
  final selectedId = ref.watch(activeProjectIdProvider);
  if (selectedId == null || selectedId.isEmpty) {
    return null;
  }
  for (final project in projects) {
    if (project.id == selectedId) {
      return project;
    }
  }
  return null;
});

final scopedPostsStreamProvider = StreamProvider<List<Post>>((ref) {
  final project = ref.watch(activeProjectProvider);
  return ref.watch(postRepoProvider).watchPosts(projectId: project?.id);
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
  final activePost = ref.watch(activePostProvider);
  final includeGlobal = ref.watch(includeGlobalSourcesProvider);
  return ref.watch(sourceRepoProvider).watchSourceItems(
        postId: activePost?.id,
        includeGlobal: includeGlobal,
      );
});

final scopedDraftsStreamProvider = StreamProvider<List<Draft>>((ref) {
  final activePost = ref.watch(activePostProvider);
  return ref
      .watch(draftRepoProvider)
      .watchRecentDrafts(postId: activePost?.id, limit: 50);
});
