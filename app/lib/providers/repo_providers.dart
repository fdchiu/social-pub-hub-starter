import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_db.dart';
import '../data/repos/draft_repo.dart';
import '../data/repos/bundle_repo.dart';
import '../data/repos/publish_log_repo.dart';
import '../data/repos/source_repo.dart';
import '../data/repos/style_profile_repo.dart';
import '../data/repos/sync_conflict_repo.dart';
import '../data/repos/variant_repo.dart';
import 'db_providers.dart';

final sourceRepoProvider = Provider<SourceRepo>((ref) {
  return SourceRepo(ref.watch(appDatabaseProvider));
});

final draftRepoProvider = Provider<DraftRepo>((ref) {
  return DraftRepo(ref.watch(appDatabaseProvider));
});

final bundleRepoProvider = Provider<BundleRepo>((ref) {
  return BundleRepo(ref.watch(appDatabaseProvider));
});

final variantRepoProvider = Provider<VariantRepo>((ref) {
  return VariantRepo(ref.watch(appDatabaseProvider));
});

final publishLogRepoProvider = Provider<PublishLogRepo>((ref) {
  return PublishLogRepo(ref.watch(appDatabaseProvider));
});

final styleProfileRepoProvider = Provider<StyleProfileRepo>((ref) {
  return StyleProfileRepo(ref.watch(appDatabaseProvider));
});

final syncConflictRepoProvider = Provider<SyncConflictRepo>((ref) {
  return SyncConflictRepo(ref.watch(appDatabaseProvider));
});

final sourceItemsStreamProvider = StreamProvider<List<SourceItem>>((ref) {
  return ref.watch(sourceRepoProvider).watchSourceItems();
});

final publishLogsStreamProvider = StreamProvider<List<PublishLog>>((ref) {
  return ref.watch(publishLogRepoProvider).watchPublishLogs();
});

final draftVariantsStreamProvider =
    StreamProvider.family<List<Variant>, String>((ref, draftId) {
  return ref.watch(variantRepoProvider).watchVariantsForDraft(draftId);
});

final allVariantsStreamProvider = StreamProvider<List<Variant>>((ref) {
  return ref.watch(variantRepoProvider).watchAllVariants();
});

final bundlesStreamProvider = StreamProvider<List<Bundle>>((ref) {
  return ref.watch(bundleRepoProvider).watchBundles();
});

final openSyncConflictsStreamProvider =
    StreamProvider<List<SyncConflict>>((ref) {
  return ref.watch(syncConflictRepoProvider).watchOpenConflicts();
});
