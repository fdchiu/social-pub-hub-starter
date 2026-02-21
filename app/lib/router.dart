import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/settings_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/inbox', builder: (c, s) => const InboxScreen()),
    GoRoute(path: '/compose', builder: (c, s) => const ComposeScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);
