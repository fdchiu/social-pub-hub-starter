# Social Pub Hub

Project-first social publishing workspace.

Desktop app + backend for collecting source material, organizing it by scope, drafting with LLM assistance, generating platform variants, queueing/manual publishing, and tracking history.

## What It Does

- Project-first workflow: one global active project, with posts nested under that project.
- Capture flow: Inbox and Library support `global`, `project`, and `post` scoped source material.
- Draft flow: create canonical draft, polish it, generate variants, humanize variants, generate cover images.
- Publish flow: assisted publishing, queue management, publish logs, checklists, analytics.
- Offline-first app data: local Drift database with sync support.
- Backend: FastAPI service for sync, draft generation, polish, variant generation, image generation, and integrations state.
- DB backend abstraction on server: SQL default, MongoDB optional via env.

## Repo Layout

- `app/`: Flutter desktop/mobile app (primary target currently macOS).
- `backend/`: FastAPI backend service.
- `social-pub-hub-docs/`: workflow and product docs.
- `scripts/`: helper scripts.

## Core Workflow

1. Open `Projects`.
2. Create/select a project.
3. Create/select a post workspace inside that project.
4. Add sources in `Inbox` or refine sources in `Library`.
5. Create draft from sources.
6. Edit in `Compose`, optionally `Polish`.
7. Generate variants per platform.
8. Group related variants into a `Bundle` when coordinating a social wave.
9. Use checklists.
10. Publish now or queue (single variant or bundle queue).
11. Review `History` and `Analytics`.

## Concept Model

Primary operator flow:

`project -> inbox -> library -> post -> compose -> variants -> bundle -> queue -> publish`

Meaning of each step:

- `project`: top-level working context.
- `inbox`: capture raw evidence and ideas.
- `library`: refine, filter, retag, and rebalance reusable sources.
- `post`: the main publishing unit inside a project.
- `compose`: canonical draft workspace for editing, polish, cover images, and variant generation.
- `variants`: platform-specific outputs derived from the canonical draft.
- `bundle`: a grouped set of variants/sources used for coordinated distribution.
- `queue`: scheduled publishing reminders/tracking entries.
- `publish`: integration status, assisted publish confirmation, and publish logs.

Important:
- Posts are project-owned.
- On non-Projects screens, project/post controls in the header are context display, not the main place to change selection.
- The left sidebar project explorer is the primary place to switch project/post context.

## App Features

- Inbox: add `url`, `note`, `snippet`, `image`, `video`, `audio`, `file`.
- Library: search/filter, scope rebalance, draft from selected sources.
- Compose:
  - edit canonical draft
  - polish draft
  - upload/select local cover image file
  - import cover image from external URL
  - generate/revise cover images with follow-up prompt + negative prompt
  - generate cover images using a reference image URL
  - generate variants
  - humanize visible variants
  - generate and persist cover image versions
  - confirm posted or queue individual variants
- Bundles:
  - group content around an anchor post
  - review coordinated publish sets
  - queue all bundle variants at once
  - auto-stagger bundle queue timing with a saved default minute interval (`0` = same time)
- Publish: assisted publish + publish logs.
- Queue: schedule/manual queue tracking.
- Settings: app-wide settings, sync diagnostics, style profile.

## Running Locally

### Backend

```bash
cd backend
./.venv/bin/pip install -r requirements.txt
./.venv/bin/uvicorn app.main:app --reload
```

Default backend URL in app:
- `https://social-pub-hub-backend.onrender.com`

Useful local endpoints:
- `GET /health`
- `GET /integrations`

### App (macOS)

```bash
cd app
flutter pub get
flutter run -d macos
```

## Environment

### Backend env

- `DB_BACKEND=sql` (default)
- `DATABASE_URL=sqlite:///./social_pub_hub.db` (default SQL path)
- `DB_BACKEND=mongo`
- `MONGODB_URI=mongodb://127.0.0.1:27017/social_pub_hub`
- `MONGODB_DB=social_pub_hub`
- `OPENAI_API_KEY=...`
- `OPENAI_MODEL=gpt-5.3-codex`

See also:
- `backend/.env.example`

### App server URL

Configured in app provider default:
- `app/lib/providers/sync_providers.dart`

Current default points to:
- `https://social-pub-hub-backend.onrender.com`

## Testing

### App

```bash
cd app
flutter analyze
flutter test
```

### Backend

```bash
cd backend
./.venv/bin/python -m pytest -q
```

## Deployment Notes

### Backend

Render-compatible.

Current backend includes:
- startup route logging
- request logging for `/polish`
- warning logs for `4xx/5xx`

If `Polish` returns `404`, check backend logs for:
- `startup.routes ... POST /drafts/{draft_id}/polish ...`
- `request.start method=POST path=/drafts/<id>/polish ...`
- `request.complete method=POST path=/drafts/<id>/polish status=404 ...`

If the startup route list does not include the route, the deployed backend is stale or booting the wrong app entrypoint.

## Docs

Primary workflow doc:
- `social-pub-hub-docs/docs/12_App_Workflow.md`

Other useful docs:
- `social-pub-hub-docs/docs/02_Data_Model.md`
- `social-pub-hub-docs/docs/03_API_Spec.md`
- `social-pub-hub-docs/docs/10_Navigation_Menu.md`

## Current Direction

- Project-first UX
- Scoped content reuse (`global` / `project` / `post`)
- Assisted/manual publishing first
- Direct auto-publish adapters remain future work

## Troubleshooting

### Compose `Polish` shows backend 404

- The app now falls back locally if the backend route is missing.
- Real draft-missing `404` still surfaces as an error.
- Redeploy backend if route is absent in startup log.

### macOS build fails with Flutter ephemeral file list errors

Typical fix:
- rerun Flutter build artifacts generation (`flutter clean`, `flutter pub get`, rebuild)
- ensure Xcode build is opening the Flutter-generated workspace state after Flutter has run

### SQLite migration duplicate column errors

If a local schema is older and migration was partially applied, remove the broken local DB or patch migration logic before rerun.

## Status

This repo is no longer just a scaffold. It contains an actively evolving app flow with implemented UI and ongoing functionality hardening screen by screen.
