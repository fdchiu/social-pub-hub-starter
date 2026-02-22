import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'repo_utils.dart';

class StyleProfileRepo {
  StyleProfileRepo(this._db);

  final AppDatabase _db;

  Future<StyleProfile> getOrCreateDefault() async {
    final first =
        await (_db.select(_db.styleProfiles)..limit(1)).getSingleOrNull();
    if (first != null) {
      return first;
    }

    final id = generateEntityId();
    final now = DateTime.now().toUtc();
    await _db.into(_db.styleProfiles).insert(
          StyleProfilesCompanion.insert(
            id: id,
            voiceName: const Value('David'),
            casualFormal: const Value(0.6),
            punchiness: const Value(0.7),
            emojiLevel: const Value('light'),
            bannedPhrases: const Value(<String>[
              'delve',
              'unlock',
              'leverage',
              'fast-paced world',
              'game-changer',
            ]),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('dirty'),
          ),
        );

    return (_db.select(_db.styleProfiles)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> updateStyleProfile({
    required String id,
    required String voiceName,
    required double casualFormal,
    required double punchiness,
    required String emojiLevel,
    required List<String> bannedPhrases,
  }) async {
    final normalizedPhrases = bannedPhrases
        .map((phrase) => phrase.trim())
        .where((phrase) => phrase.isNotEmpty)
        .toList(growable: false);

    await (_db.update(_db.styleProfiles)..where((t) => t.id.equals(id))).write(
      StyleProfilesCompanion(
        voiceName: Value(voiceName.trim().isEmpty ? 'David' : voiceName.trim()),
        casualFormal: Value(casualFormal),
        punchiness: Value(punchiness),
        emojiLevel: Value(emojiLevel),
        bannedPhrases: Value(normalizedPhrases),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('dirty'),
      ),
    );
  }
}
