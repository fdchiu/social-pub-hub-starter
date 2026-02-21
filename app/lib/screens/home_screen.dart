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
            onPressed: () => context.go('/compose'),
            child: const Text("Compose"),
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
