import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    this.initialVariantId,
    this.initialPostId,
    this.initialPlatform,
    this.initialStatus,
    this.initialMode,
    this.initialWindow,
  });

  final String? initialVariantId;
  final String? initialPostId;
  final String? initialPlatform;
  final String? initialStatus;
  final String? initialMode;
  final String? initialWindow;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();
  String _query = '';
  String _platformFilter = 'all';
  String _statusFilter = 'all';
  String _modeFilter = 'all';
  _HistoryWindow _window = _HistoryWindow.all;
  String? _variantFilterId;
  bool _includeAllPosts = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    final initialPostId = widget.initialPostId?.trim();
    if (initialPostId != null && initialPostId.isNotEmpty) {
      ref.read(activePostIdProvider.notifier).state = initialPostId;
    }
    final initialVariantId = widget.initialVariantId?.trim();
    if (initialVariantId != null && initialVariantId.isNotEmpty) {
      _variantFilterId = initialVariantId;
      _variantController.text = initialVariantId;
    }
    final initialPlatform = widget.initialPlatform?.trim().toLowerCase();
    if (initialPlatform != null && initialPlatform.isNotEmpty) {
      _platformFilter = initialPlatform;
    }
    final initialStatus = widget.initialStatus?.trim().toLowerCase();
    if (initialStatus != null && initialStatus.isNotEmpty) {
      _statusFilter = initialStatus;
    }
    final initialMode = widget.initialMode?.trim().toLowerCase();
    if (initialMode != null && initialMode.isNotEmpty) {
      _modeFilter = initialMode;
    }
    final initialWindow = _parseWindow(widget.initialWindow);
    if (initialWindow != null) {
      _window = initialWindow;
    }
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _variantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(publishLogsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'History',
        actions: [
          IconButton(
            tooltip: 'Export filtered CSV',
            onPressed: _exportFilteredCsv,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          final scopedLogs = _scopeLogs(
            logs,
            activePostId: activePost?.id,
            includeAllPosts: _includeAllPosts,
          );
          final platformOptions = <String>{
            'all',
            ...scopedLogs.map((row) => row.platform.toLowerCase()),
          }.toList()
            ..sort();
          final statusOptions = <String>{
            'all',
            ...scopedLogs.map((row) => row.status.toLowerCase()),
          }.toList()
            ..sort();
          final modeOptions = <String>{
            'all',
            ...scopedLogs.map((row) => row.mode.toLowerCase()),
          }.toList()
            ..sort();
          final platformFilter =
              _normalizeFilter(_platformFilter, platformOptions);
          final statusFilter = _normalizeFilter(_statusFilter, statusOptions);
          final modeFilter = _normalizeFilter(_modeFilter, modeOptions);
          final filtered = _filterLogs(
            scopedLogs,
            platformFilter: platformFilter,
            statusFilter: statusFilter,
            modeFilter: modeFilter,
          );

          String labelFor(String value) {
            if (value == 'all') {
              return 'All';
            }
            return value.toUpperCase();
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: PostScopeHeader(showGlobalToggle: false),
              ),
              SwitchListTile(
                value: _includeAllPosts,
                onChanged: (value) {
                  setState(() {
                    _includeAllPosts = value;
                  });
                },
                title: const Text('Include all posts'),
                subtitle: const Text(
                  'Show history rows from all posts instead of only active post',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (scopedLogs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      labelText: 'Search logs',
                      hintText: 'platform, status, variant id, url',
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
                ),
              if (scopedLogs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _variantController,
                    decoration: InputDecoration(
                      labelText: 'Variant ID (exact match)',
                      hintText: 'Paste full variant id',
                      prefixIcon: const Icon(Icons.tag_outlined),
                      suffixIcon: _variantController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _variantController.clear();
                                setState(() {
                                  _variantFilterId = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      setState(() {
                        _variantFilterId = trimmed.isEmpty ? null : trimmed;
                      });
                    },
                  ),
                ),
              if (scopedLogs.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _HistoryWindow.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final option = _HistoryWindow.values[index];
                      final label = switch (option) {
                        _HistoryWindow.days7 => '7D',
                        _HistoryWindow.days30 => '30D',
                        _HistoryWindow.days90 => '90D',
                        _HistoryWindow.all => 'All',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: _window == option,
                        onSelected: (selected) {
                          if (!selected) {
                            return;
                          }
                          setState(() {
                            _window = option;
                          });
                        },
                      );
                    },
                  ),
                ),
              if (scopedLogs.isNotEmpty) const SizedBox(height: 6),
              if (scopedLogs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: platformFilter,
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
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: statusFilter,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
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
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: modeFilter,
                          decoration: const InputDecoration(labelText: 'Mode'),
                          items: modeOptions
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
                              _modeFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (scopedLogs.isNotEmpty && _variantFilterId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Variant filter: ${_shortId(_variantFilterId!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _variantController.clear();
                          setState(() {
                            _variantFilterId = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('No publish logs yet.'))
                    : scopedLogs.isEmpty
                        ? Center(
                            child: Text(
                              _includeAllPosts
                                  ? 'No history rows yet.'
                                  : 'No history rows for active post scope.',
                            ),
                          )
                        : filtered.isEmpty
                            ? const Center(
                                child: Text('No logs match filters.'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final posted = item.postedAt
                                          ?.toLocal()
                                          .toIso8601String() ??
                                      '-';
                                  final variantLabel = item.variantId == null
                                      ? '-'
                                      : _shortId(item.variantId!);
                                  final postLabel = item.postId == null
                                      ? 'unscoped'
                                      : _shortId(item.postId!);
                                  return ListTile(
                                    title: Text(
                                        '${item.platform.toUpperCase()} · ${item.status}'),
                                    subtitle: Text(
                                        'post=$postLabel · mode=${item.mode} · variant=$variantLabel · postedAt=$posted'),
                                    trailing: PopupMenuButton<_HistoryAction>(
                                      onSelected: (action) {
                                        if (action ==
                                            _HistoryAction.cloneAsDraft) {
                                          _cloneAsDraft(item);
                                          return;
                                        }
                                        if (action ==
                                                _HistoryAction
                                                    .openExternalUrl &&
                                            item.externalUrl != null) {
                                          _openExternalUrl(item.externalUrl!);
                                          return;
                                        }
                                        if (action ==
                                            _HistoryAction.deleteLog) {
                                          _deleteLog(item);
                                        }
                                      },
                                      itemBuilder: (context) {
                                        final menu =
                                            <PopupMenuEntry<_HistoryAction>>[];
                                        if (item.variantId != null) {
                                          menu.add(
                                            const PopupMenuItem(
                                              value:
                                                  _HistoryAction.cloneAsDraft,
                                              child: Text('Clone as draft'),
                                            ),
                                          );
                                        }
                                        if (item.externalUrl != null &&
                                            item.externalUrl!
                                                .trim()
                                                .isNotEmpty) {
                                          menu.add(
                                            const PopupMenuItem(
                                              value: _HistoryAction
                                                  .openExternalUrl,
                                              child: Text('Open external URL'),
                                            ),
                                          );
                                        }
                                        menu.add(
                                          const PopupMenuItem(
                                            value: _HistoryAction.deleteLog,
                                            child: Text('Delete log'),
                                          ),
                                        );
                                        if (menu.isEmpty) {
                                          menu.add(
                                            const PopupMenuItem(
                                              enabled: false,
                                              value:
                                                  _HistoryAction.cloneAsDraft,
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

  Future<void> _cloneAsDraft(PublishLog log) async {
    final variantId = log.variantId;
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

    final activePost = ref.read(activePostProvider);
    final postId = log.postId ?? activePost?.id;
    final post = postId == null
        ? activePost
        : await ref.read(postRepoProvider).getPostById(postId);
    final contentType = post?.contentType ?? 'general_post';

    final draftId = await ref.read(draftRepoProvider).createDraft(
          canonicalMarkdown: variant.body,
          intent: _intentForContentType(contentType),
          audience: post?.audience,
          postId: postId,
          contentType: contentType,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created draft ${draftId.substring(0, 8)}')),
    );
    final encoded = Uri.encodeQueryComponent(draftId);
    context.go('/compose?draftId=$encoded');
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

  Future<void> _deleteLog(PublishLog log) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete history log?'),
            content: const Text(
              'This permanently removes the history row and syncs deletion.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await ref.read(publishLogRepoProvider).deletePublishLog(log.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History log deleted')),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id;
    }
    return id.substring(0, 8);
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

  List<PublishLog> _filterLogs(
    List<PublishLog> logs, {
    required String platformFilter,
    required String statusFilter,
    required String modeFilter,
  }) {
    final needle = _query.toLowerCase();
    final now = DateTime.now().toUtc();
    final since = switch (_window) {
      _HistoryWindow.days7 => now.subtract(const Duration(days: 7)),
      _HistoryWindow.days30 => now.subtract(const Duration(days: 30)),
      _HistoryWindow.days90 => now.subtract(const Duration(days: 90)),
      _HistoryWindow.all => null,
    };
    return logs.where((row) {
      final platformMatches = platformFilter == 'all' ||
          row.platform.toLowerCase() == platformFilter;
      final statusMatches =
          statusFilter == 'all' || row.status.toLowerCase() == statusFilter;
      final modeMatches =
          modeFilter == 'all' || row.mode.toLowerCase() == modeFilter;
      final variantMatches =
          _variantFilterId == null || row.variantId == _variantFilterId;
      final windowMatches = since == null || row.createdAt.isAfter(since);
      final queryMatches = needle.isEmpty ||
          [
            row.platform,
            row.status,
            row.mode,
            row.variantId ?? '',
            row.externalUrl ?? '',
            row.postedAt?.toIso8601String() ?? '',
          ].join(' ').toLowerCase().contains(needle);
      return platformMatches &&
          statusMatches &&
          modeMatches &&
          variantMatches &&
          windowMatches &&
          queryMatches;
    }).toList(growable: false);
  }

  Future<void> _exportFilteredCsv() async {
    final logs = ref.read(publishLogsStreamProvider).valueOrNull;
    final activePost = ref.read(activePostProvider);
    if (logs == null || logs.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to export')),
      );
      return;
    }
    final scopedLogs = _scopeLogs(
      logs,
      activePostId: activePost?.id,
      includeAllPosts: _includeAllPosts,
    );
    if (scopedLogs.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _includeAllPosts
                ? 'No logs to export'
                : 'No logs in active post scope',
          ),
        ),
      );
      return;
    }

    final platformOptions = <String>{
      'all',
      ...scopedLogs.map((row) => row.platform.toLowerCase()),
    }.toList()
      ..sort();
    final statusOptions = <String>{
      'all',
      ...scopedLogs.map((row) => row.status.toLowerCase()),
    }.toList()
      ..sort();
    final modeOptions = <String>{
      'all',
      ...scopedLogs.map((row) => row.mode.toLowerCase()),
    }.toList()
      ..sort();
    final filtered = _filterLogs(
      scopedLogs,
      platformFilter: _normalizeFilter(_platformFilter, platformOptions),
      statusFilter: _normalizeFilter(_statusFilter, statusOptions),
      modeFilter: _normalizeFilter(_modeFilter, modeOptions),
    );
    if (filtered.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filtered logs to export')),
      );
      return;
    }

    final lines = <String>[
      'id,platform,status,mode,variant_id,post_id,external_url,posted_at,created_at',
      ...filtered.map((row) {
        return [
          _csv(row.id),
          _csv(row.platform),
          _csv(row.status),
          _csv(row.mode),
          _csv(row.variantId ?? ''),
          _csv(row.postId ?? ''),
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

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _normalizeFilter(String value, List<String> options) {
    return options.contains(value) ? value : 'all';
  }

  List<PublishLog> _scopeLogs(
    List<PublishLog> logs, {
    required String? activePostId,
    required bool includeAllPosts,
  }) {
    if (includeAllPosts || activePostId == null || activePostId.isEmpty) {
      return logs;
    }
    return logs
        .where((row) => row.postId != null && row.postId == activePostId)
        .toList(growable: false);
  }

  _HistoryWindow? _parseWindow(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      '7d' => _HistoryWindow.days7,
      '30d' => _HistoryWindow.days30,
      '90d' => _HistoryWindow.days90,
      'all' => _HistoryWindow.all,
      _ => null,
    };
  }

  String _intentForContentType(String contentType) {
    return switch (contentType) {
      'coding_guide' => 'guide',
      'ai_tool_guide' => 'tool_guide',
      _ => 'how_to',
    };
  }
}

enum _HistoryAction {
  cloneAsDraft,
  openExternalUrl,
  deleteLog,
}

enum _HistoryWindow {
  days7,
  days30,
  days90,
  all,
}
