# MVP Backlog & Sprint Plan (Phase I)

## Sprint 0 (Setup)
- Repo scaffolding (Flutter apps + FastAPI)
- CI: lint + unit tests
- Local dev docker compose (FastAPI + Postgres + MinIO optional)

## Sprint 1 — Local-first core (macOS in Flutter)
- Local SQLite schema + migrations
- Inbox: add URL/note/snippet + tags
- Library: list/search/filter
- Composer: canonical editor
- Variant Studio: platform tabs + basic constraints
- History: PublishLog list (manual entry)

Definition of done:
- You can create a draft, generate variants (stub), and store history locally.

## Sprint 2 — iOS capture + sync
- iOS Share Sheet capture (native extension + Flutter bridge)
- Sync engine: delta pull/push
- FastAPI sync endpoints + Postgres persistence
- Attachment upload via signed URL
- Conflict strategy: LWW + manual “choose version” on collisions

DoD:
- Capture on iOS appears on macOS within 1 minute.

## Sprint 3 — RAG + style engine v1
- URL readability extraction + PDF text extraction (server-side)
- Chunk + embed + semantic search (pgvector)
- Draft-from-sources pipeline: outline → canonical draft
- Variants generator templates for X/LI/Reddit/FB/YT
- Humanize pass + “Sounds like me” rating loop

DoD:
- Select 3 sources → get a canonical + 4 variants that require only edits.

## Sprint 4 — Publishing console (assisted-first)
- Integration status UI
- Assisted publish:
  - copy
  - open composer URL
  - confirm posted + optional external URL
- Optional direct publish adapter skeleton (feature-flagged)

DoD:
- End-to-end: capture → draft → variants → assisted publish → history.

## Sprint 5 — Bundles (YouTube compound)
- Bundle entity + UI
- YouTube metadata templates
- Social cross-post generator referencing the bundle anchor
- “Publish checklist” view

DoD:
- Create a bundle around a YouTube idea and generate the social wave.

## Post-MVP (Phase II)
- Trend ingestion (RSS + Reddit + optional platform APIs)
- Scheduling and queues
- Analytics where permitted
- Team workflow + approvals

