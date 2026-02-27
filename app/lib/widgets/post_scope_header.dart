import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../utils/content_type_utils.dart';

class PostScopeHeader extends ConsumerWidget {
  const PostScopeHeader({
    super.key,
    this.showGlobalToggle = false,
    this.showManagementActions = false,
  });

  final bool showGlobalToggle;
  final bool showManagementActions;

  static const List<String> _contentTypeOptions = <String>[
    ...presetContentTypes,
    customContentTypeOption,
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
    final includeProject = ref.watch(includeProjectSourcesProvider);
    final activeProject = ref.watch(activeProjectProvider);

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

    if (activeProject != null && selectedProjectId != activeProject.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setActiveProjectSelection(ref, projectId: activeProject.id);
      });
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
        final projectId = activeProject?.id ?? activePost?.projectId;
        if (projectId == null || projectId.isEmpty) {
          ref.read(activePostIdProvider.notifier).state = activePost?.id;
          return;
        }
        setActivePostSelection(
          ref,
          projectId: projectId,
          postId: activePost!.id,
        );
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 860;
                final selector = Row(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: showManagementActions
                          ? DropdownButtonFormField<String>(
                              value: activeProject?.id,
                              items: projects
                                  .map(
                                    (project) => DropdownMenuItem(
                                      value: project.id,
                                      child: Text(project.name),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: projects.isEmpty
                                  ? null
                                  : (next) {
                                      if (next == null) {
                                        return;
                                      }
                                      setActiveProjectSelection(
                                        ref,
                                        projectId: next,
                                      );
                                    },
                              decoration: const InputDecoration(
                                labelText: 'Project scope',
                                isDense: true,
                              ),
                            )
                          : _buildReadOnlyScopeField(
                              label: 'Project scope',
                              value:
                                  activeProject?.name ?? 'No project selected',
                            ),
                    ),
                  ],
                );
                final actions = showManagementActions
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: () =>
                                _showCreateProjectDialog(context, ref),
                            child: const Text('New project'),
                          ),
                          IconButton(
                            tooltip: activeProject == null
                                ? 'Select project to edit'
                                : 'Edit project',
                            onPressed: activeProject == null
                                ? null
                                : () => _showEditProjectDialog(
                                      context,
                                      ref,
                                      project: activeProject,
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
                                      project: activeProject,
                                    ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      )
                    : FilledButton.tonalIcon(
                        onPressed: () => context.go('/projects'),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Project screen'),
                      );

                if (!compact) {
                  return Row(
                    children: [
                      Expanded(child: selector),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    selector,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actions,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (posts.isEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  final trailingAction = showManagementActions
                      ? FilledButton.tonal(
                          onPressed: () => _showCreatePostDialog(context, ref),
                          child: const Text('New post'),
                        )
                      : FilledButton.tonal(
                          onPressed: () => context.go('/projects'),
                          child: const Text('Manage posts'),
                        );

                  if (!compact) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('No posts in this project yet'),
                      subtitle: const Text(
                        'Create a post workspace to scope inbox and drafting.',
                      ),
                      trailing: trailingAction,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.article_outlined),
                        title: Text('No posts in this project yet'),
                        subtitle: Text(
                          'Create a post workspace to scope inbox and drafting.',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: trailingAction,
                      ),
                    ],
                  );
                },
              )
            else ...[
              Builder(
                builder: (context) {
                  final currentPost = activePost!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 860;
                          final selector = Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: showManagementActions
                                    ? DropdownButtonFormField<String>(
                                        value: currentPost.id,
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
                                          final projectId = activeProject?.id ??
                                              currentPost.projectId;
                                          if (projectId == null ||
                                              projectId.isEmpty) {
                                            ref
                                                .read(activePostIdProvider
                                                    .notifier)
                                                .state = next;
                                            return;
                                          }
                                          setActivePostSelection(
                                            ref,
                                            projectId: projectId,
                                            postId: next,
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Active post',
                                          isDense: true,
                                        ),
                                      )
                                    : _buildReadOnlyScopeField(
                                        label: 'Active post',
                                        value: currentPost.title,
                                      ),
                              ),
                            ],
                          );
                          final actions = showManagementActions
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _showCreatePostDialog(context, ref),
                                      child: const Text('New post'),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit post',
                                      onPressed: () => _showEditPostDialog(
                                        context,
                                        ref,
                                        post: currentPost,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete post',
                                      onPressed: () => _confirmDeletePost(
                                        context,
                                        ref,
                                        post: currentPost,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                )
                              : FilledButton.tonal(
                                  onPressed: () => context.go('/projects'),
                                  child: const Text('Manage in project screen'),
                                );

                          if (!compact) {
                            return Row(
                              children: [
                                Expanded(child: selector),
                                const SizedBox(width: 12),
                                actions,
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              selector,
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                              label: Text(
                                  'type: ${contentTypeDisplayLabel(currentPost.contentType)}')),
                          Chip(label: Text('status: ${currentPost.status}')),
                          if (currentPost.audience != null &&
                              currentPost.audience!.isNotEmpty)
                            Chip(
                                label:
                                    Text('audience: ${currentPost.audience}')),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
            if (showGlobalToggle) ...[
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Include project sources'),
                subtitle: const Text(
                  'Show project-level sources (shared across posts in this project)',
                ),
                value: includeProject,
                onChanged: (next) {
                  ref.read(includeProjectSourcesProvider.notifier).state = next;
                },
              ),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Include global sources'),
                subtitle: const Text(
                  'Show reusable sources (not tied to any project/post) together with current context',
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

  Widget _buildReadOnlyScopeField({
    required String label,
    required String value,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
    setActiveProjectSelection(
      ref,
      projectId: projectId,
      useRememberedPostIfPostIdMissing: false,
      expandProject: true,
    );
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
    final activeProjectId = ref.read(activeProjectIdProvider) ??
        ref.read(activeProjectProvider)?.id;
    final normalizedProjectId = activeProjectId?.trim();
    if (normalizedProjectId == null || normalizedProjectId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Select a project before creating a post')),
        );
      }
      return;
    }

    final titleController = TextEditingController();
    final goalController = TextEditingController();
    final audienceController = TextEditingController(text: 'builders');
    final customTypeController = TextEditingController();
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
                              child: Text(contentTypeOptionLabel(value)),
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
                    if (selectedType == customContentTypeOption) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Custom content type',
                          hintText: 'release_notes_guide',
                        ),
                      ),
                    ],
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
      customTypeController.dispose();
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
      customTypeController.dispose();
      return;
    }

    if (selectedType == customContentTypeOption &&
        customTypeController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom content type is required')),
        );
      }
      titleController.dispose();
      goalController.dispose();
      audienceController.dispose();
      customTypeController.dispose();
      return;
    }

    final resolvedContentType = resolveContentTypeInput(
      selectedOption: selectedType,
      customInput: customTypeController.text,
    );

    final postId = await ref.read(postRepoProvider).createPost(
          title: title,
          contentType: resolvedContentType,
          goal: goalController.text,
          audience: audienceController.text,
          projectId: normalizedProjectId,
        );
    setActivePostSelection(
      ref,
      projectId: normalizedProjectId,
      postId: postId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post workspace created')),
      );
    }

    titleController.dispose();
    goalController.dispose();
    audienceController.dispose();
    customTypeController.dispose();
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
    final customTypeController = TextEditingController(
      text: _contentTypeOptions.contains(post.contentType)
          ? ''
          : post.contentType,
    );
    var selectedType = _contentTypeOptions.contains(post.contentType)
        ? post.contentType
        : customContentTypeOption;
    var status = post.status;
    final availableProjects =
        ref.read(projectsStreamProvider).valueOrNull ?? const <Project>[];
    final existingProjectId = post.projectId?.trim();
    String? selectedProjectId = availableProjects
            .any((project) => project.id == existingProjectId)
        ? existingProjectId
        : (availableProjects.isNotEmpty ? availableProjects.first.id : null);

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
                      value: selectedType,
                      items: _contentTypeOptions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(contentTypeOptionLabel(value)),
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
                      decoration:
                          const InputDecoration(labelText: 'Content type'),
                    ),
                    if (selectedType == customContentTypeOption) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Custom content type',
                          hintText: 'release_notes_guide',
                        ),
                      ),
                    ],
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
                    if (availableProjects.isEmpty)
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.warning_amber_outlined),
                        title: Text('No project available'),
                        subtitle: Text(
                          'Create a project before saving this post.',
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedProjectId,
                        items: availableProjects
                            .map(
                              (project) => DropdownMenuItem(
                                value: project.id,
                                child: Text(project.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setLocalState(() {
                            selectedProjectId = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Project'),
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
      customTypeController.dispose();
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
      customTypeController.dispose();
      return;
    }

    if (selectedType == customContentTypeOption &&
        customTypeController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom content type is required')),
        );
      }
      titleController.dispose();
      goalController.dispose();
      audienceController.dispose();
      customTypeController.dispose();
      return;
    }

    final normalizedProjectId = selectedProjectId?.trim();
    if (normalizedProjectId == null || normalizedProjectId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project is required for a post')),
        );
      }
      titleController.dispose();
      goalController.dispose();
      audienceController.dispose();
      customTypeController.dispose();
      return;
    }

    final resolvedContentType = resolveContentTypeInput(
      selectedOption: selectedType,
      customInput: customTypeController.text,
    );

    await ref.read(postRepoProvider).updatePost(
          postId: post.id,
          title: title,
          contentType: resolvedContentType,
          goal: goalController.text,
          audience: audienceController.text,
          projectId: normalizedProjectId,
          status: status,
        );

    final previousProjectId = post.projectId?.trim();
    if (previousProjectId != null &&
        previousProjectId.isNotEmpty &&
        previousProjectId != normalizedProjectId) {
      removeRememberedPostForProject(
        ref,
        projectId: previousProjectId,
        postId: post.id,
      );
    }
    setActivePostSelection(
      ref,
      projectId: normalizedProjectId,
      postId: post.id,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
    }

    titleController.dispose();
    goalController.dispose();
    audienceController.dispose();
    customTypeController.dispose();
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
    clearProjectSelectionState(ref, project.id);
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
    final postProjectId = post.projectId;
    if (postProjectId != null && postProjectId.isNotEmpty) {
      removeRememberedPostForProject(
        ref,
        projectId: postProjectId,
        postId: post.id,
      );
    }
    if (ref.read(activePostIdProvider) == post.id) {
      ref.read(activePostIdProvider.notifier).state = null;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post workspace deleted')),
      );
    }
  }
}
