import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';

class PublishConsoleScreen extends ConsumerStatefulWidget {
  const PublishConsoleScreen({super.key, this.initialBundleId});

  final String? initialBundleId;

  @override
  ConsumerState<PublishConsoleScreen> createState() =>
      _PublishConsoleScreenState();
}

class _PublishConsoleScreenState extends ConsumerState<PublishConsoleScreen> {
  static const String _allBundlesValue = '__all_bundles__';
  final TextEditingController _queryController = TextEditingController();
  String? _selectedBundleId;
  String _statusFilter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    final initialBundleId = widget.initialBundleId?.trim();
    if (initialBundleId != null && initialBundleId.isNotEmpty) {
      _selectedBundleId = initialBundleId;
    }
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final integrationsAsync = ref.watch(integrationsProvider);
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final bundlesAsync = ref.watch(bundlesStreamProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Publish Console',
        actions: [
          IconButton(
            tooltip: 'Export filtered logs CSV',
            onPressed: _exportFilteredLogsCsv,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
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
              FilledButton.tonal(
                onPressed: () => context.go('/queue'),
                child: const Text('Open queue'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => context.go('/analytics'),
                child: const Text('Analytics'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.go('/compose'),
                child: const Text('Open compose'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          bundlesAsync.when(
            data: (bundles) {
              final selectedBundle =
                  _findBundleById(bundles, _selectedBundleId);
              final selectedValue = selectedBundle?.id ?? _allBundlesValue;
              final activeLabel = selectedBundle == null
                  ? 'All bundles'
                  : 'Bundle: ${selectedBundle.name}';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'Filter by bundle',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: _allBundlesValue,
                        child: Text('All bundles'),
                      ),
                      ...bundles.map(
                        (bundle) => DropdownMenuItem<String>(
                          value: bundle.id,
                          child: Text(bundle.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value == null || value == _allBundlesValue) {
                          _selectedBundleId = null;
                          return;
                        }
                        _selectedBundleId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(activeLabel),
                  const SizedBox(height: 8),
                  logsAsync.when(
                    data: (logs) {
                      final bundleFilteredLogs =
                          _filterLogsForBundle(logs, selectedBundle);
                      final statusOptions = <String>{
                        'all',
                        ...bundleFilteredLogs
                            .map((row) => row.status.toLowerCase()),
                      }.toList(growable: false)
                        ..sort();
                      final selectedStatus =
                          statusOptions.contains(_statusFilter)
                              ? _statusFilter
                              : 'all';
                      final filteredLogs = _applyLogFilters(
                        bundleFilteredLogs,
                        selectedStatus: selectedStatus,
                      );
                      if (bundleFilteredLogs.isEmpty) {
                        if (selectedBundle == null) {
                          return const Text('No publish logs yet.');
                        }
                        return Text(
                            'No publish logs for ${selectedBundle.name} yet.');
                      }
                      final recent =
                          filteredLogs.take(20).toList(growable: false);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _queryController,
                            decoration: InputDecoration(
                              labelText: 'Search logs',
                              hintText: 'platform, status, mode, variant id',
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
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: statusOptions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final status = statusOptions[index];
                                return ChoiceChip(
                                  label: Text(
                                    status == 'all'
                                        ? 'ALL'
                                        : status.toUpperCase(),
                                  ),
                                  selected: selectedStatus == status,
                                  onSelected: (selected) {
                                    if (!selected) {
                                      return;
                                    }
                                    setState(() {
                                      _statusFilter = status;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Visible: ${filteredLogs.length}'),
                          const SizedBox(height: 8),
                          if (recent.isEmpty)
                            const Text('No logs match current filters.')
                          else
                            for (final log in recent)
                              Card(
                                child: ListTile(
                                  title: Text(
                                    '${log.platform.toUpperCase()} · ${log.status}',
                                  ),
                                  subtitle: Text(
                                    'mode=${log.mode} · postedAt=${log.postedAt?.toLocal().toIso8601String() ?? '-'}',
                                  ),
                                  trailing: PopupMenuButton<_LogAction>(
                                    onSelected: (action) {
                                      if (action == _LogAction.openHistory &&
                                          log.variantId != null &&
                                          log.variantId!.isNotEmpty) {
                                        final encoded =
                                            Uri.encodeQueryComponent(
                                          log.variantId!,
                                        );
                                        context
                                            .go('/history?variantId=$encoded');
                                        return;
                                      }
                                      if (action == _LogAction.openExternal &&
                                          log.externalUrl != null &&
                                          log.externalUrl!.trim().isNotEmpty) {
                                        _openExternalUrl(log.externalUrl!);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final items =
                                          <PopupMenuEntry<_LogAction>>[];
                                      if (log.variantId != null &&
                                          log.variantId!.isNotEmpty) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: _LogAction.openHistory,
                                            child: Text('Open in history'),
                                          ),
                                        );
                                      }
                                      if (log.externalUrl != null &&
                                          log.externalUrl!.trim().isNotEmpty) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: _LogAction.openExternal,
                                            child: Text('Open external URL'),
                                          ),
                                        );
                                      }
                                      if (items.isEmpty) {
                                        items.add(
                                          const PopupMenuItem(
                                            enabled: false,
                                            value: _LogAction.openHistory,
                                            child: Text('No actions'),
                                          ),
                                        );
                                      }
                                      return items;
                                    },
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
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text('Failed loading bundles: $error'),
          ),
        ],
      ),
    );
  }

  Bundle? _findBundleById(List<Bundle> bundles, String? bundleId) {
    if (bundleId == null || bundleId.isEmpty) {
      return null;
    }
    for (final bundle in bundles) {
      if (bundle.id == bundleId) {
        return bundle;
      }
    }
    return null;
  }

  List<PublishLog> _filterLogsForBundle(List<PublishLog> logs, Bundle? bundle) {
    if (bundle == null) {
      return logs;
    }
    final variantIds = bundle.relatedVariantIds.toSet();
    return logs.where((log) {
      final variantId = log.variantId;
      return variantId != null && variantIds.contains(variantId);
    }).toList(growable: false);
  }

  List<PublishLog> _applyLogFilters(
    List<PublishLog> logs, {
    required String selectedStatus,
  }) {
    final needle = _query.toLowerCase();
    return logs.where((row) {
      final statusMatches =
          selectedStatus == 'all' || row.status.toLowerCase() == selectedStatus;
      final queryMatches = needle.isEmpty ||
          [
            row.platform,
            row.status,
            row.mode,
            row.variantId ?? '',
            row.externalUrl ?? '',
            row.postedAt?.toIso8601String() ?? '',
          ].join(' ').toLowerCase().contains(needle);
      return statusMatches && queryMatches;
    }).toList(growable: false);
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

  Future<void> _exportFilteredLogsCsv() async {
    final logs = ref.read(publishLogsStreamProvider).valueOrNull;
    final bundles = ref.read(bundlesStreamProvider).valueOrNull;

    if (logs == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publish logs are still loading')),
      );
      return;
    }

    final bundle =
        _findBundleById(bundles ?? const <Bundle>[], _selectedBundleId);
    final bundleFiltered = _filterLogsForBundle(logs, bundle);
    final statusOptions = <String>{
      'all',
      ...bundleFiltered.map((row) => row.status.toLowerCase()),
    };
    final selectedStatus =
        statusOptions.contains(_statusFilter) ? _statusFilter : 'all';
    final filtered = _applyLogFilters(
      bundleFiltered,
      selectedStatus: selectedStatus,
    );
    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to export for current filter')),
      );
      return;
    }

    final lines = <String>[
      'id,platform,status,mode,variant_id,external_url,posted_at,created_at',
      ...filtered.map((row) {
        return [
          _csv(row.id),
          _csv(row.platform),
          _csv(row.status),
          _csv(row.mode),
          _csv(row.variantId ?? ''),
          _csv(row.externalUrl ?? ''),
          _csv(row.postedAt?.toUtc().toIso8601String() ?? ''),
          _csv(row.createdAt.toUtc().toIso8601String()),
        ].join(',');
      }),
    ];
    final csv = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: csv));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filtered.length} logs as CSV')),
    );
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

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
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
}

enum _LogAction {
  openHistory,
  openExternal,
}
