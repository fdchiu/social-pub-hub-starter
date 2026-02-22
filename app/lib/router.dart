import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/library_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/history_screen.dart';
import 'screens/publish_checklist_screen.dart';
import 'screens/settings_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/inbox', builder: (c, s) => const InboxScreen()),
    GoRoute(path: '/library', builder: (c, s) => const LibraryScreen()),
    GoRoute(path: '/compose', builder: (c, s) => const ComposeScreen()),
    GoRoute(
      path: '/publish-checklist',
      builder: (c, s) => const PublishChecklistScreen(),
    ),
    GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);
