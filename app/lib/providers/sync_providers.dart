import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/sync/sync_service.dart';
import 'db_providers.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://social-pub-hub-backend.onrender.com',
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    client: ref.watch(httpClientProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

class IntegrationStatusItem {
  const IntegrationStatusItem({
    required this.platform,
    required this.connected,
    required this.capabilities,
  });

  final String platform;
  final bool connected;
  final Map<String, dynamic> capabilities;
}

final integrationsProvider =
    FutureProvider<List<IntegrationStatusItem>>((ref) async {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final response = await ref.watch(httpClientProvider).get(
        Uri.parse('$baseUrl/integrations'),
      );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed loading integrations: ${response.statusCode}');
  }
  final parsed = jsonDecode(response.body) as Map<String, dynamic>;
  final raw = parsed['integrations'];
  if (raw is! List) {
    return const <IntegrationStatusItem>[];
  }
  return raw.whereType<Map>().map((row) {
    final item = row.cast<String, dynamic>();
    return IntegrationStatusItem(
      platform: (item['platform'] as String?) ?? 'unknown',
      connected: (item['connected'] as bool?) ?? false,
      capabilities:
          (item['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }).toList(growable: false);
});
