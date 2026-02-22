import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  String _tagFilter = 'all';

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
    final sourceItemsAsync = ref.watch(sourceItemsStreamProvider);
    final bundlesAsync = ref.watch(bundlesStreamProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Library',
      ),
      body: sourceItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No sources in library yet.'));
          }

          final tags = <String>{for (final item in items) ...item.tags}.toList()
            ..sort();
          final filtered = items.where((item) => _matches(item)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                          final bundles = bundlesAsync.valueOrNull;
                          return ListTile(
                            title: Text(_itemTitle(item)),
                            subtitle: Text(subtitle),
                            trailing: PopupMenuButton<_LibraryAction>(
                              onSelected: (action) async {
                                final messenger = ScaffoldMessenger.of(context);
                                if (action == _LibraryAction.createDraft) {
                                  await _createDraftFromSource(item);
                                  return;
                                }
                                if (action == _LibraryAction.addToBundle) {
                                  await _showAssignBundleDialog(
                                    item: item,
                                    bundles: bundles ?? const <Bundle>[],
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
      if (item.bundleId != null && item.bundleId!.isNotEmpty)
        'bundle:${item.bundleId!.substring(0, 8)}',
      if (item.url != null && item.url!.trim().isNotEmpty) item.url!.trim(),
      if (item.userNote != null && item.userNote!.trim().isNotEmpty)
        item.userNote!.trim(),
      if (item.tags.isNotEmpty) item.tags.map((tag) => '#$tag').join(' '),
    ];
    return parts.join('  •  ');
  }

  Future<void> _createDraftFromSource(SourceItem item) async {
    final canonical = '''
# Draft

Hook: I pulled this from my library and want to turn it into a post.

Source:
- Type: ${item.type}
- URL: ${item.url ?? '-'}
- Notes: ${item.userNote ?? '-'}
- Tags: ${item.tags.isEmpty ? '-' : item.tags.join(', ')}

Takeaway: Start with one clear point, then iterate.
''';
    final draftId = await ref.read(draftRepoProvider).createDraft(
          canonicalMarkdown: canonical,
          intent: 'how_to',
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft ${draftId.substring(0, 8)} created')),
    );
    context.go('/compose');
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
}

enum _LibraryAction {
  createDraft,
  addToBundle,
  clearBundle,
}
