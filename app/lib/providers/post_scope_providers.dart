import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import 'repo_providers.dart';

final activeProjectIdProvider = StateProvider<String?>((ref) => null);

final activePostIdProvider = StateProvider<String?>((ref) => null);

final includeGlobalSourcesProvider = StateProvider<bool>((ref) => true);

final includeProjectSourcesProvider = StateProvider<bool>((ref) => true);

final expandedProjectIdsProvider = StateProvider<Set<String>>((ref) {
  return <String>{};
});

final rememberedPostIdsByProjectProvider =
    StateProvider<Map<String, String>>((ref) {
  return <String, String>{};
});

void _expandProjectId(WidgetRef ref, String projectId) {
  final current = ref.read(expandedProjectIdsProvider);
  if (current.contains(projectId)) {
    return;
  }
  ref.read(expandedProjectIdsProvider.notifier).state = <String>{
    ...current,
    projectId,
  };
}

void rememberPostForProject(
  WidgetRef ref, {
  required String projectId,
  required String postId,
}) {
  if (projectId.isEmpty || postId.isEmpty) {
    return;
  }
  final current = ref.read(rememberedPostIdsByProjectProvider);
  if (current[projectId] == postId) {
    return;
  }
  ref.read(rememberedPostIdsByProjectProvider.notifier).state =
      <String, String>{
    ...current,
    projectId: postId,
  };
}

void removeRememberedPostForProject(
  WidgetRef ref, {
  required String projectId,
  required String postId,
}) {
  final current = ref.read(rememberedPostIdsByProjectProvider);
  if (current[projectId] != postId) {
    return;
  }
  final next = <String, String>{...current}..remove(projectId);
  ref.read(rememberedPostIdsByProjectProvider.notifier).state = next;
}

void setActiveProjectSelection(
  WidgetRef ref, {
  required String projectId,
  String? postId,
  bool useRememberedPostIfPostIdMissing = true,
  bool expandProject = true,
}) {
  ref.read(activeProjectIdProvider.notifier).state = projectId;

  var resolvedPostId = postId;
  if ((resolvedPostId == null || resolvedPostId.isEmpty) &&
      useRememberedPostIfPostIdMissing) {
    resolvedPostId = ref.read(rememberedPostIdsByProjectProvider)[projectId];
  }

  ref.read(activePostIdProvider.notifier).state =
      (resolvedPostId == null || resolvedPostId.isEmpty)
          ? null
          : resolvedPostId;

  if (resolvedPostId != null && resolvedPostId.isNotEmpty) {
    rememberPostForProject(
      ref,
      projectId: projectId,
      postId: resolvedPostId,
    );
  }

  if (expandProject) {
    _expandProjectId(ref, projectId);
  }
}

void setActivePostSelection(
  WidgetRef ref, {
  required String projectId,
  required String postId,
  bool expandProject = true,
}) {
  ref.read(activeProjectIdProvider.notifier).state = projectId;
  ref.read(activePostIdProvider.notifier).state = postId;
  rememberPostForProject(ref, projectId: projectId, postId: postId);
  if (expandProject) {
    _expandProjectId(ref, projectId);
  }
}

void clearProjectSelectionState(WidgetRef ref, String projectId) {
  final remembered = <String, String>{
    ...ref.read(rememberedPostIdsByProjectProvider),
  }..remove(projectId);
  ref.read(rememberedPostIdsByProjectProvider.notifier).state = remembered;

  final expanded = <String>{...ref.read(expandedProjectIdsProvider)}
    ..remove(projectId);
  ref.read(expandedProjectIdsProvider.notifier).state = expanded;

  if (ref.read(activeProjectIdProvider) == projectId) {
    ref.read(activeProjectIdProvider.notifier).state = null;
    ref.read(activePostIdProvider.notifier).state = null;
  }
}

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
  if (selectedId != null && selectedId.isNotEmpty) {
    for (final post in posts) {
      if (post.id == selectedId) {
        return post;
      }
    }
  }

  final activeProjectId = ref.watch(activeProjectProvider)?.id;
  if (activeProjectId != null && activeProjectId.isNotEmpty) {
    final rememberedId =
        ref.watch(rememberedPostIdsByProjectProvider)[activeProjectId];
    if (rememberedId != null && rememberedId.isNotEmpty) {
      for (final post in posts) {
        if (post.id == rememberedId) {
          return post;
        }
      }
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
