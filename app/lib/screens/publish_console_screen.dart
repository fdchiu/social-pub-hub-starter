import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';

class PublishConsoleScreen extends ConsumerStatefulWidget {
  const PublishConsoleScreen({super.key, this.initialBundleId});

  final String? initialBundleId;

  @override
  ConsumerState<PublishConsoleScreen> createState() =>
      _PublishConsoleScreenState();
}

class _PublishConsoleScreenState extends ConsumerState<PublishConsoleScreen> {
  static const String _allBundlesValue = '__all_bundles__';
  String? _selectedBundleId;

  @override
  void initState() {
    super.initState();
    final initialBundleId = widget.initialBundleId?.trim();
    if (initialBundleId != null && initialBundleId.isNotEmpty) {
      _selectedBundleId = initialBundleId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final integrationsAsync = ref.watch(integrationsProvider);
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final bundlesAsync = ref.watch(bundlesStreamProvider);

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
                      final filteredLogs =
                          _filterLogsForBundle(logs, selectedBundle);
                      if (filteredLogs.isEmpty) {
                        if (selectedBundle == null) {
                          return const Text('No publish logs yet.');
                        }
                        return Text(
                            'No publish logs for ${selectedBundle.name} yet.');
                      }
                      final recent =
                          filteredLogs.take(20).toList(growable: false);
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
