import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Social Pub Hub")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => context.go('/inbox'),
            child: const Text("Inbox"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/library'),
            child: const Text("Library"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/compose'),
            child: const Text("Compose"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/bundles'),
            child: const Text("Bundles"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/bundle-checklist'),
            child: const Text("Bundle Checklist"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/publish'),
            child: const Text("Publish"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/publish-checklist'),
            child: const Text("Publish Checklist"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/sync-conflicts'),
            child: const Text("Sync Conflicts"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/history'),
            child: const Text("History"),
          ),
          ElevatedButton(
            onPressed: () => context.go('/settings'),
            child: const Text("Settings"),
          ),
        ],
      ),
    );
  }
}
