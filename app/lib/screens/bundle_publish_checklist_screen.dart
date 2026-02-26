import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';
import '../utils/content_type_utils.dart';

class BundlePublishChecklistScreen extends ConsumerStatefulWidget {
  const BundlePublishChecklistScreen({super.key});

  @override
  ConsumerState<BundlePublishChecklistScreen> createState() =>
      _BundlePublishChecklistScreenState();
}

class _BundlePublishChecklistScreenState
    extends ConsumerState<BundlePublishChecklistScreen> {
  bool _includeAllPosts = false;

  static const List<String> _targetPlatforms = <String>[
    'x',
    'linkedin',
    'reddit',
    'facebook',
    'youtube',
    'substack',
    'medium',
  ];

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final bundlesAsync = ref.watch(bundlesStreamProvider);
    final sourcesAsync = ref.watch(sourceItemsStreamProvider);
    final variantsAsync = ref.watch(allVariantsStreamProvider);
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Bundle Publish Checklist',
        actions: [
          IconButton(
            tooltip: 'Export checklist CSV',
            onPressed: () => _exportChecklistCsv(context, ref),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Open bundles',
            onPressed: () => context.go('/bundles'),
            icon: const Icon(Icons.view_kanban_outlined),
          ),
        ],
      ),
      body: bundlesAsync.when(
        data: (bundles) {
          final scopedBundles = _scopeBundles(
            bundles,
            activePostId: activePost?.id,
            includeAllPosts: _includeAllPosts,
          );
          return sourcesAsync.when(
            data: (sources) {
              return variantsAsync.when(
                data: (variants) {
                  return logsAsync.when(
                    data: (logs) {
                      final variantById = <String, Variant>{
                        for (final row in variants) row.id: row,
                      };
                      final reports = scopedBundles
                          .map(
                            (bundle) => _buildReport(
                              bundle: bundle,
                              sources: sources,
                              variantById: variantById,
                              logs: logs,
                            ),
                          )
                          .toList(growable: false);
                      reports.sort((a, b) {
                        final aProgress = a.totalChecks == 0
                            ? 0.0
                            : a.passedChecks / a.totalChecks;
                        final bProgress = b.totalChecks == 0
                            ? 0.0
                            : b.passedChecks / b.totalChecks;
                        return aProgress.compareTo(bProgress);
                      });

                      final readyCount = reports
                          .where((row) => row.passedChecks >= row.totalChecks)
                          .length;
                      final needsWorkCount = reports.length - readyCount;
                      final totalMissingPlatforms = reports.fold<int>(
                        0,
                        (sum, row) => sum + row.missingPlatforms.length,
                      );
                      final totalMissingVariants = reports.fold<int>(
                        0,
                        (sum, row) => sum + row.missingVariantCount,
                      );

                      return ListView(
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
                              'Show bundles from all posts instead of only active post',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          if (scopedBundles.isEmpty)
                            Text(
                              _includeAllPosts
                                  ? 'No bundles found. Create a bundle first.'
                                  : 'No bundles in active post scope.',
                            ),
                          if (scopedBundles.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text('Bundles: ${reports.length}'),
                                    Text('Ready: $readyCount'),
                                    Text('Needs work: $needsWorkCount'),
                                    Text(
                                        'Missing platforms: $totalMissingPlatforms'),
                                    Text(
                                        'Missing variants: $totalMissingVariants'),
                                  ],
                                ),
                              ),
                            ),
                          if (scopedBundles.isNotEmpty)
                            const SizedBox(height: 12),
                          if (scopedBundles.isNotEmpty)
                            ...reports.map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _BundleChecklistCard(
                                  report: report,
                                  onGenerateCanonicalDraft: () =>
                                      _generateCanonicalDraftFromSources(
                                    context: context,
                                    ref: ref,
                                    report: report,
                                  ),
                                  onAttachSource: () =>
                                      _attachLatestSourceToBundle(
                                    context: context,
                                    ref: ref,
                                    report: report,
                                  ),
                                  onBackfillVariants: () =>
                                      _backfillBundleVariants(
                                    context: context,
                                    ref: ref,
                                    report: report,
                                  ),
                                  onCleanMissingVariants: () =>
                                      _cleanMissingVariantRefs(
                                    context: context,
                                    ref: ref,
                                    report: report,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                        child: Text('Failed loading publish logs: $error')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed loading variants: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed loading source items: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading bundles: $error')),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => context.go('/compose'),
                child: const Text('Compose'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  if (!_includeAllPosts && activePost != null) {
                    final encoded = Uri.encodeQueryComponent(activePost.id);
                    context.go('/history?postId=$encoded');
                    return;
                  }
                  context.go('/history');
                },
                child: const Text('History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BundleReport _buildReport({
    required Bundle bundle,
    required List<SourceItem> sources,
    required Map<String, Variant> variantById,
    required List<PublishLog> logs,
  }) {
    final relatedVariantIds = bundle.relatedVariantIds;
    final linkedSources = sources
        .where((row) => row.bundleId == bundle.id)
        .toList(growable: false);
    final resolvedVariants = relatedVariantIds
        .map((id) => variantById[id])
        .whereType<Variant>()
        .toList(growable: false);
    final missingVariantIds = relatedVariantIds
        .where((id) => !variantById.containsKey(id))
        .toList(growable: false);

    final postedLogs = logs.where((row) {
      final variantId = row.variantId;
      if (variantId == null) {
        return false;
      }
      return relatedVariantIds.contains(variantId) && row.status == 'posted';
    }).toList(growable: false);
    final postedVariantIds =
        postedLogs.map((row) => row.variantId).whereType<String>().toSet();

    final uniquePlatforms = resolvedVariants.map((row) => row.platform).toSet();
    final missingPlatforms = _targetPlatforms
        .where((platform) => !uniquePlatforms.contains(platform))
        .toList(growable: false);
    final canonicalDraftId = bundle.canonicalDraftId;
    final referenceDraftId = (canonicalDraftId != null &&
            canonicalDraftId.trim().isNotEmpty)
        ? canonicalDraftId
        : (resolvedVariants.isEmpty ? null : resolvedVariants.first.draftId);

    final checks = <_ChecklistLine>[
      _ChecklistLine(
        label: 'Anchor reference set',
        passed: bundle.anchorRef != null && bundle.anchorRef!.trim().isNotEmpty,
        detail: 'anchor=${bundle.anchorType}:${bundle.anchorRef ?? '-'}',
      ),
      _ChecklistLine(
        label: 'Canonical draft linked',
        passed: referenceDraftId != null && referenceDraftId.isNotEmpty,
        detail: referenceDraftId == null || referenceDraftId.isEmpty
            ? 'Generate canonical from linked sources'
            : 'draft=${referenceDraftId.substring(0, 8)}',
      ),
      _ChecklistLine(
        label: 'At least 1 source linked',
        passed: linkedSources.isNotEmpty,
        detail: 'linked sources=${linkedSources.length}',
      ),
      _ChecklistLine(
        label: 'At least 1 variant selected',
        passed: relatedVariantIds.isNotEmpty,
        detail: 'selected variants=${relatedVariantIds.length}',
      ),
      _ChecklistLine(
        label: 'No missing local variants',
        passed: missingVariantIds.isEmpty,
        detail: missingVariantIds.isEmpty
            ? 'all selected variants exist locally'
            : 'missing=${missingVariantIds.length}',
      ),
      _ChecklistLine(
        label: 'Platform diversity (2+)',
        passed: uniquePlatforms.length >= 2,
        detail: 'platforms=${uniquePlatforms.length}',
      ),
      _ChecklistLine(
        label: 'Publish progress complete',
        passed: relatedVariantIds.isNotEmpty &&
            postedVariantIds.length >= relatedVariantIds.length,
        detail: 'posted=${postedVariantIds.length}/${relatedVariantIds.length}',
      ),
    ];

    final passedChecks = checks.where((row) => row.passed).length;
    return _BundleReport(
      bundle: bundle,
      checks: checks,
      passedChecks: passedChecks,
      totalChecks: checks.length,
      linkedSources: linkedSources,
      sourceCount: linkedSources.length,
      variantCount: relatedVariantIds.length,
      postedCount: postedVariantIds.length,
      missingVariantCount: missingVariantIds.length,
      missingVariantIds: missingVariantIds,
      missingPlatforms: missingPlatforms,
      referenceDraftId: referenceDraftId,
    );
  }

  Future<void> _generateCanonicalDraftFromSources({
    required BuildContext context,
    required WidgetRef ref,
    required _BundleReport report,
  }) async {
    final activePost = ref.read(activePostProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (report.linkedSources.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link at least one source first')),
      );
      return;
    }
    final postId = report.bundle.postId ?? activePost?.id;
    final post = postId == null
        ? activePost
        : await ref.read(postRepoProvider).getPostById(postId);
    final contentType = post?.contentType ?? 'general_post';
    final styleProfile =
        await ref.read(styleProfileRepoProvider).getOrCreateDefault();
    final tone = styleProfile.casualFormal.clamp(0.0, 1.0).toDouble();
    final punchiness = styleProfile.punchiness.clamp(0.0, 1.0).toDouble();
    final localCanonical = _canonicalFromSources(
      report.bundle,
      report.linkedSources,
      contentType: contentType,
    );

    final draftRepo = ref.read(draftRepoProvider);
    var draftId = '';
    var canonical = '';
    var llmUsed = false;

    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/from_sources'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'source_ids': report.linkedSources
                  .map((row) => row.id)
                  .toList(growable: false),
              'source_materials': report.linkedSources
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
              'intent': _intentForContentType(contentType),
              'tone': tone,
              'punchiness': punchiness,
              'audience': post?.audience ?? activePost?.audience ?? 'engineers',
              'length_target': 'short',
              'post_id': postId,
              'post_title':
                  post?.title ?? activePost?.title ?? report.bundle.name,
              'post_goal': post?.goal ?? activePost?.goal,
              'content_type': contentType,
              'style_traits': styleProfile.personalTraits,
              'differentiation_points': styleProfile.differentiationPoints,
              'personal_prompt': styleProfile.customPrompt,
              'banned_phrases': styleProfile.bannedPhrases,
            }),
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        draftId = (parsed['draft_id'] as String?)?.trim() ?? '';
        canonical = (parsed['canonical_markdown'] as String?)?.trim() ?? '';
        llmUsed = parsed['llm_used'] as bool? ?? false;
      }
    } catch (_) {
      // Fall back to local template generation when backend is unavailable.
    }

    if (draftId.isEmpty) {
      draftId = await draftRepo.createDraft(
        canonicalMarkdown: localCanonical,
        intent: _intentForContentType(contentType),
        tone: tone,
        punchiness: punchiness,
        audience: post?.audience ?? activePost?.audience ?? 'engineers',
        postId: postId,
        contentType: contentType,
      );
      llmUsed = false;
    } else {
      await draftRepo.createDraft(
        id: draftId,
        canonicalMarkdown: canonical.isEmpty ? localCanonical : canonical,
        intent: _intentForContentType(contentType),
        tone: tone,
        punchiness: punchiness,
        audience: post?.audience ?? activePost?.audience ?? 'engineers',
        postId: postId,
        contentType: contentType,
      );
    }
    await ref.read(bundleRepoProvider).setCanonicalDraftId(
          bundleId: report.bundle.id,
          draftId: draftId,
        );
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            llmUsed
                ? 'Canonical draft ${draftId.substring(0, 8)} linked (LLM).'
                : 'Canonical draft ${draftId.substring(0, 8)} linked (template).',
          ),
        ),
      );
    }
  }

  Future<void> _attachLatestSourceToBundle({
    required BuildContext context,
    required WidgetRef ref,
    required _BundleReport report,
  }) async {
    final activePost = ref.read(activePostProvider);
    final scopedPostId = report.bundle.postId ?? activePost?.id;
    final sourceRepo = ref.read(sourceRepoProvider);
    final existing = await sourceRepo.getLatestUnbundledSource(
      postId: scopedPostId,
      includeGlobal: true,
    );
    if (existing != null) {
      await sourceRepo.assignBundle(
        sourceId: existing.id,
        bundleId: report.bundle.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Attached source ${existing.id.substring(0, 8)}')),
        );
      }
      return;
    }

    final createdId = await sourceRepo.createSourceItem(
      type: 'note',
      userNote: 'Seed source for bundle: ${report.bundle.name}',
      tags: const <String>['bundle', 'seed'],
      bundleId: report.bundle.id,
      postId: scopedPostId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Seed source ${createdId.substring(0, 8)} created')),
      );
    }
  }

  Future<void> _backfillBundleVariants({
    required BuildContext context,
    required WidgetRef ref,
    required _BundleReport report,
  }) async {
    if (report.missingPlatforms.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No missing platforms to backfill')),
        );
      }
      return;
    }

    var draftId = report.referenceDraftId;
    if (draftId == null || draftId.isEmpty) {
      final latestDraft = await ref.read(draftRepoProvider).getLatestDraft(
            postId: report.bundle.postId ?? ref.read(activePostProvider)?.id,
          );
      draftId = latestDraft?.id;
    }
    if (draftId == null || draftId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No draft found to backfill variants')),
        );
      }
      return;
    }

    final variantRepo = ref.read(variantRepoProvider);
    final createdIds = <String>[];
    var contentType = 'general_post';
    var fallbackReason = '';
    try {
      final styleProfile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      final draft = await ref.read(draftRepoProvider).getDraftById(draftId);
      final activePost = ref.read(activePostProvider);
      final postId = report.bundle.postId ?? activePost?.id;
      final post = postId == null
          ? activePost
          : await ref.read(postRepoProvider).getPostById(postId);
      contentType = draft?.contentType ?? post?.contentType ?? 'general_post';

      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/$draftId/variants'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'platforms': report.missingPlatforms,
              'style_profile_id': styleProfile.id,
              'content_type': contentType,
            }),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final variantsRaw = parsed['variants'];
      final generated = variantsRaw is List
          ? variantsRaw
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (generated.isEmpty) {
        throw Exception('empty response');
      }

      for (final variant in generated) {
        final variantId = await variantRepo.createVariant(
          id: variant['id'] as String?,
          draftId: draftId,
          platform: (variant['platform'] as String?) ?? 'x',
          body: (variant['text'] as String?) ?? '',
        );
        createdIds.add(variantId);
      }
    } catch (error) {
      fallbackReason = '$error';
      for (final platform in report.missingPlatforms) {
        final variantId = await variantRepo.createVariant(
          draftId: draftId,
          platform: platform,
          body: _variantTemplate(platform, contentType: contentType),
        );
        createdIds.add(variantId);
      }
    }
    await ref.read(bundleRepoProvider).addRelatedVariantIds(
          bundleId: report.bundle.id,
          variantIds: createdIds,
        );
    if (context.mounted) {
      final suffix =
          fallbackReason.isEmpty ? '' : ' (template fallback: $fallbackReason)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backfilled ${createdIds.length} variants$suffix'),
        ),
      );
    }
  }

  Future<void> _cleanMissingVariantRefs({
    required BuildContext context,
    required WidgetRef ref,
    required _BundleReport report,
  }) async {
    if (report.missingVariantIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No stale refs to clean')),
        );
      }
      return;
    }
    await ref.read(bundleRepoProvider).removeRelatedVariantIds(
          bundleId: report.bundle.id,
          variantIds: report.missingVariantIds,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Removed ${report.missingVariantIds.length} stale variant refs'),
        ),
      );
    }
  }

  String _variantTemplate(String platform, {required String contentType}) {
    if (isCodingGuideType(contentType) ||
        (isGuideLikeType(contentType) && !isAiToolGuideType(contentType))) {
      if (platform == 'x') {
        return 'Guide quick take:\n- Problem\n- Fix\n- Verify\nWhat edge case should I add?';
      }
      if (platform == 'linkedin') {
        return 'Guide summary:\n• Setup\n• Implementation steps\n• Verification\nWhat would you change?';
      }
      if (platform == 'reddit') {
        return 'Context + implementation tradeoff:\nI tested a practical guide path and saw mixed results.\nWhat should I benchmark next?';
      }
      if (platform == 'facebook') {
        return 'Guide update:\n- Setup\n- Steps\n- Pitfall to avoid\nThoughts?';
      }
      if (platform == 'youtube') {
        return 'Title: Practical guide breakdown\nDescription:\n- Problem\n- Implementation\n- Verification\nPinned comment: Which case should I test next?';
      }
      if (platform == 'substack') {
        return 'Title: Practical guide walkthrough\n\nSection outline:\n- Setup and prerequisites\n- Step-by-step implementation\n- Verification and pitfalls\n\nCTA: Which section should I expand?';
      }
      if (platform == 'medium') {
        return 'Title: Practical implementation guide\n\nDraft outline:\n- Problem framing\n- Implementation steps\n- Verification + pitfalls\n- Repro checklist\n\nClose: What edge case should I add?';
      }
    }
    if (isAiToolGuideType(contentType)) {
      if (platform == 'x') {
        return 'AI tool guide:\n- Prompt shape\n- Guardrail\n- Cost note\nWhat tool should I compare next?';
      }
      if (platform == 'linkedin') {
        return 'AI workflow note:\n• Use-case\n• Prompt template\n• Guardrails and cost\nHow are you running this?';
      }
      if (platform == 'reddit') {
        return 'AI tooling context + tradeoff:\nI tested a prompt workflow and saw mixed results.\nWhat parameters would you tune first?';
      }
      if (platform == 'facebook') {
        return 'AI tool update:\n- Use-case\n- Prompt template\n- Failure mode to watch\nWould you use this flow?';
      }
      if (platform == 'youtube') {
        return 'Title: Practical AI tool workflow\nDescription:\n- Use-case\n- Prompt + parameters\n- Guardrails/cost\nPinned comment: What tool should I test next?';
      }
      if (platform == 'substack') {
        return 'Title: Practical AI tool guide\n\nSection outline:\n- Use-case and context\n- Prompt template + parameters\n- Guardrails, cost, and failure modes\n- Operating checklist\n\nCTA: Which tool should I benchmark next?';
      }
      if (platform == 'medium') {
        return 'Title: AI workflow field guide\n\nDraft outline:\n- Problem framing\n- Prompt strategy\n- Guardrails + cost controls\n- Lessons learned\n\nClose: What would you tune first?';
      }
    }
    if (platform == 'x') {
      return 'Quick build update:\n- What changed\n- Tradeoff\nWhat would you test next?';
    }
    if (platform == 'linkedin') {
      return 'Build note:\n• Context\n• Decision\n• Result to watch\nHow would you approach this?';
    }
    if (platform == 'reddit') {
      return 'Context + tradeoff:\nI tried a lightweight path and got mixed results.\nWhat would you change first?';
    }
    if (platform == 'facebook') {
      return 'Sharing a practical update from this build cycle.\nWhat do you think?';
    }
    if (platform == 'youtube') {
      return 'Title: Practical breakdown\nDescription:\n- Context\n- Tradeoff\n- Next step\nPinned comment: What should I test next?';
    }
    if (platform == 'substack') {
      return 'Title: Build decision breakdown\n\nSection outline:\n- Context\n- Decision + tradeoff\n- Evidence\n- Next action\n\nCTA: Which part deserves a deeper dive?';
    }
    if (platform == 'medium') {
      return 'Title: Build decision deep dive\n\nDraft outline:\n- Problem framing\n- Options considered\n- Chosen path + tradeoff\n- What to test next\n\nClose: How would you approach this?';
    }
    return 'Platform variant draft';
  }

  String _canonicalFromSources(
    Bundle bundle,
    List<SourceItem> sources, {
    required String contentType,
  }) {
    final bullets = sources.take(5).map((source) {
      final label = source.title?.trim().isNotEmpty == true
          ? source.title!.trim()
          : (source.userNote?.trim().isNotEmpty == true
              ? source.userNote!.trim()
              : (source.url?.trim().isNotEmpty == true
                  ? source.url!.trim()
                  : source.type));
      return '- $label';
    }).join('\n');
    if (isCodingGuideType(contentType) ||
        (isGuideLikeType(contentType) && !isAiToolGuideType(contentType))) {
      return '''
# ${bundle.name}

Hook: Practical guide walkthrough from this bundle.

Sources:
$bullets

Guide shape:
- Setup and prerequisites
- Step-by-step implementation
- Verification and pitfalls

Takeaway: Start with one testable path, then iterate.
''';
    }
    if (isAiToolGuideType(contentType)) {
      return '''
# ${bundle.name}

Hook: Applied AI tool workflow pulled from this bundle.

Sources:
$bullets

Guide shape:
- Use-case and setup
- Prompt template + parameters
- Guardrails, cost, and failure modes

Takeaway: Start narrow, measure, then harden.
''';
    }
    return '''
# ${bundle.name}

Hook: I grouped these sources into one publish wave and extracted a practical angle.

Sources:
$bullets

Draft shape:
- What changed
- Why it matters now
- One tradeoff worth debating

Takeaway: Start with a concrete step and ask for feedback.
''';
  }

  Future<void> _exportChecklistCsv(BuildContext context, WidgetRef ref) async {
    final bundles = ref.read(bundlesStreamProvider).valueOrNull;
    final sources = ref.read(sourceItemsStreamProvider).valueOrNull;
    final variants = ref.read(allVariantsStreamProvider).valueOrNull;
    final logs = ref.read(publishLogsStreamProvider).valueOrNull;
    final activePost = ref.read(activePostProvider);

    if (bundles == null ||
        sources == null ||
        variants == null ||
        logs == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist still loading')),
      );
      return;
    }

    final scopedBundles = _scopeBundles(
      bundles,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    );
    final variantById = {for (final row in variants) row.id: row};
    final reports = scopedBundles
        .map(
          (bundle) => _buildReport(
            bundle: bundle,
            sources: sources,
            variantById: variantById,
            logs: logs,
          ),
        )
        .toList(growable: false);
    if (reports.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bundles to export')),
      );
      return;
    }

    final lines = <String>[
      'bundle_id,bundle_name,readiness_score,passed_checks,total_checks,source_count,variant_count,posted_count,missing_variant_count,missing_platforms,reference_draft_id',
      ...reports.map((report) {
        final readiness = report.totalChecks == 0
            ? 0.0
            : report.passedChecks / report.totalChecks;
        return [
          _csv(report.bundle.id),
          _csv(report.bundle.name),
          _csv(readiness.toStringAsFixed(3)),
          _csv('${report.passedChecks}'),
          _csv('${report.totalChecks}'),
          _csv('${report.sourceCount}'),
          _csv('${report.variantCount}'),
          _csv('${report.postedCount}'),
          _csv('${report.missingVariantCount}'),
          _csv(report.missingPlatforms.join('|')),
          _csv(report.referenceDraftId ?? ''),
        ].join(',');
      }),
    ];

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${reports.length} bundle checklist rows')),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
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

  String _intentForContentType(String contentType) {
    return intentForContentType(contentType);
  }
}

