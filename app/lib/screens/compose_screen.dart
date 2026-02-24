import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../utils/composer_links.dart';
import '../widgets/hub_app_bar.dart';
import 'compose_queue_action.dart';

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

  final TextEditingController _controller = TextEditingController();
  Timer? _saveDebounce;
  String? _draftId;
  bool _loading = true;
  bool _hydratingEditor = false;
  String? _saveError;
  String? _variantError;
  bool _generatingVariants = false;
  bool _polishingDraft = false;
  final Set<String> _humanizingVariantIds = <String>{};
  double _humanizeStrictness = 0.7;
  String _variantPlatformFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEditorChanged);
    unawaited(_loadOrCreateDraft());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _controller.removeListener(_onEditorChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variantsAsync = _draftId == null
        ? null
        : ref.watch(draftVariantsStreamProvider(_draftId!));

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
            onPressed: (_draftId == null || _generatingVariants)
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
                                            onPressed: filtered.isEmpty
                                                ? null
                                                : () =>
                                                    _humanizeVisibleVariants(
                                                      filtered,
                                                    ),
                                            child:
                                                const Text('Humanize visible'),
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
                                          return ListTile(
                                            title: Text(
                                              variant.platform.toUpperCase(),
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
    final repo = ref.read(draftRepoProvider);
    var draft = await () async {
      final preferredDraftId = widget.initialDraftId;
      if (preferredDraftId != null && preferredDraftId.isNotEmpty) {
        return repo.getDraftById(preferredDraftId);
      }
      return null;
    }();
    draft ??= await repo.getLatestDraft();
    draft ??= await () async {
      final draftId = await repo.createDraft(
        canonicalMarkdown: _seedDraftText,
        intent: 'how_to',
      );
      return repo.getDraftById(draftId);
    }();

    if (!mounted) {
      return;
    }

    _hydratingEditor = true;
    _draftId = draft?.id;
    _controller.text = draft?.canonicalMarkdown ?? '';
    _hydratingEditor = false;
    setState(() {
      _loading = false;
      _saveError = null;
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
              ],
            }),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Generate failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final variantsRaw = parsed['variants'];
      final variants = variantsRaw is List
          ? variantsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>())
          : const Iterable<Map<String, dynamic>>.empty();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${variants.length} variants')),
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
      final sourceItems =
          await ref.read(sourceRepoProvider).getRecentSourceItems(limit: 12);
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/$draftId/polish'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
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
              'strictness': _humanizeStrictness,
            }),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Polish failed: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final nextText = (parsed['canonical_markdown'] as String?)?.trim();
      if (nextText == null || nextText.isEmpty) {
        throw Exception('Polish returned empty text');
      }
      final llmUsed = parsed['llm_used'] as bool? ?? false;
      final fallbackReason = (parsed['fallback_reason'] as String?)?.trim();

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
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/variants/${variant.id}/humanize'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'style_profile_id': styleProfile.id,
              'strictness': _humanizeStrictness,
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
    await ref.read(variantRepoProvider).updateVariantBody(
          variantId: variant.id,
          body: nextText,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Updated ${variant.platform.toUpperCase()} variant')),
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

  Future<void> _confirmPosted(String variantId, String platform) async {
    try {
      final externalUrl = await _promptExternalUrl();
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
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Publish confirm failed: ${response.statusCode}');
      }
      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final loggedUrl = (parsed['external_post_url'] as String?) ?? externalUrl;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publish confirmed and logged')),
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
