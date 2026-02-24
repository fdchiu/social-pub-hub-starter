import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  bool _resolvingAll = false;

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
          IconButton(
            tooltip: 'Export conflicts JSON',
            onPressed: _exportConflictsJson,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text('No open sync conflicts.'));
          }
          final filtered = _filterConflicts(conflicts);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: 'Search conflicts',
                    hintText: 'entity id/type/status/voice',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _queryController.clear(),
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:
                      Text('Visible: ${filtered.length}/${conflicts.length}'),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No conflicts match search.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conflict = filtered[index];
                          return _ConflictCard(conflict: conflict);
                        },
                      ),
              ),
            ],
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

  void _onQueryChanged() {
    final next = _queryController.text.trim();
    if (next == _query) {
      return;
    }
    setState(() {
      _query = next;
    });
  }

  List<SyncConflict> _filterConflicts(List<SyncConflict> conflicts) {
    final needle = _query.toLowerCase();
    if (needle.isEmpty) {
      return conflicts;
    }
    return conflicts.where((row) {
      final haystack = [
        row.entityType,
        row.entityId,
        row.localPayload['status']?.toString() ?? '',
        row.remotePayload['status']?.toString() ?? '',
        row.localPayload['voice_name']?.toString() ?? '',
        row.remotePayload['voice_name']?.toString() ?? '',
        row.detectedAt.toIso8601String(),
      ].join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList(growable: false);
  }

  Future<void> _exportConflictsJson() async {
    final conflicts = ref.read(openSyncConflictsStreamProvider).valueOrNull;
    if (conflicts == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conflicts still loading')),
      );
      return;
    }
    final filtered = _filterConflicts(conflicts);
    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conflicts to export')),
      );
      return;
    }

    final payload = {
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'count': filtered.length,
      'conflicts': filtered
          .map(
            (row) => {
              'id': row.id,
              'entity_type': row.entityType,
              'entity_id': row.entityId,
              'detected_at': row.detectedAt.toUtc().toIso8601String(),
              'resolved_at': row.resolvedAt?.toUtc().toIso8601String(),
              'local_payload': row.localPayload,
              'remote_payload': row.remotePayload,
            },
          )
          .toList(growable: false),
    };

    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filtered.length} conflicts as JSON')),
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
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showPayloadComparison(context),
                  child: const Text('Compare payloads'),
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

  Future<void> _showPayloadComparison(BuildContext context) async {
    const pretty = JsonEncoder.withIndent('  ');
    final localJson = pretty.convert(conflict.localPayload);
    final remoteJson = pretty.convert(conflict.remotePayload);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compare ${conflict.entityType} payloads'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  localJson,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Remote',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  remoteJson,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
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
