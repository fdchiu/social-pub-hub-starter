# Architecture — Phase I (MVP)

## 1. High-level overview
A **local-first** Flutter app (macOS + iOS) backed by a thin FastAPI control plane.

**Core principle:** The app is useful even with **zero** direct publishing APIs. Direct publishing is additive.

## 2. Components
### 2.1 Flutter clients
- **macOS app**: primary authoring & library management
- **iOS app**: capture (Share Sheet), quick edits, assisted publish
- Shared code: domain models, editor, variant generator UI, sync client

### 2.2 Native modules (where required)
- OAuth redirect handling + secure token storage (Keychain)
- iOS Share Extension for capture
- Background uploads for large media (YouTube optional)

### 2.3 Backend (FastAPI)
- OAuth callback endpoints (platform integrations)
- Sync API (delta changes)
- AI job API (drafting, variants, humanize, embeddings)
- Publish adapter service (optional direct publish)

### 2.4 Data stores
- **Local**: SQLite (drift/sqlcipher optional)
- **Server**: Postgres (+ pgvector) for sync state, embeddings, publish logs
- **Object storage**: S3/R2 for PDFs/images/video

## 3. Data flow
### 3.1 Capture flow
iOS Share → local DB (SourceItem) → sync push → backend persists → optional async extraction/embedding → sync pull to macOS.

### 3.2 Draft flow (RAG)
Select SourceItems → backend retrieves relevant chunks → outline → canonical draft → variants → humanize pass → return results → stored locally.

### 3.3 Publish flow
Variant → choose network:
- Assisted: copy + open composer URL scheme → user posts → user confirms → PublishLog stored.
- Direct: backend adapter publishes using OAuth token → returns external post URL → PublishLog stored.

### 3.4 Bundle flow
Create Bundle with anchor (YouTube or social) → generate metadata & cross-post variants → publish sequence.

## 4. Core services (backend)
- **Source ingestion**: fetch title/meta; optional readability extraction
- **Chunker**: split text into chunks
- **Embedder**: create embeddings for chunks
- **Retriever**: semantic + keyword retrieval
- **Generator**: outline/draft/variant/humanize pipelines
- **Style engine**: apply StyleProfile constraints, anti-AI heuristics
- **Publish adapters**: network-specific wrappers (optional)

## 5. Client architecture (Flutter)
- State management: Riverpod (recommended) or Bloc
- Offline-first repositories:
  - `SourceRepository`
  - `DraftRepository`
  - `VariantRepository`
  - `PublishLogRepository`
  - `StyleProfileRepository`
- Sync engine:
  - delta-based pull/push
  - conflict resolution (server timestamp + client “last-write-wins” for MVP; per-field later)

## 6. Observability
- Structured logs on backend
- Client local logs for sync/publish debugging
- Audit log for token events and publish attempts

## 7. Trust boundaries
- Tokens: never stored in plaintext; Keychain on device; encrypted at rest server-side
- Generated content: stored with source references for traceability
- User confirmation required for posting (assisted mode)

## 8. Deployment (MVP)
- Backend: single Dockerized FastAPI service + Postgres
- Object store: managed (R2/S3)
- Optional workers: Celery/RQ for long jobs (embedding, extraction, YouTube upload)

