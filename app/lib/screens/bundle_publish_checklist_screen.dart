import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';

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
      appBar: AppBar(
        title: const Text('Bundle Publish Checklist'),
        actions: [
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
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: bundles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bundle = bundles[index];
                          final report = _buildReport(
                            bundle: bundle,
                            sources: sources,
                            variantById: variantById,
                            logs: logs,
                          );
                          return _BundleChecklistCard(
                            report: report,
                            onAttachSource: () => _attachLatestSourceToBundle(
                              context: context,
                              ref: ref,
                              report: report,
                            ),
                            onBackfillVariants: () => _backfillBundleVariants(
                              context: context,
                              ref: ref,
                              report: report,
                            ),
                          );
                        },
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
    final referenceDraftId =
        resolvedVariants.isEmpty ? null : resolvedVariants.first.draftId;

    final checks = <_ChecklistLine>[
      _ChecklistLine(
        label: 'Anchor reference set',
        passed: bundle.anchorRef != null && bundle.anchorRef!.trim().isNotEmpty,
        detail: 'anchor=${bundle.anchorType}:${bundle.anchorRef ?? '-'}',
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
      sourceCount: linkedSources.length,
      variantCount: relatedVariantIds.length,
      postedCount: postedVariantIds.length,
      missingVariantCount: missingVariantIds.length,
      missingPlatforms: missingPlatforms,
      referenceDraftId: referenceDraftId,
    );
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
}

class _BundleChecklistCard extends StatelessWidget {
  const _BundleChecklistCard({
    required this.report,
    required this.onAttachSource,
    required this.onBackfillVariants,
  });

  final _BundleReport report;
  final Future<void> Function() onAttachSource;
  final Future<void> Function() onBackfillVariants;

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
                if (report.missingPlatforms.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: onBackfillVariants,
                    child: Text(
                        'Backfill ${report.missingPlatforms.length} platforms'),
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
    required this.sourceCount,
    required this.variantCount,
    required this.postedCount,
    required this.missingVariantCount,
    required this.missingPlatforms,
    required this.referenceDraftId,
  });

  final Bundle bundle;
  final List<_ChecklistLine> checks;
  final int passedChecks;
  final int totalChecks;
  final int sourceCount;
  final int variantCount;
  final int postedCount;
  final int missingVariantCount;
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
