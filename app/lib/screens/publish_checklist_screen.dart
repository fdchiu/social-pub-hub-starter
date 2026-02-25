import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/db/app_db.dart';
import '../providers/post_scope_providers.dart';
import '../providers/repo_providers.dart';
import '../widgets/hub_app_bar.dart';
import '../widgets/post_scope_header.dart';

class PublishChecklistScreen extends ConsumerStatefulWidget {
  const PublishChecklistScreen({
    super.key,
    this.initialDraftId,
  });

  final String? initialDraftId;

  @override
  ConsumerState<PublishChecklistScreen> createState() =>
      _PublishChecklistScreenState();
}

class _PublishChecklistScreenState
    extends ConsumerState<PublishChecklistScreen> {
  String? _selectedDraftId;
  late final Future<StyleProfile> _styleProfileFuture;
  bool _includeAllPosts = false;

  @override
  void initState() {
    super.initState();
    final initialDraftId = widget.initialDraftId?.trim();
    if (initialDraftId != null && initialDraftId.isNotEmpty) {
      _selectedDraftId = initialDraftId;
    }
    _styleProfileFuture =
        ref.read(styleProfileRepoProvider).getOrCreateDefault();
  }

  @override
  Widget build(BuildContext context) {
    final activePost = ref.watch(activePostProvider);
    final draftsAsync = _includeAllPosts
        ? ref.watch(allDraftsStreamProvider)
        : ref.watch(scopedDraftsStreamProvider);

    return Scaffold(
      appBar: buildHubAppBar(
        context: context,
        title: 'Publish checklist',
      ),
      body: draftsAsync.when(
        data: (drafts) {
          if (drafts.isEmpty) {
            return ListView(
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
                    'Show drafts from all posts instead of only active post',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Text(
                  _includeAllPosts
                      ? 'No draft found. Create one first.'
                      : 'No drafts found for active post scope.',
                ),
              ],
            );
          }

          final selectedDraft = _resolveSelectedDraft(drafts);
          final draftId = selectedDraft.id;
          final selectedValue = _selectedDraftId == null
              ? draftId
              : (drafts.any((row) => row.id == _selectedDraftId)
                  ? _selectedDraftId!
                  : draftId);

          return FutureBuilder<StyleProfile>(
            future: _styleProfileFuture,
            builder: (context, styleSnapshot) {
              if (styleSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (styleSnapshot.hasError) {
                return Center(
                  child: Text(
                      'Failed loading style profile: ${styleSnapshot.error}'),
                );
              }
              final styleProfile = styleSnapshot.data;
              final checks = _evaluateDraft(
                markdown: selectedDraft.canonicalMarkdown,
                bannedPhrases: styleProfile?.bannedPhrases ?? const <String>[],
                contentType: selectedDraft.contentType ??
                    activePost?.contentType ??
                    'general_post',
              );
              final passedChecks = checks.where((row) => row.passed).length;

              return ListView(
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
                      'Show drafts from all posts instead of only active post',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'Draft',
                      border: OutlineInputBorder(),
                    ),
                    items: drafts
                        .map(
                          (row) => DropdownMenuItem<String>(
                            value: row.id,
                            child: Text(_draftLabel(row)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedDraftId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Draft: ${selectedDraft.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (selectedDraft.postId != null ||
                      (!_includeAllPosts && activePost != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Post: ${selectedDraft.postId ?? activePost!.id}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Intent: ${selectedDraft.intent ?? 'n/a'}  •  Audience: ${selectedDraft.audience ?? 'n/a'}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Content type: ${selectedDraft.contentType ?? activePost?.contentType ?? 'general_post'}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: $passedChecks/${checks.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          final encoded = Uri.encodeQueryComponent(draftId);
                          context.go('/compose?draftId=$encoded');
                        },
                        child: const Text('Open in compose'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _copyChecklistReport(
                          draft: selectedDraft,
                          checks: checks,
                          passedChecks: passedChecks,
                        ),
                        child: const Text('Copy report'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _copyRevisionPrompt(
                          draft: selectedDraft,
                          checks: checks,
                          styleProfile: styleProfile,
                        ),
                        child: const Text('Copy revision prompt'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Human-sounding rubric',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final check in checks)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          check.passed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: check.passed ? Colors.green : Colors.orange,
                        ),
                        title: Text(check.label),
                        subtitle: Text(check.detail),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Assisted publish flow',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Copy variant text'),
                      subtitle: Text('Use Compose → variant actions'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Open platform composer'),
                      subtitle: Text('Use Compose → open composer button'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Confirm posted and log URL'),
                      subtitle: Text('Use Compose → confirm posted'),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading drafts: $error')),
      ),
    );
  }

  Draft _resolveSelectedDraft(List<Draft> drafts) {
    final selectedDraftId = _selectedDraftId;
    if (selectedDraftId != null) {
      for (final draft in drafts) {
        if (draft.id == selectedDraftId) {
          return draft;
        }
      }
    }
    return drafts.first;
  }

  String _draftLabel(Draft draft) {
    final snippet = draft.canonicalMarkdown
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final shortSnippet = snippet.isEmpty
        ? '(empty)'
        : (snippet.length > 64 ? '${snippet.substring(0, 64)}...' : snippet);
    return '${draft.id.substring(0, 8)}  $shortSnippet';
  }

  List<_ChecklistResult> _evaluateDraft({
    required String markdown,
    required List<String> bannedPhrases,
    required String contentType,
  }) {
    final text = markdown.trim();
    final lowerText = text.toLowerCase();
    final normalizedType = contentType.trim().toLowerCase();
    final lines =
        text.split('\n').map((line) => line.trim()).where((l) => l.isNotEmpty);
    final firstLine = lines.isEmpty ? '' : lines.first;
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentenceCount = text.split(RegExp(r'[.!?]+')).where((s) {
      return s.trim().isNotEmpty;
    }).length;
    final avgWordsPerSentence = sentenceCount == 0
        ? words.length.toDouble()
        : words.length / sentenceCount;

    final hasHook = firstLine.length >= 20;
    final shortSentences = avgWordsPerSentence <= 18;
    final hasSpecificDetail = RegExp(r'\b\d+\b').hasMatch(text) ||
        lowerText.contains('tradeoff') ||
        lowerText.contains('constraint');
    final hasStance = RegExp(r'\b(i|my|we)\b', caseSensitive: false).hasMatch(
      text,
    );
    final hasQuestion = text.contains('?');
    final hasNumberedSteps =
        RegExp(r'^\s*\d+[.)\s]', multiLine: true).hasMatch(text);
    final hasBulletSteps =
        RegExp(r'^\s*[-*]\s+', multiLine: true).hasMatch(text);
    final hasCodeFence = text.contains('```');
    final hasPromptLanguage = lowerText.contains('prompt') ||
        lowerText.contains('input') ||
        lowerText.contains('parameter') ||
        lowerText.contains('template');
    final hasRiskLanguage = lowerText.contains('risk') ||
        lowerText.contains('guardrail') ||
        lowerText.contains('failure') ||
        lowerText.contains('cost');
    final hasSetupLanguage = lowerText.contains('setup') ||
        lowerText.contains('prereq') ||
        lowerText.contains('requirement') ||
        lowerText.contains('install');

    final normalizedBanned = bannedPhrases
        .map((phrase) => phrase.trim())
        .where((phrase) => phrase.isNotEmpty)
        .map((phrase) => phrase.toLowerCase())
        .toSet();
    final foundBanned = normalizedBanned
        .where((phrase) => lowerText.contains(phrase))
        .toList(growable: false)
      ..sort();

    final checks = <_ChecklistResult>[
      _ChecklistResult(
        label: 'Hook in first 1-2 lines',
        passed: hasHook,
        detail: hasHook
            ? 'Opening line has enough context.'
            : 'Add a stronger opening line near the top.',
      ),
      _ChecklistResult(
        label: 'Short sentences; avoid filler',
        passed: shortSentences,
        detail: shortSentences
            ? 'Average sentence length looks concise.'
            : 'Shorten sentence length and cut filler words.',
      ),
      _ChecklistResult(
        label: 'One specific detail or tradeoff',
        passed: hasSpecificDetail,
        detail: hasSpecificDetail
            ? 'Detected a concrete detail/tradeoff.'
            : 'Add one number, constraint, or explicit tradeoff.',
      ),
      _ChecklistResult(
        label: 'Personal stance',
        passed: hasStance,
        detail: hasStance
            ? 'Detected first-person stance.'
            : 'Add what you would do again or avoid.',
      ),
      _ChecklistResult(
        label: 'End with question/CTA',
        passed: hasQuestion,
        detail: hasQuestion
            ? 'Question detected.'
            : 'Close with a genuine question or CTA.',
      ),
      _ChecklistResult(
        label: 'No banned phrases',
        passed: foundBanned.isEmpty,
        detail: foundBanned.isEmpty
            ? 'No banned phrases detected.'
            : 'Detected: ${foundBanned.join(', ')}',
      ),
    ];

    if (normalizedType == 'coding_guide') {
      checks.addAll(
        [
          _ChecklistResult(
            label: 'Coding guide: setup/prerequisites',
            passed: hasSetupLanguage,
            detail: hasSetupLanguage
                ? 'Detected setup/prerequisite language.'
                : 'Add setup, install steps, or prerequisites.',
          ),
          _ChecklistResult(
            label: 'Coding guide: actionable steps/code',
            passed: hasNumberedSteps || hasBulletSteps || hasCodeFence,
            detail: hasNumberedSteps || hasBulletSteps || hasCodeFence
                ? 'Detected actionable steps or code block.'
                : 'Add explicit steps and at least one concrete code snippet.',
          ),
        ],
      );
    }

    if (normalizedType == 'ai_tool_guide') {
      checks.addAll(
        [
          _ChecklistResult(
            label: 'AI tool guide: prompt/inputs',
            passed: hasPromptLanguage,
            detail: hasPromptLanguage
                ? 'Detected prompt/input language.'
                : 'Add prompt template, key inputs, or parameters.',
          ),
          _ChecklistResult(
            label: 'AI tool guide: guardrails/cost/failure modes',
            passed: hasRiskLanguage,
            detail: hasRiskLanguage
                ? 'Detected guardrail/risk language.'
                : 'Add cost, guardrails, and likely failure modes.',
          ),
        ],
      );
    }

    return checks;
  }

  Future<void> _copyChecklistReport({
    required Draft draft,
    required List<_ChecklistResult> checks,
    required int passedChecks,
  }) async {
    final failedChecks =
        checks.where((row) => !row.passed).toList(growable: false);
    final payload = <String, dynamic>{
      'draft_id': draft.id,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'score': {'passed': passedChecks, 'total': checks.length},
      'intent': draft.intent,
      'audience': draft.audience,
      'content_type': draft.contentType ?? 'general_post',
      'failed_checks': failedChecks
          .map((row) => {'label': row.label, 'detail': row.detail})
          .toList(growable: false),
      'checks': checks
          .map(
            (row) => {
              'label': row.label,
              'passed': row.passed,
              'detail': row.detail,
            },
          )
          .toList(growable: false),
    };

    final summary = StringBuffer()
      ..writeln('Publish Checklist Report')
      ..writeln('draft=${draft.id}')
      ..writeln('score=$passedChecks/${checks.length}')
      ..writeln(
          'intent=${draft.intent ?? 'n/a'} audience=${draft.audience ?? 'n/a'}')
      ..writeln('content_type=${draft.contentType ?? 'general_post'}')
      ..writeln('generated_at=${DateTime.now().toUtc().toIso8601String()}')
      ..writeln()
      ..writeln('failed_checks=${failedChecks.length}');
    for (final row in failedChecks) {
      summary.writeln('- ${row.label}: ${row.detail}');
    }
    summary
      ..writeln()
      ..writeln('json:')
      ..writeln(const JsonEncoder.withIndent('  ').convert(payload));

    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checklist report copied')),
    );
  }

  Future<void> _copyRevisionPrompt({
    required Draft draft,
    required List<_ChecklistResult> checks,
    required StyleProfile? styleProfile,
  }) async {
    final failedChecks =
        checks.where((row) => !row.passed).toList(growable: false);
    final banned = styleProfile?.bannedPhrases ?? const <String>[];
    final bannedText = banned.isEmpty ? '(none)' : banned.join(', ');
    final intent = draft.intent?.trim().isEmpty ?? true ? 'n/a' : draft.intent!;
    final audience =
        draft.audience?.trim().isEmpty ?? true ? 'n/a' : draft.audience!;
    final contentType = draft.contentType ?? 'general_post';
    final voice = styleProfile?.voiceName.trim().isEmpty ?? true
        ? 'default'
        : styleProfile!.voiceName;

    final prompt = StringBuffer()
      ..writeln('Rewrite this draft to pass a publish checklist.')
      ..writeln('Keep claims accurate. Keep original meaning.')
      ..writeln('style_voice=$voice')
      ..writeln('intent=$intent audience=$audience')
      ..writeln('content_type=$contentType')
      ..writeln('banned_phrases=$bannedText')
      ..writeln()
      ..writeln('failed_checks=${failedChecks.length}');
    if (failedChecks.isEmpty) {
      prompt.writeln('- No failed checks. Tighten language only.');
    } else {
      for (final row in failedChecks) {
        prompt.writeln('- ${row.label}: ${row.detail}');
      }
    }
    prompt
      ..writeln()
      ..writeln('return_format:')
      ..writeln('1) revised_markdown')
      ..writeln('2) checklist_fix_summary (one line per failed check)')
      ..writeln()
      ..writeln('draft_markdown:')
      ..writeln(_clipDraft(draft.canonicalMarkdown));

    await Clipboard.setData(ClipboardData(text: prompt.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedChecks.isEmpty
              ? 'Revision prompt copied (no failed checks)'
              : 'Revision prompt copied (${failedChecks.length} failed checks)',
        ),
      ),
    );
  }

  String _clipDraft(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 4000) {
      return trimmed;
    }
    return '${trimmed.substring(0, 4000)}\n...[truncated]';
  }
}

class _ChecklistResult {
  const _ChecklistResult({
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String label;
  final bool passed;
  final String detail;
}
