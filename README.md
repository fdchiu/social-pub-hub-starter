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

Next steps:
1. `cd backend && docker compose up --build`
2. `cd app && flutter run -d macos`
