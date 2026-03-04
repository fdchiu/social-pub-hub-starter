import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_db.dart';
import '../providers/repo_providers.dart';

const _bundleQueueIntervalKey = 'bundle_queue.default_interval_minutes';
const _defaultBundleQueueIntervalMinutes = 15;

Future<void> queueBundleFromVariants({
  required BuildContext context,
  required WidgetRef ref,
  required Bundle bundle,
  required Map<String, Variant> variantsById,
}) async {
  final variants = bundle.relatedVariantIds
      .map((id) => variantsById[id])
      .whereType<Variant>()
      .toList(growable: false);
  if (variants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle has no local variants to queue')),
    );
    return;
  }

  final schedule = await _promptBundleQueueSchedule(context);
  if (schedule == null) {
    return;
  }

  final repo = ref.read(scheduledPostRepoProvider);
  for (var index = 0; index < variants.length; index += 1) {
    final variant = variants[index];
    final scheduledFor = schedule.startTime.add(
      Duration(minutes: schedule.intervalMinutes * index),
    );
    await repo.createScheduledPost(
      variantId: variant.id,
      platform: variant.platform,
      content: variant.body,
      scheduledFor: scheduledFor.toUtc(),
    );
  }

  if (!context.mounted) {
    return;
  }
  final intervalLabel = schedule.intervalMinutes == 0
      ? 'same time'
      : '${schedule.intervalMinutes} min apart';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content:
          Text('Queued ${variants.length} bundle variants ($intervalLabel)'),
      action: SnackBarAction(
        label: 'Open queue',
        onPressed: () => context.go('/queue'),
      ),
    ),
  );
}

class _BundleQueueSchedule {
  const _BundleQueueSchedule({
    required this.startTime,
    required this.intervalMinutes,
  });

  final DateTime startTime;
  final int intervalMinutes;
}

Future<_BundleQueueSchedule?> _promptBundleQueueSchedule(
  BuildContext context,
) async {
  final startTime = await _pickBundleStartTime(context);
  if (startTime == null || !context.mounted) {
    return null;
  }

  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) {
    return null;
  }
  final storedInterval = prefs.getInt(_bundleQueueIntervalKey);
  final controller = TextEditingController(
    text: '${storedInterval ?? _defaultBundleQueueIntervalMinutes}',
  );

  final intervalMinutes = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Bundle queue spacing'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start: ${_formatLocalDateTime(startTime)}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Default minutes between items',
                hintText: '0 queues all items at the same time',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved as the default for future bundle queue actions.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = int.tryParse(controller.text.trim());
            if (parsed == null || parsed < 0) {
              return;
            }
            Navigator.of(dialogContext).pop(parsed);
          },
          child: const Text('Queue bundle'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (intervalMinutes == null) {
    return null;
  }
  await prefs.setInt(_bundleQueueIntervalKey, intervalMinutes);
  return _BundleQueueSchedule(
    startTime: startTime,
    intervalMinutes: intervalMinutes,
  );
}

Future<DateTime?> _pickBundleStartTime(BuildContext context) async {
  final now = DateTime.now();
  final defaultTime = now.add(const Duration(hours: 1));
  final date = await showDatePicker(
    context: context,
    initialDate: defaultTime,
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) {
    return null;
  }
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(defaultTime),
  );
  if (time == null) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _formatLocalDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
          ? value.hour - 12
          : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute $suffix';
}
