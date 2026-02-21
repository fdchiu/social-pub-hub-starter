
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
    return MaterialApp.router(
      title: 'Social Pub Hub',
      routerConfig: router,
      theme: ThemeData.dark(),
    );
  }
}
