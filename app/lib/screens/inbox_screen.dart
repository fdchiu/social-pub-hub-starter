
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final sourceItemsAsync = ref.watch(sourceItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            onPressed: _createDraftFromSelectedStub,
            icon: const Icon(Icons.note_add_outlined),
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

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
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
                controlAffinity: ListTileControlAffinity.leading,
                isThreeLine: secondary.length > 80,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed loading inbox: $error')),
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

  Future<void> _showAddSourceDialog() async {
    final repo = ref.read(sourceRepoProvider);
    final urlController = TextEditingController();
    final noteController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedType = 'url';

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
                            DropdownMenuItem(value: 'note', child: Text('Note')),
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

  void _createDraftFromSelectedStub() {
    final count = _selectedIds.length;
    final message = count == 0
        ? 'Select source items first.'
        : 'Draft creation from $count selected items is stubbed next.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
