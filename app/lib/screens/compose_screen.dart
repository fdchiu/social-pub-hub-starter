
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repo_providers.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  static const String _seedDraftText = '''
# Draft

Hook:

- point 1
- point 2

Takeaway:
''';

  final TextEditingController _controller = TextEditingController();
  Timer? _saveDebounce;
  String? _draftId;
  bool _loading = true;
  bool _hydratingEditor = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEditorChanged);
    unawaited(_loadOrCreateDraft());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _controller.removeListener(_onEditorChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        actions: [
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: _saveError!,
                child: const Icon(Icons.error_outline, color: Colors.orange),
              ),
            ),
          if (_draftId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Draft ${_draftId!.substring(0, 8)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                minLines: null,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write canonical markdown draft...',
                ),
              ),
            ),
    );
  }

  Future<void> _loadOrCreateDraft() async {
    final repo = ref.read(draftRepoProvider);
    final latest = await repo.getLatestDraft();
    final draft = latest ??
        await () async {
          final draftId = await repo.createDraft(
            canonicalMarkdown: _seedDraftText,
            intent: 'how_to',
          );
          return repo.getDraftById(draftId);
        }();

    if (!mounted) {
      return;
    }

    _hydratingEditor = true;
    _draftId = draft?.id;
    _controller.text = draft?.canonicalMarkdown ?? '';
    _hydratingEditor = false;
    setState(() {
      _loading = false;
      _saveError = null;
    });
  }

  void _onEditorChanged() {
    if (_hydratingEditor || _draftId == null) {
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(draftRepoProvider);
      try {
        await repo.updateCanonicalMarkdown(
          draftId: _draftId!,
          canonicalMarkdown: _controller.text,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _saveError = null;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        setState(() {
          _saveError = 'Failed saving draft: $e';
        });
      }
    });
  }
}
