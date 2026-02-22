import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';

class SyncConflictsScreen extends ConsumerWidget {
  const SyncConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(openSyncConflictsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync conflicts')),
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
