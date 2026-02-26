import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';
import '../utils/content_type_utils.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  String _tagFilter = 'all';
  bool _creatingDraft = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceItemsAsync = ref.watch(scopedSourceItemsStreamProvider);
    final bundlesAsync = ref.watch(bundlesStreamProvider);
    final activePost = ref.watch(activePostProvider);
    final scopedBundles = _scopeBundles(
      bundlesAsync.valueOrNull ?? const <Bundle>[],
      activePostId: activePost?.id,
    );

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Library',
        actions: [
          sourceItemsAsync.maybeWhen(
            data: (items) {
              final filtered = items.where((item) => _matches(item)).toList();
              return IconButton(
                tooltip: 'Create draft from filtered',
                onPressed:
                    _creatingDraft || activePost == null || filtered.isEmpty
                        ? null
                        : () => _createDraftFromSources(
                              filtered,
                              activePost: activePost,
                            ),
                icon: _creatingDraft
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.note_add_outlined),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Export filtered CSV',
            onPressed: _exportFilteredCsv,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: sourceItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  PostScopeHeader(showGlobalToggle: true),
                  SizedBox(height: 16),
                  Expanded(
                      child: Center(child: Text('No sources in library yet.'))),
                ],
              ),
            );
          }

          final tags = <String>{for (final item in items) ...item.tags}.toList()
            ..sort();
          final filtered = items.where((item) => _matches(item)).toList();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: PostScopeHeader(showGlobalToggle: true),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: 'Search sources',
                    hintText: 'title, url, note, tag',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _queryController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (tags.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _tagFilter == 'all',
                          onSelected: (_) {
                            setState(() {
                              _tagFilter = 'all';
                            });
                          },
                        ),
                      ),
                      for (final tag in tags)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('#$tag'),
                            selected: _tagFilter == tag,
                            onSelected: (_) {
                              setState(() {
                                _tagFilter = tag;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No sources match current filters.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final subtitle = _itemSubtitle(item);
                          return ListTile(
                            title: Text(_itemTitle(item)),
                            subtitle: Text(subtitle),
                            trailing: PopupMenuButton<_LibraryAction>(
                              onSelected: (action) async {
                                final messenger = ScaffoldMessenger.of(context);
                                if (action == _LibraryAction.createDraft) {
                                  if (activePost == null) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Create/select a post workspace first'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  await _createDraftFromSources(
                                    <SourceItem>[item],
                                    activePost: activePost,
                                  );
                                  return;
                                }
                                if (action == _LibraryAction.openUrl) {
                                  final url = item.url?.trim();
                                  if (url == null || url.isEmpty) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('No URL on this source'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  final uri = Uri.tryParse(url);
                                  if (uri == null) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid URL'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  final launched = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!launched && mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Unable to open URL'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (action == _LibraryAction.copyUrl) {
                                  final url = item.url?.trim();
                                  if (url == null || url.isEmpty) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('No URL on this source'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  await Clipboard.setData(
                                    ClipboardData(text: url),
                                  );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('URL copied'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (action == _LibraryAction.moveToActivePost) {
                                  if (activePost == null) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('No active post selected'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  await ref.read(sourceRepoProvider).assignPost(
                                        sourceId: item.id,
                                        postId: activePost.id,
                                      );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Moved source to ${activePost.title}',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (action == _LibraryAction.makeGlobal) {
                                  await ref.read(sourceRepoProvider).assignPost(
                                        sourceId: item.id,
                                        postId: null,
                                      );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Source marked global'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (action == _LibraryAction.addToBundle) {
                                  await _showAssignBundleDialog(
                                    item: item,
                                    bundles: scopedBundles,
                                  );
                                  return;
                                }
                                if (action == _LibraryAction.clearBundle) {
                                  await ref
                                      .read(sourceRepoProvider)
                                      .assignBundle(
                                        sourceId: item.id,
                                        bundleId: null,
                                      );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text('Removed from bundle')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) {
                                return [
                                  const PopupMenuItem(
                                    value: _LibraryAction.createDraft,
                                    child: Text('Create draft'),
                                  ),
                                  const PopupMenuItem(
                                    value: _LibraryAction.openUrl,
                                    child: Text('Open URL'),
                                  ),
                                  const PopupMenuItem(
                                    value: _LibraryAction.copyUrl,
                                    child: Text('Copy URL'),
                                  ),
                                  if (activePost != null &&
                                      item.postId != activePost.id)
                                    const PopupMenuItem(
                                      value: _LibraryAction.moveToActivePost,
                                      child: Text('Move to active post'),
                                    ),
                                  if (item.postId != null &&
                                      item.postId!.isNotEmpty)
                                    const PopupMenuItem(
                                      value: _LibraryAction.makeGlobal,
                                      child: Text('Mark as global source'),
                                    ),
                                  const PopupMenuItem(
                                    value: _LibraryAction.addToBundle,
                                    child: Text('Add to bundle'),
                                  ),
                                  if (item.bundleId != null &&
                                      item.bundleId!.isNotEmpty)
                                    const PopupMenuItem(
                                      value: _LibraryAction.clearBundle,
                                      child: Text('Clear bundle'),
                                    ),
                                ];
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading library: $error')),
      ),
    );
  }

  void _onQueryChanged() {
    final next = _queryController.text.trim();
    if (next == _query) {
      return;
    }
    setState(() {
      _query = next;
    });
  }

  bool _matches(SourceItem item) {
    if (_tagFilter != 'all' && !item.tags.contains(_tagFilter)) {
      return false;
    }
    if (_query.isEmpty) {
      return true;
    }
    final needle = _query.toLowerCase();
    final haystack = <String>[
      item.type,
      item.title ?? '',
      item.url ?? '',
      item.userNote ?? '',
      ...item.tags,
    ].join('\n').toLowerCase();
    return haystack.contains(needle);
  }

  String _itemTitle(SourceItem item) {
    if (item.title != null && item.title!.trim().isNotEmpty) {
      return item.title!.trim();
    }
    if (item.userNote != null && item.userNote!.trim().isNotEmpty) {
      return item.userNote!.trim().split('\n').first;
    }
    if (item.url != null && item.url!.trim().isNotEmpty) {
      return item.url!.trim();
    }
    return item.type.toUpperCase();
  }

  String _itemSubtitle(SourceItem item) {
    final parts = <String>[
      item.type,
      if (item.postId != null && item.postId!.isNotEmpty)
        'post:${item.postId!.substring(0, 8)}',
      if (item.bundleId != null && item.bundleId!.isNotEmpty)
        'bundle:${item.bundleId!.substring(0, 8)}',
      if (item.url != null && item.url!.trim().isNotEmpty) item.url!.trim(),
      if (item.userNote != null && item.userNote!.trim().isNotEmpty)
        item.userNote!.trim(),
      if (item.tags.isNotEmpty) item.tags.map((tag) => '#$tag').join(' '),
    ];
    return parts.join('  •  ');
  }

  Future<void> _createDraftFromSources(
    List<SourceItem> items, {
    required Post activePost,
  }) async {
    if (items.isEmpty) {
      return;
    }

    setState(() {
      _creatingDraft = true;
    });

    final sourceIds = items.map((item) => item.id).toList(growable: false);
    final draftRepo = ref.read(draftRepoProvider);
    final styleProfile =
        await ref.read(styleProfileRepoProvider).getOrCreateDefault();
    final tone = styleProfile.casualFormal.clamp(0.0, 1.0).toDouble();
    final punchiness = styleProfile.punchiness.clamp(0.0, 1.0).toDouble();

    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/from_sources'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'source_ids': sourceIds,
              'source_materials': items
                  .map(
                    (item) => {
                      'id': item.id,
                      'type': item.type,
                      'title': item.title,
                      'url': item.url,
                      'note': item.userNote,
                      'tags': item.tags,
                    },
                  )
                  .toList(growable: false),
              'intent': _intentForContentType(activePost.contentType),
              'tone': tone,
              'punchiness': punchiness,
              'audience': activePost.audience ?? 'builders',
              'length_target': 'short',
              'post_id': activePost.id,
              'post_title': activePost.title,
              'post_goal': activePost.goal,
              'content_type': activePost.contentType,
              'style_traits': styleProfile.personalTraits,
              'differentiation_points': styleProfile.differentiationPoints,
              'personal_prompt': styleProfile.customPrompt,
              'banned_phrases': styleProfile.bannedPhrases,
            }),
          );

      String draftId = '';
      String canonicalMarkdown = '';
      var llmUsed = false;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        draftId = (parsed['draft_id'] as String?)?.trim() ?? '';
        canonicalMarkdown =
            (parsed['canonical_markdown'] as String?)?.trim() ?? '';
        llmUsed = parsed['llm_used'] as bool? ?? false;
        if (canonicalMarkdown.isEmpty) {
          canonicalMarkdown = _buildLocalDraftTemplate(
            items,
            contentType: activePost.contentType,
          );
        }
      }

      if (draftId.isEmpty) {
        draftId = await draftRepo.createDraft(
          canonicalMarkdown: _buildLocalDraftTemplate(
            items,
            contentType: activePost.contentType,
          ),
          intent: _intentForContentType(activePost.contentType),
          tone: tone,
          punchiness: punchiness,
          audience: activePost.audience ?? 'builders',
          postId: activePost.id,
          contentType: activePost.contentType,
        );
      } else {
        await draftRepo.createDraft(
          id: draftId,
          canonicalMarkdown: canonicalMarkdown,
          intent: _intentForContentType(activePost.contentType),
          tone: tone,
          punchiness: punchiness,
          audience: activePost.audience ?? 'builders',
          postId: activePost.id,
          contentType: activePost.contentType,
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            llmUsed
                ? 'Draft generated from ${items.length} library sources.'
                : 'Draft template created from ${items.length} library sources.',
          ),
        ),
      );
      context.go(
        Uri(path: '/compose', queryParameters: {'draftId': draftId}).toString(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed creating draft: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingDraft = false;
        });
      }
    }
  }

  String _buildLocalDraftTemplate(
    List<SourceItem> items, {
    required String contentType,
  }) {
    final sourceHint = items.map((item) => item.id).take(3).join(', ');
    final outlineHint = draftOutlineHintForContentType(contentType);
    return '''
# Draft

Hook: Quick synthesis from selected library evidence.

- Source IDs: ${sourceHint.isEmpty ? 'none' : sourceHint}
$outlineHint

Takeaway: Start with one clear claim, then expand.
''';
  }

  String _intentForContentType(String contentType) {
    return intentForContentType(contentType);
  }

  Future<void> _showAssignBundleDialog({
    required SourceItem item,
    required List<Bundle> bundles,
  }) async {
    if (bundles.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bundles found. Create one first.')),
      );
      return;
    }
    String selectedBundleId = item.bundleId ?? bundles.first.id;
    final chosenBundleId = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Assign to bundle'),
              content: DropdownButtonFormField<String>(
                value: selectedBundleId,
                items: bundles
                    .map(
                      (bundle) => DropdownMenuItem(
                        value: bundle.id,
                        child: Text(bundle.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setLocalState(() {
                    selectedBundleId = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selectedBundleId),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
    if (chosenBundleId == null) {
      return;
    }
    await ref.read(sourceRepoProvider).assignBundle(
          sourceId: item.id,
          bundleId: chosenBundleId,
        );
    if (!mounted) {
      return;
    }
    final chosen = bundles.firstWhere((b) => b.id == chosenBundleId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to bundle: ${chosen.name}')),
    );
  }

  Future<void> _exportFilteredCsv() async {
    final items = ref.read(scopedSourceItemsStreamProvider).valueOrNull;
    if (items == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Library still loading')),
      );
      return;
    }
    final filtered =
        items.where((item) => _matches(item)).toList(growable: false);
    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filtered rows to export')),
      );
      return;
    }

    final lines = <String>[
      'id,type,title,url,user_note,tags,post_id,bundle_id,created_at,updated_at',
      ...filtered.map((item) {
        return [
          _csv(item.id),
          _csv(item.type),
          _csv(item.title ?? ''),
          _csv(item.url ?? ''),
          _csv(item.userNote ?? ''),
          _csv(item.tags.join('|')),
          _csv(item.postId ?? ''),
          _csv(item.bundleId ?? ''),
          _csv(item.createdAt.toUtc().toIso8601String()),
          _csv(item.updatedAt.toUtc().toIso8601String()),
        ].join(',');
      }),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filtered.length} library rows as CSV')),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<Bundle> _scopeBundles(
    List<Bundle> bundles, {
    required String? activePostId,
  }) {
    if (activePostId == null || activePostId.isEmpty) {
      return bundles;
    }
    return bundles
        .where(
            (bundle) => bundle.postId == null || bundle.postId == activePostId)
        .toList(growable: false);
  }
}

enum _LibraryAction {
  createDraft,
  openUrl,
  copyUrl,
  moveToActivePost,
  makeGlobal,
  addToBundle,
  clearBundle,
}
