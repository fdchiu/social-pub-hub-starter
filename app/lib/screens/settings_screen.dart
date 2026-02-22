import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/sync/sync_service.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';

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
  final TextEditingController _voiceController = TextEditingController();
  final TextEditingController _bannedPhrasesController =
      TextEditingController();
  String? _styleProfileId;
  bool _loadingStyleProfile = true;
  bool _savingStyleProfile = false;
  String? _styleProfileError;
  double _casualFormal = 0.6;
  double _punchiness = 0.7;
  String _emojiLevel = 'light';

  @override
  void initState() {
    super.initState();
    _loadStyleProfile();
  }

  @override
  void dispose() {
    _voiceController.dispose();
    _bannedPhrasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final integrationsAsync = ref.watch(integrationsProvider);
    final conflictsAsync = ref.watch(openSyncConflictsStreamProvider);
    final openConflictCount = conflictsAsync.maybeWhen(
      data: (rows) => rows.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Settings',
      ),
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
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                openConflictCount == 0
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: openConflictCount == 0 ? Colors.green : Colors.orange,
              ),
              title: Text('Sync conflicts: $openConflictCount open'),
              subtitle: const Text('Review and choose local/remote versions'),
              trailing: FilledButton.tonal(
                onPressed: () => context.go('/sync-conflicts'),
                child: const Text('Open'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStyleProfileCard(),
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

  Widget _buildStyleProfileCard() {
    final profileId = _styleProfileId;
    final disabled = _loadingStyleProfile || _savingStyleProfile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_loadingStyleProfile)
              const LinearProgressIndicator()
            else ...[
              TextField(
                controller: _voiceController,
                enabled: !disabled,
                decoration: const InputDecoration(
                  labelText: 'Voice name',
                  hintText: 'David',
                ),
              ),
              const SizedBox(height: 12),
              Text('Casual/Formal: ${_casualFormal.toStringAsFixed(1)}'),
              Slider(
                min: 0,
                max: 1,
                divisions: 10,
                value: _casualFormal,
                onChanged: disabled
                    ? null
                    : (value) {
                        setState(() {
                          _casualFormal = value;
                        });
                      },
              ),
              Text('Punchiness: ${_punchiness.toStringAsFixed(1)}'),
              Slider(
                min: 0,
                max: 1,
                divisions: 10,
                value: _punchiness,
                onChanged: disabled
                    ? null
                    : (value) {
                        setState(() {
                          _punchiness = value;
                        });
                      },
              ),
              DropdownButtonFormField<String>(
                value: _emojiLevel,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No emoji')),
                  DropdownMenuItem(value: 'light', child: Text('Light emoji')),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Medium emoji'),
                  ),
                  DropdownMenuItem(value: 'high', child: Text('High emoji')),
                ],
                onChanged: disabled
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _emojiLevel = value;
                        });
                      },
                decoration: const InputDecoration(labelText: 'Emoji level'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bannedPhrasesController,
                enabled: !disabled,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Banned phrases',
                  hintText: 'delve, leverage, game-changer',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    (profileId == null || disabled) ? null : _saveStyleProfile,
                icon: _savingStyleProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_savingStyleProfile ? 'Saving…' : 'Save profile'),
              ),
              if (_styleProfileError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _styleProfileError!,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ],
        ),
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

  Future<void> _loadStyleProfile() async {
    try {
      final profile =
          await ref.read(styleProfileRepoProvider).getOrCreateDefault();
      if (!mounted) {
        return;
      }
      setState(() {
        _styleProfileId = profile.id;
        _voiceController.text = profile.voiceName;
        _casualFormal = profile.casualFormal;
        _punchiness = profile.punchiness;
        _emojiLevel = profile.emojiLevel;
        _bannedPhrasesController.text = profile.bannedPhrases.join(', ');
        _loadingStyleProfile = false;
        _styleProfileError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingStyleProfile = false;
        _styleProfileError = 'Failed loading style profile: $error';
      });
    }
  }

  Future<void> _saveStyleProfile() async {
    final profileId = _styleProfileId;
    if (profileId == null) {
      return;
    }

    setState(() {
      _savingStyleProfile = true;
      _styleProfileError = null;
    });

    try {
      await ref.read(styleProfileRepoProvider).updateStyleProfile(
            id: profileId,
            voiceName: _voiceController.text,
            casualFormal: _casualFormal,
            punchiness: _punchiness,
            emojiLevel: _emojiLevel,
            bannedPhrases: _bannedPhrasesController.text
                .split(',')
                .map((phrase) => phrase.trim())
                .where((phrase) => phrase.isNotEmpty)
                .toList(growable: false),
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _savingStyleProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Style profile saved')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingStyleProfile = false;
        _styleProfileError = 'Failed saving style profile: $error';
      });
    }
  }

  String _summaryText(SyncSummary summary) {
    return 'Pushed d/v/p/s/q: '
        '${summary.pushedDrafts}/${summary.pushedVariants}/'
        '${summary.pushedPublishLogs}/${summary.pushedStyleProfiles}/'
        '${summary.pushedScheduledPosts}\n'
        'Pulled d/v/p/s/q: '
        '${summary.pulledDrafts}/${summary.pulledVariants}/'
        '${summary.pulledPublishLogs}/${summary.pulledStyleProfiles}/'
        '${summary.pulledScheduledPosts}\n'
        'Deleted d/v/p/s/q: '
        '${summary.deletedDrafts}/${summary.deletedVariants}/'
        '${summary.deletedPublishLogs}/${summary.deletedStyleProfiles}/'
        '${summary.deletedScheduledPosts}\n'
        'Conflicts detected: ${summary.detectedConflicts}';
  }
}
