import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';

class PublishChecklistScreen extends ConsumerWidget {
  const PublishChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish checklist')),
      body: FutureBuilder<Draft?>(
        future: ref.read(draftRepoProvider).getLatestDraft(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed loading draft: ${snapshot.error}'));
          }

          final draft = snapshot.data;
          if (draft == null) {
            return const Center(
                child: Text('No draft found. Create one first.'));
          }

          final checks = _evaluateDraft(draft.canonicalMarkdown);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Latest draft: ${draft.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Intent: ${draft.intent ?? 'n/a'}  •  Audience: ${draft.audience ?? 'n/a'}',
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
                      check.passed ? Icons.check_circle : Icons.error_outline,
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
      ),
    );
  }

  List<_ChecklistResult> _evaluateDraft(String markdown) {
    final text = markdown.trim();
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
        text.toLowerCase().contains('tradeoff') ||
        text.toLowerCase().contains('constraint');
    final hasStance =
        RegExp(r'\b(i|my|we)\b', caseSensitive: false).hasMatch(text);
    final hasQuestion = text.contains('?');

    return [
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
    ];
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
