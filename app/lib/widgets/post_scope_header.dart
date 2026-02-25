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
  static const List<String> _statusOptions = <String>[
    'active',
    'archived',
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
    Project? activeProject;
    if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
      for (final project in projects) {
        if (project.id == selectedProjectId) {
          activeProject = project;
          break;
        }
      }
    }

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
                const SizedBox(width: 8),
                IconButton(
                  tooltip: activeProject == null
                      ? 'Select project to edit'
                      : 'Edit project',
                  onPressed: activeProject == null
                      ? null
                      : () => _showEditProjectDialog(
                            context,
                            ref,
                            project: activeProject!,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: activeProject == null
                      ? 'Select project to delete'
                      : 'Delete project',
                  onPressed: activeProject == null
                      ? null
                      : () => _confirmDeleteProject(
                            context,
                            ref,
                            project: activeProject!,
                          ),
                  icon: const Icon(Icons.delete_outline),
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
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Edit post',
                    onPressed: () => _showEditPostDialog(
                      context,
                      ref,
                      post: activePost!,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete post',
                    onPressed: () => _confirmDeletePost(
                      context,
                      ref,
                      post: activePost!,
                    ),
                    icon: const Icon(Icons.delete_outline),
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

  Future<void> _showEditProjectDialog(
    BuildContext context,
    WidgetRef ref, {
    required Project project,
  }) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController =
        TextEditingController(text: project.description ?? '');
    var status = project.status;

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: Text('Edit project ${project.id.substring(0, 8)}'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Project name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          _statusOptions.contains(status) ? status : 'active',
                      items: _statusOptions
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
                          status = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
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
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldSave) {
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

    await ref.read(projectRepoProvider).updateProject(
          projectId: project.id,
          name: name,
          description: descriptionController.text,
          status: status,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project updated')),
      );
    }
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditPostDialog(
    BuildContext context,
    WidgetRef ref, {
    required Post post,
  }) async {
    final titleController = TextEditingController(text: post.title);
    final goalController = TextEditingController(text: post.goal ?? '');
    final audienceController = TextEditingController(text: post.audience ?? '');
    var contentType = post.contentType;
    var status = post.status;

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: Text('Edit post ${post.id.substring(0, 8)}'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _contentTypeOptions.contains(contentType)
                          ? contentType
                          : _contentTypeOptions.first,
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
                          contentType = value;
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: 'Content type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Goal'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: audienceController,
                      decoration: const InputDecoration(labelText: 'Audience'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          _statusOptions.contains(status) ? status : 'active',
                      items: _statusOptions
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
                          status = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
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
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldSave) {
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

    await ref.read(postRepoProvider).updatePost(
          postId: post.id,
          title: title,
          contentType: contentType,
          goal: goalController.text,
          audience: audienceController.text,
          projectId: post.projectId,
          status: status,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
    }

    titleController.dispose();
    goalController.dispose();
    audienceController.dispose();
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref, {
    required Project project,
  }) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete project?'),
            content: Text(
              'Delete "${project.name}" and unassign linked posts from this project?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

    await ref.read(projectRepoProvider).deleteProject(project.id);
    ref.read(activeProjectIdProvider.notifier).state = null;
    ref.read(activePostIdProvider.notifier).state = null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted')),
      );
    }
  }

  Future<void> _confirmDeletePost(
    BuildContext context,
    WidgetRef ref, {
    required Post post,
  }) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete post workspace?'),
            content: Text(
              'Delete "${post.title}" and unassign linked drafts, sources, queue rows, logs, and bundles from this post?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

    await ref.read(postRepoProvider).deletePost(post.id);
    ref.read(activePostIdProvider.notifier).state = null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post workspace deleted')),
      );
    }
  }
}
