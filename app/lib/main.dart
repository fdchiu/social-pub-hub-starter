import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: SocialHubApp()));
}

class SocialHubApp extends StatelessWidget {
  const SocialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E90FA);
    return MaterialApp.router(
      title: 'Social Pub Hub',
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0F14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0F14),
          foregroundColor: Color(0xFFEDF0F7),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1F2130),
          elevation: 0,
        ),
      ),
    );
  }
}
