# Social Pub Hub — Starter Scaffold

Generated: 2026-02-20T21:42:27.784130Z

Stack:
- Flutter (macOS/iOS/Web ready)
- FastAPI backend
- Postgres (planned)
- Offline-first local DB (Drift)

This scaffold includes:
- Flutter flows: inbox, library, compose, history, publish console, bundles
- Queue scheduling: queue variants from compose + manage queued items
- FastAPI server with health + stub/sync endpoints
- Docker compose for backend + Postgres
- Style profile editor in Settings (voice, cadence, emoji, banned phrases)
- Compose actions: generate variants, platform filter tabs, humanize per variant

Next steps:
1. `cd backend && docker compose up --build`
2. `cd app && flutter run -d macos`

Testing:
1. Flutter: `cd app && flutter analyze && flutter test`
2. Backend: `cd backend && ./.venv/bin/pip install -r requirements.txt && ./.venv/bin/python -m pytest -q`

Key workflow:
1. Open Inbox, select source items, click "Create draft from selected".
2. Compose opens with canonical draft; generate variants from the sparkle action.
3. Filter variants by platform, run Humanize, then copy/open composer/queue/confirm post.
4. Use Settings to tune style profile and run sync.
