import 'package:flutter/material.dart';

import 'hub_pages.dart';

const _panel = Color(0xFF191B23);
const _card = Color(0xFF1F2130);
const _cardHover = Color(0xFF252840);
const _border = Color.fromRGBO(255, 255, 255, 0.07);
const _text = Color(0xFFEDF0F7);
const _soft = Color(0xFF9CA3AF);
const _muted = Color(0xFF6B7280);
const _accent = Color(0xFF6C7CFF);
const _accent2 = Color(0xFFA78BFA);
const _accent3 = Color(0xFF34D399);
const _accent4 = Color(0xFFF59E0B);
const _accent5 = Color(0xFFF87171);

class HubTopAction {
  const HubTopAction({required this.label, this.primary = false});

  final String label;
  final bool primary;
}

class HubPageViewData {
  const HubPageViewData({
    required this.actions,
    required this.content,
  });

  final List<HubTopAction> actions;
  final Widget content;
}

HubPageViewData buildHubPageViewData(HubPage page) {
  return switch (page) {
    HubPage.projects => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Open Project Workspace', primary: true)
        ],
        content: _settings(),
      ),
    HubPage.inbox => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Filter'),
          HubTopAction(label: '+ Capture Source', primary: true),
        ],
        content: _inbox(),
      ),
    HubPage.library => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Export'),
          HubTopAction(label: 'Create Draft', primary: true),
        ],
        content: _library(),
      ),
    HubPage.compose => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Save Draft'),
          HubTopAction(label: '🚀 Publish', primary: true),
        ],
        content: _compose(),
      ),
    HubPage.bundles => HubPageViewData(
        actions: const [HubTopAction(label: '+ New Bundle', primary: true)],
        content: _bundles(),
      ),
    HubPage.bundleChecklist => HubPageViewData(
        actions: const [HubTopAction(label: 'Backfill Missing', primary: true)],
        content: _bundleChecklist(),
      ),
    HubPage.publish => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Sync Integrations'),
          HubTopAction(label: 'Publish Bundle', primary: true),
        ],
        content: _publish(),
      ),
    HubPage.publishChecklist => HubPageViewData(
        actions: const [HubTopAction(label: 'Run All Checks', primary: true)],
        content: _publishChecklist(),
      ),
    HubPage.queue => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Filter'),
          HubTopAction(label: '+ Schedule Post', primary: true),
        ],
        content: _queue(),
      ),
    HubPage.syncConflicts => HubPageViewData(
        actions: const [
          HubTopAction(label: 'Accept All Local'),
          HubTopAction(label: 'Accept All Remote', primary: true),
        ],
        content: _syncConflicts(),
      ),
    HubPage.history => HubPageViewData(
        actions: const [HubTopAction(label: 'Export Log')],
        content: _history(),
      ),
    HubPage.analytics => HubPageViewData(
        actions: const [HubTopAction(label: 'Export CSV')],
        content: _analytics(),
      ),
    HubPage.settings => HubPageViewData(
        actions: const [HubTopAction(label: 'Run Sync', primary: true)],
        content: _settings(),
      ),
  };
}

Widget _inbox() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _statRow(const [
        _Stat('New Items', '3', 'Since last session', _accent),
        _Stat('Ready to Draft', '12', 'Selected items', _accent3),
        _Stat('Captured Today', '7', 'Across all sources', _text),
      ]),
      _sectionTitle('Unprocessed Sources'),
      _itemList(const [
        _Item(
          icon: '🔗',
          title: 'TechCrunch – AI Funding Rounds Q1 2025',
          desc:
              'Exclusive: 14 AI startups raised \$2.3B combined in the first quarter...',
          metaA: 'techcrunch.com',
          metaB: '2h ago',
          tag: 'Article',
          tagTone: _TagTone.blue,
          actionLabel: 'Create Draft',
          actionPrimary: true,
        ),
        _Item(
          icon: '🐦',
          title: '@sama tweet thread – on reasoning models',
          desc:
              'A new class of models that can plan, reason, and reflect before answering...',
          metaA: 'twitter.com',
          metaB: '4h ago',
          tag: 'Thread',
          tagTone: _TagTone.purple,
          actionLabel: 'Create Draft',
          actionPrimary: true,
        ),
        _Item(
          icon: '📄',
          title: 'Internal brief – Product launch messaging',
          desc:
              'Key talking points for the upcoming v3 feature rollout across platforms...',
          metaA: 'Uploaded file',
          metaB: '1d ago',
          tag: 'Brief',
          tagTone: _TagTone.green,
          actionLabel: 'Create Draft',
          actionPrimary: true,
        ),
      ]),
    ],
  );
}

