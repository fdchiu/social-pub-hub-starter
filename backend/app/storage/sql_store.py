from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import Base, SessionLocal, engine
from app.models import (
    Bundle,
    Draft,
    Post,
    Project,
    PublishLog,
    ScheduledPost,
    SourceItem,
    StyleProfile,
    SyncCounter,
    Variant,
)
from app.schemas import SyncPushRequest

from .base import DataStore
from .common import (
    SYNC_TABLE_NAMES,
    model_to_dict,
    normalize_content_type,
    to_utc,
    utc_now,
)

TABLE_MODEL_MAP: dict[str, Any] = {
    "source_items": SourceItem,
    "projects": Project,
    "posts": Post,
    "bundles": Bundle,
    "drafts": Draft,
    "variants": Variant,
    "publish_logs": PublishLog,
    "style_profiles": StyleProfile,
    "scheduled_posts": ScheduledPost,
}


class SQLDataStore(DataStore):
    backend_name = "sql"

    def setup(self) -> None:
        Base.metadata.create_all(bind=engine)
        with SessionLocal() as db:
            self._ensure_sync_counter(db)
            db.commit()

    def healthcheck(self) -> None:
        with SessionLocal() as db:
            db.execute(select(1))

    def sync_changes(self, since: int = 0) -> dict[str, Any]:
        upserts: dict[str, list[dict[str, Any]]] = {
            key: [] for key in SYNC_TABLE_NAMES
        }
        deletes: dict[str, list[str]] = {key: [] for key in SYNC_TABLE_NAMES}
        max_cursor = since

        with SessionLocal() as db:
            for table_name, model in TABLE_MODEL_MAP.items():
                rows = db.execute(
                    select(model)
                    .where(model.sync_cursor > since)
                    .order_by(model.sync_cursor.asc())
                ).scalars()
                for row in rows:
                    max_cursor = max(max_cursor, row.sync_cursor)
                    if row.deleted_at is None:
                        upserts[table_name].append(model_to_dict(row, table_name))
                    else:
                        deletes[table_name].append(row.id)

        return {"cursor": max_cursor, "upserts": upserts, "deletes": deletes}

    def sync_push(self, payload: SyncPushRequest) -> dict[str, Any]:
        with SessionLocal() as db:
            for table_name, model in TABLE_MODEL_MAP.items():
                for item in getattr(payload.upserts, table_name):
                    self._apply_upsert(db, table_name, model, item.model_dump())

            for table_name, model in TABLE_MODEL_MAP.items():
                for entity_id in getattr(payload.deletes, table_name):
                    self._soft_delete(db, model, entity_id)

            db.commit()
            cursor = self._ensure_sync_counter(db).value
        return {"cursor": cursor, "status": "ok"}

    def create_draft(
        self,
        *,
        draft_id: str,
        canonical_markdown: str,
        intent: str | None,
        tone: float | None,
        punchiness: float | None,
        emoji_level: str | None,
        audience: str | None,
        post_id: str | None,
        content_type: str | None,
    ) -> dict[str, Any]:
        now = utc_now()
        with SessionLocal() as db:
            draft = Draft(
                id=draft_id,
                canonical_markdown=canonical_markdown,
                intent=intent,
                tone=tone,
                punchiness=punchiness,
                emoji_level=emoji_level,
                audience=audience,
                post_id=post_id,
                content_type=normalize_content_type(content_type),
                created_at=now,
                updated_at=now,
                deleted_at=None,
                sync_cursor=self._next_cursor(db),
            )
            db.add(draft)
            db.commit()
            db.refresh(draft)
            return model_to_dict(draft, "drafts")

    def get_draft(self, draft_id: str) -> dict[str, Any] | None:
        with SessionLocal() as db:
            row = db.get(Draft, draft_id)
            if row is None or row.deleted_at is not None:
                return None
            return model_to_dict(row, "drafts")

    def update_draft_markdown(
        self,
        *,
        draft_id: str,
        canonical_markdown: str,
    ) -> dict[str, Any] | None:
        with SessionLocal() as db:
            row = db.get(Draft, draft_id)
            if row is None or row.deleted_at is not None:
                return None
            row.canonical_markdown = canonical_markdown
            row.updated_at = utc_now()
            row.sync_cursor = self._next_cursor(db)
            db.commit()
            db.refresh(row)
            return model_to_dict(row, "drafts")

    def get_style_profile(self, style_profile_id: str) -> dict[str, Any] | None:
        with SessionLocal() as db:
            row = db.get(StyleProfile, style_profile_id)
            if row is None or row.deleted_at is not None:
                return None
            return model_to_dict(row, "style_profiles")

    def upsert_variant(
        self,
        *,
        variant_id: str,
        draft_id: str,
        platform: str,
        text: str,
    ) -> dict[str, Any]:
        now = utc_now()
        with SessionLocal() as db:
            row = db.get(Variant, variant_id)
            if row is None:
                row = Variant(
                    id=variant_id,
                    draft_id=draft_id,
                    platform=platform,
                    text=text,
                    created_at=now,
                    updated_at=now,
                    deleted_at=None,
                )
                db.add(row)
            else:
                row.draft_id = draft_id
                row.platform = platform
                row.text = text
                row.updated_at = now
                row.deleted_at = None

            row.sync_cursor = self._next_cursor(db)
            db.commit()
            db.refresh(row)
            return model_to_dict(row, "variants")

    def get_variant(self, variant_id: str) -> dict[str, Any] | None:
        with SessionLocal() as db:
            row = db.get(Variant, variant_id)
            if row is None or row.deleted_at is not None:
                return None
            return model_to_dict(row, "variants")

    def update_variant_text(
        self,
        *,
        variant_id: str,
        text: str,
    ) -> dict[str, Any] | None:
        with SessionLocal() as db:
            row = db.get(Variant, variant_id)
            if row is None or row.deleted_at is not None:
                return None
            row.text = text
            row.updated_at = utc_now()
            row.sync_cursor = self._next_cursor(db)
            db.commit()
            db.refresh(row)
            return model_to_dict(row, "variants")

    def create_publish_log(
        self,
        *,
        log_id: str,
        variant_id: str | None,
        post_id: str | None,
        platform: str,
        mode: str,
        status: str,
        external_url: str | None,
        posted_at: datetime | None,
    ) -> dict[str, Any]:
        now = utc_now()
        with SessionLocal() as db:
            row = PublishLog(
                id=log_id,
                variant_id=variant_id,
                post_id=post_id,
                platform=platform,
                mode=mode,
                status=status,
                external_url=external_url,
                posted_at=to_utc(posted_at) if posted_at else now,
                created_at=now,
                updated_at=now,
                deleted_at=None,
                sync_cursor=self._next_cursor(db),
            )
            db.add(row)
            db.commit()
            db.refresh(row)
            return model_to_dict(row, "publish_logs")

    @staticmethod
    def _ensure_sync_counter(db: Session) -> SyncCounter:
        counter = db.get(SyncCounter, 1)
        if counter is None:
            counter = SyncCounter(id=1, value=0)
            db.add(counter)
            db.flush()
        return counter

    def _next_cursor(self, db: Session) -> int:
        counter = self._ensure_sync_counter(db)
        counter.value += 1
        db.flush()
        return counter.value

    def _apply_upsert(
        self,
        db: Session,
        table_name: str,
        model: Any,
        payload: dict[str, Any],
    ) -> None:
        now = utc_now()
        entity_id = payload["id"]
        incoming_updated_at = to_utc(payload.get("updated_at"))
        row = db.get(model, entity_id)

        if row is not None and incoming_updated_at <= to_utc(row.updated_at):
            return

        if row is None:
            created_at = payload.get("created_at")
            row = model(
                id=entity_id,
                created_at=to_utc(created_at) if created_at else now,
            )
            db.add(row)

        for field, value in payload.items():
            if field in {"id", "created_at", "updated_at", "deleted_at"}:
                continue
            if not hasattr(row, field):
                continue
            if field == "content_type":
                value = normalize_content_type(value)
            elif field in {"scheduled_for", "posted_at"} and value is not None:
                value = to_utc(value)
            setattr(row, field, value)

        row.updated_at = incoming_updated_at
        deleted_at = payload.get("deleted_at")
        row.deleted_at = to_utc(deleted_at) if deleted_at else None
        row.sync_cursor = self._next_cursor(db)

    def _soft_delete(self, db: Session, model: Any, entity_id: str) -> None:
        row = db.get(model, entity_id)
        if row is None:
            return

        now = utc_now()
        row.deleted_at = now
        row.updated_at = now
        row.sync_cursor = self._next_cursor(db)
