import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import 'analytics_screen.dart';
import 'bundle_builder_screen.dart';
import 'bundle_publish_checklist_screen.dart';
import 'compose_screen.dart';
import 'history_screen.dart';
import 'hub_pages.dart';
import 'inbox_screen.dart';
import 'library_screen.dart';
import 'publish_checklist_screen.dart';
import 'project_screen.dart';
import 'publish_console_screen.dart';
import 'queue_screen.dart';
import 'settings_screen.dart';
import 'sync_conflicts_screen.dart';

const _bg = Color(0xFF0E0F14);
const _sidebar = Color(0xFF13141A);
const _border = Color.fromRGBO(255, 255, 255, 0.07);
const _text = Color(0xFFEDF0F7);
const _soft = Color(0xFF9CA3AF);
const _muted = Color(0xFF6B7280);
const _accent = Color(0xFF6C7CFF);
const _accent2 = Color(0xFFA78BFA);

class HubShellScreen extends StatelessWidget {
  const HubShellScreen({
    super.key,
    required this.currentPage,
    this.initialDraftId,
    this.initialBundleId,
    this.initialVariantId,
    this.initialPublishChecklistDraftId,
    this.initialHistoryPostId,
    this.initialHistoryPlatform,
    this.initialHistoryStatus,
    this.initialHistoryMode,
    this.initialHistoryWindow,
  });

  final HubPage currentPage;
  final String? initialDraftId;
  final String? initialBundleId;
  final String? initialVariantId;
  final String? initialPublishChecklistDraftId;
  final String? initialHistoryPostId;
  final String? initialHistoryPlatform;
  final String? initialHistoryStatus;
  final String? initialHistoryMode;
  final String? initialHistoryWindow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          _Sidebar(currentPage: currentPage),
          Expanded(
            child: ColoredBox(
              color: _bg,
              child: _buildPageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return switch (currentPage) {
      HubPage.projects => const ProjectScreen(),
      HubPage.inbox => const InboxScreen(),
      HubPage.library => const LibraryScreen(),
      HubPage.compose => ComposeScreen(initialDraftId: initialDraftId),
      HubPage.bundles => const BundleBuilderScreen(),
      HubPage.bundleChecklist => const BundlePublishChecklistScreen(),
      HubPage.publish => PublishConsoleScreen(initialBundleId: initialBundleId),
      HubPage.publishChecklist =>
        PublishChecklistScreen(initialDraftId: initialPublishChecklistDraftId),
      HubPage.queue => const QueueScreen(),
      HubPage.syncConflicts => const SyncConflictsScreen(),
      HubPage.history => HistoryScreen(
          initialVariantId: initialVariantId,
          initialPostId: initialHistoryPostId,
          initialPlatform: initialHistoryPlatform,
          initialStatus: initialHistoryStatus,
          initialMode: initialHistoryMode,
          initialWindow: initialHistoryWindow,
        ),
      HubPage.analytics => const AnalyticsScreen(),
      HubPage.settings => const SettingsScreen(),
    };
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.currentPage});

