Below is a **Codex Agent Handoff Doc** you can drop into your repo as `HANDOFF_CODEX.md`. It’s written so a fresh Codex CLI / IDE session can immediately resume work with minimal reorientation, and it explicitly covers **approval/permissions** and **what to run first**. (Codex has configurable approval modes via `/permissions` in CLI sessions. ([OpenAI Developers][1]))

---

# HANDOFF_CODEX.md — Social Pub Hub (Flutter + FastAPI)

## 0) TL;DR

**Project:** Social network publishing hub (Phase I MVP)
**Stack:** Flutter (macOS/iOS priority) + FastAPI + Postgres
**MVP stance:** **Hybrid publishing** (assisted publish everywhere; direct only where feasible/approved)
**Sync stance:** **Cloud sync for metadata (Draft/Variant/PublishLog/StyleProfile/IntegrationMeta)**; Source pool stays local-first with **selective sync**.

### Immediate next objective

Implement **Local DB (Drift)** + **Sync protocol** + **Draft/Variant generation endpoints** and wire the Flutter UI to real data.

---

## 1) Repo/artifacts locations

### Provided artifacts (already generated)

* Docs ZIP: `social-pub-hub-docs.zip`
* Starter scaffold ZIP: `social-pub-hub-starter.zip`

> If these are already unzipped into the repo, confirm presence of:

* `docs/00_PRD.md`
* `docs/01_Architecture.md`
* `docs/02_Data_Model.md`
* `docs/03_API_Spec.md`
* `docs/04_UX_Design.md`
* `docs/06_MVP_Backlog.md`
* Flutter app: `app/`
* FastAPI backend: `backend/`

If not present, ask user where they unzipped, or unzip from the artifacts into workspace.

---

## 2) Current status snapshot

### What exists now

* Flutter app skeleton:

  * routes: `/`, `/inbox`, `/compose`
  * placeholder screens
* FastAPI skeleton:

  * `GET /health`
  * `GET /integrations` (stub)
* Docker compose:

  * Postgres service
  * FastAPI service

### What is missing (highest priority)

1. Local persistence (Drift schema + repositories + Riverpod providers)
2. Sync engine (push/pull deltas) + backend tables
3. Draft pipeline endpoints (from sources → canonical → variants → humanize)
4. UI wiring (Inbox uses DB, Compose uses Draft entity)

---

## 3) Guardrails / constraints

### Platform constraints

* No scraping / ToS-violating automation.
* Assisted publish is default. Direct publish is **feature-flagged**.
* Don’t store OAuth tokens in plaintext (Keychain on device; encrypted server-side).

### “Human-sounding” requirements

* Short, hook-first, personal stance, specific details, minimal corporate filler.
* StyleProfile: banned phrases list + cadence rules (see `docs/07_Prompt_Style_System.md`).

---

## 4) How to run locally (for Codex)

### Backend

```bash
cd backend
docker compose up --build
# API at http://localhost:8000
```

### Flutter (macOS)

```bash
cd app
flutter pub get
flutter run -d macos
```

---

## 5) Codex operating mode (important)

When using Codex CLI:

* Start in **read-only** for discovery.
* Switch to “workspace write” only when ready to apply changes.
* Use `/permissions` to adjust approval/automation as needed. ([OpenAI Developers][1])

**Recommended policy for this repo:**

* Planning & inspection: read-only
* Implementation: on-failure / workspace-write (so it doesn’t spam approvals, but still safe)

---

## 6) Concrete tasks for the next Codex session (ordered)

### Task A — Add Drift local DB (Phase I minimal schema)

**Goal:** Persist SourceItem, Draft, Variant, PublishLog, StyleProfile locally.

**Deliverables:**

* `app/lib/data/db/app_db.dart`
* `app/lib/data/db/tables/*.dart`
* `app/lib/data/repos/*.dart`
* `app/lib/providers/*.dart` (Riverpod providers)

**Schema to implement (minimum fields)**

* SourceItem: id, type, url, title, userNote, tags(json/text), createdAt, updatedAt
* Draft: id, canonicalMarkdown, intent, tone, punchiness, emojiLevel, audience, createdAt, updatedAt
* Variant: id, draftId, platform, text, createdAt, updatedAt
* PublishLog: id, variantId, platform, mode, status, externalUrl, postedAt, createdAt
* StyleProfile: id, voiceName, casualFormal, punchiness, emojiLevel, bannedPhrases(json/text), updatedAt

**Notes:**

* Use JSON encoding for arrays in SQLite for MVP (tags, bannedPhrases).
* Add migrations from day 1.

### Task B — Implement backend persistence + sync endpoints

**Goal:** Server holds syncable metadata: Draft/Variant/PublishLog/StyleProfile (+ optional SourceItem summaries)

**Deliverables:**

* SQLAlchemy models + Alembic migrations
* `GET /sync/changes?since=cursor`
* `POST /sync/push`

**Simplest working sync (MVP):**

* cursor = monotonic integer or timestamp
* last-write-wins per row using `updated_at`
* soft deletes via `deleted_at`

### Task C — Wire Flutter UI to local DB

* Inbox reads SourceItems from Drift
* Compose creates Draft and saves
* Variant Studio generates placeholder variants locally (until backend gen is wired)

### Task D — Generation pipeline stubs

**Backend endpoints:**

* `POST /drafts/from_sources` (return canonicalMarkdown stub)
* `POST /drafts/{id}/variants` (use template rules)
* `POST /variants/{id}/humanize` (light rewrite rules)

Even rule-based stubs are fine; swap to LLM later.

---

## 7) Definition of Done for this milestone

* You can:

  1. capture/add a SourceItem
  2. create a Draft
  3. generate Variants
  4. see them in UI
  5. push/pull metadata sync between devices (even if only one device available, endpoint calls succeed)
  6. record a PublishLog via “assisted publish confirm”

---

## 8) Open questions (defer; don’t block)

* YouTube upload in Phase I: optional, behind flag.
* Which platforms will be direct publish in Phase I: decide later; keep adapters feature-flagged.
* Encryption tier for local DB: plaintext ok for MVP, but prepare SQLCipher hook.

---

## 9) Commands/checks Codex should run before coding

1. List tree; confirm expected files exist
2. Run backend via docker compose and hit `/health`
3. Run `flutter analyze` + `flutter test` (if tests exist)
4. After changes: ensure `flutter pub get` and app still runs

---

## 10) Commit plan (small, reviewable PRs)

1. Add Drift DB + minimal repos + providers
2. Wire Inbox + Compose to DB
3. Add backend models + migrations
4. Add sync endpoints
5. Add client sync engine
6. Add generation stubs + UI actions

---

If you want, I can also generate a **Codex-friendly TASKS.md** (one checklist per PR) and a **“prompt block”** you paste into Codex to enforce the style/rules for this repo.

[1]: https://developers.openai.com/codex/cli/features/?utm_source=chatgpt.com "Codex CLI features"