class _BundleChecklistCard extends StatelessWidget {
  const _BundleChecklistCard({
    required this.report,
    required this.onGenerateCanonicalDraft,
    required this.onAttachSource,
    required this.onBackfillVariants,
    required this.onCleanMissingVariants,
  });

  final _BundleReport report;
  final Future<void> Function() onGenerateCanonicalDraft;
  final Future<void> Function() onAttachSource;
  final Future<void> Function() onBackfillVariants;
  final Future<void> Function() onCleanMissingVariants;

  @override
  Widget build(BuildContext context) {
    final publishProgress = report.variantCount == 0
        ? 0.0
        : report.postedCount / report.variantCount;
    final readinessProgress = report.totalChecks == 0
        ? 0.0
        : report.passedChecks / report.totalChecks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.bundle.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'anchor=${report.bundle.anchorType}:${report.bundle.anchorRef ?? '-'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Sources ${report.sourceCount}  •  Variants ${report.variantCount}  •  Posted ${report.postedCount}',
            ),
            if (report.missingVariantCount > 0)
              Text(
                'Missing local variants: ${report.missingVariantCount}',
                style: const TextStyle(color: Colors.orange),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (report.sourceCount == 0)
                  FilledButton.tonal(
                    onPressed: onAttachSource,
                    child: const Text('Attach latest source'),
                  ),
                if (report.sourceCount > 0 &&
                    (report.referenceDraftId == null ||
                        report.referenceDraftId!.isEmpty))
                  FilledButton.tonal(
                    onPressed: onGenerateCanonicalDraft,
                    child: const Text('Generate canonical draft'),
                  ),
                if (report.referenceDraftId != null &&
                    report.referenceDraftId!.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () {
                      final encoded =
                          Uri.encodeQueryComponent(report.referenceDraftId!);
                      context.go('/compose?draftId=$encoded');
                    },
                    child: const Text('Open canonical'),
                  ),
                FilledButton.tonal(
                  onPressed: () {
                    final encoded = Uri.encodeQueryComponent(report.bundle.id);
                    context.go('/publish?bundleId=$encoded');
                  },
                  child: const Text('Open publish console'),
                ),
                if (report.missingPlatforms.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: onBackfillVariants,
                    child: Text(
                        'Backfill ${report.missingPlatforms.length} platforms'),
                  ),
                if (report.missingVariantCount > 0)
                  FilledButton.tonal(
                    onPressed: onCleanMissingVariants,
                    child:
                        Text('Clean ${report.missingVariantCount} stale refs'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Readiness ${report.passedChecks}/${report.totalChecks}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: readinessProgress),
            const SizedBox(height: 10),
            Text(
              'Publish progress ${report.postedCount}/${report.variantCount}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: publishProgress),
            const SizedBox(height: 10),
            for (final check in report.checks)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  check.passed ? Icons.check_circle : Icons.error_outline,
                  color: check.passed ? Colors.green : Colors.orange,
                ),
                title: Text(check.label),
                subtitle: Text(check.detail),
              ),
          ],
        ),
      ),
    );
  }
}

class _BundleReport {
  const _BundleReport({
    required this.bundle,
    required this.checks,
    required this.passedChecks,
    required this.totalChecks,
    required this.linkedSources,
    required this.sourceCount,
    required this.variantCount,
    required this.postedCount,
    required this.missingVariantCount,
    required this.missingVariantIds,
    required this.missingPlatforms,
    required this.referenceDraftId,
  });

  final Bundle bundle;
  final List<_ChecklistLine> checks;
  final int passedChecks;
  final int totalChecks;
  final List<SourceItem> linkedSources;
  final int sourceCount;
  final int variantCount;
  final int postedCount;
  final int missingVariantCount;
  final List<String> missingVariantIds;
  final List<String> missingPlatforms;
  final String? referenceDraftId;
}

class _ChecklistLine {
  const _ChecklistLine({
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String label;
  final bool passed;
  final String detail;
}
