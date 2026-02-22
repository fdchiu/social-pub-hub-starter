import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';

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
    final bundlesAsync = ref.watch(bundlesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bundle Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      if (variants.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child:
                              Text('No variants yet. Generate variants first.'),
                        );
                      }
                      return SizedBox(
                        height: 220,
                        child: ListView.separated(
                          itemCount: variants.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final variant = variants[index];
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
              if (bundles.isEmpty) {
                return const Text('No bundles yet.');
              }
              return variantsAsync.when(
                data: (variants) {
                  final byId = {for (final v in variants) v.id: v};
                  return Column(
                    children: [
                      for (final bundle in bundles)
                        Card(
                          child: ListTile(
                            title: Text(bundle.name),
                            subtitle: Text(
                              'anchor=${bundle.anchorType}:${bundle.anchorRef ?? '-'} · '
                              'variants=${bundle.relatedVariantIds.length}',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () =>
                                      _showWavePreview(context, bundle, byId),
                                  child: const Text('Wave'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () => _showYouTubeMetadataPreview(
                                    context,
                                    bundle,
                                    byId,
                                  ),
                                  child: const Text('YouTube meta'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle name is required')),
      );
      return;
    }
    if (_selectedVariantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one variant')),
      );
      return;
    }

    final bundleId = await ref.read(bundleRepoProvider).createBundle(
          name: name,
          anchorType: _anchorType,
          anchorRef: _anchorRefController.text,
          relatedVariantIds: _selectedVariantIds.toList(growable: false),
          notes: _notesController.text,
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
}
