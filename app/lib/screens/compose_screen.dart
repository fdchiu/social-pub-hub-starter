import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../utils/composer_links.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';
import '../utils/content_type_utils.dart';
import 'compose_queue_action.dart';

class _VariantSnapshot {
  const _VariantSnapshot({
    required this.id,
    required this.draftId,
    required this.platform,
    required this.body,
  });

  factory _VariantSnapshot.fromVariant(Variant variant) {
    return _VariantSnapshot(
      id: variant.id,
      draftId: variant.draftId,
      platform: variant.platform,
      body: variant.body,
    );
  }

  final String id;
  final String draftId;
  final String platform;
  final String body;
}

class _ResolvedImagePayload {
  const _ResolvedImagePayload({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

final _composeCoverVersionsProvider =
    StreamProvider.family<List<SourceItem>, String>((ref, postId) {
  return ref
      .watch(sourceRepoProvider)
      .watchSourceItems(
          postId: postId, includeGlobal: false, includeProject: false)
      .map(
        (rows) => rows
            .where(
              (row) =>
                  row.type.trim().toLowerCase() == 'image' &&
                  row.tags.any(
                      (tag) => tag.trim().toLowerCase() == 'cover_version'),
            )
            .toList(growable: false),
      );
});

final _composePolishSourcesProvider = StreamProvider<List<SourceItem>>((ref) {
  final activePost = ref.watch(activePostProvider);
  final activeProject = ref.watch(activeProjectProvider);
  final includeGlobal = ref.watch(includeGlobalSourcesProvider);
  final includeProject = ref.watch(includeProjectSourcesProvider);

  return ref
      .watch(sourceRepoProvider)
      .watchSourceItems(
        postId: activePost?.id,
        projectId: activeProject?.id,
        includeGlobal: includeGlobal,
        includeProject: includeProject,
      )
      .map((rows) {
    final sorted = rows.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(12).toList(growable: false);
  });
});

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({
    super.key,
    this.initialDraftId,
  });

  final String? initialDraftId;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  static const String _seedDraftText = '''
# Draft

Hook:

- point 1
- point 2

Takeaway:
''';

  static const int _xVariantCharLimit = 280;
  static const String _coverVersionTag = 'cover_version';
  static const String _coverGeneratedTag = 'cover_generated';

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _polishInstructionController =
      TextEditingController();
  Timer? _saveDebounce;
  Timer? _polishInstructionSaveDebounce;
  String? _draftId;
  String? _loadedForPostId;
  bool _loading = true;
  bool _hydratingEditor = false;
  String? _saveError;
  String? _variantError;
  bool _generatingVariants = false;
  bool _regeneratingVisibleVariants = false;
  bool _polishingDraft = false;
  bool _generatingCoverImage = false;
  final Set<String> _excludedPolishSourceIds = <String>{};
  final Set<String> _humanizingVariantIds = <String>{};
  double _humanizeStrictness = 0.7;
  String _variantPlatformFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEditorChanged);
    _polishInstructionController.addListener(_onPolishInstructionChanged);
    unawaited(_loadOrCreateDraft());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _polishInstructionSaveDebounce?.cancel();
    _controller.removeListener(_onEditorChanged);
    _polishInstructionController.removeListener(_onPolishInstructionChanged);
    _controller.dispose();
    _polishInstructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePost = ref.watch(activePostProvider);
    final activePostId = activePost?.id;
    if (!_loading && activePostId != null && activePostId != _loadedForPostId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = true;
        });
        unawaited(_loadOrCreateDraft());
      });
    }
    final variantsAsync = _draftId == null
        ? null
        : ref.watch(draftVariantsStreamProvider(_draftId!));
    final coverVersionsAsync = activePostId == null
        ? null
        : ref.watch(_composeCoverVersionsProvider(activePostId));
    final polishSourcesAsync = ref.watch(_composePolishSourcesProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Compose',
        actions: [
          IconButton(
            onPressed:
                (_draftId == null || _polishingDraft) ? null : _polishDraft,
            tooltip: 'Polish draft',
            icon: _polishingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.spellcheck),
          ),
          IconButton(
            onPressed: (_draftId == null || _generatingCoverImage)
                ? null
                : _generateCoverImage,
            tooltip: 'Generate cover image',
            icon: _generatingCoverImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
          ),
          IconButton(
            onPressed: (_draftId == null ||
                    _generatingVariants ||
                    _regeneratingVisibleVariants)
                ? null
                : _generateVariants,
            tooltip: 'Generate variants',
            icon: _generatingVariants
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
          ),
          IconButton(
            onPressed: _draftId == null ? null : _exportVariantsCsv,
            tooltip: 'Export variants CSV',
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            onPressed: _draftId == null ? null : _openPublishChecklist,
            tooltip: 'Open publish checklist',
            icon: const Icon(Icons.checklist_outlined),
          ),
          IconButton(
            onPressed: _draftId == null ? null : _deleteDraft,
            tooltip: 'Delete draft',
            icon: const Icon(Icons.delete_outline),
          ),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: _saveError!,
                child: const Icon(Icons.error_outline, color: Colors.orange),
              ),
            ),
          if (_draftId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Draft ${_draftId!.substring(0, 8)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const PostScopeHeader(showGlobalToggle: false),
                  if (activePost != null && coverVersionsAsync != null) ...[
                    const SizedBox(height: 8),
                    coverVersionsAsync.when(
                      data: (coverVersions) => _buildPostCoverSection(
                        post: activePost,
                        coverVersions: coverVersions,
                      ),
                      loading: () => _buildPostCoverSection(
                        post: activePost,
                        coverVersions: const <SourceItem>[],
                      ),
                      error: (error, _) => Column(
                        children: [
                          _buildPostCoverSection(
                            post: activePost,
                            coverVersions: const <SourceItem>[],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Cover versions failed: $error',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPolishSourceContextCard(polishSourcesAsync),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _polishInstructionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Polish instruction (optional)',
                      hintText:
                          'Example: Summarize the notes first, then get to the point on how to choose AI apps that match the notes.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Write canonical markdown draft...',
                      ),
                    ),
                  ),
                  if (_variantError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _variantError!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Humanize strictness'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: 1,
                          divisions: 10,
                          value: _humanizeStrictness,
                          label: _humanizeStrictness.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _humanizeStrictness = value;
                            });
                          },
                        ),
                      ),
                      Text(_humanizeStrictness.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: variantsAsync == null
                          ? const SizedBox.shrink()
                          : variantsAsync.when(
                              data: (variants) {
                                if (variants.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No variants yet. Tap sparkle to generate.',
                                    ),
                                  );
                                }
                                final platforms = variants
                                    .map((v) => v.platform)
                                    .toSet()
                                    .toList(growable: false)
                                  ..sort();
                                final filterOptions = <String>[
                                  'all',
                                  ...platforms,
                                ];
                                final selectedFilter = filterOptions
                                        .contains(_variantPlatformFilter)
                                    ? _variantPlatformFilter
                                    : 'all';
                                final filtered = selectedFilter == 'all'
                                    ? variants
                                    : variants
                                        .where(
                                          (variant) =>
                                              variant.platform ==
                                              selectedFilter,
                                        )
                                        .toList(growable: false);

                                return Column(
                                  children: [
                                    SizedBox(
                                      height: 42,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: filterOptions.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final filter = filterOptions[index];
                                          return ChoiceChip(
                                            label: Text(
                                              filter == 'all'
                                                  ? 'ALL'
                                                  : filter.toUpperCase(),
                                            ),
                                            selected: filter == selectedFilter,
                                            onSelected: (selected) {
                                              if (!selected) {
                                                return;
                                              }
                                              setState(() {
                                                _variantPlatformFilter = filter;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                              'Visible variants: ${filtered.length}'),
                                          const Spacer(),
                                          FilledButton.tonal(
                                            onPressed: filtered.isEmpty ||
                                                    _regeneratingVisibleVariants
                                                ? null
                                                : () =>
                                                    _humanizeVisibleVariants(
                                                      filtered,
                                                    ),
                                            child:
                                                const Text('Humanize visible'),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.tonal(
                                            onPressed: filtered.isEmpty ||
                                                    _regeneratingVisibleVariants
                                                ? null
                                                : () =>
                                                    _regenerateVisibleVariants(
                                                      filtered,
                                                    ),
                                            child: _regeneratingVisibleVariants
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Regenerate visible',
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final variant = filtered[index];
                                          final humanizing =
                                              _humanizingVariantIds
                                                  .contains(variant.id);
                                          final charLimit = _platformCharLimit(
                                            variant.platform,
                                          );
                                          final charCount =
                                              variant.body.trim().length;
                                          final overLimit = charLimit != null &&
                                              charCount > charLimit;
                                          return ListTile(
                                            title: Row(
                                              children: [
                                                Text(
                                                  variant.platform
                                                      .toUpperCase(),
                                                ),
                                                if (charLimit != null) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '$charCount/$charLimit',
                                                    style: TextStyle(
                                                      color: overLimit
                                                          ? Colors.redAccent
                                                          : Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            subtitle: Text(
                                              variant.body,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Wrap(
                                              spacing: 4,
                                              children: [
                                                IconButton(
                                                  tooltip: 'Copy',
                                                  onPressed: () =>
                                                      _copyVariantText(
                                                    variant.body,
                                                  ),
                                                  icon: const Icon(Icons.copy),
                                                ),
                                                IconButton(
                                                  tooltip: 'Open composer',
                                                  onPressed: () =>
                                                      _openComposerForVariant(
                                                    platform: variant.platform,
                                                    text: variant.body,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.open_in_new,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Confirm posted',
                                                  onPressed: () =>
                                                      _confirmPosted(
                                                    variant.id,
                                                    variant.platform,
                                                    variant.body,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Queue',
                                                  onPressed: () =>
                                                      queueVariantFromCompose(
                                                    context: context,
                                                    ref: ref,
                                                    variantId: variant.id,
                                                    platform: variant.platform,
                                                    body: variant.body,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.schedule_outlined,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Edit',
                                                  onPressed: () =>
                                                      _editVariant(variant),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Delete',
                                                  onPressed: () =>
                                                      _deleteVariant(variant),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Humanize',
                                                  onPressed: humanizing
                                                      ? null
                                                      : () => _humanizeVariant(
                                                            variant,
                                                          ),
                                                  icon: humanizing
                                                      ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.auto_fix_high,
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, _) =>
                                  Center(child: Text('Variant error: $error')),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadOrCreateDraft() async {
    final activePost = ref.read(activePostProvider);
    if (activePost == null) {
      if (!mounted) {
        return;
      }
      _hydratingEditor = true;
      _draftId = null;
      _loadedForPostId = null;
      _controller.text = '';
      _polishInstructionController.text = '';
      _hydratingEditor = false;
      setState(() {
        _excludedPolishSourceIds.clear();
        _loading = false;
        _saveError = null;
      });
      return;
    }
    final repo = ref.read(draftRepoProvider);
    var draft = await () async {
      final preferredDraftId = widget.initialDraftId;
      if (preferredDraftId != null && preferredDraftId.isNotEmpty) {
        return repo.getDraftById(preferredDraftId);
      }
      return null;
    }();
    draft ??= await repo.getLatestDraft(postId: activePost.id);
    draft ??= await () async {
      final draftId = await repo.createDraft(
        canonicalMarkdown: _seedDraftText,
        intent: intentForContentType(activePost.contentType),
        audience: activePost.audience,
        postId: activePost.id,
        contentType: activePost.contentType,
      );
      return repo.getDraftById(draftId);
    }();

    if (!mounted) {
      return;
    }

    _hydratingEditor = true;
    _draftId = draft?.id;
    _loadedForPostId = activePost.id;
    _controller.text = draft?.canonicalMarkdown ?? '';
    _polishInstructionController.text = draft?.polishInstruction ?? '';
    _hydratingEditor = false;
    setState(() {
      _excludedPolishSourceIds
        ..clear()
        ..addAll(draft?.polishExcludedSourceIds ?? const <String>[]);
      _loading = false;
      _saveError = null;
    });
  }

  Widget _buildPolishSourceContextCard(
      AsyncValue<List<SourceItem>> sourcesAsync) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: sourcesAsync.when(
          data: (sources) {
            final scopedCount = sources.length;
            if (scopedCount == 0) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Polish context: no scoped Inbox/Library sources yet.',
                ),
              );
            }

            final selectedSources = _selectedPolishSources(sources);
            final excludedCount = scopedCount - selectedSources.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Polish context',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (excludedCount > 0)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _excludedPolishSourceIds.clear();
                          });
                          unawaited(_persistPolishSourceSelection());
                        },
                        child: const Text('Use all'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Included on polish: ${selectedSources.length} / $scopedCount. Tap any row to exclude/include. Latest 12 shown; LLM reads first 8.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    itemCount: scopedCount,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sources[index];
                      final included =
                          !_excludedPolishSourceIds.contains(item.id);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _togglePolishSource(item.id),
                        leading: Icon(
                          _iconForSourceType(item.type),
                          size: 18,
                          color: included ? null : Colors.white38,
                        ),
                        title: Text(
                          item.title?.trim().isNotEmpty == true
                              ? item.title!.trim()
                              : _sourceTypeLabel(item.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: included
                              ? null
                              : const TextStyle(color: Colors.white54),
                        ),
                        subtitle: Text(
                          _composeSourcePreview(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: included
                              ? null
                              : const TextStyle(color: Colors.white38),
                        ),
                        trailing: Icon(
                          included
                              ? Icons.check_circle_outline
                              : Icons.remove_circle_outline,
                          size: 18,
                          color: included ? null : Colors.orange,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Align(
            alignment: Alignment.centerLeft,
            child: Text('Loading polish context...'),
          ),
          error: (error, _) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Polish context failed: $error',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ),
      ),
    );
  }

  List<SourceItem> _selectedPolishSources(List<SourceItem> sources) {
    return sources
        .where((item) => !_excludedPolishSourceIds.contains(item.id))
        .toList(growable: false);
  }

  void _togglePolishSource(String sourceId) {
    setState(() {
      if (_excludedPolishSourceIds.contains(sourceId)) {
        _excludedPolishSourceIds.remove(sourceId);
      } else {
        _excludedPolishSourceIds.add(sourceId);
      }
    });
    unawaited(_persistPolishSourceSelection());
  }

  Future<void> _persistPolishSourceSelection() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }

    try {
      await ref.read(draftRepoProvider).updatePolishExcludedSourceIds(
            draftId: draftId,
            sourceIds: _excludedPolishSourceIds.toList(growable: false),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (_saveError == 'Failed saving polish source selection') {
          _saveError = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveError = 'Failed saving polish source selection';
      });
    }
  }

  String _composeSourcePreview(SourceItem item) {
    final note = item.userNote?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    final url = item.url?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    if (item.tags.isNotEmpty) {
      return item.tags.map((tag) => '#$tag').join(' ');
    }
    return item.id;
  }

  String _sourceTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'url':
        return 'URL';
      case 'note':
        return 'Note';
      case 'snippet':
        return 'Snippet';
      case 'image':
        return 'Image';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'file':
        return 'File';
      default:
        final normalized = type.trim().toLowerCase();
        return normalized.isEmpty ? 'Source' : normalized.replaceAll('_', ' ');
    }
  }

  IconData _iconForSourceType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'url':
        return Icons.link_outlined;
      case 'note':
        return Icons.sticky_note_2_outlined;
      case 'snippet':
        return Icons.code_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'file':
        return Icons.attach_file_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  void _onPolishInstructionChanged() {
    if (_hydratingEditor || _draftId == null) {
      return;
    }

    _polishInstructionSaveDebounce?.cancel();
    _polishInstructionSaveDebounce =
        Timer(const Duration(milliseconds: 500), () async {
      try {
        await ref.read(draftRepoProvider).updatePolishInstruction(
              draftId: _draftId!,
              instruction: _polishInstructionController.text,
            );
        if (!mounted) {
          return;
        }
        setState(() {
          if (_saveError == 'Failed saving polish instruction') {
            _saveError = null;
          }
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _saveError = 'Failed saving polish instruction';
        });
      }
    });
  }

  void _onEditorChanged() {
    if (_hydratingEditor || _draftId == null) {
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(draftRepoProvider);
      try {
        await repo.updateCanonicalMarkdown(
          draftId: _draftId!,
          canonicalMarkdown: _controller.text,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _saveError = null;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        setState(() {
          _saveError = 'Failed saving draft: $e';
        });
      }
    });
  }

  Future<void> _generateVariants() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }

    setState(() {
      _generatingVariants = true;
      _variantError = null;
    });

    try {
      await ref.read(draftRepoProvider).updateCanonicalMarkdown(
            draftId: draftId,
            canonicalMarkdown: _controller.text,
          );

      final activePost = ref.read(activePostProvider);
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();

      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/$draftId/variants'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'platforms': const [
                'x',
                'linkedin',
                'reddit',
                'facebook',
                'youtube',
                'substack',
                'medium',
              ],
              'style_profile_id': styleProfile.id,
              'content_type': activePost?.contentType,
            }),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Generate failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final variantsRaw = parsed['variants'];
      final variants = variantsRaw is List
          ? variantsRaw
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final llmCount =
          variants.where((row) => (row['llm_used'] as bool?) ?? false).length;
      final fallbackReasons = variants
          .map((row) => (row['fallback_reason'] as String?)?.trim())
          .whereType<String>()
          .where((reason) => reason.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final repo = ref.read(variantRepoProvider);

      for (final variant in variants) {
        await repo.createVariant(
          id: variant['id'] as String?,
          draftId: draftId,
          platform: (variant['platform'] as String?) ?? 'x',
          body: (variant['text'] as String?) ?? '',
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _generatingVariants = false;
        _variantError = null;
      });
      final templateCount = variants.length - llmCount;
      final summary = templateCount == 0
          ? 'Generated ${variants.length} variants with LLM.'
          : llmCount == 0
              ? 'Generated ${variants.length} variants with template fallback.'
              : 'Generated ${variants.length} variants (LLM $llmCount, fallback $templateCount).';
      final detail =
          fallbackReasons.isEmpty ? '' : ' ${fallbackReasons.first}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$summary$detail')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _generatingVariants = false;
        _variantError = 'Variant generation failed: $e';
      });
    }
  }

  Future<void> _polishDraft() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }

    setState(() {
      _polishingDraft = true;
      _saveError = null;
    });

    try {
      await ref.read(draftRepoProvider).updateCanonicalMarkdown(
            draftId: draftId,
            canonicalMarkdown: _controller.text,
          );
      final activeProject = ref.read(activeProjectProvider);
      final availableSourceItems =
          await ref.read(sourceRepoProvider).getRecentSourceItemsForPost(
                limit: 12,
                postId: ref.read(activePostProvider)?.id,
                projectId: activeProject?.id,
                includeGlobal: ref.read(includeGlobalSourcesProvider),
                includeProject: ref.read(includeProjectSourcesProvider),
              );
      final sourceItems = _selectedPolishSources(availableSourceItems);
      if (sourceItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select at least one source in Polish context.'),
            ),
          );
        }
        setState(() {
          _polishingDraft = false;
        });
        return;
      }
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      final baseUrl = ref.read(apiBaseUrlProvider);
      final requestBody = jsonEncode({
        'canonical_markdown': _controller.text,
        'source_materials': sourceItems
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
        'style_profile_id': styleProfile.id,
        'banned_phrases': styleProfile.bannedPhrases,
        'style_traits': styleProfile.personalTraits,
        'differentiation_points': styleProfile.differentiationPoints,
        'personal_prompt': styleProfile.customPrompt,
        'polish_instruction': _polishInstructionController.text.trim().isEmpty
            ? null
            : _polishInstructionController.text.trim(),
        'strictness': _humanizeStrictness,
      });
      final client = ref.read(httpClientProvider);
      final previewUri = Uri.parse('$baseUrl/drafts/polish_preview');
      final primaryUri = _isServerBackedDraftId(draftId)
          ? Uri.parse('$baseUrl/drafts/$draftId/polish')
          : previewUri;
      var response = await client.post(
        primaryUri,
        headers: const {'content-type': 'application/json'},
        body: requestBody,
      );
      if (response.statusCode == 404 &&
          primaryUri != previewUri &&
          _extractErrorDetail(response.body) == 'Draft not found') {
        response = await client.post(
          previewUri,
          headers: const {'content-type': 'application/json'},
          body: requestBody,
        );
      }

      late final String nextText;
      late final bool llmUsed;
      String? fallbackReason;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        final parsedText = (parsed['canonical_markdown'] as String?)?.trim();
        if (parsedText == null || parsedText.isEmpty) {
          throw Exception('Polish returned empty text');
        }
        nextText = parsedText;
        llmUsed = parsed['llm_used'] as bool? ?? false;
        fallbackReason = (parsed['fallback_reason'] as String?)?.trim();
      } else if (response.statusCode == 404) {
        final detail = _extractErrorDetail(response.body);
        nextText = _fallbackPolishText(
          canonicalMarkdown: _controller.text,
          strictness: _humanizeStrictness,
          bannedPhrases: styleProfile.bannedPhrases,
        );
        llmUsed = false;
        fallbackReason = detail == null
            ? 'backend unavailable (HTTP 404)'
            : 'backend unavailable (HTTP 404: $detail)';
      } else {
        final detail = _extractErrorDetail(response.body);
        throw Exception(
          detail == null
              ? 'Polish failed: ${response.statusCode}'
              : 'Polish failed: ${response.statusCode} ($detail)',
        );
      }

      await ref.read(draftRepoProvider).updateCanonicalMarkdown(
            draftId: draftId,
            canonicalMarkdown: nextText,
          );
      if (!mounted) {
        return;
      }

      _hydratingEditor = true;
      _controller.text = nextText;
      _hydratingEditor = false;
      setState(() {
        _polishingDraft = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            llmUsed
                ? 'Draft polished with LLM evidence pass.'
                : 'Draft polished with fallback rules (${fallbackReason ?? 'no LLM'}).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _polishingDraft = false;
        _saveError = 'Draft polish failed: $e';
      });
    }
  }

  bool _isServerBackedDraftId(String draftId) {
    return draftId.trim().startsWith('draft_');
  }

  String? _extractErrorDetail(String responseBody) {
    final body = responseBody.trim();
    if (body.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } catch (_) {
      // Ignore non-JSON error bodies.
    }
    return body.length > 120 ? '${body.substring(0, 120)}…' : body;
  }

  String _fallbackPolishText({
    required String canonicalMarkdown,
    required double strictness,
    required List<String> bannedPhrases,
  }) {
    var result = canonicalMarkdown;
    for (final phrase in bannedPhrases) {
      final trimmed = phrase.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      result = result.replaceAll(
        RegExp(RegExp.escape(trimmed), caseSensitive: false),
        '',
      );
    }
    if (strictness >= 0.6) {
      result = result.replaceAll(
        RegExp(r'\b(?:very|really)\s+', caseSensitive: false),
        '',
      );
    }

    final cleanedLines = LineSplitter.split(result)
        .map((line) => line.replaceFirst(RegExp(r'\s+$'), ''))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    return cleanedLines.join('\n').trim();
  }

  Future<void> _generateCoverImage() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }

    setState(() {
      _generatingCoverImage = true;
    });

    try {
      await ref.read(draftRepoProvider).updateCanonicalMarkdown(
            draftId: draftId,
            canonicalMarkdown: _controller.text,
          );
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/$draftId/cover-image'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'canonical_markdown': _controller.text,
              'size': '1024x1024',
              'style_hint': ref.read(activePostProvider)?.contentType,
            }),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Cover image failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final imageUrl = (parsed['image_url'] as String?)?.trim();
      final dataUri = (parsed['image_data_uri'] as String?)?.trim();
      final prompt = (parsed['prompt'] as String?)?.trim() ?? '';
      final revisedPrompt = (parsed['revised_prompt'] as String?)?.trim();
      final model = (parsed['model'] as String?)?.trim();
      final llmUsed = parsed['llm_used'] as bool? ?? false;
      final fallbackReason = (parsed['fallback_reason'] as String?)?.trim();

      Uint8List? imageBytes;
      if (dataUri != null && dataUri.isNotEmpty) {
        final commaIndex = dataUri.indexOf(',');
        if (commaIndex > 0 && commaIndex + 1 < dataUri.length) {
          try {
            imageBytes = base64Decode(dataUri.substring(commaIndex + 1));
          } catch (_) {
            imageBytes = null;
          }
        }
      }

      if ((imageUrl == null || imageUrl.isEmpty) && imageBytes == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cover image fallback (${fallbackReason ?? 'no image payload'}).',
            ),
          ),
        );
        return;
      }

      final activePost = ref.read(activePostProvider);
      if (activePost != null) {
        await _saveGeneratedCoverVersion(
          post: activePost,
          imageUrl: imageUrl,
          dataUri: dataUri,
          prompt: revisedPrompt ?? prompt,
          model: model,
        );
      }
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Cover image preview'),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(imageBytes),
                      )
                    else if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageUrl),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      llmUsed
                          ? 'Generated with ${model ?? 'OpenAI image model'}'
                          : 'Fallback response (${fallbackReason ?? 'no LLM'})',
                    ),
                    if (prompt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Prompt used'),
                      const SizedBox(height: 4),
                      SelectableText(prompt),
                    ],
                    if (revisedPrompt != null && revisedPrompt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Revised prompt'),
                      const SizedBox(height: 4),
                      SelectableText(revisedPrompt),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: imageUrl));
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Image URL copied')),
                      );
                    }
                  },
                  child: const Text('Copy URL'),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(imageUrl);
                    if (uri == null) {
                      return;
                    }
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text('Open image'),
                ),
              TextButton(
                onPressed: () => _saveAndRevealCoverImage(
                  dataUri: dataUri,
                  imageUrl: imageUrl,
                  suggestedName:
                      activePost == null ? 'cover_image' : activePost.title,
                ),
                child: const Text('Save + reveal'),
              ),
              TextButton(
                onPressed: activePost == null
                    ? null
                    : () async {
                        await _applyCoverImageToPost(
                          post: activePost,
                          imageUrl: imageUrl,
                          dataUri: dataUri,
                          prompt: revisedPrompt ?? prompt,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                child: const Text('Apply to post'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover image failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingCoverImage = false;
        });
      }
    }
  }

  Future<void> _copyVariantText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied variant text')),
    );
  }

  Future<void> _humanizeVariant(Variant variant) async {
    await _humanizeVariantInternal(variant, showSuccessSnackBar: true);
  }

  Future<bool> _humanizeVariantInternal(
    Variant variant, {
    required bool showSuccessSnackBar,
  }) async {
    setState(() {
      _humanizingVariantIds.add(variant.id);
    });

    try {
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      final activePost = ref.read(activePostProvider);
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/variants/${variant.id}/humanize'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'style_profile_id': styleProfile.id,
              'strictness': _humanizeStrictness,
              'content_type': activePost?.contentType,
            }),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Humanize failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final nextText = (parsed['text'] as String?)?.trim();
      if (nextText == null || nextText.isEmpty) {
        throw Exception('Humanize returned empty text');
      }

      await ref.read(variantRepoProvider).updateVariantBody(
            variantId: variant.id,
            body: nextText,
          );

      if (!mounted) {
        return true;
      }
      if (showSuccessSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Humanized ${variant.platform.toUpperCase()} variant'),
          ),
        );
      }
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Humanize failed: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _humanizingVariantIds.remove(variant.id);
        });
      }
    }
  }

  Future<void> _humanizeVisibleVariants(List<Variant> variants) async {
    final toHumanize = variants
        .where((variant) => !_humanizingVariantIds.contains(variant.id))
        .toList(growable: false);
    if (toHumanize.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No visible variants available to humanize')),
      );
      return;
    }

    var successCount = 0;
    for (final variant in toHumanize) {
      final ok =
          await _humanizeVariantInternal(variant, showSuccessSnackBar: false);
      if (ok) {
        successCount += 1;
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Humanized $successCount/${toHumanize.length} visible variants'),
      ),
    );
  }

  Future<void> _regenerateVisibleVariants(List<Variant> variants) async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }
    final platformSet = variants.map((row) => row.platform).toSet();
    final platforms = platformSet.toList(growable: false)..sort();
    if (platforms.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No visible platforms to regenerate')),
      );
      return;
    }

    final previousSnapshots =
        variants.map(_VariantSnapshot.fromVariant).toList(growable: false);

    setState(() {
      _regeneratingVisibleVariants = true;
      _variantError = null;
    });

    try {
      await ref.read(draftRepoProvider).updateCanonicalMarkdown(
            draftId: draftId,
            canonicalMarkdown: _controller.text,
          );
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/$draftId/variants'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'platforms': platforms,
              'style_profile_id': styleProfile.id,
              'content_type': ref.read(activePostProvider)?.contentType,
            }),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Regenerate failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final variantsRaw = parsed['variants'];
      final regenerated = variantsRaw is List
          ? variantsRaw
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final llmCount = regenerated
          .where((row) => (row['llm_used'] as bool?) ?? false)
          .length;
      final fallbackReasons = regenerated
          .map((row) => (row['fallback_reason'] as String?)?.trim())
          .whereType<String>()
          .where((reason) => reason.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final repo = ref.read(variantRepoProvider);
      final previousById = {
        for (final row in previousSnapshots) row.id: row,
      };
      final previousByPlatform = <String, _VariantSnapshot>{
        for (final row in previousSnapshots)
          if (!previousSnapshots
              .take(previousSnapshots.indexOf(row))
              .any((existing) => existing.platform == row.platform))
            row.platform: row,
      };
      final createdVariantIds = <String>[];

      for (final variant in regenerated) {
        final platform = (variant['platform'] as String?) ?? 'x';
        final nextBody = (variant['text'] as String?) ?? '';
        final responseId = (variant['id'] as String?)?.trim();

        _VariantSnapshot? target;
        if (responseId != null && responseId.isNotEmpty) {
          target = previousById[responseId];
        }
        target ??= previousByPlatform[platform];

        if (target != null) {
          await repo.updateVariantBody(
            variantId: target.id,
            body: nextBody,
          );
        } else {
          final createdId = await repo.createVariant(
            id: (responseId == null || responseId.isEmpty) ? null : responseId,
            draftId: draftId,
            platform: platform,
            body: nextBody,
          );
          createdVariantIds.add(createdId);
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _regeneratingVisibleVariants = false;
        _variantError = null;
      });
      final templateCount = regenerated.length - llmCount;
      final summary = templateCount == 0
          ? 'Regenerated ${regenerated.length} variants with LLM.'
          : llmCount == 0
              ? 'Regenerated ${regenerated.length} variants with template fallback.'
              : 'Regenerated ${regenerated.length} variants (LLM $llmCount, fallback $templateCount).';
      final detail =
          fallbackReasons.isEmpty ? '' : ' ${fallbackReasons.first}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$summary$detail'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              unawaited(
                _undoVisibleRegeneration(
                  previousSnapshots: previousSnapshots,
                  createdVariantIds: createdVariantIds,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _regeneratingVisibleVariants = false;
        _variantError = 'Variant regeneration failed: $e';
      });
    }
  }

  Future<void> _undoVisibleRegeneration({
    required List<_VariantSnapshot> previousSnapshots,
    required List<String> createdVariantIds,
  }) async {
    final repo = ref.read(variantRepoProvider);
    try {
      for (final createdId in createdVariantIds) {
        await repo.deleteVariantById(createdId);
      }
      for (final row in previousSnapshots) {
        final existing = await repo.getVariantById(row.id);
        if (existing == null) {
          await repo.createVariant(
            id: row.id,
            draftId: row.draftId,
            platform: row.platform,
            body: row.body,
          );
          continue;
        }
        await repo.updateVariantBody(
          variantId: row.id,
          body: row.body,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reverted regenerated variants (${previousSnapshots.length}).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Undo failed: $error')),
      );
    }
  }

  Widget _buildPostCoverSection({
    required Post post,
    required List<SourceItem> coverVersions,
  }) {
    final widgets = <Widget>[];
    final activeCard = _buildActivePostCoverCard(post);
    if (activeCard is! SizedBox) {
      widgets.add(activeCard);
    }
    if (coverVersions.isNotEmpty) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(_buildCoverVersionsCard(post, coverVersions));
    }
    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(children: widgets);
  }

  Widget _buildCoverVersionsCard(Post post, List<SourceItem> coverVersions) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved cover versions (${coverVersions.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coverVersions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final source = coverVersions[index];
                  final raw = source.url?.trim();
                  final isDataUri = raw != null && raw.startsWith('data:image');
                  final dataUri = isDataUri ? raw : null;
                  final imageUrl = isDataUri ? null : raw;
                  final selected = _isSelectedCoverVersion(post, source);

                  return SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? Colors.lightGreenAccent
                                      : Colors.white24,
                                ),
                              ),
                              child: _buildCoverImagePreview(
                                dataUri: dataUri,
                                imageUrl: imageUrl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selected ? 'ACTIVE' : 'version ${index + 1}',
                                style: Theme.of(context).textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Compare',
                              onPressed: () => _showCoverCompareDialog(
                                post: post,
                                source: source,
                              ),
                              icon: const Icon(Icons.compare_arrows, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Use',
                              onPressed: () => _applyCoverVersionToPost(
                                post: post,
                                source: source,
                              ),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 18),
                            ),
                            IconButton(
                              tooltip: 'Save + reveal',
                              onPressed: () => _saveAndRevealCoverImage(
                                dataUri: dataUri,
                                imageUrl: imageUrl,
                                suggestedName: post.title,
                              ),
                              icon:
                                  const Icon(Icons.save_alt_outlined, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                await ref
                                    .read(sourceRepoProvider)
                                    .deleteSourceItemById(source.id);
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cover version deleted'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelectedCoverVersion(Post post, SourceItem source) {
    final raw = source.url?.trim();
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final currentDataUri = post.coverImageDataUri?.trim();
    final currentUrl = post.coverImageUrl?.trim();
    if (raw.startsWith('data:image')) {
      return currentDataUri == raw;
    }
    return currentUrl == raw;
  }

  Widget _buildCoverImagePreview({String? dataUri, String? imageUrl}) {
    final bytes = dataUri == null || dataUri.isEmpty
        ? null
        : _decodeDataUriBytes(dataUri);
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    return const Center(child: Text('No image'));
  }

  Future<void> _showCoverCompareDialog({
    required Post post,
    required SourceItem source,
  }) async {
    final currentDataUri = post.coverImageDataUri?.trim();
    final currentUrl = post.coverImageUrl?.trim();
    final candidateRaw = source.url?.trim();
    final candidateDataUri =
        candidateRaw != null && candidateRaw.startsWith('data:image')
            ? candidateRaw
            : null;
    final candidateUrl = candidateDataUri == null ? candidateRaw : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compare cover versions'),
        content: SizedBox(
          width: 760,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current'),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildCoverImagePreview(
                          dataUri: currentDataUri,
                          imageUrl: currentUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Candidate'),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildCoverImagePreview(
                          dataUri: candidateDataUri,
                          imageUrl: candidateUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await _applyCoverVersionToPost(post: post, source: source);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Use candidate'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGeneratedCoverVersion({
    required Post post,
    required String? imageUrl,
    required String? dataUri,
    required String? prompt,
    required String? model,
  }) async {
    var persistedDataUri = dataUri?.trim();
    final normalizedUrl = imageUrl?.trim();
    if ((persistedDataUri == null || persistedDataUri.isEmpty) &&
        normalizedUrl != null &&
        normalizedUrl.isNotEmpty) {
      persistedDataUri = await _downloadImageAsDataUri(normalizedUrl);
    }

    final storage = persistedDataUri?.isNotEmpty == true
        ? persistedDataUri
        : (normalizedUrl?.isNotEmpty == true ? normalizedUrl : null);
    if (storage == null || storage.isEmpty) {
      return;
    }

    final promptText = (prompt?.trim().isNotEmpty ?? false)
        ? prompt!.trim()
        : (model?.trim().isNotEmpty ?? false)
            ? 'model: ${model!.trim()}'
            : null;

    await ref.read(sourceRepoProvider).createSourceItem(
          type: 'image',
          url: storage,
          title: 'Cover version ${DateTime.now().toUtc().toIso8601String()}',
          userNote: promptText,
          tags: const <String>[_coverVersionTag, _coverGeneratedTag],
          postId: post.id,
          projectId: post.projectId,
        );
  }

  Future<void> _applyCoverVersionToPost({
    required Post post,
    required SourceItem source,
  }) async {
    final raw = source.url?.trim();
    if (raw == null || raw.isEmpty) {
      return;
    }
    final dataUri = raw.startsWith('data:image') ? raw : null;
    final imageUrl = dataUri == null ? raw : null;
    await _applyCoverImageToPost(
      post: post,
      imageUrl: imageUrl,
      dataUri: dataUri,
      prompt: source.userNote?.trim().isEmpty ?? true
          ? source.title
          : source.userNote,
    );
  }

  Widget _buildActivePostCoverCard(Post post) {
    final dataUri = post.coverImageDataUri?.trim();
    final imageUrl = post.coverImageUrl?.trim();
    final prompt = post.coverImagePrompt?.trim();

    if ((dataUri == null || dataUri.isEmpty) &&
        (imageUrl == null || imageUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    final bytes = dataUri == null || dataUri.isEmpty
        ? null
        : _decodeDataUriBytes(dataUri);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 140,
                height: 90,
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : Image.network(imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current post cover image',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (prompt != null && prompt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Save + reveal',
              onPressed: () => _saveAndRevealCoverImage(
                dataUri: dataUri,
                imageUrl: imageUrl,
                suggestedName: post.title,
              ),
              icon: const Icon(Icons.save_alt_outlined),
            ),
            IconButton(
              tooltip: 'Clear post cover',
              onPressed: () async {
                await ref.read(postRepoProvider).updatePostCover(
                      postId: post.id,
                      coverImageUrl: null,
                      coverImageDataUri: null,
                      coverImagePrompt: null,
                    );
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post cover cleared')),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndRevealCoverImage({
    required String? dataUri,
    required String? imageUrl,
    String? suggestedName,
  }) async {
    try {
      final filePath = await _exportCoverImageForManualPublish(
        dataUri: dataUri,
        imageUrl: imageUrl,
        suggestedName: suggestedName,
      );
      if (!mounted) {
        return;
      }
      if (filePath == null || filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save cover image')),
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: filePath));
      await _revealExportedFile(filePath);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved cover image: $filePath (path copied)')),
      );
    } catch (error, stackTrace) {
      debugPrint(
          'compose.cover.save_reveal_failed error=$error stack=$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save + reveal failed: $error')),
      );
    }
  }

  Future<String?> _exportCoverImageForManualPublish({
    required String? dataUri,
    required String? imageUrl,
    String? suggestedName,
  }) async {
    final payload = await _resolveCoverImagePayload(
      dataUri: dataUri,
      imageUrl: imageUrl,
    );
    if (payload == null) {
      return null;
    }

    final downloads = await getDownloadsDirectory();
    final docs = await getApplicationDocumentsDirectory();
    final temp = await getTemporaryDirectory();
    final directories = <Directory?>[downloads, docs, temp];

    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final safeName = _sanitizeFilename(suggestedName ?? 'cover_image');

    for (final directory in directories.whereType<Directory>()) {
      try {
        await directory.create(recursive: true);
        final filePath =
            '${directory.path}/social_pub_hub_${safeName}_$timestamp.${payload.extension}';
        final file = File(filePath);
        await file.writeAsBytes(payload.bytes, flush: true);
        return file.path;
      } catch (error) {
        debugPrint(
          'compose.cover.write_failed directory=${directory.path} error=$error',
        );
      }
    }
    return null;
  }

  Future<_ResolvedImagePayload?> _resolveCoverImagePayload({
    required String? dataUri,
    required String? imageUrl,
  }) async {
    final normalizedDataUri = dataUri?.trim();
    if (normalizedDataUri != null && normalizedDataUri.isNotEmpty) {
      final commaIndex = normalizedDataUri.indexOf(',');
      if (commaIndex > 0 && commaIndex + 1 < normalizedDataUri.length) {
        try {
          final bytes =
              base64Decode(normalizedDataUri.substring(commaIndex + 1));
          final header =
              normalizedDataUri.substring(0, commaIndex).toLowerCase();
          final mimeMatch = RegExp(r'^data:([^;]+);base64$').firstMatch(header);
          final mimeType =
              mimeMatch == null ? 'image/png' : mimeMatch.group(1)!;
          return _ResolvedImagePayload(
            bytes: bytes,
            extension: _imageExtensionFromMime(mimeType),
          );
        } catch (error) {
          debugPrint('compose.cover.data_uri_decode_failed error=$error');
          return null;
        }
      }
    }

    final normalizedUrl = imageUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      return null;
    }
    try {
      final response = await ref.read(httpClientProvider).get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'compose.cover.image_download_failed status=${response.statusCode} url=$normalizedUrl',
        );
        return null;
      }
      final contentType =
          (response.headers['content-type'] ?? '').split(';').first.trim();
      var extension = contentType.isEmpty
          ? ''
          : _imageExtensionFromMime(contentType.toLowerCase());
      if (extension.isEmpty && uri.pathSegments.isNotEmpty) {
        final segment = uri.pathSegments.last;
        final dotIndex = segment.lastIndexOf('.');
        if (dotIndex >= 0 && dotIndex + 1 < segment.length) {
          final raw = segment.substring(dotIndex + 1).toLowerCase();
          if (raw == 'jpeg') {
            extension = 'jpg';
          } else if (const <String>{'png', 'jpg', 'webp', 'gif'}
              .contains(raw)) {
            extension = raw;
          }
        }
      }
      if (extension.isEmpty) {
        extension = 'png';
      }
      return _ResolvedImagePayload(
        bytes: response.bodyBytes,
        extension: extension,
      );
    } catch (error) {
      debugPrint('compose.cover.image_download_exception error=$error');
      return null;
    }
  }

  String _imageExtensionFromMime(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();
    if (normalized.contains('png')) {
      return 'png';
    }
    if (normalized.contains('jpeg') || normalized.contains('jpg')) {
      return 'jpg';
    }
    if (normalized.contains('webp')) {
      return 'webp';
    }
    if (normalized.contains('gif')) {
      return 'gif';
    }
    return 'png';
  }

  String _sanitizeFilename(String value) {
    final normalized = value.trim().toLowerCase();
    final cleaned = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'cover_image' : cleaned;
  }

  Future<void> _revealExportedFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('compose.cover.reveal_missing_file path=$filePath');
      return;
    }

    if (Platform.isMacOS) {
      try {
        final result =
            await Process.run('/usr/bin/open', <String>['-R', filePath]);
        if (result.exitCode == 0) {
          return;
        }
        debugPrint(
          'compose.cover.reveal_open_failed code=${result.exitCode} stderr=${result.stderr}',
        );
      } catch (error) {
        debugPrint('compose.cover.reveal_open_exception error=$error');
      }

      try {
        final launchedFolder = await launchUrl(
          Uri.directory(file.parent.path),
          mode: LaunchMode.externalApplication,
        );
        if (launchedFolder) {
          return;
        }
      } catch (error) {
        debugPrint('compose.cover.reveal_folder_launch_exception error=$error');
      }
    }

    try {
      await launchUrl(
        Uri.file(filePath),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('compose.cover.reveal_file_launch_exception error=$error');
    }
  }

  Uint8List? _decodeDataUriBytes(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex <= 0 || commaIndex + 1 >= dataUri.length) {
      return null;
    }
    try {
      return base64Decode(dataUri.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadImageAsDataUri(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return null;
    }
    try {
      final response = await ref.read(httpClientProvider).get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final contentTypeHeader = response.headers['content-type'];
      final mime = contentTypeHeader == null
          ? 'image/png'
          : contentTypeHeader.split(';').first.trim();
      final safeMime = mime.startsWith('image/') ? mime : 'image/png';
      return 'data:$safeMime;base64,${base64Encode(response.bodyBytes)}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyCoverImageToPost({
    required Post post,
    required String? imageUrl,
    required String? dataUri,
    required String? prompt,
  }) async {
    var persistedDataUri = dataUri?.trim();
    final normalizedUrl = imageUrl?.trim();
    if ((persistedDataUri == null || persistedDataUri.isEmpty) &&
        normalizedUrl != null &&
        normalizedUrl.isNotEmpty) {
      persistedDataUri = await _downloadImageAsDataUri(normalizedUrl);
    }

    await ref.read(postRepoProvider).updatePostCover(
          postId: post.id,
          coverImageUrl: normalizedUrl?.isEmpty ?? true ? null : normalizedUrl,
          coverImageDataUri:
              persistedDataUri?.isEmpty ?? true ? null : persistedDataUri,
          coverImagePrompt: prompt,
        );

    if (!mounted) {
      return;
    }
    final persisted = persistedDataUri != null && persistedDataUri.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          persisted
              ? 'Cover image applied to current post'
              : 'Cover applied with URL only (image host may expire)',
        ),
      ),
    );
  }

  int? _platformCharLimit(String platform) {
    if (platform.trim().toLowerCase() == 'x') {
      return _xVariantCharLimit;
    }
    return null;
  }

  String _enforceVariantPlatformLimit(String platform, String body) {
    final normalized = body.trim();
    final limit = _platformCharLimit(platform);
    if (limit == null || normalized.length <= limit) {
      return normalized;
    }

    final baseLimit = limit > 1 ? limit - 1 : 1;
    var truncated = normalized.substring(0, baseLimit).trimRight();
    final cutIndex = truncated.lastIndexOf(' ');
    if (cutIndex >= baseLimit - 48 && cutIndex > 0) {
      truncated = truncated.substring(0, cutIndex).trimRight();
    }
    if (truncated.isEmpty) {
      truncated = normalized.substring(0, baseLimit);
    }
    return '$truncated…';
  }

  Future<void> _openComposerForVariant({
    required String platform,
    required String text,
  }) async {
    final uri = composerUriForPlatform(platform: platform, text: text);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No composer URL configured for $platform')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open composer for $platform')),
      );
    }
  }

  Future<void> _editVariant(Variant variant) async {
    final controller = TextEditingController(text: variant.body);
    final nextText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${variant.platform.toUpperCase()} variant'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Variant text',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nextText == null) {
      return;
    }
    if (nextText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variant text cannot be empty')),
      );
      return;
    }
    final limitedText =
        _enforceVariantPlatformLimit(variant.platform, nextText);
    final limitApplied = limitedText.length < nextText.length;
    await ref.read(variantRepoProvider).updateVariantBody(
          variantId: variant.id,
          body: limitedText,
        );
    if (!mounted) {
      return;
    }
    final limit = _platformCharLimit(variant.platform);
    final message = limitApplied && limit != null
        ? 'Updated ${variant.platform.toUpperCase()} variant (trimmed to $limit chars)'
        : 'Updated ${variant.platform.toUpperCase()} variant';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteVariant(Variant variant) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete ${variant.platform.toUpperCase()} variant?'),
            content: const Text(
              'This removes the variant from local storage.',
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
    await ref.read(variantRepoProvider).deleteVariantById(variant.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Deleted ${variant.platform.toUpperCase()} variant')),
    );
  }

  Future<void> _confirmPosted(
    String variantId,
    String platform,
    String variantBody,
  ) async {
    try {
      final limit = _platformCharLimit(platform);
      final charCount = variantBody.trim().length;
      if (limit != null && charCount > limit) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'X variant is $charCount/$limit chars. Shorten before publish.',
            ),
          ),
        );
        return;
      }

      final externalUrl = await _promptExternalUrl();
      var loggedUrl = externalUrl;
      var backendConfirmed = false;
      Object? backendError;

      try {
        final baseUrl = ref.read(apiBaseUrlProvider);
        final response = await ref.read(httpClientProvider).post(
              Uri.parse('$baseUrl/publish/confirm'),
              headers: const {'content-type': 'application/json'},
              body: jsonEncode({
                'variant_id': variantId,
                if (externalUrl != null && externalUrl.isNotEmpty)
                  'external_post_url': externalUrl,
              }),
            );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          loggedUrl = (parsed['external_post_url'] as String?) ?? externalUrl;
          backendConfirmed = true;
        } else {
          backendError =
              Exception('Publish confirm failed: ${response.statusCode}');
        }
      } catch (error) {
        backendError = error;
      }

      await ref.read(publishLogRepoProvider).createPublishLog(
            variantId: variantId,
            platform: platform,
            mode: 'assisted',
            status: 'posted',
            externalUrl: loggedUrl,
            postedAt: DateTime.now().toUtc(),
          );

      if (!mounted) {
        return;
      }
      final fallbackSuffix = backendConfirmed
          ? ''
          : backendError == null
              ? ' (local log only)'
              : ' (fallback: ${backendError.runtimeType})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            backendConfirmed
                ? 'Publish confirmed and logged'
                : 'Backend confirm unavailable$fallbackSuffix. Logged locally as posted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirm failed: $e')),
      );
    }
  }

  Future<String?> _promptExternalUrl() async {
    final controller = TextEditingController();
    final value = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External post URL (optional)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value?.isEmpty ?? true ? null : value;
  }

  void _openPublishChecklist() {
    final draftId = _draftId;
    if (draftId == null || draftId.isEmpty) {
      return;
    }
    final encoded = Uri.encodeQueryComponent(draftId);
    context.go('/publish-checklist?draftId=$encoded');
  }

  Future<void> _deleteDraft() async {
    final draftId = _draftId;
    if (draftId == null || draftId.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete draft?'),
            content: const Text(
              'This permanently removes the draft, linked variants, and syncs the deletion.',
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

    _saveDebounce?.cancel();
    await ref.read(draftRepoProvider).deleteDraftById(draftId);
    if (!mounted) {
      return;
    }

    setState(() {
      _draftId = null;
      _loadedForPostId = null;
      _variantError = null;
      _saveError = null;
      _loading = true;
    });
    await _loadOrCreateDraft();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft ${draftId.substring(0, 8)} deleted')),
    );
  }

  Future<void> _exportVariantsCsv() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }
    final variants = ref.read(draftVariantsStreamProvider(draftId)).valueOrNull;
    if (variants == null || variants.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No variants to export')),
      );
      return;
    }
    final lines = <String>[
      'id,draft_id,platform,body,created_at,updated_at',
      ...variants.map((variant) {
        return [
          _csv(variant.id),
          _csv(variant.draftId),
          _csv(variant.platform),
          _csv(variant.body),
          _csv(variant.createdAt.toUtc().toIso8601String()),
          _csv(variant.updatedAt.toUtc().toIso8601String()),
        ].join(',');
      }),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${variants.length} variants as CSV')),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
