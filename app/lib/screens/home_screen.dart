import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_MenuEntry> _menuEntries = <_MenuEntry>[
    _MenuEntry(
      title: 'Inbox',
      subtitle: 'Capture source items and create a draft from selected items.',
      route: '/inbox',
    ),
    _MenuEntry(
      title: 'Library',
      subtitle:
          'Search/filter saved sources, create draft, and assign bundles.',
      route: '/library',
    ),
    _MenuEntry(
      title: 'Compose',
      subtitle:
          'Edit draft, polish with LLM, generate/humanize variants, publish.',
      route: '/compose',
    ),
    _MenuEntry(
      title: 'Bundles',
      subtitle: 'Create bundle plans with anchors and related variants.',
      route: '/bundles',
    ),
    _MenuEntry(
      title: 'Bundle Checklist',
      subtitle: 'Validate bundle readiness and backfill missing pieces.',
      route: '/bundle-checklist',
    ),
    _MenuEntry(
      title: 'Publish',
      subtitle: 'View integration status and recent publish logs by bundle.',
      route: '/publish',
    ),
    _MenuEntry(
      title: 'Publish Checklist',
      subtitle: 'Run human-sounding rubric checks before posting.',
      route: '/publish-checklist',
    ),
    _MenuEntry(
      title: 'Queue',
      subtitle: 'Manage scheduled posts: filter, open composer, mark posted.',
      route: '/queue',
    ),
    _MenuEntry(
      title: 'Sync Conflicts',
      subtitle: 'Resolve sync collisions by choosing local or remote.',
      route: '/sync-conflicts',
    ),
    _MenuEntry(
      title: 'History',
      subtitle:
          'Review publish timeline, filter logs, clone variants into draft.',
      route: '/history',
    ),
    _MenuEntry(
      title: 'Analytics',
      subtitle: 'See posted totals, queue health, and platform breakdown.',
      route: '/analytics',
    ),
    _MenuEntry(
      title: 'Settings',
      subtitle: 'Run sync, edit style profile, and inspect integrations.',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFFD0D5DD);
    const textColor = Color(0xFF101828);
    const mutedColor = Color(0xFF475467);
    const brandColor = Color(0xFF2E90FA);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFEEF4FF), Color(0xFFF3F5F8)],
            stops: <double>[0, 0.35],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: lineColor),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.08),
                        blurRadius: 36,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const _HomeAppBar(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          children: [
                            const Text(
                              'Navigation menu',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Each menu item opens a focused workflow.',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final entry in _menuEntries) ...[
                              _MenuCard(entry: entry),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 4),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: brandColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => context.go('/compose'),
                              child: const Text(
                                'Quick start: Compose',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _DashedDivider(color: lineColor),
                            const SizedBox(height: 14),
                            const Text(
                              'Static layout snapshot for design handoff. Current app behavior: tapping a card navigates to the route above.',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFFD0D5DD);
    const textColor = Color(0xFF101828);
    const mutedColor = Color(0xFF475467);

    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: lineColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: lineColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 18,
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Social Pub Hub',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFFD0D5DD);
    const textColor = Color(0xFF101828);
    const mutedColor = Color(0xFF475467);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lineColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(entry.route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Route: ',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: entry.route,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '›',
                  style: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedDividerPainter(color: color),
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const gapWidth = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dashWidth, size.width), 0),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String route;
}
