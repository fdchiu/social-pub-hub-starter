import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../utils/content_type_utils.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

enum _ProjectPane { overview, posts, settings }

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  _ProjectPane _pane = _ProjectPane.overview;

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(activeProjectProvider);
    final postsAsync = ref.watch(scopedPostsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Projects',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const PostScopeHeader(showManagementActions: true),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project workspace',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<_ProjectPane>(
                      segments: const [
                        ButtonSegment<_ProjectPane>(
                          value: _ProjectPane.overview,
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Overview'),
                        ),
                        ButtonSegment<_ProjectPane>(
                          value: _ProjectPane.posts,
                          icon: Icon(Icons.article_outlined),
                          label: Text('Posts'),
                        ),
                        ButtonSegment<_ProjectPane>(
                          value: _ProjectPane.settings,
                          icon: Icon(Icons.settings_outlined),
                          label: Text('Settings'),
                        ),
                      ],
                      selected: <_ProjectPane>{_pane},
                      onSelectionChanged: (next) {
                        if (next.isEmpty) {
                          return;
                        }
                        setState(() {
                          _pane = next.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            switch (_pane) {
              _ProjectPane.overview => _OverviewPane(
                  activeProject: activeProject, postsAsync: postsAsync),
              _ProjectPane.posts => _PostsPane(
                  activeProject: activeProject,
                  postsAsync: postsAsync,
                  activePostId: activePost?.id,
                ),
              _ProjectPane.settings =>
                _SettingsPane(activeProject: activeProject),
            },
          ],
        ),
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    required this.activeProject,
    required this.postsAsync,
  });

  final Project? activeProject;
  final AsyncValue<List<Post>> postsAsync;

  @override
  Widget build(BuildContext context) {
    if (activeProject == null) {
      return const _EmptyProjectCard(
        title: 'No project selected',
        description:
            'Create or choose a project above, then define posts inside that project.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            postsAsync.when(
              data: (posts) {
                final activeCount = posts
                    .where((post) => post.status.toLowerCase() == 'active')
                    .length;
                final withCoverCount = posts
                    .where((post) =>
                        (post.coverImageDataUri ?? '').trim().isNotEmpty ||
                        (post.coverImageUrl ?? '').trim().isNotEmpty)
                    .length;
                final typeCount = posts
                    .map((post) => post.contentType.trim())
                    .where((type) => type.isNotEmpty)
                    .toSet()
                    .length;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: 'Posts', value: '${posts.length}'),
                    _MetricChip(label: 'Active', value: '$activeCount'),
                    _MetricChip(label: 'With cover', value: '$withCoverCount'),
                    _MetricChip(label: 'Content types', value: '$typeCount'),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Failed loading posts: $error'),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Name', value: activeProject!.name),
            const SizedBox(height: 6),
            _DetailRow(label: 'Status', value: activeProject!.status),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Description',
              value: (activeProject!.description ?? '').trim().isEmpty
                  ? 'No description yet'
                  : activeProject!.description!.trim(),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Created',
              value: _formatDateTime(activeProject!.createdAt),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Updated',
              value: _formatDateTime(activeProject!.updatedAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsPane extends ConsumerWidget {
  const _PostsPane({
    required this.activeProject,
    required this.postsAsync,
    required this.activePostId,
  });

  final Project? activeProject;
  final AsyncValue<List<Post>> postsAsync;
  final String? activePostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activeProject == null) {
      return const _EmptyProjectCard(
        title: 'No project selected',
        description: 'Pick a project to view and switch post workspaces.',
      );
    }

    final allPostsAsync = ref.watch(postsStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Posts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const Text(
                    'No post workspaces yet. Use "New post" in the scope header.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: posts
                      .map(
                        (post) => _PostTile(
                          post: post,
                          isActive: activePostId == post.id,
                          onSelect: () {
                            setActivePostSelection(
                              ref,
                              projectId: activeProject!.id,
                              postId: post.id,
                            );
                          },
                          onOpenCompose: () {
                            setActivePostSelection(
                              ref,
                              projectId: activeProject!.id,
                              postId: post.id,
                            );
                            context.go('/compose');
                          },
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Failed loading posts: $error'),
            ),
            const SizedBox(height: 12),
            _buildUnassignedLegacySection(
              context,
              ref,
              allPostsAsync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnassignedLegacySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Post>> allPostsAsync,
  ) {
    return allPostsAsync.when(
      data: (allPosts) {
        final unassigned = allPosts
            .where((post) => (post.projectId ?? '').trim().isEmpty)
            .toList(growable: false);
        if (unassigned.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unassigned legacy posts',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Attach these posts to this project to bring them into the project-first flow.',
              ),
              const SizedBox(height: 8),
              for (final post in unassigned)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(contentTypeDisplayLabel(post.contentType)),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      final targetProjectId = activeProject!.id;
                      await ref.read(postRepoProvider).updatePost(
                            postId: post.id,
                            title: post.title,
                            contentType: post.contentType,
                            goal: post.goal,
                            audience: post.audience,
                            projectId: targetProjectId,
                            status: post.status,
                          );
                      setActivePostSelection(
                        ref,
                        projectId: targetProjectId,
                        postId: post.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Post moved to ${activeProject!.name}'),
                          ),
                        );
                      }
                    },
                    child: const Text('Attach'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Text('Failed loading legacy posts: $error'),
    );
  }
}

class _SettingsPane extends StatelessWidget {
  const _SettingsPane({required this.activeProject});

  final Project? activeProject;

  @override
  Widget build(BuildContext context) {
    if (activeProject == null) {
      return const _EmptyProjectCard(
        title: 'No project selected',
        description: 'Select a project to configure project-specific workflow.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen owns project/post management. Keep global app preferences in Settings.',
            ),
            const SizedBox(height: 10),
            const _DetailRow(
              label: 'Editing scope',
              value: 'Project and post metadata',
            ),
            const SizedBox(height: 6),
            const _DetailRow(
              label: 'Selection source',
              value: 'Sidebar project explorer',
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.tune),
              label: const Text('Open app settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.isActive,
    required this.onSelect,
    required this.onOpenCompose,
  });

  final Post post;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onOpenCompose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? const Color.fromRGBO(108, 124, 255, 0.45)
              : const Color.fromRGBO(255, 255, 255, 0.09),
        ),
        color: isActive
            ? const Color.fromRGBO(108, 124, 255, 0.10)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(
                            contentTypeDisplayLabel(post.contentType),
                          ),
                        ),
                        Chip(label: Text('status: ${post.status}')),
                        if ((post.audience ?? '').trim().isNotEmpty)
                          Chip(
                              label:
                                  Text('audience: ${post.audience!.trim()}')),
                        if (isActive) const Chip(label: Text('active')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onOpenCompose,
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Compose'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _EmptyProjectCard extends StatelessWidget {
  const _EmptyProjectCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final datePart =
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final timePart =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$datePart $timePart';
}
