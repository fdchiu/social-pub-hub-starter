import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class BundleBuilderScreen extends ConsumerStatefulWidget {
  const BundleBuilderScreen({super.key});

  @override
  ConsumerState<BundleBuilderScreen> createState() =>
      _BundleBuilderScreenState();
}

class _BundleBuilderScreenState extends ConsumerState<BundleBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _anchorRefController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _selectedVariantIds = <String>{};
  String _anchorType = 'youtube';
  bool _includeAllPosts = false;

  @override
  void dispose() {
    _nameController.dispose();
    _anchorRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(allVariantsStreamProvider);
    final draftsAsync = ref.watch(allDraftsStreamProvider);
    final bundlesAsync = ref.watch(bundlesStreamProvider);
    final sourceItemsAsync = ref.watch(sourceItemsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Bundle Builder',
        actions: [
          IconButton(
            tooltip: 'Bundle checklist',
            onPressed: () => context.go('/bundle-checklist'),
            icon: const Icon(Icons.checklist),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PostScopeHeader(showGlobalToggle: false),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _includeAllPosts,
            onChanged: (value) {
              setState(() {
                _includeAllPosts = value;
              });
            },
            title: const Text('Include all posts'),
            subtitle: const Text(
              'Show variants and bundles from all posts instead of only active post',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          Text(
            'Create bundle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bundle name',
                      hintText: 'YouTube launch wave',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _anchorType,
                    decoration: const InputDecoration(labelText: 'Anchor type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'youtube',
                        child: Text('YouTube'),
                      ),
                      DropdownMenuItem(
                        value: 'social',
                        child: Text('Social'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _anchorType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _anchorRefController,
                    decoration: const InputDecoration(
                      labelText: 'Anchor ref',
                      hintText: 'youtube video id or draft/variant id',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Goal, sequencing, publish window',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Related variants',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  variantsAsync.when(
                    data: (variants) {
                      return draftsAsync.when(
                        data: (drafts) {
                          final draftsById = {
                            for (final row in drafts) row.id: row
                          };
                          final scopedVariants = _scopeVariants(
                            variants,
                            draftsById: draftsById,
                            activePostId: activePost?.id,
                            includeAllPosts: _includeAllPosts,
                          );
                          if (scopedVariants.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _includeAllPosts
                                    ? 'No variants yet. Generate variants first.'
                                    : 'No variants in active post scope yet.',
                              ),
                            );
                          }
                          return SizedBox(
                            height: 220,
                            child: ListView.separated(
                              itemCount: scopedVariants.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final variant = scopedVariants[index];
                                final selected =
                                    _selectedVariantIds.contains(variant.id);
                                return CheckboxListTile(
                                  value: selected,
                                  dense: true,
                                  title: Text(
                                      '${variant.platform.toUpperCase()} · ${variant.id.substring(0, 8)}'),
                                  subtitle: Text(
                                    variant.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (_) {
                                    setState(() {
                                      if (selected) {
                                        _selectedVariantIds.remove(variant.id);
                                      } else {
                                        _selectedVariantIds.add(variant.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (error, _) =>
                            Text('Failed loading drafts: $error'),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (error, _) =>
                        Text('Failed loading variants: $error'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _createBundle,
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Create bundle'),
                      ),
                      const SizedBox(width: 12),
                      Text('${_selectedVariantIds.length} variants selected'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Saved bundles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          bundlesAsync.when(
            data: (bundles) {
              final scopedBundles = _scopeBundles(
                bundles,
                activePostId: activePost?.id,
                includeAllPosts: _includeAllPosts,
              );
              if (scopedBundles.isEmpty) {
                return Text(
                  _includeAllPosts
                      ? 'No bundles yet.'
                      : 'No bundles in active post scope.',
                );
              }
              return variantsAsync.when(
                data: (variants) {
                  final byId = {for (final v in variants) v.id: v};
                  return sourceItemsAsync.when(
                    data: (sources) {
                      final sourceCountByBundle = <String, int>{};
                      for (final source in sources) {
                        final bundleId = source.bundleId;
                        if (bundleId == null || bundleId.isEmpty) {
                          continue;
                        }
                        sourceCountByBundle[bundleId] =
                            (sourceCountByBundle[bundleId] ?? 0) + 1;
                      }
                      return Column(
                        children: [
                          for (final bundle in scopedBundles)
                            Card(
                              child: ListTile(
                                title: Text(bundle.name),
                                subtitle: Text(
                                  'post=${bundle.postId == null ? 'unscoped' : bundle.postId!.substring(0, 8)} · '
                                  'anchor=${bundle.anchorType}:${bundle.anchorRef ?? '-'} · '
                                  'variants=${bundle.relatedVariantIds.length} · '
                                  'sources=${sourceCountByBundle[bundle.id] ?? 0}',
                                ),
                                trailing: PopupMenuButton<_BundleAction>(
                                  onSelected: (action) => _handleBundleAction(
                                    action: action,
                                    bundle: bundle,
                                    variantsById: byId,
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _BundleAction.wavePreview,
                                      child: Text('Wave preview'),
                                    ),
                                    PopupMenuItem(
                                      value: _BundleAction.youtubeMeta,
                                      child: Text('YouTube metadata'),
                                    ),
                                    PopupMenuItem(
                                      value: _BundleAction.openChecklist,
                                      child: Text('Open checklist'),
                                    ),
                                    PopupMenuItem(
                                      value: _BundleAction.openPublish,
                                      child: Text('Open publish console'),
                                    ),
                                    PopupMenuItem(
                                      value: _BundleAction.edit,
                                      child: Text('Edit bundle'),
                                    ),
                                    PopupMenuItem(
                                      value: _BundleAction.delete,
                                      child: Text('Delete bundle'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Source map error: $error'),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Variant map error: $error'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Failed loading bundles: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBundle() async {
    final activePost = ref.read(activePostProvider);
    if (activePost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select an active post before creating bundle')),
      );
      return;
    }

    final allVariants = ref.read(allVariantsStreamProvider).valueOrNull;
    final allDrafts = ref.read(allDraftsStreamProvider).valueOrNull;
    if (allVariants == null || allDrafts == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variants are still loading')),
      );
      return;
    }
    final draftsById = {for (final row in allDrafts) row.id: row};
    final scopedVariants = _scopeVariants(
      allVariants,
      draftsById: draftsById,
      activePostId: activePost.id,
      includeAllPosts: _includeAllPosts,
    );
    final scopedVariantIds = scopedVariants.map((row) => row.id).toSet();
    final selectedScopedVariantIds = _selectedVariantIds
        .where((id) => scopedVariantIds.contains(id))
        .toList(growable: false);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle name is required')),
      );
      return;
    }
    if (selectedScopedVariantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one variant in active post scope'),
        ),
      );
      return;
    }

    final bundleId = await ref.read(bundleRepoProvider).createBundle(
          name: name,
          anchorType: _anchorType,
          anchorRef: _anchorRefController.text,
          relatedVariantIds: selectedScopedVariantIds,
          notes: _notesController.text,
          postId: activePost.id,
        );

    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.clear();
      _anchorRefController.clear();
      _notesController.clear();
      _selectedVariantIds.clear();
      _anchorType = 'youtube';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bundle ${bundleId.substring(0, 8)} created')),
    );
  }

  Future<void> _handleBundleAction({
    required _BundleAction action,
    required Bundle bundle,
    required Map<String, Variant> variantsById,
  }) async {
    if (action == _BundleAction.wavePreview) {
      await _showWavePreview(context, bundle, variantsById);
      return;
    }
    if (action == _BundleAction.youtubeMeta) {
      await _showYouTubeMetadataPreview(context, bundle, variantsById);
      return;
    }
    if (action == _BundleAction.openChecklist) {
      if (!mounted) {
        return;
      }
      context.go('/bundle-checklist');
      return;
    }
    if (action == _BundleAction.openPublish) {
      if (!mounted) {
        return;
      }
      final encoded = Uri.encodeQueryComponent(bundle.id);
      context.go('/publish?bundleId=$encoded');
      return;
    }
    if (action == _BundleAction.edit) {
      await _editBundle(bundle);
      return;
    }
    if (action == _BundleAction.delete) {
      await _deleteBundle(bundle);
    }
  }

  Future<void> _editBundle(Bundle bundle) async {
    final nameController = TextEditingController(text: bundle.name);
    final anchorRefController =
        TextEditingController(text: bundle.anchorRef ?? '');
    final notesController = TextEditingController(text: bundle.notes ?? '');
    var anchorType = bundle.anchorType;

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: Text('Edit bundle ${bundle.id.substring(0, 8)}'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Bundle name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: anchorType,
                      decoration:
                          const InputDecoration(labelText: 'Anchor type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'youtube', child: Text('YouTube')),
                        DropdownMenuItem(
                            value: 'social', child: Text('Social')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setLocalState(() {
                          anchorType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: anchorRefController,
                      decoration: const InputDecoration(
                        labelText: 'Anchor ref',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
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
      anchorRefController.dispose();
      notesController.dispose();
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle name is required')),
      );
      nameController.dispose();
      anchorRefController.dispose();
      notesController.dispose();
      return;
    }

    await ref.read(bundleRepoProvider).updateBundle(
          bundleId: bundle.id,
          name: name,
          anchorType: anchorType,
          anchorRef: anchorRefController.text,
          notes: notesController.text,
          canonicalDraftId: bundle.canonicalDraftId,
          postId: bundle.postId ?? ref.read(activePostProvider)?.id,
        );

    nameController.dispose();
    anchorRefController.dispose();
    notesController.dispose();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle updated')),
    );
  }

  Future<void> _deleteBundle(Bundle bundle) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete bundle ${bundle.id.substring(0, 8)}?'),
            content: const Text(
              'This will remove the bundle and unassign linked sources.',
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
    if (!confirmed) {
      return;
    }

    await ref.read(bundleRepoProvider).deleteBundle(bundle.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle deleted')),
    );
  }

  Future<void> _showWavePreview(
    BuildContext context,
    Bundle bundle,
    Map<String, Variant> variantsById,
  ) async {
    final text = _socialWavePreview(bundle, variantsById);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wave preview · ${bundle.name}'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wave preview copied')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showYouTubeMetadataPreview(
    BuildContext context,
    Bundle bundle,
    Map<String, Variant> variantsById,
  ) async {
    final text = _youtubeMetadataTemplate(bundle, variantsById);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('YouTube metadata · ${bundle.name}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('YouTube metadata copied')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _socialWavePreview(Bundle bundle, Map<String, Variant> variantsById) {
    final lines = <String>[
      'Anchor: ${bundle.anchorType}:${bundle.anchorRef ?? '-'}',
      'Bundle: ${bundle.name}',
      '',
      'Suggested cross-post wave:',
    ];
    var step = 1;
    for (final variantId in bundle.relatedVariantIds) {
      final variant = variantsById[variantId];
      if (variant == null) {
        continue;
      }
      final firstLine = variant.body
          .split('\n')
          .map((line) => line.trim())
          .firstWhere((line) => line.isNotEmpty, orElse: () => variant.body);
      lines.add(
        '$step. ${variant.platform.toUpperCase()} - ${_truncate(firstLine, 90)}',
      );
      step += 1;
    }
    if (step == 1) {
      lines.add('1. No linked variants found locally.');
    }
    if (bundle.notes != null && bundle.notes!.trim().isNotEmpty) {
      lines.add('');
      lines.add('Notes: ${bundle.notes!.trim()}');
    }
    return lines.join('\n');
  }

  String _youtubeMetadataTemplate(
    Bundle bundle,
    Map<String, Variant> variantsById,
  ) {
    final anchors = <String>[];
    for (final variantId in bundle.relatedVariantIds) {
      final variant = variantsById[variantId];
      if (variant == null) {
        continue;
      }
      final line = variant.body
          .split('\n')
          .map((s) => s.trim())
          .firstWhere((s) => s.isNotEmpty, orElse: () => variant.body);
      anchors.add(_truncate(line, 80));
      if (anchors.length >= 3) {
        break;
      }
    }
    final seed = anchors.isEmpty ? 'practical build notes' : anchors.first;
    final chapter2 = anchors.length >= 2 ? anchors[1] : 'Decision tradeoff';
    final chapter3 = anchors.length >= 3 ? anchors[2] : 'What to test next';
    final anchorRef = bundle.anchorRef?.trim().isEmpty ?? true
        ? '-'
        : bundle.anchorRef!.trim();

    return '''
Title:
${_truncate(bundle.name, 60)} | ${_truncate(seed, 60)}

Description:
In this video I break down the bundle "${bundle.name}" and the real decisions behind it.

Anchor: ${bundle.anchorType}:$anchorRef
What you'll get:
- Context for the build
- Tradeoff analysis
- Action plan for the next iteration

Chapters:
00:00 Hook + context
01:20 ${_truncate(seed, 45)}
03:10 ${_truncate(chapter2, 45)}
05:00 ${_truncate(chapter3, 45)}
06:30 Wrap-up + next step

Pinned comment:
Which part should I break down deeper in the next upload?
''';
  }

  String _truncate(String value, int max) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}...';
  }

  List<Bundle> _scopeBundles(
    List<Bundle> bundles, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return bundles;
    }
    return bundles
        .where(
            (bundle) => bundle.postId == null || bundle.postId == activePostId)
        .toList(growable: false);
  }

  List<Variant> _scopeVariants(
    List<Variant> variants, {
    required Map<String, Draft> draftsById,
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return variants;
    }
    return variants.where((variant) {
      final draft = draftsById[variant.draftId];
      final draftPostId = draft?.postId;
      return draftPostId == null || draftPostId == activePostId;
    }).toList(growable: false);
  }
}

enum _BundleAction {
  wavePreview,
  youtubeMeta,
  openChecklist,
  openPublish,
  edit,
  delete,
}
