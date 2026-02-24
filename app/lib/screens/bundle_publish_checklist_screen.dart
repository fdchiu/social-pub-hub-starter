import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';

class BundlePublishChecklistScreen extends ConsumerWidget {
  const BundlePublishChecklistScreen({super.key});

  static const List<String> _targetPlatforms = <String>[
    'x',
    'linkedin',
    'reddit',
    'facebook',
    'youtube',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundlesAsync = ref.watch(bundlesStreamProvider);
    final sourcesAsync = ref.watch(sourceItemsStreamProvider);
    final variantsAsync = ref.watch(allVariantsStreamProvider);
    final logsAsync = ref.watch(publishLogsStreamProvider);

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
          if (bundles.isEmpty) {
            return const Center(
              child: Text('No bundles found. Create a bundle first.'),
            );
          }
          return sourcesAsync.when(
            data: (sources) {
              return variantsAsync.when(
                data: (variants) {
                  return logsAsync.when(
                    data: (logs) {
                      final variantById = <String, Variant>{
                        for (final row in variants) row.id: row,
                      };
                      final reports = bundles
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
                          const SizedBox(height: 12),
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
                onPressed: () => context.go('/history'),
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
    final messenger = ScaffoldMessenger.of(context);
    if (report.linkedSources.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link at least one source first')),
      );
      return;
    }
    final canonical =
        _canonicalFromSources(report.bundle, report.linkedSources);
    final draftId = await ref.read(draftRepoProvider).createDraft(
          canonicalMarkdown: canonical,
          intent: 'how_to',
          audience: 'engineers',
        );
    await ref.read(bundleRepoProvider).setCanonicalDraftId(
          bundleId: report.bundle.id,
          draftId: draftId,
        );
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Canonical draft ${draftId.substring(0, 8)} linked'),
        ),
      );
    }
  }

  Future<void> _attachLatestSourceToBundle({
    required BuildContext context,
    required WidgetRef ref,
    required _BundleReport report,
  }) async {
    final sourceRepo = ref.read(sourceRepoProvider);
    final existing = await sourceRepo.getLatestUnbundledSource();
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
      final latestDraft = await ref.read(draftRepoProvider).getLatestDraft();
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
    for (final platform in report.missingPlatforms) {
      final variantId = await variantRepo.createVariant(
        draftId: draftId,
        platform: platform,
        body: _variantTemplate(platform),
      );
      createdIds.add(variantId);
    }
    await ref.read(bundleRepoProvider).addRelatedVariantIds(
          bundleId: report.bundle.id,
          variantIds: createdIds,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backfilled ${createdIds.length} variants')),
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

  String _variantTemplate(String platform) {
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
    return 'Platform variant draft';
  }

  String _canonicalFromSources(Bundle bundle, List<SourceItem> sources) {
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

    final variantById = {for (final row in variants) row.id: row};
    final reports = bundles
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
