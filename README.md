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
- LLM-backed draft polish path with evidence-pack fallback (template/rules when no key)

Next steps:
1. `cd backend && docker compose up --build`
2. `cd app && flutter run -d macos`

Backend DB backend selection:
1. SQL (default): `DB_BACKEND=sql` (uses `DATABASE_URL`, default `sqlite:///./social_pub_hub.db`)
2. MongoDB: `DB_BACKEND=mongo` with `MONGODB_URI` (default `mongodb://127.0.0.1:27017/social_pub_hub`)
3. Optional Mongo DB override: `MONGODB_DB=<db_name>`

Testing:
1. Full gate (recommended): `./scripts/gate.sh`
2. Flutter only: `cd app && flutter analyze && flutter test`
3. Backend only: `cd backend && ./.venv/bin/pip install -r requirements.txt && ./.venv/bin/python -m pytest -q`

CI:
1. GitHub Actions workflow: `.github/workflows/ci.yml`

Key workflow:
1. Open Inbox, select source items, click "Create draft from selected".
2. Compose opens with canonical draft. Optional: click "Polish draft" for LLM publish pass.
3. Filter variants by platform, run Humanize, then copy/open composer/queue/confirm post.
4. Use Settings to tune style profile and run sync.

Navigation menu (home side menu equivalent):
1. Inbox: capture source items, select items, create grounded draft.
2. Library: search/filter sources; create drafts; attach sources to bundles.
3. Compose: write draft, LLM polish, generate/humanize variants, publish actions.
4. Bundles: build YouTube/social bundle with anchor + linked variants.
5. Bundle Checklist: readiness checks, backfill variants, canonical linking.
6. Publish: integration status + recent publish logs, with bundle filter.
7. Publish Checklist: pre-publish human-sounding rubric checks.
8. Queue: manage scheduled posts and mark posted/canceled.
9. Sync Conflicts: resolve local-vs-remote data collisions.
10. History: timeline of publish logs, filters, clone variant to new draft.
11. Analytics: posted counts, queue health, platform breakdown.
12. Settings: sync now, style profile controls, integration refresh.

Optional LLM config (backend):
1. `OPENAI_API_KEY=<your key>`
2. `OPENAI_MODEL=gpt-5.3-codex` (or another model)
