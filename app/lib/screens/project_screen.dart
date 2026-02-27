import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/post_scope_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    final postsAsync = ref.watch(scopedPostsStreamProvider);

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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (activeProject == null)
                      const Text('Create a project to unlock project settings.')
                    else ...[
                      Text('Name: ${activeProject.name}'),
                      const SizedBox(height: 4),
                      Text('Status: ${activeProject.status}'),
                      if (activeProject.description != null &&
                          activeProject.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                            'Description: ${activeProject.description!.trim()}'),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Use edit controls above to change project metadata. '
                        'Post creation and post edits are also managed on this screen.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posts in project',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    postsAsync.when(
                      data: (posts) {
                        if (posts.isEmpty) {
                          return const Text('No post workspaces yet.');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: posts
                              .map(
                                (post) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• ${post.title}'),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Text('Failed loading posts: $error'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