Widget _library() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _searchRow('Search sources by title, tag, or platform…',
          trailing: _tag('48 saved', _TagTone.gray)),
      _filterRow(const [
        'All',
        'Articles',
        'Threads',
        'Briefs',
        'Videos',
        '🏷 Bundles'
      ]),
      _sectionTitle('Saved Sources'),
      _itemList(const [
        _Item(
          icon: '🔗',
          title: 'State of AI Report 2025',
          desc:
              'Comprehensive annual survey of AI adoption, investment, and capabilities.',
          metaA: 'Bundle: AI Trends',
          metaB: 'Saved 3d ago',
          tag: 'Bundle',
          tagTone: _TagTone.purple,
          actionLabel: 'Open',
        ),
        _Item(
          icon: '🎬',
          title: 'YT: How to build a second brain',
          desc:
              'Ali Abdaal\'s breakdown of his entire note-taking workflow and PKM system.',
          metaA: 'youtube.com',
          metaB: '1w ago',
          tag: 'Video',
          tagTone: _TagTone.amber,
          actionLabel: 'Draft',
        ),
        _Item(
          icon: '📰',
          title: 'The Verge – Apple Intelligence Recap',
          desc:
              'Everything Apple announced about on-device AI features in iOS 18.4.',
          metaA: 'theverge.com',
          metaB: '5d ago',
          tag: 'Article',
          tagTone: _TagTone.green,
          actionLabel: 'Draft',
        ),
      ]),
    ],
  );
}

Widget _compose() {
  return Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      SizedBox(
        width: 560,
        child: _panelCard(
          title: 'Draft Editor',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI funding hit a record \$2.3B in Q1 2025 — here\'s what it means for the ecosystem and why this wave is different from 2021…',
                  style: TextStyle(color: _text, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniButton('✨ Polish with AI'),
                  _MiniButton('🔀 Humanize'),
                  _MiniButton('📏 Shorten'),
                  _MiniButton('+ Variant'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _border),
              const SizedBox(height: 8),
              const Text('PUBLISH TO',
                  style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PlatformChip('𝕏 Twitter/X', on: true),
                  _PlatformChip('in LinkedIn', on: true),
                  _PlatformChip('f Facebook'),
                  _PlatformChip('▶ Threads'),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Variants'),
            _itemList(const [
              _Item(
                icon: '𝕏',
                title: 'Twitter — Long · 240 chars',
                desc:
                    'AI funding hit a record \$2.3B in Q1 2025. Here\'s what that means…',
                tag: 'Twitter',
                tagTone: _TagTone.blue,
              ),
              _Item(
                icon: 'in',
                title: 'LinkedIn — Pro · 580 chars',
                desc:
                    'The AI funding wave of 2025 is fundamentally different from 2021. Here\'s why…',
                tag: 'LinkedIn',
                tagTone: _TagTone.purple,
              ),
            ]),
          ],
        ),
      ),
    ],
  );
}

