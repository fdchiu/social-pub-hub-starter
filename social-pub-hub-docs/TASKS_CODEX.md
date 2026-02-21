# TASKS_CODEX.md — Social Pub Hub (Flutter + FastAPI)

## How to use this file
- Codex should pick ONE PR-sized task group at a time.
- After each group: run commands listed in "Verification".
- Keep diffs small, reviewable, and reversible.

---

# PR-001: Flutter local DB foundation (Drift)
## Goal
Offline-first persistence for SourceItem, Draft, Variant, PublishLog, StyleProfile.

## Tasks
- Add dependencies:
  - drift, drift_flutter, sqlite3_flutter_libs (desktop), path_provider, path
  - build_runner, drift_dev
- Create DB layer:
  - app/lib/data/db/app_db.dart
  - app/lib/data/db/tables/source_items.dart
  - app/lib/data/db/tables/drafts.dart
  - app/lib/data/db/tables/variants.dart
  - app/lib/data/db/tables/publish_logs.dart
  - app/lib/data/db/tables/style_profiles.dart
- Create converters for arrays:
  - tags: List<String> ↔ JSON string
  - bannedPhrases: List<String> ↔ JSON string
- Create repositories:
  - app/lib/data/repos/source_repo.dart
  - app/lib/data/repos/draft_repo.dart
  - app/lib/data/repos/variant_repo.dart
  - app/lib/data/repos/publish_log_repo.dart
  - app/lib/data/repos/style_profile_repo.dart
- Riverpod providers:
  - app/lib/providers/db_providers.dart
  - app/lib/providers/repo_providers.dart

## Verification
- flutter pub get
- dart run build_runner build --delete-conflicting-outputs
- flutter analyze
- flutter run -d macos

---

# PR-002: Wire Inbox + Compose screens to local DB
## Goal
Inbox shows SourceItems; Compose can create/update Drafts.

## Tasks
- Inbox:
  - list SourceItems (sorted desc by createdAt)
  - add SourceItem via a simple dialog (type=url/note, url/note, tags)
- Compose:
  - create new Draft
  - edit canonical_markdown
  - persist on change (debounced)
- Add minimal navigation:
  - from Inbox → "Create draft from selected sources" (stores selection; can be stub)
- Add "History" screen (optional in this PR if time permits):
  - show PublishLogs (local)

## Verification
- flutter analyze
- run app; create SourceItem; confirm it appears in Inbox
- create Draft; confirm it persists after restart

---

# PR-003: Backend persistence models + migrations
## Goal
Server stores syncable metadata: Draft/Variant/PublishLog/StyleProfile (+ optional Source summary).

## Tasks
- Add SQLAlchemy models and Alembic:
  - backend/app/models/*.py
  - backend/app/db/session.py
  - backend/alembic/ + initial migration
- Tables:
  - drafts, variants, publish_logs, style_profiles
  - (optional) source_summaries (NOT full source pool)
- Add timestamps:
  - created_at, updated_at, deleted_at

## Verification
- docker compose up --build
- run migration
- hit /health

---

# PR-004: Sync protocol (server)
## Goal
Delta-based pull/push for metadata.

## Tasks
- Implement:
  - GET /sync/changes?since=<cursor>
  - POST /sync/push
- Cursor strategy (MVP):
  - server monotonic cursor (BIGINT) written per change
  - return cursor with every response
- Conflict strategy:
  - last-write-wins using updated_at (server trusts client updated_at only if newer; else overwrite)
  - deletions via deleted_at

## Verification
- unit tests for sync merge rules
- manual curl:
  - push an upsert
  - pull changes with cursor

---

# PR-005: Sync engine (Flutter client)
## Goal
Client pushes local changes + pulls deltas; updates Drift.

## Tasks
- Track dirty rows:
  - add `sync_status` to tables (clean/dirty/deleted) OR separate outbox table
- Implement:
  - pull loop: GET /sync/changes
  - push loop: POST /sync/push
- Conflict handling MVP:
  - if both dirty → last-write-wins + keep conflict copy locally (optional)
- Add a "Sync now" button in Settings.

## Verification
- run backend + app
- create Draft on macOS; sync; verify server has it
- modify Draft; sync; verify updated

---

# PR-006: Generation pipeline stubs (server) + UI hooks
## Goal
Make the product usable before real LLM integration.

## Tasks (server)
- POST /drafts/from_sources:
  - return canonical markdown using templates + retrieved source snippets
- POST /drafts/{id}/variants:
  - generate per-platform variants via deterministic templates
- POST /variants/{id}/humanize:
  - apply rewrite heuristics (shorten, remove banned phrases, add personal aside)

## Tasks (client)
- Compose: "Generate variants" button calls backend and stores variants in Drift
- Variant view tabs per platform

## Verification
- end-to-end: select sources → generate canonical → generate variants → view in app

---

# PR-007: Assisted publish flows + PublishLog
## Goal
Assisted publish everywhere with confirmation.

## Tasks
- For each platform, implement:
  - Copy text button
  - Open composer URL (best effort)
  - Confirm posted (manual) → create PublishLog
- Add history timeline with filters.

## Verification
- run on macOS; copy/open/confirm creates publish log