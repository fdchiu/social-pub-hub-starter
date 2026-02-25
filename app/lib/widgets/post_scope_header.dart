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
    final postsAsync = ref.watch(postsStreamProvider);
    final selectedId = ref.watch(activePostIdProvider);
    final includeGlobal = ref.watch(includeGlobalSourcesProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('No posts yet'),
              subtitle: const Text(
                  'Create a post workspace to scope inbox and drafting.'),
              trailing: FilledButton.tonal(
                onPressed: () => _showCreatePostDialog(context, ref),
                child: const Text('New post'),
              ),
            ),
          );
        }

        Post? active;
        for (final post in posts) {
          if (post.id == selectedId) {
            active = post;
            break;
          }
        }
        active ??= posts.first;
        if (selectedId != active.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activePostIdProvider.notifier).state = active?.id;
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
                    const Icon(Icons.account_tree_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: active.id,
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
                    Chip(
                      label: Text('type: ${active.contentType}'),
                    ),
                    Chip(
                      label: Text('status: ${active.status}'),
                    ),
                    if (active.audience != null && active.audience!.isNotEmpty)
                      Chip(
                        label: Text('audience: ${active.audience}'),
                      ),
                  ],
                ),
                if (showGlobalToggle) ...[
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include global sources'),
                    subtitle: const Text(
                        'Show reusable sources (not tied to any post) together with current post sources'),
                    value: includeGlobal,
                    onChanged: (next) {
                      ref.read(includeGlobalSourcesProvider.notifier).state =
                          next;
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Failed loading posts: $error'),
    );
  }

  Future<void> _showCreatePostDialog(
      BuildContext context, WidgetRef ref) async {
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
