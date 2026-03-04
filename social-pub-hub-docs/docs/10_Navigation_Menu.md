# Navigation Menu Functions

This document explains the function of each home navigation item (sometimes called the side menu in product discussions).

## Mental model

Primary operating sequence:

`project -> inbox -> library -> post -> compose -> variants -> bundle -> queue -> publish`

Notes:
- `project` and `post` are context selectors, not just screens.
- `compose` is the main single-post production workspace.
- `bundle` is the coordinated multi-variant packaging step.
- `queue` is a scheduling/tracking layer.
- `publish` is the operational confirmation/log layer.

## Menu map

### 1) Inbox (`/inbox`)
- Purpose: collect source material and start draft creation from selected items.
- Primary actions:
  - Add source item (`url`, `note`, `snippet`, `image`, `video`, `audio`, `file`)
  - Select multiple sources
  - Create draft from selected sources (sends source evidence to backend)
- Typical output: canonical draft opened in Compose.

### 2) Library (`/library`)
- Purpose: browse/search/filter saved source items.
- Primary actions:
  - Text search over title/url/note/tag
  - Tag filters
  - Create draft from a source
  - Attach/clear source bundle assignment
- Typical output: organized source pool + faster draft starts.

### 3) Compose (`/compose`)
- Purpose: draft and variant production workspace.
- Primary actions:
  - Edit canonical markdown draft
  - Polish draft (LLM pass when configured, fallback rules otherwise)
  - Generate and revise cover images
  - Generate variants by platform
  - Filter variants by platform
  - Humanize variant text
  - Copy/open composer/confirm posted/queue
- Typical output: publish-ready platform variants + publish logs.

### 4) Bundles (`/bundles`)
- Purpose: build cross-post bundles around an anchor.
- Primary actions:
  - Create bundle with anchor type/ref
  - Link variants to bundle
  - Review wave preview and YouTube metadata preview
  - Queue all bundle variants in one action
  - Apply saved stagger spacing between queued items (`0` means same-time queue)
- Typical output: bundle plan for coordinated publishing.

### 5) Bundle Checklist (`/bundle-checklist`)
- Purpose: validate bundle readiness before distribution.
- Primary actions:
  - Checklist evaluation
  - Generate canonical draft from linked sources
  - Attach latest source
  - Backfill missing variants/platforms
  - Queue bundle directly once ready
  - Clean missing variant references
- Typical output: complete bundle with fewer publish blockers.

### 6) Publish (`/publish`)
- Purpose: operational publish console.
- Primary actions:
  - View integration capability/connection status
  - Filter recent logs by bundle
  - Jump to Queue, Analytics, Compose
- Typical output: quick publish-state visibility.

### 7) Publish Checklist (`/publish-checklist`)
- Purpose: quality gate for the latest draft.
- Primary actions:
  - Run human-sounding rubric checks
  - Review assisted publish process reminders
- Typical output: confidence check before posting.

### 8) Queue (`/queue`)
- Purpose: manage scheduled posts.
- Primary actions:
  - Filter by platform/status
  - Overdue-only toggle
  - Copy/open composer
  - Mark posted/cancel
  - Open related history
  - Review bundle-generated queued items, including staggered batches
- Typical output: cleaner scheduled publishing workflow.

### 9) Sync Conflicts (`/sync-conflicts`)
- Purpose: resolve data conflicts from sync.
- Primary actions:
  - Compare local vs remote payload summary
  - Keep remote or use local
- Typical output: conflict-free sync state.

### 10) History (`/history`)
- Purpose: timeline and audit of publish logs.
- Primary actions:
  - Filter by platform/status/variant
  - Open external posted URL
  - Clone variant into a new draft
- Typical output: reusable post history and traceability.

### 11) Analytics (`/analytics`)
- Purpose: lightweight KPI snapshot.
- Primary actions:
  - Posted count
  - Queue queued/overdue counts
  - Posted-by-platform breakdown
- Typical output: quick health metrics, not deep BI.

### 12) Settings (`/settings`)
- Purpose: sync + style + integration controls.
- Primary actions:
  - Run sync now
  - Inspect conflict counts
  - Edit style profile (voice, sliders, banned phrases)
  - Refresh integration status
- Typical output: tuned writing style + synchronized state.

## Notes
- Navigation back behavior:
  - If screen can pop, leading button is Back.
  - Otherwise leading button routes Home (`/`).
- Home currently presents these menu entries as the primary navigation surface.
