import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';

class PublishConsoleScreen extends ConsumerWidget {
  const PublishConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationsAsync = ref.watch(integrationsProvider);
    final logsAsync = ref.watch(publishLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Publish Console')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                'Integration status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(integrationsProvider),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          integrationsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No integration data from backend.');
              }
              return Column(
                children: [
                  for (final item in items)
                    Card(
                      child: ListTile(
                        title: Text(item.platform.toUpperCase()),
                        subtitle: Text(_capabilityText(item.capabilities)),
                        trailing: Icon(
                          item.connected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: item.connected ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text('Failed loading integrations: $error'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Recent publish logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/compose'),
                child: const Text('Open compose'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Text('No publish logs yet.');
              }
              final recent = logs.take(20).toList(growable: false);
              return Column(
                children: [
                  for (final log in recent)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${log.platform.toUpperCase()} · ${log.status}',
                        ),
                        subtitle: Text(
                          'mode=${log.mode} · postedAt=${log.postedAt?.toLocal().toIso8601String() ?? '-'}',
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text('Failed loading logs: $error'),
          ),
        ],
      ),
    );
  }

  String _capabilityText(Map<String, dynamic> capabilities) {
    final enabled = <String>[];
    capabilities.forEach((key, value) {
      if (value == true) {
        enabled.add(key);
      }
    });
    if (enabled.isEmpty) {
      return 'Capabilities: none';
    }
    return 'Capabilities: ${enabled.join(', ')}';
  }
}
