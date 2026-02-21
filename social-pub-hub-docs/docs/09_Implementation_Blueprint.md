# Implementation Blueprint (Flutter + FastAPI)

## 1. Flutter packages (suggested)
- `dio` or `http` for API
- `drift` or `isar` for local DB (Drift recommended for SQL + migrations)
- `flutter_riverpod` for state management
- `go_router` for navigation
- `flutter_markdown` or rich editor (Phase I: Markdown)
- `share_plus` (basic sharing), plus native share extensions for capture

## 2. Backend packages (suggested)
- FastAPI + Pydantic v2
- SQLAlchemy 2 + Alembic
- pgvector
- Celery/RQ for async jobs (optional in MVP)
- boto3-compatible client for object storage

## 3. Native bridging targets
- iOS Share Extension → app group storage → Flutter import
- macOS URL handler for oauth callbacks
- Keychain storage wrappers for tokens

## 4. Feature flags
- `direct_publish_x`
- `direct_publish_facebook_pages`
- `youtube_upload_enabled`

## 5. Minimal endpoints you implement first
- /sync/push, /sync/changes
- /sources, /search
- /drafts/from_sources
- /drafts/{id}/variants
- /variants/{id}/humanize
- /publish/confirm

