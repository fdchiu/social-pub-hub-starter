import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final queueAsync = ref.watch(scheduledPostsStreamProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Analytics',
      ),
      body: logsAsync.when(
        data: (logs) => queueAsync.when(
          data: (queueItems) {
            final postedLogs =
                logs.where((row) => row.status == 'posted').toList();
            final byPlatform = <String, int>{};
            for (final row in postedLogs) {
              byPlatform.update(row.platform, (value) => value + 1,
                  ifAbsent: () => 1);
            }
            final platformRows = byPlatform.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final queuedCount =
                queueItems.where((row) => row.status == 'queued').length;
            final overdueCount = queueItems
                .where((row) =>
                    row.status == 'queued' &&
                    row.scheduledFor.isBefore(DateTime.now().toUtc()))
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Posted logs',
                      value: '${postedLogs.length}',
                    ),
                    _MetricCard(
                      label: 'Queued posts',
                      value: '$queuedCount',
                    ),
                    _MetricCard(
                      label: 'Overdue queue',
                      value: '$overdueCount',
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
                  const Text('No posted logs yet.')
                else
                  ...platformRows.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.key.toUpperCase()),
                        trailing: Text(
                          '${entry.value}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
