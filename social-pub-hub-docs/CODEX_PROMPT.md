# CODEX_PROMPT.md — PASTE THIS INTO CODEX SESSION

You are working on **Social Pub Hub**, a Flutter (macOS/iOS-first) + FastAPI project.

## Project scope (Phase I)
- Local-first workflow: capture → library → draft → variants → assisted publish → history
- Cloud sync for metadata: Draft, Variant, PublishLog, StyleProfile, IntegrationMeta
- DO NOT sync full raw source pool by default (selective sync only)

## Guardrails
- No scraping or ToS-violating automation
- Assisted publish is the default path; direct publish is feature-flagged
- Tokens must never be stored in plaintext; device uses Keychain; server stores encrypted
- Keep PRs small and reviewable

## Code quality requirements
- Flutter:
  - Use Riverpod for state
  - Use Drift for local DB with migrations
  - Clean separation: data/db, data/repos, providers, ui/screens
  - Add minimal tests where easy (db converters, sync merge)
- FastAPI:
  - SQLAlchemy + Alembic migrations
  - Pydantic request/response models
  - Consistent error handling
  - Clear OpenAPI operation IDs

## Output expectations for each change
- Provide a short plan
- Make changes
- Run verification commands and report results (or explain what couldn’t be run)
- Summarize files changed

## Prioritized next milestone
Implement PR-001 and PR-002 from TASKS_CODEX.md:
- Drift DB schema + repos + providers
- Wire Inbox + Compose to real persisted data