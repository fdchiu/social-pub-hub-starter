import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_db.dart';

class SyncSummary {
  const SyncSummary({
    required this.cursor,
    required this.pushedDrafts,
    required this.pushedVariants,
    required this.pushedPublishLogs,
    required this.pushedStyleProfiles,
    required this.pulledDrafts,
    required this.pulledVariants,
    required this.pulledPublishLogs,
    required this.pulledStyleProfiles,
    required this.deletedDrafts,
    required this.deletedVariants,
    required this.deletedPublishLogs,
    required this.deletedStyleProfiles,
  });

  final int cursor;
  final int pushedDrafts;
  final int pushedVariants;
  final int pushedPublishLogs;
  final int pushedStyleProfiles;
  final int pulledDrafts;
  final int pulledVariants;
  final int pulledPublishLogs;
  final int pulledStyleProfiles;
  final int deletedDrafts;
  final int deletedVariants;
  final int deletedPublishLogs;
  final int deletedStyleProfiles;
}

class SyncService {
  SyncService({
    required AppDatabase db,
    required http.Client client,
    required String baseUrl,
  })  : _db = db,
        _client = client,
        _baseUrl = baseUrl;

  static const String _cursorKey = 'sync.cursor';

  final AppDatabase _db;
  final http.Client _client;
  final String _baseUrl;