  final HubPage currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = <String, List<HubNavItem>>{};
    for (final item in hubNavItems) {
      sections.putIfAbsent(item.section, () => <HubNavItem>[]).add(item);
    }
    final projects =
        ref.watch(projectsStreamProvider).valueOrNull ?? const <Project>[];
    final scopedPosts =
        ref.watch(scopedPostsStreamProvider).valueOrNull ?? const <Post>[];
    final selectedProjectId = ref.watch(activeProjectIdProvider);
    final activeProject = ref.watch(activeProjectProvider);
    if (activeProject != null && selectedProjectId != activeProject.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeProjectIdProvider.notifier).state = activeProject.id;
      });
    }

    final activePost = ref.watch(activePostProvider);
    final sourceItems = ref.watch(scopedSourceItemsStreamProvider).valueOrNull;
    final bundles = _scopeBundles(
      ref.watch(bundlesStreamProvider).valueOrNull,
      activePostId: activePost?.id,
    );
    final queueItems = _scopeQueueItems(
      ref.watch(scheduledPostsStreamProvider).valueOrNull,
      activePostId: activePost?.id,
    );
    final conflicts = ref.watch(openSyncConflictsStreamProvider).valueOrNull;
    final integrations = ref.watch(integrationsProvider).maybeWhen(
          data: (rows) => rows,
          orElse: () => null,
        );

    _DynamicBadge countBadge(int? count) {
      if (count == null) {
        return const _DynamicBadge('…', HubBadgeTone.muted);
      }
      if (count == 0) {
        return const _DynamicBadge('0', HubBadgeTone.green);
      }
      return _DynamicBadge('$count', HubBadgeTone.red);
    }

    final badgeByPage = <HubPage, _DynamicBadge>{
      HubPage.projects: countBadge(projects.length),
      HubPage.inbox: countBadge(sourceItems?.length),
      HubPage.library: countBadge(sourceItems?.length),
      HubPage.bundles: countBadge(bundles?.length),
      HubPage.queue: countBadge(
        queueItems?.where((row) => row.status.toLowerCase() == 'queued').length,
      ),
      HubPage.syncConflicts: countBadge(conflicts?.length),
      HubPage.publish: integrations == null
          ? const _DynamicBadge('…', HubBadgeTone.muted)
          : integrations.any((row) => row.connected)
              ? const _DynamicBadge('On', HubBadgeTone.green)
              : const _DynamicBadge('Off', HubBadgeTone.amber),
    };

    return Container(
      width: 240,
      color: _sidebar,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: const Row(
              children: [
                _BrandIcon(),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Social Pub Hub',
                        style: TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'PRO WORKSPACE',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
              children: [
                _ProjectExplorer(
                  projects: projects,
                  scopedPosts: scopedPosts,
                  activeProjectId: activeProject?.id,
                  activePostId: activePost?.id,
                ),
                const SizedBox(height: 10),
                for (final section in sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Text(
                      section.key.toUpperCase(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  for (final item in section.value)
                    _NavRow(
                      item: item,
                      active: item.page == currentPage,
                      badge: badgeByPage[item.page],
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: _accent2,
                    child: Text(
                      'JM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jamie Morgan',
                          style: TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Content Manager',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Bundle>? _scopeBundles(
    List<Bundle>? bundles, {
    required String? activePostId,
  }) {
    if (bundles == null) {
      return null;
    }
    if (activePostId == null || activePostId.isEmpty) {
      return bundles;
    }
    return bundles
        .where(
            (bundle) => bundle.postId == null || bundle.postId == activePostId)
        .toList(growable: false);
  }

  List<ScheduledPost>? _scopeQueueItems(
    List<ScheduledPost>? queueItems, {
    required String? activePostId,
  }) {
    if (queueItems == null) {
      return null;
    }
    if (activePostId == null || activePostId.isEmpty) {
      return queueItems;
    }
    return queueItems
        .where((row) => row.postId == null || row.postId == activePostId)
        .toList(growable: false);
  }
}

class _ProjectExplorer extends ConsumerWidget {
  const _ProjectExplorer({
    required this.projects,
    required this.scopedPosts,
    required this.activeProjectId,
    required this.activePostId,
  });

  final List<Project> projects;
  final List<Post> scopedPosts;
  final String? activeProjectId;
  final String? activePostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PROJECTS',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .8,
                  ),
                ),
              ),
              IconButton(
                iconSize: 16,
                tooltip: 'New project',
                onPressed: () => _showQuickCreateProjectDialog(context, ref),
                icon: const Icon(Icons.add, color: _soft),
              ),
              IconButton(
                iconSize: 16,
                tooltip: 'Open project screen',
                onPressed: () => context.go('/projects'),
                icon: const Icon(Icons.settings_outlined, color: _soft),
              ),
            ],
          ),
          if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
              child: Text(
                'No projects yet',
                style: TextStyle(color: _soft, fontSize: 12),
              ),
            )
          else ...[
            for (final project in projects)
              _ProjectRow(
                project: project,
                active: activeProjectId == project.id,
                posts: activeProjectId == project.id
                    ? scopedPosts
                    : const <Post>[],
                activePostId: activePostId,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _showQuickCreateProjectDialog(
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
              width: 480,
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
                    decoration: const InputDecoration(labelText: 'Description'),
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
      context.go('/projects');
    }

    nameController.dispose();
    descriptionController.dispose();
  }
}

class _ProjectRow extends ConsumerWidget {
  const _ProjectRow({
    required this.project,
    required this.active,
    required this.posts,
    required this.activePostId,
  });

  final Project project;
  final bool active;
  final List<Post> posts;
  final String? activePostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            ref.read(activeProjectIdProvider.notifier).state = project.id;
            ref.read(activePostIdProvider.notifier).state = null;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: active ? const Color.fromRGBO(108, 124, 255, 0.16) : null,
              border: active
                  ? Border.all(color: const Color.fromRGBO(108, 124, 255, 0.24))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  active ? Icons.folder_open_outlined : Icons.folder_outlined,
                  size: 14,
                  color: active ? _text : _soft,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? _text : _soft,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (active && posts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: posts
                  .map(
                    (post) => InkWell(
                      onTap: () {
                        ref.read(activeProjectIdProvider.notifier).state =
                            project.id;
                        ref.read(activePostIdProvider.notifier).state = post.id;
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: activePostId == post.id
                              ? const Color.fromRGBO(108, 124, 255, 0.14)
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.article_outlined,
                                size: 12, color: _soft),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                post.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      activePostId == post.id ? _text : _soft,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.item,
    required this.active,
    this.badge,
  });

  final HubNavItem item;
  final bool active;
  final _DynamicBadge? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.page.route),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: active
              ? const LinearGradient(
                  colors: [
                    Color.fromRGBO(108, 124, 255, 0.18),
                    Color.fromRGBO(167, 139, 250, 0.10),
                  ],
                )
              : null,
          border: active
              ? Border.all(color: const Color.fromRGBO(108, 124, 255, 0.30))
              : null,
          color: active ? null : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              item.icon,
              style: TextStyle(color: active ? _accent : _soft, fontSize: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: active ? _text : _soft,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor(badge!.tone),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!.label,
                  style: TextStyle(
                    color: badgeTextColor(badge!.tone),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_accent, _accent2]),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text('📡', style: TextStyle(fontSize: 16)),
    );
  }
}

class _DynamicBadge {
  const _DynamicBadge(this.label, this.tone);

  final String label;
  final HubBadgeTone tone;
}