Widget _bundles() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow(const [
          _Stat('Active Bundles', '5', '', _accent),
          _Stat('Pending Variants', '11', '', _accent4),
          _Stat('Published', '29', '', _accent3),
        ]),
        _sectionTitle('Bundle Plans'),
        _itemList(const [
          _Item(
              icon: '📦',
              title: 'AI Trends — May 2025',
              desc: 'Anchor deep-dive · 4 variants ready · 2 missing',
              tag: 'In Progress',
              tagTone: _TagTone.amber,
              actionLabel: 'Edit'),
          _Item(
              icon: '📦',
              title: 'Product Launch Week',
              desc: 'Anchor announcement · 6 variants · All approved',
              tag: 'Ready',
              tagTone: _TagTone.green,
              actionLabel: 'View'),
          _Item(
              icon: '📦',
              title: 'Thought Leadership – Q2',
              desc: 'Industry opinion piece · Planning phase',
              tag: 'Draft',
              tagTone: _TagTone.gray,
              actionLabel: 'Edit'),
        ]),
      ],
    );

Widget _bundleChecklist() => _twoCol(
      left: _panelCard(
        title: 'Readiness Checklist',
        child: const Column(
          children: [
            _CheckRow('Anchor post written', true, 'Done', _TagTone.green),
            _CheckRow('Twitter variant approved', true, 'Done', _TagTone.green),
            _CheckRow(
                'LinkedIn variant approved', true, 'Done', _TagTone.green),
            _CheckRow('Threads variant needed', false, 'Missing', _TagTone.red),
            _CheckRow(
                'Facebook variant needed', false, 'Missing', _TagTone.red),
            _CheckRow('Publish window set', true, 'Done', _TagTone.green),
          ],
        ),
      ),
      right: _panelCard(
        title: 'Bundle Status',
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('67%',
                style: TextStyle(
                    color: _accent, fontSize: 32, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            _Progress(0.67),
            SizedBox(height: 10),
            Text('4 of 6 items complete',
                style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      ),
    );

Widget _publish() => _twoCol(
      left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Platform Integrations'),
        _itemList(const [
          _Item(
              icon: '𝕏',
              title: 'Twitter / X',
              desc: '@jamie_morgan · API v2',
              tag: 'Active',
              tagTone: _TagTone.green),
          _Item(
              icon: 'in',
              title: 'LinkedIn',
              desc: 'Jamie Morgan · Page connected',
              tag: 'Active',
              tagTone: _TagTone.green),
          _Item(
              icon: '▶',
              title: 'Threads',
              desc: '@jamie · Meta integration',
              tag: 'Active',
              tagTone: _TagTone.green),
          _Item(
              icon: 'f',
              title: 'Facebook',
              desc: 'Business Page · Graph API',
              tag: 'Active',
              tagTone: _TagTone.green),
        ]),
      ]),
      right: _panelCard(
        title: 'Recent Publish Log',
        child: const Column(
          children: [
            _TimelineRow('AI Trends – Twitter variant',
                'Today, 9:05 AM · Twitter/X', _accent3),
            _TimelineRow('AI Trends – LinkedIn anchor',
                'Today, 9:00 AM · LinkedIn', _accent3),
            _TimelineRow('Product Launch – Threads',
                'Yesterday, 6:30 PM · Threads', _accent4),
            _TimelineRow('Facebook sync error – retrying',
                'Yesterday, 2:14 PM · Facebook', _accent5),
          ],
        ),
      ),
    );

Widget _publishChecklist() => _twoCol(
      left: _panelCard(
        title: 'Human-Sounding Rubric',
        child: const Column(
          children: [
            _CheckRow(
                'No AI filler phrases detected', true, 'Pass', _TagTone.green),
            _CheckRow('Reading level: Grade 9 (target)', true, 'Pass',
                _TagTone.green),
            _CheckRow(
                'Sentence variety score: 78/100', true, 'Pass', _TagTone.green),
            _CheckRow('Repetition score: 2 flagged phrases', false, 'Review',
                _TagTone.amber),
            _CheckRow(
                'Tone matches style profile', true, 'Pass', _TagTone.green),
            _CheckRow(
                'Character limits within range', true, 'Pass', _TagTone.green),
            _CheckRow('Hashtag count: 6 (recommended ≤4)', false, 'Review',
                _TagTone.amber),
          ],
        ),
      ),
      right: _panelCard(
        title: 'Rubric Score',
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('82/100',
                style: TextStyle(
                    color: _accent4,
                    fontSize: 48,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            _Progress(0.82, colors: [Color(0xFFF59E0B), Color(0x88F59E0B)]),
          ],
        ),
      ),
    );

Widget _queue() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow(const [
          _Stat('Scheduled', '7', '', _accent),
          _Stat('Next Post', '2h 14m', 'May 9 · 12:00 PM', _text),
          _Stat('Posted Today', '4', '', _accent3),
        ]),
        _sectionTitle('Scheduled Posts'),
        _itemList(const [
          _Item(
              icon: '🕐',
              title: 'Today 12:00 PM',
              desc: 'AI funding round-up thread — Twitter/X & LinkedIn',
              tag: 'Scheduled',
              tagTone: _TagTone.blue),
          _Item(
              icon: '🕐',
              title: 'Today 3:30 PM',
              desc: 'Product v3 launch day — short-form reel hook',
              tag: 'Scheduled',
              tagTone: _TagTone.blue),
          _Item(
              icon: '🕐',
              title: 'May 10 9:00 AM',
              desc: 'Thought leadership: AI adoption',
              tag: 'Pending',
              tagTone: _TagTone.purple),
          _Item(
              icon: '✅',
              title: 'Posted 9:05 AM',
              desc: 'AI Trends – Twitter variant',
              tag: 'Posted',
              tagTone: _TagTone.green),
        ]),
      ],
    );

