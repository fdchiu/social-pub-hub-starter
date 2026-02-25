import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _AnalyticsWindow _window = _AnalyticsWindow.days30;
  bool _includeAllPosts = false;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final queueAsync = ref.watch(scheduledPostsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Analytics',
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) => queueAsync.when(
          data: (queueItems) {
            final scopedLogs = _scopeLogs(
              logs,
              activePostId: activePost?.id,
              includeAllPosts: _includeAllPosts,
            );
            final scopedQueueItems = _scopeQueueItems(
              queueItems,
              activePostId: activePost?.id,
              includeAllPosts: _includeAllPosts,
            );
            final now = DateTime.now().toUtc();
            final since = _sinceForWindow(now, _window);
            final filteredLogs = since == null
                ? scopedLogs
                : scopedLogs
                    .where((row) => row.createdAt.isAfter(since))
                    .toList();
            final postedLogs = filteredLogs
                .where((row) => row.status.toLowerCase() == 'posted')
                .toList(growable: false);

            final byPlatform = <String, int>{};
            final byMode = <String, int>{};
            for (final row in postedLogs) {
              byPlatform.update(
                row.platform.toLowerCase(),
                (value) => value + 1,
                ifAbsent: () => 1,
              );
              byMode.update(
                row.mode.toLowerCase(),
                (value) => value + 1,
                ifAbsent: () => 1,
              );
            }
            final platformRows = byPlatform.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final modeRows = byMode.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final queuedCount =
                scopedQueueItems.where((row) => row.status == 'queued').length;
            final postedQueueCount =
                scopedQueueItems.where((row) => row.status == 'posted').length;
            final overdueCount = scopedQueueItems
                .where(
                  (row) =>
                      row.status == 'queued' && row.scheduledFor.isBefore(now),
                )
                .length;
            final postedRate = filteredLogs.isEmpty
                ? 0.0
                : postedLogs.length / filteredLogs.length;

            final trend = _buildDailyTrend(postedLogs, now: now, days: 7);
            final peak = trend.fold<int>(
              0,
              (max, row) => row.count > max ? row.count : max,
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
                    'Show analytics for all posts instead of only active post',
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _AnalyticsWindow.values)
                      ChoiceChip(
                        label: Text(_windowLabel(option)),
                        selected: _window == option,
                        onSelected: (selected) {
                          if (!selected) {
                            return;
                          }
                          setState(() {
                            _window = option;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Posted logs',
                      value: '${postedLogs.length}',
                    ),
                    _MetricCard(
                      label: 'All logs',
                      value: '${filteredLogs.length}',
                    ),
                    _MetricCard(
                      label: 'Posted rate',
                      value: '${(postedRate * 100).toStringAsFixed(1)}%',
                    ),
                    _MetricCard(
                      label: 'Queued posts',
                      value: '$queuedCount',
                    ),
                    _MetricCard(
                      label: 'Queue posted',
                      value: '$postedQueueCount',
                    ),
                    _MetricCard(
                      label: 'Overdue queue',
                      value: '$overdueCount',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.go('/queue'),
                      child: const Text('Open queue'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _openHistoryDrilldown(),
                      child: const Text('Open history'),
                    ),
                    FilledButton.tonal(
                      onPressed: _window == _AnalyticsWindow.all
                          ? null
                          : () => _copyWindowHint(_window),
                      child: const Text('Copy window hint'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Posted by platform',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (platformRows.isEmpty)
                  const Text('No posted logs in selected window.')
                else
                  ...platformRows.map(
                    (entry) => Card(
                      child: ListTile(
                        onTap: () => _openHistoryDrilldown(platform: entry.key),
                        title: Text(entry.key.toUpperCase()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Posted by mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (modeRows.isEmpty)
                  const Text('No mode data in selected window.')
                else
                  ...modeRows.map(
                    (entry) => Card(
                      child: ListTile(
                        onTap: () => _openHistoryDrilldown(mode: entry.key),
                        title: Text(entry.key.toUpperCase()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Last 7 days trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (trend.every((row) => row.count == 0))
                  const Text('No posted activity in the last 7 days.')
                else
                  ...trend.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 68,
                            child: Text(
                              _shortDate(row.day.toLocal()),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: peak == 0 ? 0 : row.count / peak,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${row.count}'),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Failed loading queue data: $error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Failed loading publish logs: $error'),
        ),
      ),
    );
  }

  DateTime? _sinceForWindow(DateTime now, _AnalyticsWindow window) {
    return switch (window) {
      _AnalyticsWindow.days7 => now.subtract(const Duration(days: 7)),
      _AnalyticsWindow.days30 => now.subtract(const Duration(days: 30)),
      _AnalyticsWindow.days90 => now.subtract(const Duration(days: 90)),
      _AnalyticsWindow.all => null,
    };
  }

  String _windowLabel(_AnalyticsWindow window) {
    return switch (window) {
      _AnalyticsWindow.days7 => '7D',
      _AnalyticsWindow.days30 => '30D',
      _AnalyticsWindow.days90 => '90D',
      _AnalyticsWindow.all => 'All',
    };
  }

  List<_DailyCount> _buildDailyTrend(
    List<PublishLog> postedLogs, {
    required DateTime now,
    required int days,
  }) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final counts = <DateTime, int>{};
    for (var i = days - 1; i >= 0; i -= 1) {
      final day = today.subtract(Duration(days: i));
      counts[day] = 0;
    }
    for (final log in postedLogs) {
      final postedAt = log.postedAt?.toUtc();
      if (postedAt == null) {
        continue;
      }
      final day = DateTime.utc(postedAt.year, postedAt.month, postedAt.day);
      if (counts.containsKey(day)) {
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    return counts.entries
        .map((entry) => _DailyCount(day: entry.key, count: entry.value))
        .toList(growable: false);
  }

  String _shortDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  Future<void> _exportCsv() async {
    final logs = ref.read(publishLogsStreamProvider).valueOrNull;
    final queueItems = ref.read(scheduledPostsStreamProvider).valueOrNull;
    final activePost = ref.read(activePostProvider);
    if (logs == null || queueItems == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics still loading')),
      );
      return;
    }
    final scopedLogs = _scopeLogs(
      logs,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    );
    final scopedQueueItems = _scopeQueueItems(
      queueItems,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    );

    final now = DateTime.now().toUtc();
    final since = _sinceForWindow(now, _window);
    final filteredLogs = since == null
        ? scopedLogs
        : scopedLogs.where((row) => row.createdAt.isAfter(since)).toList();
    final postedLogs = filteredLogs
        .where((row) => row.status.toLowerCase() == 'posted')
        .toList(growable: false);

    final lines = <String>[
      'window,total_logs,posted_logs,queued_posts,queue_posted,overdue_queue',
      [
        _csv(_windowLabel(_window)),
        _csv('${filteredLogs.length}'),
        _csv('${postedLogs.length}'),
        _csv('${scopedQueueItems.where((r) => r.status == 'queued').length}'),
        _csv('${scopedQueueItems.where((r) => r.status == 'posted').length}'),
        _csv(
          '${scopedQueueItems.where((r) => r.status == 'queued' && r.scheduledFor.isBefore(now)).length}',
        ),
      ].join(','),
      '',
      'id,platform,status,mode,variant_id,post_id,external_url,posted_at,created_at',
      ...filteredLogs.map((row) {
        return [
          _csv(row.id),
          _csv(row.platform),
          _csv(row.status),
          _csv(row.mode),
          _csv(row.variantId ?? ''),
          _csv(row.postId ?? ''),
          _csv(row.externalUrl ?? ''),
          _csv(row.postedAt?.toUtc().toIso8601String() ?? ''),
          _csv(row.createdAt.toUtc().toIso8601String()),
        ].join(',');
      }),
    ];

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filteredLogs.length} rows as CSV')),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _copyWindowHint(_AnalyticsWindow window) async {
    final now = DateTime.now().toUtc();
    final since = _sinceForWindow(now, window);
    if (since == null) {
      return;
    }
    final text = 'Window filter: ${_windowLabel(window)}\n'
        'Since UTC: ${since.toIso8601String()}\n'
        'Use this when reviewing history/exports.';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Window hint copied')),
    );
  }

  void _openHistoryDrilldown({
    String? platform,
    String? mode,
  }) {
    final activePost = ref.read(activePostProvider);
    final query = <String, String>{
      'status': 'posted',
    };
    final normalizedPlatform = platform?.trim().toLowerCase();
    if (normalizedPlatform != null && normalizedPlatform.isNotEmpty) {
      query['platform'] = normalizedPlatform;
    }
    final normalizedMode = mode?.trim().toLowerCase();
    if (normalizedMode != null && normalizedMode.isNotEmpty) {
      query['mode'] = normalizedMode;
    }
    final window = _windowQuery(_window);
    if (window != null) {
      query['window'] = window;
    }
    if (!_includeAllPosts && activePost != null) {
      query['postId'] = activePost.id;
    }
    final uri = Uri(path: '/history', queryParameters: query);
    context.go(uri.toString());
  }

  List<PublishLog> _scopeLogs(
    List<PublishLog> logs, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return logs;
    }
    return logs
        .where((row) => row.postId != null && row.postId == activePostId)
        .toList(growable: false);
  }

  List<ScheduledPost> _scopeQueueItems(
    List<ScheduledPost> queueItems, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return queueItems;
    }
    return queueItems
        .where((row) => row.postId != null && row.postId == activePostId)
        .toList(growable: false);
  }

  String? _windowQuery(_AnalyticsWindow window) {
    return switch (window) {
      _AnalyticsWindow.days7 => '7d',
      _AnalyticsWindow.days30 => '30d',
      _AnalyticsWindow.days90 => '90d',
      _AnalyticsWindow.all => null,
    };
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCount {
  const _DailyCount({
    required this.day,
    required this.count,
  });

  final DateTime day;
  final int count;
}

enum _AnalyticsWindow {
  days7,
  days30,
  days90,
  all,
}
