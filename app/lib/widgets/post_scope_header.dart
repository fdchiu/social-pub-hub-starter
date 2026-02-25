import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';

class PostScopeHeader extends ConsumerWidget {
  const PostScopeHeader({
    super.key,
    this.showGlobalToggle = false,
  });

  final bool showGlobalToggle;

  static const List<String> _contentTypeOptions = <String>[
    'general_post',
    'coding_guide',
    'ai_tool_guide',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final postsAsync = ref.watch(scopedPostsStreamProvider);
    final selectedProjectId = ref.watch(activeProjectIdProvider);
    final selectedPostId = ref.watch(activePostIdProvider);
    final includeGlobal = ref.watch(includeGlobalSourcesProvider);

    if (projectsAsync.isLoading || postsAsync.isLoading) {
      return const LinearProgressIndicator();
    }
    if (projectsAsync.hasError) {
      return Text('Failed loading projects: ${projectsAsync.error}');
    }
    if (postsAsync.hasError) {
      return Text('Failed loading posts: ${postsAsync.error}');
    }

    final projects = projectsAsync.valueOrNull ?? const <Project>[];
    final posts = postsAsync.valueOrNull ?? const <Post>[];

    Post? activePost;
    for (final post in posts) {
      if (post.id == selectedPostId) {
        activePost = post;
        break;
      }
    }
    activePost ??= posts.isEmpty ? null : posts.first;
    if (activePost != null && selectedPostId != activePost.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activePostIdProvider.notifier).state = activePost?.id;
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedProjectId ?? '__all__',
                    items: [
                      const DropdownMenuItem(
                        value: '__all__',
                        child: Text('All projects'),
                      ),
                      ...projects.map(
                        (project) => DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      ),
                    ],
                    onChanged: (next) {
                      final normalized = next == '__all__' ? null : next;
                      ref.read(activeProjectIdProvider.notifier).state =
                          normalized;
                      ref.read(activePostIdProvider.notifier).state = null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Project scope',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => _showCreateProjectDialog(context, ref),
                  child: const Text('New project'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (posts.isEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: const Text('No posts in this scope'),
                subtitle: const Text(
                  'Create a post workspace to scope inbox and drafting.',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => _showCreatePostDialog(context, ref),
                  child: const Text('New post'),
                ),
              )
            else ...[
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: activePost!.id,
                      items: posts
                          .map(
                            (post) => DropdownMenuItem(
                              value: post.id,
                              child: Text(post.title),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (next) {
                        if (next == null) {
                          return;
                        }
                        ref.read(activePostIdProvider.notifier).state = next;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Active post',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: () => _showCreatePostDialog(context, ref),
                    child: const Text('New post'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('type: ${activePost.contentType}')),
                  Chip(label: Text('status: ${activePost.status}')),
                  if (activePost.audience != null &&
                      activePost.audience!.isNotEmpty)
                    Chip(label: Text('audience: ${activePost.audience}')),
                ],
              ),
            ],
            if (showGlobalToggle) ...[
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Include global sources'),
                subtitle: const Text(
                  'Show reusable sources (not tied to any post) together with current post sources',
                ),
                value: includeGlobal,
                onChanged: (next) {
                  ref.read(includeGlobalSourcesProvider.notifier).state = next;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateProjectDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Create project'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project name',
                      hintText: '2026 AI Guides',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Create'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldCreate) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project name is required')),
        );
      }
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final projectId = await ref.read(projectRepoProvider).createProject(
          name: name,
          description: descriptionController.text,
        );
    ref.read(activeProjectIdProvider.notifier).state = projectId;
    ref.read(activePostIdProvider.notifier).state = null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created')),
      );
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showCreatePostDialog(
      BuildContext context, WidgetRef ref) async {
    final activeProjectId = ref.read(activeProjectIdProvider);
    final titleController = TextEditingController();
    final goalController = TextEditingController();
    final audienceController = TextEditingController(text: 'builders');
    var selectedType = _contentTypeOptions.first;

    final shouldCreate = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: const Text('Create post workspace'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Post title',
                        hintText: 'Shipping SQLite sync on desktop',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: _contentTypeOptions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setLocalState(() {
                          selectedType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Content type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                        hintText:
                            'Explain setup + pitfalls + verification path',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: audienceController,
                      decoration: const InputDecoration(
                        labelText: 'Audience',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldCreate) {
      titleController.dispose();
      goalController.dispose();
      audienceController.dispose();
      return;
    }

    final title = titleController.text.trim();
    if (title.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post title is required')),
        );
      }
      titleController.dispose();
      goalController.dispose();
      audienceController.dispose();
      return;
    }

    final postId = await ref.read(postRepoProvider).createPost(
          title: title,
          contentType: selectedType,
          goal: goalController.text,
          audience: audienceController.text,
          projectId: activeProjectId,
        );
    ref.read(activePostIdProvider.notifier).state = postId;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post workspace created')),
      );
    }

    titleController.dispose();
    goalController.dispose();
    audienceController.dispose();
  }
}