Widget _syncConflicts() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(248, 113, 113, 0.07),
            border: Border.all(color: const Color.fromRGBO(248, 113, 113, 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
              '⚡ 1 conflict detected — choose local or remote version.',
              style: TextStyle(color: _soft, fontSize: 13.5)),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'Draft conflict: AI Trends – LinkedIn Anchor',
          child: const _CheckRow('Local vs remote content mismatch', false,
              'Conflict', _TagTone.red),
        ),
      ],
    );

Widget _history() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterRow(const [
          'All Time',
          'This Week',
          'Twitter/X',
          'LinkedIn',
          'Threads'
        ]),
        _sectionTitle('Publish Timeline'),
        _itemList(const [
          _Item(
              icon: '🚀',
              title: 'AI Trends – Twitter variant published',
              desc: 'Bundle: AI Trends · Today, 9:05 AM',
              actionLabel: 'Clone to Draft'),
          _Item(
              icon: '🚀',
              title: 'Product Launch – Threads short-form',
              desc: 'Bundle: Product Launch Week · Yesterday, 6:30 PM',
              actionLabel: 'Clone to Draft'),
          _Item(
              icon: '⚠️',
              title: 'Facebook sync failed – Product Launch',
              desc: 'Error: OAuth token expired.',
              tag: 'Failed',
              tagTone: _TagTone.red),
        ]),
      ],
    );

