import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repo_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _platformFilter = 'all';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(publishLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No publish logs yet.'));
          }
          final platformOptions = <String>{
            'all',
            ...logs.map((row) => row.platform.toLowerCase()),
          }.toList()
            ..sort();
          final statusOptions = <String>{
            'all',
            ...logs.map((row) => row.status.toLowerCase()),
          }.toList()
            ..sort();

          final filtered = logs.where((row) {
            final platformMatches = _platformFilter == 'all' ||
                row.platform.toLowerCase() == _platformFilter;
            final statusMatches = _statusFilter == 'all' ||
                row.status.toLowerCase() == _statusFilter;
            return platformMatches && statusMatches;
          }).toList();

          String labelFor(String value) {
            if (value == 'all') {
              return 'All';
            }
            return value.toUpperCase();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _platformFilter,
                        decoration:
                            const InputDecoration(labelText: 'Platform'),
                        items: platformOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(labelFor(value)),
                              ),
                            )
                            .toList(),
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
                        value: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: statusOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(labelFor(value)),
                              ),
                            )
                            .toList(),
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
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No logs match filters.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final posted =
                              item.postedAt?.toLocal().toIso8601String() ?? '-';
                          return ListTile(
                            title: Text(
                                '${item.platform.toUpperCase()} · ${item.status}'),
                            subtitle:
                                Text('mode=${item.mode} · postedAt=$posted'),
                            trailing: item.externalUrl == null
                                ? null
                                : IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.link),
                                    tooltip: item.externalUrl!,
                                  ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading history: $error')),
      ),
    );
  }
}
