import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
                            trailing: PopupMenuButton<_HistoryAction>(
                              onSelected: (action) {
                                if (action == _HistoryAction.cloneAsDraft) {
                                  _cloneAsDraft(item.variantId);
                                  return;
                                }
                                if (action == _HistoryAction.openExternalUrl &&
                                    item.externalUrl != null) {
                                  _openExternalUrl(item.externalUrl!);
                                }
                              },
                              itemBuilder: (context) {
                                final menu = <PopupMenuEntry<_HistoryAction>>[];
                                if (item.variantId != null) {
                                  menu.add(
                                    const PopupMenuItem(
                                      value: _HistoryAction.cloneAsDraft,
                                      child: Text('Clone as draft'),
                                    ),
                                  );
                                }
                                if (item.externalUrl != null &&
                                    item.externalUrl!.trim().isNotEmpty) {
                                  menu.add(
                                    const PopupMenuItem(
                                      value: _HistoryAction.openExternalUrl,
                                      child: Text('Open external URL'),
                                    ),
                                  );
                                }
                                if (menu.isEmpty) {
                                  menu.add(
                                    const PopupMenuItem(
                                      enabled: false,
                                      value: _HistoryAction.cloneAsDraft,
                                      child: Text('No actions'),
                                    ),
                                  );
                                }
                                return menu;
                              },
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

  Future<void> _cloneAsDraft(String? variantId) async {
    if (variantId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No variant linked to this history row')),
      );
      return;
    }

    final variant =
        await ref.read(variantRepoProvider).getVariantById(variantId);
    if (variant == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variant not found')),
      );
      return;
    }

    final draftId = await ref.read(draftRepoProvider).createDraft(
          canonicalMarkdown: variant.body,
          intent: 'how_to',
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created draft ${draftId.substring(0, 8)}')),
    );
    context.go('/compose');
  }

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open URL')),
      );
    }
  }
}

enum _HistoryAction {
  cloneAsDraft,
  openExternalUrl,
}