Widget _analytics() => _twoCol(
      left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _statRow(const [
          _Stat('Posts This Month', '47', '↑ 18% vs last month', _accent),
          _Stat('Queue Health', 'Good', '7 scheduled, 0 overdue', _accent3),
          _Stat('Platforms Active', '4', 'All connected', _text),
          _Stat('Avg Posts/Day', '3.1', 'Target: 3', _text),
        ]),
        _panelCard(
          title: 'Posts by Day (Last 14 Days)',
          child: SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(14, (index) {
                final h = <double>[
                  .40,
                  .60,
                  .35,
                  .80,
                  .50,
                  .90,
                  .45,
                  .70,
                  .55,
                  1.0,
                  .60,
                  .75,
                  .85,
                  .65
                ][index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                        height: 80 * h,
                        decoration: BoxDecoration(
                            color: index == 9 ? _accent2 : _accent,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)))),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
      right: _panelCard(
        title: 'Platform Breakdown',
        child: const Column(
          children: [
            _TimelineRow('Twitter / X · 19 posts', '', _accent),
            _TimelineRow('LinkedIn · 14 posts', '', _accent2),
            _TimelineRow('Threads · 9 posts', '', _accent3),
            _TimelineRow('Facebook · 5 posts', '', _accent4),
          ],
        ),
      ),
    );

Widget _settings() => _twoCol(
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelCard(
            title: 'Style Profile',
            child: const Column(
              children: [
                _SettingRow('Tone', 'Professional · Witty', _TagTone.blue),
                _SettingRow('Reading Level', 'Grade 9', _TagTone.gray),
                _SettingRow('Forbidden phrases', '12 phrases', _TagTone.red),
                _SettingRow('Emoji usage', 'Enabled', _TagTone.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panelCard(
              title: 'Data Sync',
              child: const Text('Last sync: 4 minutes ago · All clear',
                  style: TextStyle(color: _soft, fontSize: 13))),
        ],
      ),
      right: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Integrations'),
        _itemList(const [
          _Item(
              icon: '𝕏',
              title: 'Twitter / X',
              desc: 'OAuth 2.0 · API v2 · @jamie_morgan',
              tag: 'Active',
              tagTone: _TagTone.green,
              actionLabel: 'Revoke'),
          _Item(
              icon: 'in',
              title: 'LinkedIn',
              desc: 'OAuth 2.0 · Page Manager',
              tag: 'Active',
              tagTone: _TagTone.green,
              actionLabel: 'Revoke'),
          _Item(
              icon: '▶',
              title: 'Threads',
              desc: 'Meta Graph API · @jamie',
              tag: 'Active',
              tagTone: _TagTone.green,
              actionLabel: 'Revoke'),
          _Item(
              icon: 'f',
              title: 'Facebook',
              desc: 'Graph API · token expires in 7d',
              tag: 'Expiring',
              tagTone: _TagTone.amber,
              actionLabel: 'Refresh',
              actionPrimary: true),
        ]),
      ]),
    );

Widget _twoCol({required Widget left, required Widget right}) =>
    Wrap(spacing: 16, runSpacing: 16, children: [
      SizedBox(width: 520, child: left),
      SizedBox(width: 520, child: right)
    ]);

Widget _statRow(List<_Stat> items) =>
    Wrap(spacing: 14, runSpacing: 14, children: items.map(_statCard).toList());
Widget _statCard(_Stat s) => Container(
    width: 240,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.label,
          style: const TextStyle(
              color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text(s.value,
          style: TextStyle(
              color: s.color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1)),
      if (s.sub.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(s.sub, style: const TextStyle(color: _soft, fontSize: 12))
      ]
    ]));
Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 14),
    child: Text(t.toUpperCase(),
        style: const TextStyle(
            color: _soft,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .6)));
Widget _itemList(List<_Item> items) => Column(
    children: items
        .map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10), child: _itemCard(e)))
        .toList());
Widget _itemCard(_Item i) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border)),
    child: Row(children: [
      Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _cardHover, borderRadius: BorderRadius.circular(10)),
          child: Text(i.icon, style: const TextStyle(fontSize: 16))),
      const SizedBox(width: 16),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(i.title,
            style: const TextStyle(
                color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(i.desc,
            style: const TextStyle(color: _soft, fontSize: 12.5, height: 1.4)),
        if (i.metaA != null || i.metaB != null) ...[
          const SizedBox(height: 4),
          Text([i.metaA, i.metaB].whereType<String>().join('  ·  '),
              style: const TextStyle(color: _muted, fontSize: 11))
        ]
      ])),
      if (i.tag != null) ...[
        const SizedBox(width: 8),
        _tag(i.tag!, i.tagTone ?? _TagTone.gray)
      ],
      if (i.actionLabel != null) ...[
        const SizedBox(width: 8),
        _miniAction(i.actionLabel!, i.actionPrimary)
      ]
    ]));
Widget _panelCard({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: const TextStyle(
              color: _soft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: .5)),
      const SizedBox(height: 14),
      child
    ]));
