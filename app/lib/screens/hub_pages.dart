import 'package:flutter/material.dart';

enum HubPage {
  inbox,
  library,
  compose,
  bundles,
  bundleChecklist,
  publish,
  publishChecklist,
  queue,
  syncConflicts,
  history,
  analytics,
  settings,
}

extension HubPageX on HubPage {
  String get route => switch (this) {
        HubPage.inbox => '/inbox',
        HubPage.library => '/library',
        HubPage.compose => '/compose',
        HubPage.bundles => '/bundles',
        HubPage.bundleChecklist => '/bundle-checklist',
        HubPage.publish => '/publish',
        HubPage.publishChecklist => '/publish-checklist',
        HubPage.queue => '/queue',
        HubPage.syncConflicts => '/sync-conflicts',
        HubPage.history => '/history',
        HubPage.analytics => '/analytics',
        HubPage.settings => '/settings',
      };

  String get title => switch (this) {
        HubPage.inbox => 'Inbox',
        HubPage.library => 'Library',
        HubPage.compose => 'Compose',
        HubPage.bundles => 'Bundles',
        HubPage.bundleChecklist => 'Bundle Checklist',
        HubPage.publish => 'Publish',
        HubPage.publishChecklist => 'Publish Checklist',
        HubPage.queue => 'Queue',
        HubPage.syncConflicts => 'Sync Conflicts',
        HubPage.history => 'History',
        HubPage.analytics => 'Analytics',
        HubPage.settings => 'Settings',
      };
}

enum HubBadgeTone { red, green, amber, muted }

class HubNavItem {
  const HubNavItem({
    required this.section,
    required this.label,
    required this.icon,
    required this.page,
    this.badge,
    this.badgeTone,
  });

  final String section;
  final String label;
  final String icon;
  final HubPage page;
  final String? badge;
  final HubBadgeTone? badgeTone;
}

const hubNavItems = <HubNavItem>[
  HubNavItem(
    section: 'Capture',
    label: 'Inbox',
    icon: '📥',
    page: HubPage.inbox,
    badge: '3',
    badgeTone: HubBadgeTone.red,
  ),
  HubNavItem(
    section: 'Capture',
    label: 'Library',
    icon: '🗂',
    page: HubPage.library,
    badge: '48',
    badgeTone: HubBadgeTone.muted,
  ),
  HubNavItem(
    section: 'Create',
    label: 'Compose',
    icon: '✏️',
    page: HubPage.compose,
  ),
  HubNavItem(
    section: 'Create',
    label: 'Bundles',
    icon: '📦',
    page: HubPage.bundles,
    badge: '2',
    badgeTone: HubBadgeTone.amber,
  ),
  HubNavItem(
    section: 'Create',
    label: 'Bundle Checklist',
    icon: '✅',
    page: HubPage.bundleChecklist,
  ),
  HubNavItem(
    section: 'Publish',
    label: 'Publish',
    icon: '🚀',
    page: HubPage.publish,
    badge: 'On',
    badgeTone: HubBadgeTone.green,
  ),
  HubNavItem(
    section: 'Publish',
    label: 'Pub Checklist',
    icon: '📋',
    page: HubPage.publishChecklist,
  ),
  HubNavItem(
    section: 'Publish',
    label: 'Queue',
    icon: '🕐',
    page: HubPage.queue,
    badge: '7',
    badgeTone: HubBadgeTone.red,
  ),
  HubNavItem(
    section: 'Monitor',
    label: 'Sync Conflicts',
    icon: '⚡',
    page: HubPage.syncConflicts,
    badge: '1',
    badgeTone: HubBadgeTone.red,
  ),
  HubNavItem(
    section: 'Monitor',
    label: 'History',
    icon: '🕓',
    page: HubPage.history,
  ),
  HubNavItem(
    section: 'Monitor',
    label: 'Analytics',
    icon: '📊',
    page: HubPage.analytics,
  ),
  HubNavItem(
    section: 'Monitor',
    label: 'Settings',
    icon: '⚙️',
    page: HubPage.settings,
  ),
];

Color badgeColor(HubBadgeTone tone) {
  return switch (tone) {
    HubBadgeTone.red => const Color(0xFFF87171),
    HubBadgeTone.green => const Color(0xFF34D399),
    HubBadgeTone.amber => const Color(0xFFF59E0B),
    HubBadgeTone.muted => const Color(0xFF1F2130),
  };
}

Color badgeTextColor(HubBadgeTone tone) {
  return switch (tone) {
    HubBadgeTone.red => Colors.white,
    HubBadgeTone.green => const Color(0xFF0A2E22),
    HubBadgeTone.amber => const Color(0xFF3D2600),
    HubBadgeTone.muted => const Color(0xFF9CA3AF),
  };
}
