import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../utils/composer_links.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  String _statusFilter = 'all';
  String _platformFilter = 'all';
  bool _overdueOnly = false;

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(scheduledPostsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Queue'),
        actions: [
          IconButton(
            tooltip: 'Open compose',
            onPressed: () => context.go('/compose'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child:
                  Text('No scheduled posts yet. Queue from Compose variants.'),
            );
          }
          final now = DateTime.now().toUtc();
          final statusOptions = <String>{
            'all',
            ...items.map((row) => row.status.toLowerCase()),
          }.toList()
            ..sort();
          final platformOptions = <String>{
            'all',
            ...items.map((row) => row.platform.toLowerCase()),
          }.toList()
            ..sort();
          final selectedStatus =
              statusOptions.contains(_statusFilter) ? _statusFilter : 'all';
          final selectedPlatform = platformOptions.contains(_platformFilter)
              ? _platformFilter
              : 'all';

          final filtered = items.where((row) {
            final statusMatches =
                selectedStatus == 'all' || row.status == selectedStatus;
            final platformMatches = selectedPlatform == 'all' ||
                row.platform.toLowerCase() == selectedPlatform;
            final isOverdue =
                row.status == 'queued' && row.scheduledFor.isBefore(now);
            final overdueMatches = !_overdueOnly || isOverdue;
            return statusMatches && platformMatches && overdueMatches;
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPlatform,
                        decoration:
                            const InputDecoration(labelText: 'Platform'),
                        items: platformOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'all'
                                    ? 'All'
                                    : value.toUpperCase()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _platformFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: statusOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'all'
                                    ? 'All'
                                    : value.toUpperCase()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _statusFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                value: _overdueOnly,
                onChanged: (value) {
                  setState(() {
                    _overdueOnly = value;
                  });
                },
                title: const Text('Overdue only'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No queue items match filters.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isOverdue = item.status == 'queued' &&
                              item.scheduledFor.isBefore(now);
                          return _ScheduledPostCard(
                            item: item,
                            isOverdue: isOverdue,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading queue: $error')),
      ),
    );
  }
}

class _ScheduledPostCard extends ConsumerWidget {
  const _ScheduledPostCard({
    required this.item,
    required this.isOverdue,
  });

  final ScheduledPost item;
  final bool isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQueued = item.status == 'queued';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.platform.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                _StatusPill(status: item.status),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  const _OverduePill(),
                ],
                const Spacer(),
                Text(
                  _formatDateTime(item.scheduledFor.toLocal()),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _copy(context),
                  child: const Text('Copy'),
                ),
                FilledButton.tonal(
                  onPressed: () => _openComposer(context),
                  child: const Text('Open composer'),
                ),
                if (item.variantId != null && item.variantId!.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () => _openHistory(context, item.variantId!),
                    child: Text('History ${_shortId(item.variantId!)}'),
                  ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _markPosted(context, ref),
                    child: const Text('Mark posted'),
                  ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _cancel(context, ref),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied queued text')),
      );
    }
  }

  Future<void> _openComposer(BuildContext context) async {
    final uri =
        composerUriForPlatform(platform: item.platform, text: item.content);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No composer URL configured for ${item.platform}')),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open composer for ${item.platform}')),
      );
    }
  }

  void _openHistory(BuildContext context, String variantId) {
    final encoded = Uri.encodeQueryComponent(variantId);
    context.go('/history?variantId=$encoded');
  }

  Future<void> _markPosted(BuildContext context, WidgetRef ref) async {
    await ref.read(scheduledPostRepoProvider).markPosted(
          scheduledPostId: item.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item marked posted')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await ref.read(scheduledPostRepoProvider).markCanceled(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item canceled')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day ${value.year} $hour:$minute';
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id;
    }
    return id.substring(0, 8);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'posted' => (Colors.green.shade900, Colors.green.shade100),
      'canceled' => (Colors.grey.shade800, Colors.grey.shade200),
      _ => (Colors.orange.shade900, Colors.orange.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverduePill extends StatelessWidget {
  const _OverduePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade900,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'overdue',
        style: TextStyle(
          color: Colors.red.shade100,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
