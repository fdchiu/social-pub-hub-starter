import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

enum _InboxAction {
  copyUrl,
  edit,
  delete,
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final TextEditingController _queryController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _query = '';
  String _typeFilter = 'all';
  bool _creatingDraft = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceItemsAsync = ref.watch(scopedSourceItemsStreamProvider);
    final activePost = ref.watch(activePostProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Inbox',
        actions: [
          sourceItemsAsync.maybeWhen(
            data: (items) {
              final filtered = _filterItems(items);
              final allVisibleSelected = filtered.isNotEmpty &&
                  filtered.every((item) => _selectedIds.contains(item.id));
              return IconButton(
                onPressed: filtered.isEmpty
                    ? null
                    : () => _toggleSelectVisible(filtered, allVisibleSelected),
                icon: Icon(
                  allVisibleSelected
                      ? Icons.deselect_outlined
                      : Icons.select_all_outlined,
                ),
                tooltip: allVisibleSelected
                    ? 'Clear visible selection'
                    : 'Select all visible',
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: _creatingDraft || activePost == null
                ? null
                : _createDraftFromSelected,
            icon: _creatingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.note_add_outlined),
            tooltip: 'Create draft from selected',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSourceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add source'),
      ),
      body: sourceItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No source items yet. Add one to start drafting.'),
            );
          }
          final typeOptions = <String>{'all', ...items.map((i) => i.type)}
              .toList(growable: false)
            ..sort();
          final filtered = _filterItems(items);

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: PostScopeHeader(showGlobalToggle: true),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: 'Search inbox',
                    hintText: 'title, note, url, tag',
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
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final type in typeOptions)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(type == 'all' ? 'All types' : type),
                          selected: _typeFilter == type,
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _typeFilter = type;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Visible: ${filtered.length}  •  Selected: ${_selectedIds.length}',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No sources match filters.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final checked = _selectedIds.contains(item.id);
                          final secondary = _sourceSummary(item);

                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) {
                              setState(() {
                                if (checked) {
                                  _selectedIds.remove(item.id);
                                } else {
                                  _selectedIds.add(item.id);
                                }
                              });
                            },
                            title: Text(item.title ?? item.type.toUpperCase()),
                            subtitle: Text(secondary),
                            secondary: PopupMenuButton<_InboxAction>(
                              onSelected: (action) async {
                                if (action == _InboxAction.copyUrl) {
                                  await _copySourceUrl(item);
                                  return;
                                }
                                if (action == _InboxAction.edit) {
                                  await _editSource(item);
                                  return;
                                }
                                await _deleteSource(item);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: _InboxAction.copyUrl,
                                  child: Text('Copy URL'),
                                ),
                                PopupMenuItem(
                                  value: _InboxAction.edit,
                                  child: Text('Edit source'),
                                ),
                                PopupMenuItem(
                                  value: _InboxAction.delete,
                                  child: Text('Delete source'),
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            isThreeLine: secondary.length > 80,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading inbox: $error')),
      ),
    );
  }

  String _sourceSummary(SourceItem item) {
    final parts = <String>[];
    if (item.userNote != null && item.userNote!.trim().isNotEmpty) {
      parts.add(item.userNote!.trim());
    } else if (item.url != null && item.url!.trim().isNotEmpty) {
      parts.add(item.url!.trim());
    }

    if (item.tags.isNotEmpty) {
      parts.add(item.tags.map((tag) => '#$tag').join(' '));
    }

    if (parts.isEmpty) {
      return item.type;
    }
    return parts.join('  •  ');
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

  List<SourceItem> _filterItems(List<SourceItem> items) {
    final needle = _query.toLowerCase();
    return items.where((item) {
      final typeMatches = _typeFilter == 'all' || item.type == _typeFilter;
      final queryMatches = needle.isEmpty ||
          [
            item.type,
            item.title ?? '',
            item.url ?? '',
            item.userNote ?? '',
            ...item.tags,
          ].join(' ').toLowerCase().contains(needle);
      return typeMatches && queryMatches;
    }).toList(growable: false);
  }

  void _toggleSelectVisible(
      List<SourceItem> filtered, bool allVisibleSelected) {
    setState(() {
      if (allVisibleSelected) {
        for (final item in filtered) {
          _selectedIds.remove(item.id);
        }
      } else {
        for (final item in filtered) {
          _selectedIds.add(item.id);
        }
      }
    });
  }

  Future<void> _copySourceUrl(SourceItem item) async {
    final url = item.url?.trim();
    if (url == null || url.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL on this source')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied')),
    );
  }

  Future<void> _editSource(SourceItem item) async {
    final activePost = ref.read(activePostProvider);
    final typeController = TextEditingController(text: item.type);
    final titleController = TextEditingController(text: item.title ?? '');
    final urlController = TextEditingController(text: item.url ?? '');
    final noteController = TextEditingController(text: item.userNote ?? '');
    final tagsController = TextEditingController(text: item.tags.join(', '));
    var saveAsGlobal = (item.postId == null || item.postId!.isEmpty);

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              title: Text('Edit source ${item.id.substring(0, 8)}'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: typeController,
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Note'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'ai, product, launch',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (activePost != null)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: saveAsGlobal,
                          onChanged: (next) {
                            setLocalState(() {
                              saveAsGlobal = next ?? false;
                            });
                          },
                          title: const Text('Save as global source'),
                          subtitle: Text(
                            saveAsGlobal
                                ? 'Source reusable across posts'
                                : 'Source belongs to: ${activePost.title}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldSave) {
      typeController.dispose();
      titleController.dispose();
      urlController.dispose();
      noteController.dispose();
      tagsController.dispose();
      return;
    }

    final type = typeController.text.trim();
    if (type.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Type is required')),
        );
      }
      typeController.dispose();
      titleController.dispose();
      urlController.dispose();
      noteController.dispose();
      tagsController.dispose();
      return;
    }

    final tags = tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    await ref.read(sourceRepoProvider).updateSourceItem(
          sourceId: item.id,
          type: type,
          title: titleController.text,
          url: urlController.text,
          userNote: noteController.text,
          tags: tags,
          postId: saveAsGlobal ? null : (activePost?.id ?? item.postId),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source updated')),
      );
    }

    typeController.dispose();
    titleController.dispose();
    urlController.dispose();
    noteController.dispose();
    tagsController.dispose();
  }

  Future<void> _deleteSource(SourceItem item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete source ${item.id.substring(0, 8)}?'),
            content: const Text('This permanently removes the source item.'),
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

    await ref.read(sourceRepoProvider).deleteSourceItemById(item.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIds.remove(item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Source deleted')),
    );
  }

  Future<void> _showAddSourceDialog() async {
    final repo = ref.read(sourceRepoProvider);
    final activePost = ref.read(activePostProvider);
    if (activePost == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a post workspace first.')),
        );
      }
      return;
    }
    final urlController = TextEditingController();
    final noteController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedType = 'url';
    var saveAsGlobal = false;

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setLocalState) {
                return AlertDialog(
                  title: const Text('Add Source Item'),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'url', child: Text('URL')),
                            DropdownMenuItem(
                                value: 'note', child: Text('Note')),
                            DropdownMenuItem(
                              value: 'snippet',
                              child: Text('Snippet'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setLocalState(() {
                              selectedType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Post: ${activePost.title}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: saveAsGlobal,
                          onChanged: (next) {
                            setLocalState(() {
                              saveAsGlobal = next ?? false;
                            });
                          },
                          title: const Text('Save as global source'),
                          subtitle: const Text(
                              'Global sources can be reused across posts'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL (optional)',
                            hintText: 'https://...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Why this matters',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags',
                            hintText: 'ai, product, leadership',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (shouldSave) {
      final tags = tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await repo.createSourceItem(
        type: selectedType,
        url: urlController.text,
        userNote: noteController.text,
        tags: tags,
        postId: saveAsGlobal ? null : activePost.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Source item saved')));
      }
    }

    urlController.dispose();
    noteController.dispose();
    tagsController.dispose();
  }

  Future<void> _createDraftFromSelected() async {
    final count = _selectedIds.length;
    final activePost = ref.read(activePostProvider);
    if (activePost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create/select a post first.')),
      );
      return;
    }
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select source items first.')),
      );
      return;
    }

    setState(() {
      _creatingDraft = true;
    });

    final selectedSourceIds = _selectedIds.toList(growable: false);
    final draftRepo = ref.read(draftRepoProvider);
    final styleProfile =
        await ref.read(styleProfileRepoProvider).getOrCreateDefault();
    final selectedSourceItems = await ref
        .read(sourceRepoProvider)
        .getSourceItemsByIds(selectedSourceIds);

    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final response = await ref.read(httpClientProvider).post(
            Uri.parse('$baseUrl/drafts/from_sources'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'source_ids': selectedSourceIds,
              'source_materials': selectedSourceItems
                  .map(
                    (item) => {
                      'id': item.id,
                      'type': item.type,
                      'title': item.title,
                      'url': item.url,
                      'note': item.userNote,
                      'tags': item.tags,
                    },
                  )
                  .toList(growable: false),
              'intent': _intentForContentType(activePost.contentType),
              'tone': 0.6,
              'punchiness': 0.7,
              'audience': activePost.audience ?? 'builders',
              'length_target': 'short',
              'post_id': activePost.id,
              'post_title': activePost.title,
              'post_goal': activePost.goal,
              'content_type': activePost.contentType,
              'style_traits': styleProfile.personalTraits,
              'differentiation_points': styleProfile.differentiationPoints,
              'personal_prompt': styleProfile.customPrompt,
              'banned_phrases': styleProfile.bannedPhrases,
            }),
          );

      String draftId;
      String canonicalMarkdown;
      var llmUsed = false;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        draftId = (parsed['draft_id'] as String?)?.trim() ?? '';
        canonicalMarkdown =
            (parsed['canonical_markdown'] as String?)?.trim() ?? '';
        llmUsed = parsed['llm_used'] as bool? ?? false;
        if (draftId.isEmpty) {
          throw Exception('Missing draft_id in response');
        }
        if (canonicalMarkdown.isEmpty) {
          canonicalMarkdown = _buildLocalDraftTemplate(
            selectedSourceIds,
            contentType: activePost.contentType,
          );
        }
      } else {
        draftId = '';
        canonicalMarkdown = '';
      }

      if (draftId.isEmpty) {
        draftId = await draftRepo.createDraft(
          canonicalMarkdown: _buildLocalDraftTemplate(
            selectedSourceIds,
            contentType: activePost.contentType,
          ),
          intent: _intentForContentType(activePost.contentType),
          audience: activePost.audience ?? 'builders',
          postId: activePost.id,
          contentType: activePost.contentType,
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backend unavailable. Created local draft from $count source items.',
            ),
          ),
        );
      } else {
        await draftRepo.createDraft(
          id: draftId,
          canonicalMarkdown: canonicalMarkdown,
          intent: _intentForContentType(activePost.contentType),
          tone: 0.6,
          punchiness: 0.7,
          audience: activePost.audience ?? 'builders',
          postId: activePost.id,
          contentType: activePost.contentType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                llmUsed
                    ? 'Draft generated with LLM + source evidence.'
                    : 'Draft generated from template + source evidence.',
              ),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
      });
      context.go(
        Uri(
          path: '/compose',
          queryParameters: {'draftId': draftId},
        ).toString(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed creating draft: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingDraft = false;
        });
      }
    }
  }

  String _buildLocalDraftTemplate(
    List<String> sourceIds, {
    required String contentType,
  }) {
    final sourceHint = sourceIds.take(3).join(', ');
    final outlineHint = switch (contentType) {
      'coding_guide' =>
        '- Setup and prerequisites\n- Step-by-step implementation\n- Verification and pitfalls',
      'ai_tool_guide' =>
        '- Use-case and tool setup\n- Prompt template and parameters\n- Guardrails, cost, and failure modes',
      _ => '- What changed\n- Why this matters now',
    };
    return '''
# Draft

Hook: Quick synthesis from selected inbox captures.

- Source IDs: ${sourceHint.isEmpty ? 'none' : sourceHint}
$outlineHint

Takeaway: Start with one testable claim and iterate.
''';
  }

  String _intentForContentType(String contentType) {
    return switch (contentType) {
      'coding_guide' => 'guide',
      'ai_tool_guide' => 'tool_guide',
      _ => 'how_to',
    };
  }
}
