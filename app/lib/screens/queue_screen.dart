import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';
import '../utils/composer_links.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(scheduledPostsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Queue'),
        actions: [
          IconButton(
            tooltip: 'Open compose',
            onPressed: () => context.go('/compose'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child:
                  Text('No scheduled posts yet. Queue from Compose variants.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ScheduledPostCard(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed loading queue: $error')),
      ),
    );
  }
}

class _ScheduledPostCard extends ConsumerWidget {
  const _ScheduledPostCard({required this.item});

  final ScheduledPost item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQueued = item.status == 'queued';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.platform.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                _StatusPill(status: item.status),
                const Spacer(),
                Text(
                  _formatDateTime(item.scheduledFor.toLocal()),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _copy(context),
                  child: const Text('Copy'),
                ),
                FilledButton.tonal(
                  onPressed: () => _openComposer(context),
                  child: const Text('Open composer'),
                ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _markPosted(context, ref),
                    child: const Text('Mark posted'),
                  ),
                if (isQueued)
                  FilledButton.tonal(
                    onPressed: () => _cancel(context, ref),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied queued text')),
      );
    }
  }

  Future<void> _openComposer(BuildContext context) async {
    final uri =
        composerUriForPlatform(platform: item.platform, text: item.content);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No composer URL configured for ${item.platform}')),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open composer for ${item.platform}')),
      );
    }
  }

  Future<void> _markPosted(BuildContext context, WidgetRef ref) async {
    await ref.read(scheduledPostRepoProvider).markPosted(
          scheduledPostId: item.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item marked posted')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await ref.read(scheduledPostRepoProvider).markCanceled(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue item canceled')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day ${value.year} $hour:$minute';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'posted' => (Colors.green.shade900, Colors.green.shade100),
      'canceled' => (Colors.grey.shade800, Colors.grey.shade200),
      _ => (Colors.orange.shade900, Colors.orange.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
