import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_pub_hub/data/db/app_db.dart';
import 'package:social_pub_hub/main.dart';
import 'package:social_pub_hub/providers/post_scope_providers.dart';
import 'package:social_pub_hub/providers/repo_providers.dart';
import 'package:social_pub_hub/providers/sync_providers.dart';

void main() {
  testWidgets('boots app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourceItemsStreamProvider.overrideWith(
            (ref) => Stream.value(const <SourceItem>[]),
          ),
          scopedSourceItemsStreamProvider.overrideWith(
            (ref) => Stream.value(const <SourceItem>[]),
          ),
          postsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Post>[]),
          ),
          scopedPostsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Post>[]),
          ),
          projectsStreamProvider.overrideWith(
            (ref) => Stream.value(const <Project>[]),
          ),
          bundlesStreamProvider.overrideWith(
            (ref) => Stream.value(const <Bundle>[]),
          ),
          scheduledPostsStreamProvider.overrideWith(
            (ref) => Stream.value(const <ScheduledPost>[]),
          ),
          openSyncConflictsStreamProvider.overrideWith(
            (ref) => Stream.value(const <SyncConflict>[]),
          ),
          integrationsProvider.overrideWith(
            (ref) async => const <IntegrationStatusItem>[],
          ),
        ],
        child: const SocialHubApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Social Pub Hub'), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);
  });
}
