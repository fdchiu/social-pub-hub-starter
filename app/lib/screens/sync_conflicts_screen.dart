import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';

class SyncConflictsScreen extends ConsumerStatefulWidget {
  const SyncConflictsScreen({super.key});

  @override
  ConsumerState<SyncConflictsScreen> createState() =>
      _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends ConsumerState<SyncConflictsScreen> {
  bool _resolvingAll = false;

  @override
  Widget build(BuildContext context) {
    final conflictsAsync = ref.watch(openSyncConflictsStreamProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Sync conflicts',
        actions: [
          IconButton(
            tooltip: 'Keep all remote',
            onPressed:
                _resolvingAll ? null : () => _resolveAll(useLocal: false),
            icon: _resolvingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: 'Use all local',
            onPressed: _resolvingAll ? null : () => _resolveAll(useLocal: true),
            icon: const Icon(Icons.edit_note_outlined),
          ),
        ],
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text('No open sync conflicts.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: conflicts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return _ConflictCard(conflict: conflict);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading conflicts: $error')),
      ),
    );
  }

  Future<void> _resolveAll({required bool useLocal}) async {
    final conflicts = ref.read(openSyncConflictsStreamProvider).valueOrNull;
    if (conflicts == null || conflicts.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open conflicts')),
      );
      return;
    }

    final actionLabel = useLocal ? 'Use local for all' : 'Keep remote for all';
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(actionLabel),
            content: Text('Apply this to ${conflicts.length} open conflicts?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    setState(() {
      _resolvingAll = true;
    });
    try {
      final service = ref.read(syncServiceProvider);
      for (final row in conflicts) {
        if (useLocal) {
          await service.resolveConflictUseLocal(row.id);
        } else {
          await service.resolveConflictKeepRemote(row.id);
        }
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionLabel complete (${conflicts.length})')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk resolve failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingAll = false;
        });
      }
    }
  }
}

class _ConflictCard extends ConsumerWidget {
  const _ConflictCard({required this.conflict});

  final SyncConflict conflict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localUpdatedAt =
        _asShortTimestamp(conflict.localPayload['updated_at']);
    final remoteUpdatedAt =
        _asShortTimestamp(conflict.remotePayload['updated_at']);
    final summary = _summaryForConflict(conflict);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conflict.entityType} · ${conflict.entityId}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
                'Detected: ${conflict.detectedAt.toLocal().toIso8601String()}'),
            Text('Local updated: $localUpdatedAt'),
            Text('Remote updated: $remoteUpdatedAt'),
            if (summary != null) ...[
              const SizedBox(height: 6),
              Text(summary),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await ref
                        .read(syncServiceProvider)
                        .resolveConflictKeepRemote(conflict.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kept remote version')),
                      );
                    }
                  },
                  child: const Text('Keep remote'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(syncServiceProvider)
                        .resolveConflictUseLocal(conflict.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Restored local edit and marked dirty')),
                      );
                    }
                  },
                  child: const Text('Use local'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _asShortTimestamp(Object? value) {
    if (value is! String || value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value;
    }
    return parsed.toIso8601String();
  }

  String? _summaryForConflict(SyncConflict row) {
    final localText = _extractText(row.localPayload);
    final remoteText = _extractText(row.remotePayload);
    if (localText == null && remoteText == null) {
      return null;
    }
    final localPreview = (localText ?? '-').replaceAll('\n', ' ');
    final remotePreview = (remoteText ?? '-').replaceAll('\n', ' ');
    return 'Local: $localPreview\nRemote: $remotePreview';
  }

  String? _extractText(Map<String, dynamic> payload) {
    for (final key in const [
      'canonical_markdown',
      'text',
      'content',
      'status',
      'voice_name',
    ]) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        if (value.length > 120) {
          return '${value.substring(0, 120)}…';
        }
        return value;
      }
    }
    return null;
  }
}
