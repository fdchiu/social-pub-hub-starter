import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../data/sync/sync_service.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

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
  final List<_SyncRunEntry> _syncRuns = <_SyncRunEntry>[];
  final TextEditingController _voiceController = TextEditingController();
  final TextEditingController _bannedPhrasesController =
      TextEditingController();
  final TextEditingController _personalTraitsController =
      TextEditingController();
  final TextEditingController _differentiationPointsController =
      TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  String? _styleProfileId;
  bool _loadingStyleProfile = true;
  bool _savingStyleProfile = false;
  String? _styleProfileError;
  double _casualFormal = 0.6;
  double _punchiness = 0.7;
  String _emojiLevel = 'light';
  bool _includeAllPosts = false;

  @override
  void initState() {
    super.initState();
    _loadStyleProfile();
  }

  @override
  void dispose() {
    _voiceController.dispose();
    _bannedPhrasesController.dispose();
    _personalTraitsController.dispose();
    _differentiationPointsController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePost = ref.watch(activePostProvider);
    final integrationsAsync = ref.watch(integrationsProvider);
    final conflictsAsync = ref.watch(openSyncConflictsStreamProvider);
    final allDrafts = ref.watch(allDraftsStreamProvider).valueOrNull;
    final sourceCount = (_includeAllPosts
            ? ref.watch(sourceItemsStreamProvider)
            : ref.watch(scopedSourceItemsStreamProvider))
        .valueOrNull
        ?.length;
    final draftCount = (_includeAllPosts
            ? ref.watch(allDraftsStreamProvider)
            : ref.watch(scopedDraftsStreamProvider))
        .valueOrNull
        ?.length;
    final variantCount = _scopeVariants(
      ref.watch(allVariantsStreamProvider).valueOrNull,
      drafts: allDrafts,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    )?.length;
    final postCount = ref.watch(postsStreamProvider).valueOrNull?.length;
    final projectCount = ref.watch(projectsStreamProvider).valueOrNull?.length;
    final bundleCount = _scopeBundles(
      ref.watch(bundlesStreamProvider).valueOrNull,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    )?.length;
    final publishLogCount = _scopePublishLogs(
      ref.watch(publishLogsStreamProvider).valueOrNull,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    )?.length;
    final queueCount = _scopeScheduledPosts(
      ref.watch(scheduledPostsStreamProvider).valueOrNull,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    )?.length;
    final integrationCount = integrationsAsync.valueOrNull?.length;
    final connectedIntegrations =
        integrationsAsync.valueOrNull?.where((row) => row.connected).length;
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
          const PostScopeHeader(showGlobalToggle: false),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _includeAllPosts,
            onChanged: (value) {
              setState(() {
                _includeAllPosts = value;
              });
            },
            title: const Text('Include all posts'),
            subtitle: const Text(
              'Diagnostics show all posts instead of only active post',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
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
          _buildDebugCard(
            sourceCount: sourceCount,
            draftCount: draftCount,
            variantCount: variantCount,
            postCount: postCount,
            projectCount: projectCount,
            bundleCount: bundleCount,
            publishLogCount: publishLogCount,
            queueCount: queueCount,
            openConflictCount: openConflictCount,
            integrationCount: integrationCount,
            connectedIntegrationCount: connectedIntegrations,
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

  List<Variant>? _scopeVariants(
    List<Variant>? variants, {
    required List<Draft>? drafts,
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (variants == null) {
      return null;
    }
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return variants;
    }
    final draftsById = {
      for (final draft in drafts ?? const <Draft>[]) draft.id: draft,
    };
    return variants.where((variant) {
      final draftPostId = draftsById[variant.draftId]?.postId;
      return draftPostId == null || draftPostId == activePostId;
    }).toList(growable: false);
  }

  List<Bundle>? _scopeBundles(
    List<Bundle>? bundles, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (bundles == null) {
      return null;
    }
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return bundles;
    }
    return bundles
        .where(
            (bundle) => bundle.postId == null || bundle.postId == activePostId)
        .toList(growable: false);
  }

  List<PublishLog>? _scopePublishLogs(
    List<PublishLog>? logs, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (logs == null) {
      return null;
    }
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return logs;
    }
    return logs
        .where((log) => log.postId == null || log.postId == activePostId)
        .toList(growable: false);
  }

  List<ScheduledPost>? _scopeScheduledPosts(
    List<ScheduledPost>? rows, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (rows == null) {
      return null;
    }
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return rows;
    }
    return rows
        .where((row) => row.postId == null || row.postId == activePostId)
        .toList(growable: false);
  }

  Widget _buildDebugCard({
    required int? sourceCount,
    required int? draftCount,
    required int? variantCount,
    required int? postCount,
    required int? projectCount,
    required int? bundleCount,
    required int? publishLogCount,
    required int? queueCount,
    required int openConflictCount,
    required int? integrationCount,
    required int? connectedIntegrationCount,
  }) {
    String showCount(int? value) => value == null ? '...' : '$value';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'sources=${showCount(sourceCount)}  drafts=${showCount(draftCount)}  '
              'variants=${showCount(variantCount)}  posts=${showCount(postCount)}  '
              'projects=${showCount(projectCount)}  bundles=${showCount(bundleCount)}',
            ),
            Text(
              'logs=${showCount(publishLogCount)}  queue=${showCount(queueCount)}  '
              'conflicts=$openConflictCount',
            ),
            Text(
              'integrations=${showCount(integrationCount)}  '
              'connected=${showCount(connectedIntegrationCount)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _copyDiagnosticsSnapshot(
                    sourceCount: sourceCount,
                    draftCount: draftCount,
                    variantCount: variantCount,
                    postCount: postCount,
                    projectCount: projectCount,
                    bundleCount: bundleCount,
                    publishLogCount: publishLogCount,
                    queueCount: queueCount,
                    openConflictCount: openConflictCount,
                    integrationCount: integrationCount,
                    connectedIntegrationCount: connectedIntegrationCount,
                  ),
                  child: const Text('Copy diagnostics JSON'),
                ),
                FilledButton.tonal(
                  onPressed: _syncRuns.isEmpty ? null : _copySyncRuns,
                  child: const Text('Copy sync runs'),
                ),
              ],
            ),
            if (_syncRuns.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent sync runs',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final run in _syncRuns.take(5))
                Text(
                  '${run.at.toLocal().toIso8601String()} '
                  '[${run.ok ? 'ok' : 'error'}] '
                  '${run.durationMs}ms '
                  '${run.ok ? 'cursor=${run.summary?.cursor ?? '-'}' : run.error ?? '-'}',
                ),
            ],
          ],
        ),
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
              TextField(
                controller: _personalTraitsController,
                enabled: !disabled,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Personal traits',
                  hintText: 'practical, concise, candid',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _differentiationPointsController,
                enabled: !disabled,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Differentiation points',
                  hintText: 'tradeoff-first, include failure notes',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customPromptController,
                enabled: !disabled,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Custom prompt',
                  hintText: 'Always include a concrete example and caveat.',
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: profileId == null ? null : _copyStyleProfileJson,
                    child: const Text('Copy JSON'),
                  ),
                  FilledButton.tonal(
                    onPressed: (profileId == null || disabled)
                        ? null
                        : _importStyleJson,
                    child: const Text('Import JSON'),
                  ),
                ],
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
    final startedAt = DateTime.now();
    setState(() {
      _syncing = true;
      _lastError = null;
    });

    try {
      final summary = await ref.read(syncServiceProvider).syncNow();
      if (!mounted) {
        return;
      }
      final finishedAt = DateTime.now();
      setState(() {
        _syncing = false;
        _lastSummary = summary;
        _lastRunAt = finishedAt;
        _syncRuns.insert(
          0,
          _SyncRunEntry(
            at: finishedAt,
            durationMs: finishedAt.difference(startedAt).inMilliseconds,
            ok: true,
            summary: summary,
          ),
        );
        if (_syncRuns.length > 20) {
          _syncRuns.removeLast();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync done. Cursor ${summary.cursor}')),
      );
      ref.invalidate(integrationsProvider);
    } catch (e) {
      if (!mounted) {
        return;
      }
      final finishedAt = DateTime.now();
      setState(() {
        _syncing = false;
        _lastError = 'Sync failed: $e';
        _lastRunAt = finishedAt;
        _syncRuns.insert(
          0,
          _SyncRunEntry(
            at: finishedAt,
            durationMs: finishedAt.difference(startedAt).inMilliseconds,
            ok: false,
            error: '$e',
          ),
        );
        if (_syncRuns.length > 20) {
          _syncRuns.removeLast();
        }
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
        _personalTraitsController.text = profile.personalTraits.join(', ');
        _differentiationPointsController.text =
            profile.differentiationPoints.join(', ');
        _customPromptController.text = profile.customPrompt ?? '';
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
            personalTraits: _personalTraitsController.text
                .split(',')
                .map((phrase) => phrase.trim())
                .where((phrase) => phrase.isNotEmpty)
                .toList(growable: false),
            differentiationPoints: _differentiationPointsController.text
                .split(',')
                .map((phrase) => phrase.trim())
                .where((phrase) => phrase.isNotEmpty)
                .toList(growable: false),
            customPrompt: _customPromptController.text,
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

  Future<void> _copyStyleProfileJson() async {
    final profileId = _styleProfileId;
    if (profileId == null) {
      return;
    }
    final payload = {
      'id': profileId,
      'voice_name': _voiceController.text.trim(),
      'casual_formal': _casualFormal,
      'punchiness': _punchiness,
      'emoji_level': _emojiLevel,
      'banned_phrases': _bannedPhrasesController.text
          .split(',')
          .map((phrase) => phrase.trim())
          .where((phrase) => phrase.isNotEmpty)
          .toList(growable: false),
      'personal_traits': _personalTraitsController.text
          .split(',')
          .map((phrase) => phrase.trim())
          .where((phrase) => phrase.isNotEmpty)
          .toList(growable: false),
      'differentiation_points': _differentiationPointsController.text
          .split(',')
          .map((phrase) => phrase.trim())
          .where((phrase) => phrase.isNotEmpty)
          .toList(growable: false),
      'custom_prompt': _customPromptController.text.trim().isEmpty
          ? null
          : _customPromptController.text.trim(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Style profile JSON copied')),
    );
  }

  Future<void> _importStyleJson() async {
    final profileId = _styleProfileId;
    if (profileId == null) {
      return;
    }
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import style profile JSON'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 10,
            maxLines: 18,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"voice_name":"David",...}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw Exception('JSON must be an object');
      }
      final map = decoded.cast<String, dynamic>();

      final voice =
          ((map['voice_name'] ?? map['voiceName']) as String?)?.trim() ??
              _voiceController.text.trim();
      final casualFormal = _clamp01(_asDouble(
            map['casual_formal'] ?? map['casualFormal'],
          ) ??
          _casualFormal);
      final punchiness = _clamp01(_asDouble(map['punchiness']) ?? _punchiness);
      final emojiLevel = _normalizeEmojiLevel(
        (map['emoji_level'] ?? map['emojiLevel']) as String? ?? _emojiLevel,
      );
      final banned = _parseBannedPhrases(
        map['banned_phrases'] ?? map['bannedPhrases'],
      );
      final traits = _parseBannedPhrases(
        map['personal_traits'] ?? map['personalTraits'],
      );
      final diffPoints = _parseBannedPhrases(
        map['differentiation_points'] ?? map['differentiationPoints'],
      );
      final customPrompt =
          ((map['custom_prompt'] ?? map['customPrompt']) as String?)?.trim() ??
              '';

      setState(() {
        _voiceController.text = voice;
        _casualFormal = casualFormal;
        _punchiness = punchiness;
        _emojiLevel = emojiLevel;
        _bannedPhrasesController.text = banned.join(', ');
        _personalTraitsController.text = traits.join(', ');
        _differentiationPointsController.text = diffPoints.join(', ');
        _customPromptController.text = customPrompt;
      });
      await _saveStyleProfile();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _normalizeEmojiLevel(String value) {
    final normalized = value.trim().toLowerCase();
    if (const {'none', 'light', 'medium', 'high'}.contains(normalized)) {
      return normalized;
    }
    return _emojiLevel;
  }

  List<String> _parseBannedPhrases(Object? value) {
    if (value is List) {
      return value
          .map((row) => row.toString().trim())
          .where((row) => row.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      return value
          .split(',')
          .map((row) => row.trim())
          .where((row) => row.isNotEmpty)
          .toList(growable: false);
    }
    return _bannedPhrasesController.text
        .split(',')
        .map((phrase) => phrase.trim())
        .where((phrase) => phrase.isNotEmpty)
        .toList(growable: false);
  }

  String _summaryText(SyncSummary summary) {
    return 'Pushed proj/post/b/d/v/p/s/q: '
        '${summary.pushedProjects}/${summary.pushedPosts}/'
        '${summary.pushedBundles}/'
        '${summary.pushedDrafts}/${summary.pushedVariants}/'
        '${summary.pushedPublishLogs}/${summary.pushedStyleProfiles}/'
        '${summary.pushedScheduledPosts}\n'
        'Pulled proj/post/b/d/v/p/s/q: '
        '${summary.pulledProjects}/${summary.pulledPosts}/'
        '${summary.pulledBundles}/'
        '${summary.pulledDrafts}/${summary.pulledVariants}/'
        '${summary.pulledPublishLogs}/${summary.pulledStyleProfiles}/'
        '${summary.pulledScheduledPosts}\n'
        'Deleted proj/post/b/d/v/p/s/q: '
        '${summary.deletedProjects}/${summary.deletedPosts}/'
        '${summary.deletedBundles}/'
        '${summary.deletedDrafts}/${summary.deletedVariants}/'
        '${summary.deletedPublishLogs}/${summary.deletedStyleProfiles}/'
        '${summary.deletedScheduledPosts}\n'
        'Conflicts detected: ${summary.detectedConflicts}';
  }

  Future<void> _copyDiagnosticsSnapshot({
    required int? sourceCount,
    required int? draftCount,
    required int? variantCount,
    required int? postCount,
    required int? projectCount,
    required int? bundleCount,
    required int? publishLogCount,
    required int? queueCount,
    required int openConflictCount,
    required int? integrationCount,
    required int? connectedIntegrationCount,
  }) async {
    final payload = <String, dynamic>{
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'api_base_url': ref.read(apiBaseUrlProvider),
      'sync': {
        'last_run_at': _lastRunAt?.toUtc().toIso8601String(),
        'last_error': _lastError,
        'last_summary':
            _lastSummary == null ? null : _summaryMap(_lastSummary!),
      },
      'counts': {
        'source_items': sourceCount,
        'drafts': draftCount,
        'variants': variantCount,
        'posts': postCount,
        'projects': projectCount,
        'bundles': bundleCount,
        'publish_logs': publishLogCount,
        'scheduled_posts': queueCount,
        'open_sync_conflicts': openConflictCount,
        'integrations': integrationCount,
        'connected_integrations': connectedIntegrationCount,
      },
      'style_profile': {
        'id': _styleProfileId,
        'voice_name': _voiceController.text.trim(),
        'casual_formal': _casualFormal,
        'punchiness': _punchiness,
        'emoji_level': _emojiLevel,
        'banned_phrases': _bannedPhrasesController.text
            .split(',')
            .map((phrase) => phrase.trim())
            .where((phrase) => phrase.isNotEmpty)
            .toList(growable: false),
        'personal_traits': _personalTraitsController.text
            .split(',')
            .map((phrase) => phrase.trim())
            .where((phrase) => phrase.isNotEmpty)
            .toList(growable: false),
        'differentiation_points': _differentiationPointsController.text
            .split(',')
            .map((phrase) => phrase.trim())
            .where((phrase) => phrase.isNotEmpty)
            .toList(growable: false),
        'custom_prompt': _customPromptController.text.trim().isEmpty
            ? null
            : _customPromptController.text.trim(),
      },
      'recent_sync_runs': _syncRuns
          .map((run) => {
                'at': run.at.toUtc().toIso8601String(),
                'duration_ms': run.durationMs,
                'ok': run.ok,
                'error': run.error,
                'summary':
                    run.summary == null ? null : _summaryMap(run.summary!),
              })
          .toList(growable: false),
    };

    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied as JSON')),
    );
  }

  Future<void> _copySyncRuns() async {
    final lines = <String>[
      'at_utc,ok,duration_ms,cursor,error',
      ..._syncRuns.map((run) {
        final cursor = run.summary?.cursor ?? '';
        final error = (run.error ?? '').replaceAll(',', ';');
        return '${run.at.toUtc().toIso8601String()},'
            '${run.ok},'
            '${run.durationMs},'
            '$cursor,'
            '$error';
      }),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_syncRuns.length} sync runs')),
    );
  }

  Map<String, dynamic> _summaryMap(SyncSummary summary) {
    return {
      'cursor': summary.cursor,
      'pushed': {
        'projects': summary.pushedProjects,
        'posts': summary.pushedPosts,
        'bundles': summary.pushedBundles,
        'drafts': summary.pushedDrafts,
        'variants': summary.pushedVariants,
        'publish_logs': summary.pushedPublishLogs,
        'style_profiles': summary.pushedStyleProfiles,
        'scheduled_posts': summary.pushedScheduledPosts,
      },
      'pulled': {
        'projects': summary.pulledProjects,
        'posts': summary.pulledPosts,
        'bundles': summary.pulledBundles,
        'drafts': summary.pulledDrafts,
        'variants': summary.pulledVariants,
        'publish_logs': summary.pulledPublishLogs,
        'style_profiles': summary.pulledStyleProfiles,
        'scheduled_posts': summary.pulledScheduledPosts,
      },
      'deleted': {
        'projects': summary.deletedProjects,
        'posts': summary.deletedPosts,
        'bundles': summary.deletedBundles,
        'drafts': summary.deletedDrafts,
        'variants': summary.deletedVariants,
        'publish_logs': summary.deletedPublishLogs,
        'style_profiles': summary.deletedStyleProfiles,
        'scheduled_posts': summary.deletedScheduledPosts,
      },
      'detected_conflicts': summary.detectedConflicts,
    };
  }
}

class _SyncRunEntry {
  const _SyncRunEntry({
    required this.at,
    required this.durationMs,
    required this.ok,
    this.summary,
    this.error,
  });

  final DateTime at;
  final int durationMs;
  final bool ok;
  final SyncSummary? summary;
  final String? error;
}
