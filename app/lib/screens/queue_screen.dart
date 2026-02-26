import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../utils/composer_links.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  String _statusFilter = 'all';
  String _platformFilter = 'all';
  bool _overdueOnly = false;
  bool _includeAllPosts = false;

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(scheduledPostsStreamProvider);
    final activePost = ref.watch(activePostProvider);
    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Schedule Queue',
        actions: [
          IconButton(
            tooltip: 'Export filtered CSV',
            onPressed: _exportFilteredCsv,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Schedule post',
            onPressed: _showScheduleDialog,
            icon: const Icon(Icons.add_alarm_outlined),
          ),
          IconButton(
            tooltip: 'Open compose',
            onPressed: () => context.go('/compose'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (items) {
          final scopedItems = _scopeItems(
            items,
            activePostId: activePost?.id,
            includeAllPosts: _includeAllPosts,
          );
          final now = DateTime.now().toUtc();
          final statusOptions = <String>{
            'all',
            ...scopedItems.map((row) => row.status.toLowerCase()),
          }.toList()
            ..sort();
          final platformOptions = <String>{
            'all',
            ...scopedItems.map((row) => row.platform.toLowerCase()),
          }.toList()
            ..sort();
          final selectedStatus =
              statusOptions.contains(_statusFilter) ? _statusFilter : 'all';
          final selectedPlatform = platformOptions.contains(_platformFilter)
              ? _platformFilter
              : 'all';

          final filtered = _applyFilters(
            scopedItems,
            now: now,
            selectedStatus: selectedStatus,
            selectedPlatform: selectedPlatform,
          );

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: PostScopeHeader(showGlobalToggle: false),
              ),
              SwitchListTile(
                value: _includeAllPosts,
                onChanged: (value) {
                  setState(() {
                    _includeAllPosts = value;
                  });
                },
                title: const Text('Include all posts'),
                subtitle: const Text(
                  'Show queue rows from all posts instead of only active post',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (scopedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                          decoration:
                              const InputDecoration(labelText: 'Status'),
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
              if (scopedItems.isNotEmpty)
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
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No scheduled posts yet. Queue from Compose variants.',
                        ),
                      )
                    : scopedItems.isEmpty
                        ? Center(
                            child: Text(
                              _includeAllPosts
                                  ? 'No queue items yet.'
                                  : 'No queue items for active post scope.',
                            ),
                          )
                        : filtered.isEmpty
                            ? const Center(
                                child: Text('No queue items match filters.'),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
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

  Future<void> _showScheduleDialog() async {
    final activePost = ref.read(activePostProvider);
    final contentController = TextEditingController();
    String platform = 'x';
    DateTime scheduledFor = DateTime.now().add(const Duration(hours: 1));

    final shouldCreate = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: const Text('Schedule post'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: platform,
                      decoration: const InputDecoration(labelText: 'Platform'),
                      items: const [
                        DropdownMenuItem(value: 'x', child: Text('X')),
                        DropdownMenuItem(
                            value: 'linkedin', child: Text('LinkedIn')),
                        DropdownMenuItem(
                            value: 'reddit', child: Text('Reddit')),
                        DropdownMenuItem(
                            value: 'facebook', child: Text('Facebook')),
                        DropdownMenuItem(
                            value: 'youtube', child: Text('YouTube')),
                        DropdownMenuItem(
                            value: 'substack', child: Text('Substack')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Medium')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setLocalState(() {
                          platform = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText: 'Write queued post content',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Scheduled for'),
                      subtitle: Text(_formatDateTime(scheduledFor)),
                      trailing: FilledButton.tonal(
                        onPressed: () async {
                          final picked = await _pickScheduledTime(scheduledFor);
                          if (picked == null) {
                            return;
                          }
                          setLocalState(() {
                            scheduledFor = picked;
                          });
                        },
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Queue'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldCreate) {
      contentController.dispose();
      return;
    }

    final content = contentController.text.trim();
    contentController.dispose();
    if (content.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content is required')),
      );
      return;
    }

    await ref.read(scheduledPostRepoProvider).createScheduledPost(
          postId: activePost?.id,
          platform: platform,
          content: content,
          scheduledFor: scheduledFor.toUtc(),
        );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scheduled post added')),
    );
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day ${value.year} $hour:$minute';
  }

  Future<DateTime?> _pickScheduledTime(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<ScheduledPost> _applyFilters(
    List<ScheduledPost> items, {
    required DateTime now,
    required String selectedStatus,
    required String selectedPlatform,
  }) {
    return items.where((row) {
      final statusMatches =
          selectedStatus == 'all' || row.status.toLowerCase() == selectedStatus;
      final platformMatches = selectedPlatform == 'all' ||
          row.platform.toLowerCase() == selectedPlatform;
      final isOverdue = row.status.toLowerCase() == 'queued' &&
          row.scheduledFor.isBefore(now);
      final overdueMatches = !_overdueOnly || isOverdue;
      return statusMatches && platformMatches && overdueMatches;
    }).toList(growable: false);
  }

  Future<void> _exportFilteredCsv() async {
    final items = ref.read(scheduledPostsStreamProvider).valueOrNull;
    final activePost = ref.read(activePostProvider);
    if (items == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue still loading')),
      );
      return;
    }
    if (items.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No queue items to export')),
      );
      return;
    }
    final scopedItems = _scopeItems(
      items,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    );
    if (scopedItems.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _includeAllPosts
                ? 'No queue items to export'
                : 'No queue items in active post scope',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final statusOptions = <String>{
      'all',
      ...scopedItems.map((row) => row.status.toLowerCase()),
    };
    final platformOptions = <String>{
      'all',
      ...scopedItems.map((row) => row.platform.toLowerCase()),
    };
    final selectedStatus =
        statusOptions.contains(_statusFilter) ? _statusFilter : 'all';
    final selectedPlatform =
        platformOptions.contains(_platformFilter) ? _platformFilter : 'all';
    final filtered = _applyFilters(
      scopedItems,
      now: now,
      selectedStatus: selectedStatus,
      selectedPlatform: selectedPlatform,
    );
    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filtered queue rows to export')),
      );
      return;
    }

    final lines = <String>[
      'id,platform,status,variant_id,post_id,scheduled_for,external_url,content,created_at,updated_at',
      ...filtered.map((row) {
        return [
          _csv(row.id),
          _csv(row.platform),
          _csv(row.status),
          _csv(row.variantId ?? ''),
          _csv(row.postId ?? ''),
          _csv(row.scheduledFor.toUtc().toIso8601String()),
          _csv(row.externalUrl ?? ''),
          _csv(row.content),
          _csv(row.createdAt.toUtc().toIso8601String()),
          _csv(row.updatedAt.toUtc().toIso8601String()),
        ].join(',');
      }),
    ];

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filtered.length} queue rows as CSV')),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<ScheduledPost> _scopeItems(
    List<ScheduledPost> items, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return items;
    }
    return items
        .where((row) => row.postId != null && row.postId == activePostId)
        .toList(growable: false);
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
                FilledButton.tonal(
                  onPressed: () => _openHistory(context),
                  child: Text(
                    item.variantId == null || item.variantId!.isEmpty
                        ? 'History'
                        : 'History ${_shortId(item.variantId!)}',
                  ),
                ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _markPosted(context, ref),
                    child: const Text('Mark posted'),
                  ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _reschedule(context, ref),
                    child: const Text('Reschedule'),
                  ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _cancel(context, ref),
                    child: const Text('Cancel'),
                  ),
                if (!isQueued)
                  FilledButton.tonal(
                    onPressed: () => _remove(context, ref),
                    child: const Text('Remove'),
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

  void _openHistory(BuildContext context) {
    final query = <String, String>{
      'platform': item.platform.toLowerCase(),
      'mode': 'scheduled',
    };
    final variantId = item.variantId?.trim();
    if (variantId != null && variantId.isNotEmpty) {
      query['variantId'] = variantId;
    }
    if (item.status.toLowerCase() == 'posted') {
      query['status'] = 'posted';
    }
    final postId = item.postId?.trim();
    if (postId != null && postId.isNotEmpty) {
      query['postId'] = postId;
    }
    final uri = Uri(path: '/history', queryParameters: query);
    context.go(uri.toString());
  }

  Future<void> _markPosted(BuildContext context, WidgetRef ref) async {
    final externalUrl = await _promptExternalUrl(context);
    await ref.read(scheduledPostRepoProvider).markPosted(
          scheduledPostId: item.id,
          externalUrl: externalUrl,
        );
    await ref.read(publishLogRepoProvider).createPublishLog(
          variantId: item.variantId,
          postId: item.postId,
          platform: item.platform,
          mode: 'scheduled',
          status: 'posted',
          externalUrl: externalUrl,
          postedAt: DateTime.now().toUtc(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item marked posted and logged')),
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

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initial = item.scheduledFor.toLocal().isAfter(now)
        ? item.scheduledFor.toLocal()
        : now.add(const Duration(hours: 1));
    final nextTime = await _pickScheduledTime(context, initial);
    if (nextTime == null) {
      return;
    }
    await ref.read(scheduledPostRepoProvider).reschedule(
          scheduledPostId: item.id,
          scheduledFor: nextTime.toUtc(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item rescheduled')),
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove queue row?'),
            content: const Text(
              'This permanently removes the queue row and syncs deletion.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    await ref.read(scheduledPostRepoProvider).deleteScheduledPost(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item removed')),
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

  Future<String?> _promptExternalUrl(BuildContext context) async {
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
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id;
    }
    return id.substring(0, 8);
  }

  Future<DateTime?> _pickScheduledTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