Widget _tag(String text, _TagTone tone) {
  final c = switch (tone) {
    _TagTone.blue => const Color(0xFFA5B0FF),
    _TagTone.green => _accent3,
    _TagTone.amber => _accent4,
    _TagTone.red => _accent5,
    _TagTone.purple => _accent2,
    _TagTone.gray => _muted,
  };
  final bg = switch (tone) {
    _TagTone.blue => const Color.fromRGBO(108, 124, 255, 0.15),
    _TagTone.green => const Color.fromRGBO(52, 211, 153, 0.12),
    _TagTone.amber => const Color.fromRGBO(245, 158, 11, 0.12),
    _TagTone.red => const Color.fromRGBO(248, 113, 113, 0.12),
    _TagTone.purple => const Color.fromRGBO(167, 139, 250, 0.12),
    _TagTone.gray => _card,
  };
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: tone == _TagTone.gray ? Border.all(color: _border) : null),
      child: Text(text,
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)));
}

Widget _miniAction(String text, bool primary) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
        color: primary ? _accent : _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary ? _accent : _border)),
    child: Text(text,
        style: TextStyle(
            color: primary ? Colors.white : _soft,
            fontSize: 12,
            fontWeight: FontWeight.w600)));
Widget _searchRow(String hint, {Widget? trailing}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border)),
    child: Row(children: [
      const Text('🔍', style: TextStyle(color: _muted)),
      const SizedBox(width: 10),
      Expanded(
          child: Text(hint,
              style: const TextStyle(color: _muted, fontSize: 13.5))),
      if (trailing != null) trailing
    ]));
Widget _filterRow(List<String> labels) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 18),
    child: Wrap(spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < labels.length; i++)
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
                color:
                    i == 0 ? const Color.fromRGBO(108, 124, 255, 0.08) : _card,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: i == 0 ? _accent : _border)),
            child: Text(labels[i],
                style: TextStyle(
                    color: i == 0 ? _accent : _soft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)))
    ]));

class _Progress extends StatelessWidget {
  const _Progress(this.value, {this.colors = const [_accent, _accent2]});
  final double value;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => Container(
      height: 10,
      decoration:
          BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(5)),
      child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(5))))));
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.title, this.time, this.dot);
  final String title;
  final String time;
  final Color dot;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
          if (time.isNotEmpty)
            Text(time, style: const TextStyle(color: _muted, fontSize: 11.5))
        ]))
      ]));
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip(this.text, {this.on = false});
  final String text;
  final bool on;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: on ? const Color.fromRGBO(108, 124, 255, 0.1) : _panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? _accent : _border)),
      child: Text(text,
          style: TextStyle(
              color: on ? _text : _soft,
              fontSize: 12,
              fontWeight: FontWeight.w600)));
}

class _MiniButton extends StatelessWidget {
  const _MiniButton(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => _miniAction(text, false);
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.done, this.badge, this.tone);
  final String label;
  final bool done;
  final String badge;
  final _TagTone tone;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: done ? _accent3 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: done ? _accent3 : _border, width: 1.5)),
            child: done
                ? const Text('✓',
                    style: TextStyle(color: Colors.white, fontSize: 12))
                : null),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: done ? _muted : _text,
                    fontSize: 13.5,
                    decoration: done ? TextDecoration.lineThrough : null))),
        _tag(badge, tone)
      ]));
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.label, this.value, this.tone);
  final String label;
  final String value;
  final _TagTone tone;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(
                color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
        _tag(value, tone)
      ]));
}

class _Stat {
  const _Stat(this.label, this.value, this.sub, this.color);
  final String label;
  final String value;
  final String sub;
  final Color color;
}

class _Item {
  const _Item({
    required this.icon,
    required this.title,
    required this.desc,
    this.metaA,
    this.metaB,
    this.tag,
    this.tagTone,
    this.actionLabel,
    this.actionPrimary = false,
  });

  final String icon;
  final String title;
  final String desc;
  final String? metaA;
  final String? metaB;
  final String? tag;
  final _TagTone? tagTone;
  final String? actionLabel;
  final bool actionPrimary;
}

enum _TagTone { blue, green, amber, red, purple, gray }
