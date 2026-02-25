import 'package:go_router/go_router.dart';
import 'screens/hub_pages.dart';
import 'screens/hub_shell_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.inbox),
    ),
    GoRoute(
      path: '/inbox',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.inbox),
    ),
    GoRoute(
      path: '/library',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.library),
    ),
    GoRoute(
      path: '/bundles',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.bundles),
    ),
    GoRoute(
      path: '/bundle-checklist',
      builder: (c, s) =>
          const HubShellScreen(currentPage: HubPage.bundleChecklist),
    ),
    GoRoute(
      path: '/publish',
      builder: (c, s) => HubShellScreen(
        currentPage: HubPage.publish,
        initialBundleId: s.uri.queryParameters['bundleId'],
      ),
    ),
    GoRoute(
      path: '/compose',
      builder: (c, s) => HubShellScreen(
        currentPage: HubPage.compose,
        initialDraftId: s.uri.queryParameters['draftId'],
      ),
    ),
    GoRoute(
      path: '/publish-checklist',
      builder: (c, s) => HubShellScreen(
        currentPage: HubPage.publishChecklist,
        initialPublishChecklistDraftId: s.uri.queryParameters['draftId'],
      ),
    ),
    GoRoute(
      path: '/sync-conflicts',
      builder: (c, s) =>
          const HubShellScreen(currentPage: HubPage.syncConflicts),
    ),
    GoRoute(
      path: '/queue',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.queue),
    ),
    GoRoute(
      path: '/analytics',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.analytics),
    ),
    GoRoute(
      path: '/history',
      builder: (c, s) => HubShellScreen(
        currentPage: HubPage.history,
        initialVariantId: s.uri.queryParameters['variantId'],
        initialHistoryPostId: s.uri.queryParameters['postId'],
        initialHistoryPlatform: s.uri.queryParameters['platform'],
        initialHistoryStatus: s.uri.queryParameters['status'],
        initialHistoryMode: s.uri.queryParameters['mode'],
        initialHistoryWindow: s.uri.queryParameters['window'],
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (c, s) => const HubShellScreen(currentPage: HubPage.settings),
    ),
  ],
);
