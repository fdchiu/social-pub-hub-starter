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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );
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
