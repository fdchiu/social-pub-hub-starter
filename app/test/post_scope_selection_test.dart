import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_pub_hub/data/db/app_db.dart';
import 'package:social_pub_hub/providers/post_scope_providers.dart';

void main() {
  group('activePostProvider', () {
    test('uses selected post id when it exists in scoped posts', () async {
      final project = _project('project_1');
      final posts = <Post>[
        _post('post_a', projectId: project.id),
        _post('post_b', projectId: project.id),
      ];

      final container = ProviderContainer(
        overrides: [
          activeProjectProvider.overrideWith((ref) => project),
          scopedPostsStreamProvider.overrideWith((ref) => Stream.value(posts)),
        ],
      );
      addTearDown(container.dispose);

      container.read(activePostIdProvider.notifier).state = 'post_a';
      container.read(rememberedPostIdsByProjectProvider.notifier).state =
          <String, String>{project.id: 'post_b'};

      await container.read(scopedPostsStreamProvider.future);
      expect(container.read(activePostProvider)?.id, 'post_a');
    });

    test('uses remembered post when selected post id is invalid', () async {
      final project = _project('project_1');
      final posts = <Post>[
        _post('post_a', projectId: project.id),
        _post('post_b', projectId: project.id),
      ];

      final container = ProviderContainer(
        overrides: [
          activeProjectProvider.overrideWith((ref) => project),
          scopedPostsStreamProvider.overrideWith((ref) => Stream.value(posts)),
        ],
      );
      addTearDown(container.dispose);

      container.read(activePostIdProvider.notifier).state = 'missing_post';
      container.read(rememberedPostIdsByProjectProvider.notifier).state =
          <String, String>{project.id: 'post_b'};

      await container.read(scopedPostsStreamProvider.future);
      expect(container.read(activePostProvider)?.id, 'post_b');
    });

    test('falls back to first post when no selected or remembered post exists',
        () async {
      final project = _project('project_1');
      final posts = <Post>[
        _post('post_a', projectId: project.id),
        _post('post_b', projectId: project.id),
      ];

      final container = ProviderContainer(
        overrides: [
          activeProjectProvider.overrideWith((ref) => project),
          scopedPostsStreamProvider.overrideWith((ref) => Stream.value(posts)),
        ],
      );
      addTearDown(container.dispose);

      container.read(activePostIdProvider.notifier).state = 'missing_post';
      container.read(rememberedPostIdsByProjectProvider.notifier).state =
          <String, String>{project.id: 'missing_post'};

      await container.read(scopedPostsStreamProvider.future);
      expect(container.read(activePostProvider)?.id, 'post_a');
    });
  });
}

Project _project(String id) {
  final now = DateTime.utc(2026, 2, 27, 12, 0);
  return Project(
    id: id,
    name: 'Project $id',
    status: 'active',
    createdAt: now,
    updatedAt: now,
    syncStatus: 'dirty',
  );
}

Post _post(String id, {required String projectId}) {
  final now = DateTime.utc(2026, 2, 27, 12, 0);
  return Post(
    id: id,
    projectId: projectId,
    title: 'Post $id',
    contentType: 'general_post',
    status: 'active',
    createdAt: now,
    updatedAt: now,
    syncStatus: 'dirty',
  );
}
