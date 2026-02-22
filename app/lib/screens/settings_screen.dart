import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_service.dart';
import '../providers/sync_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  SyncSummary? _lastSummary;
  String? _lastError;
  DateTime? _lastRunAt;

  @override
  Widget build(BuildContext context) {
    final integrationsAsync = ref.watch(integrationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _syncing ? null : _runSync,
            icon: _syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_syncing ? 'Syncing…' : 'Sync now'),
          ),
          const SizedBox(height: 16),
          if (_lastRunAt != null)
            Text('Last run: ${_lastRunAt!.toLocal().toIso8601String()}'),
          if (_lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _lastError!,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          if (_lastSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_summaryText(_lastSummary!)),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Integrations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh integrations',
                onPressed: () => ref.invalidate(integrationsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          integrationsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No integrations reported by backend.');
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
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Failed loading integrations: $error',
                style: const TextStyle(color: Colors.orange),
              ),
            ),
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

  Future<void> _runSync() async {
    setState(() {
      _syncing = true;
      _lastError = null;
    });

    try {
      final summary = await ref.read(syncServiceProvider).syncNow();
      if (!mounted) {
        return;
      }
      setState(() {
        _syncing = false;
        _lastSummary = summary;
        _lastRunAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync done. Cursor ${summary.cursor}')),
      );
      ref.invalidate(integrationsProvider);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncing = false;
        _lastError = 'Sync failed: $e';
        _lastRunAt = DateTime.now();
      });
    }
  }

  String _summaryText(SyncSummary summary) {
    return 'Pushed d/v/p/s: '
        '${summary.pushedDrafts}/${summary.pushedVariants}/'
        '${summary.pushedPublishLogs}/${summary.pushedStyleProfiles}\n'
        'Pulled d/v/p/s: '
        '${summary.pulledDrafts}/${summary.pulledVariants}/'
        '${summary.pulledPublishLogs}/${summary.pulledStyleProfiles}\n'
        'Deleted d/v/p/s: '
        '${summary.deletedDrafts}/${summary.deletedVariants}/'
        '${summary.deletedPublishLogs}/${summary.deletedStyleProfiles}';
  }
}
