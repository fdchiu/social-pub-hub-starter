import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repo_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(publishLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No publish logs yet.'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = logs[index];
              final posted = item.postedAt?.toLocal().toIso8601String() ?? '-';
              return ListTile(
                title: Text('${item.platform.toUpperCase()} · ${item.status}'),
                subtitle: Text('mode=${item.mode} · postedAt=$posted'),
                trailing: item.externalUrl == null
                    ? null
                    : IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.link),
                        tooltip: item.externalUrl!,
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading history: $error')),
      ),
    );
  }
}
