import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/repo_providers.dart';

Future<void> queueVariantFromCompose({
  required BuildContext context,
  required WidgetRef ref,
  required String variantId,
  required String platform,
  required String body,
}) async {
  final scheduledFor = await _pickScheduledTime(context);
  if (scheduledFor == null) {
    return;
  }

  await ref.read(scheduledPostRepoProvider).createScheduledPost(
        variantId: variantId,
        platform: platform,
        content: body,
        scheduledFor: scheduledFor.toUtc(),
      );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Queued variant'),
      action: SnackBarAction(
        label: 'Open queue',
        onPressed: () => context.go('/queue'),
      ),
    ),
  );
}

Future<DateTime?> _pickScheduledTime(BuildContext context) async {
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