  Future<SyncSummary> syncNow() async {
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt(_cursorKey) ?? 0;
    final pushPayload = await _buildPushPayload();

    final pushResponse = await _client.post(
      Uri.parse('$_baseUrl/sync/push'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(pushPayload),
    );
    if (pushResponse.statusCode < 200 || pushResponse.statusCode >= 300) {
      throw Exception('Sync push failed: ${pushResponse.statusCode}');
    }

    final pushBody = jsonDecode(pushResponse.body) as Map<String, dynamic>;
    final pushCursor = (pushBody['cursor'] as num?)?.toInt() ?? since;

    final changesResponse = await _client.get(
      Uri.parse('$_baseUrl/sync/changes?since=$since'),
    );
    if (changesResponse.statusCode < 200 || changesResponse.statusCode >= 300) {
      throw Exception('Sync pull failed: ${changesResponse.statusCode}');
    }

    final changes = jsonDecode(changesResponse.body) as Map<String, dynamic>;
    final pullCursor = (changes['cursor'] as num?)?.toInt() ?? since;

    final upserts = (changes['upserts'] as Map<String, dynamic>? ?? const {});
    final deletes = (changes['deletes'] as Map<String, dynamic>? ?? const {});

    final pulledDrafts = _asMapList(upserts['drafts']);
    final pulledVariants = _asMapList(upserts['variants']);
    final pulledPublishLogs = _asMapList(upserts['publish_logs']);
    final pulledStyleProfiles = _asMapList(upserts['style_profiles']);

    final deletedDrafts = _asStringList(deletes['drafts']);
    final deletedVariants = _asStringList(deletes['variants']);
    final deletedPublishLogs = _asStringList(deletes['publish_logs']);
    final deletedStyleProfiles = _asStringList(deletes['style_profiles']);

    await _db.transaction(() async {
      await _applyDraftUpserts(pulledDrafts);
      await _applyVariantUpserts(pulledVariants);
      await _applyPublishLogUpserts(pulledPublishLogs);
      await _applyStyleProfileUpserts(pulledStyleProfiles);
      await _applyDeletes(
        deletedDrafts: deletedDrafts,
        deletedVariants: deletedVariants,
        deletedPublishLogs: deletedPublishLogs,
        deletedStyleProfiles: deletedStyleProfiles,
      );
    });

    final nextCursor = max(pushCursor, pullCursor);
    await prefs.setInt(_cursorKey, nextCursor);

    final pushUpserts = pushPayload['upserts'] as Map<String, dynamic>;
    return SyncSummary(
      cursor: nextCursor,
      pushedDrafts: _asMapList(pushUpserts['drafts']).length,
      pushedVariants: _asMapList(pushUpserts['variants']).length,
      pushedPublishLogs: _asMapList(pushUpserts['publish_logs']).length,
      pushedStyleProfiles: _asMapList(pushUpserts['style_profiles']).length,
      pulledDrafts: pulledDrafts.length,
      pulledVariants: pulledVariants.length,
      pulledPublishLogs: pulledPublishLogs.length,
      pulledStyleProfiles: pulledStyleProfiles.length,
      deletedDrafts: deletedDrafts.length,
      deletedVariants: deletedVariants.length,
      deletedPublishLogs: deletedPublishLogs.length,
      deletedStyleProfiles: deletedStyleProfiles.length,
    );
  }

  Future<Map<String, dynamic>> _buildPushPayload() async {
    final drafts = await _db.select(_db.drafts).get();
    final variants = await _db.select(_db.variants).get();
    final publishLogs = await _db.select(_db.publishLogs).get();
    final styleProfiles = await _db.select(_db.styleProfiles).get();

    return {
      'upserts': {
        'drafts': drafts
            .map(
              (row) => {
                'id': row.id,
                'canonical_markdown': row.canonicalMarkdown,
                'intent': row.intent,
                'tone': row.tone,
                'punchiness': row.punchiness,
                'emoji_level': row.emojiLevel,
                'audience': row.audience,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'variants': variants
            .map(
              (row) => {
                'id': row.id,
                'draft_id': row.draftId,
                'platform': row.platform,
                'text': row.body,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
        'publish_logs': publishLogs
            .map(
              (row) => {
                'id': row.id,
                'variant_id': row.variantId,
                'platform': row.platform,
                'mode': row.mode,
                'status': row.status,
                'external_url': row.externalUrl,
                'posted_at': row.postedAt?.toIso8601String(),
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'style_profiles': styleProfiles
            .map(
              (row) => {
                'id': row.id,
                'voice_name': row.voiceName,
                'casual_formal': row.casualFormal,
                'punchiness': row.punchiness,
                'emoji_level': row.emojiLevel,
                'banned_phrases': row.bannedPhrases,
                'created_at': row.createdAt.toIso8601String(),
                'updated_at': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      },
      'deletes': {
        'drafts': const <String>[],
        'variants': const <String>[],
        'publish_logs': const <String>[],
        'style_profiles': const <String>[],
      },
    };
  }

  Future<void> _applyDraftUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      await _db.into(_db.drafts).insertOnConflictUpdate(
            DraftsCompanion(
              id: Value(id),
              canonicalMarkdown:
                  Value((row['canonical_markdown'] as String?) ?? ''),
              intent: Value(row['intent'] as String?),
              tone: Value(_asDouble(row['tone'])),
              punchiness: Value(_asDouble(row['punchiness'])),
              emojiLevel: Value(row['emoji_level'] as String?),
              audience: Value(row['audience'] as String?),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(_asDateTime(row['updated_at']) ?? now),
            ),
          );
    }
  }

  Future<void> _applyVariantUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      final draftId = row['draft_id'] as String?;
      if (id == null || id.isEmpty || draftId == null || draftId.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      await _db.into(_db.variants).insertOnConflictUpdate(
            VariantsCompanion(
              id: Value(id),
              draftId: Value(draftId),
              platform: Value((row['platform'] as String?) ?? ''),
              body: Value((row['text'] as String?) ?? ''),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(_asDateTime(row['updated_at']) ?? now),
            ),
          );
    }
  }

  Future<void> _applyPublishLogUpserts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      await _db.into(_db.publishLogs).insertOnConflictUpdate(
            PublishLogsCompanion(
              id: Value(id),
              variantId: Value(row['variant_id'] as String?),
              platform: Value((row['platform'] as String?) ?? ''),
              mode: Value((row['mode'] as String?) ?? 'assisted'),
              status: Value((row['status'] as String?) ?? 'draft'),
              externalUrl: Value(row['external_url'] as String?),
              postedAt: Value(_asDateTime(row['posted_at'])),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
            ),
          );
    }
  }

  Future<void> _applyStyleProfileUpserts(
      List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc();
      await _db.into(_db.styleProfiles).insertOnConflictUpdate(
            StyleProfilesCompanion(
              id: Value(id),
              voiceName: Value((row['voice_name'] as String?) ?? 'David'),
              casualFormal: Value(_asDouble(row['casual_formal']) ?? 0.6),
              punchiness: Value(_asDouble(row['punchiness']) ?? 0.7),
              emojiLevel: Value((row['emoji_level'] as String?) ?? 'light'),
              bannedPhrases: Value(_asStringList(row['banned_phrases'])),
              createdAt: Value(_asDateTime(row['created_at']) ?? now),
              updatedAt: Value(_asDateTime(row['updated_at']) ?? now),
            ),
          );
    }
  }

  Future<void> _applyDeletes({
    required List<String> deletedDrafts,
    required List<String> deletedVariants,
    required List<String> deletedPublishLogs,
    required List<String> deletedStyleProfiles,
  }) async {
    if (deletedPublishLogs.isNotEmpty) {
      await (_db.delete(_db.publishLogs)
            ..where((t) => t.id.isIn(deletedPublishLogs)))
          .go();
    }

    if (deletedVariants.isNotEmpty) {
      await (_db.update(_db.publishLogs)
            ..where((t) => t.variantId.isIn(deletedVariants)))
          .write(const PublishLogsCompanion(variantId: Value(null)));
      await (_db.delete(_db.variants)..where((t) => t.id.isIn(deletedVariants)))
          .go();
    }

    if (deletedDrafts.isNotEmpty) {
      final linkedVariants = await (_db.select(_db.variants)
            ..where((t) => t.draftId.isIn(deletedDrafts)))
          .get();
      final linkedVariantIds = linkedVariants.map((v) => v.id).toList();
      if (linkedVariantIds.isNotEmpty) {
        await (_db.update(_db.publishLogs)
              ..where((t) => t.variantId.isIn(linkedVariantIds)))
            .write(const PublishLogsCompanion(variantId: Value(null)));
        await (_db.delete(_db.variants)
              ..where((t) => t.id.isIn(linkedVariantIds)))
            .go();
      }
      await (_db.delete(_db.drafts)..where((t) => t.id.isIn(deletedDrafts)))
          .go();
    }

    if (deletedStyleProfiles.isNotEmpty) {
      await (_db.delete(_db.styleProfiles)
            ..where((t) => t.id.isIn(deletedStyleProfiles)))
          .go();
    }
  }

  List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
