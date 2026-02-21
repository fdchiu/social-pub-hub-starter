from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import Depends, FastAPI
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import Base, SessionLocal, engine, get_db
from .models import (
    Draft,
    PublishLog,
    SYNC_TABLES,
    StyleProfile,
    SyncCounter,
    Variant,
    utc_now,
)
from .schemas import (
    DraftSyncItem,
    PublishLogSyncItem,
    StyleProfileSyncItem,
    SyncPushRequest,
    VariantSyncItem,
)

app = FastAPI(title="Social Pub Hub API")


def _to_utc(value: datetime | None) -> datetime:
    if value is None:
        return utc_now()
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _ensure_sync_counter(db: Session) -> SyncCounter:
    counter = db.get(SyncCounter, 1)
    if counter is None:
        counter = SyncCounter(id=1, value=0)
        db.add(counter)
        db.flush()
    return counter


def _next_cursor(db: Session) -> int:
    counter = _ensure_sync_counter(db)
    counter.value += 1
    db.flush()
    return counter.value


def _serialize_draft(item: Draft) -> dict[str, Any]:
    return {
        "id": item.id,
        "canonical_markdown": item.canonical_markdown,
        "intent": item.intent,
        "tone": item.tone,
        "punchiness": item.punchiness,
        "emoji_level": item.emoji_level,
        "audience": item.audience,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_variant(item: Variant) -> dict[str, Any]:
    return {
        "id": item.id,
        "draft_id": item.draft_id,
        "platform": item.platform,
        "text": item.text,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_publish_log(item: PublishLog) -> dict[str, Any]:
    return {
        "id": item.id,
        "variant_id": item.variant_id,
        "platform": item.platform,
        "mode": item.mode,
        "status": item.status,
        "external_url": item.external_url,
        "posted_at": item.posted_at,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_style_profile(item: StyleProfile) -> dict[str, Any]:
    return {
        "id": item.id,
        "voice_name": item.voice_name,
        "casual_formal": item.casual_formal,
        "punchiness": item.punchiness,
        "emoji_level": item.emoji_level,
        "banned_phrases": item.banned_phrases,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize(name: str, item: Any) -> dict[str, Any]:
    if name == "drafts":
        return _serialize_draft(item)
    if name == "variants":
        return _serialize_variant(item)
    if name == "publish_logs":
        return _serialize_publish_log(item)
    if name == "style_profiles":
        return _serialize_style_profile(item)
    raise ValueError(f"Unknown sync table: {name}")


def _apply_draft_upsert(db: Session, payload: DraftSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Draft, payload.id)

    if item is not None and incoming_updated_at <= item.updated_at:
        return

    if item is None:
        item = Draft(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.canonical_markdown = payload.canonical_markdown
    item.intent = payload.intent
    item.tone = payload.tone
    item.punchiness = payload.punchiness
    item.emoji_level = payload.emoji_level
    item.audience = payload.audience
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_variant_upsert(db: Session, payload: VariantSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Variant, payload.id)

    if item is not None and incoming_updated_at <= item.updated_at:
        return

    if item is None:
        item = Variant(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.draft_id = payload.draft_id
    item.platform = payload.platform
    item.text = payload.text
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_publish_log_upsert(db: Session, payload: PublishLogSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(PublishLog, payload.id)

    if item is not None and incoming_updated_at <= item.updated_at:
        return

    if item is None:
        item = PublishLog(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.variant_id = payload.variant_id
    item.platform = payload.platform
    item.mode = payload.mode
    item.status = payload.status
    item.external_url = payload.external_url
    item.posted_at = _to_utc(payload.posted_at) if payload.posted_at else None
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_style_profile_upsert(db: Session, payload: StyleProfileSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(StyleProfile, payload.id)

    if item is not None and incoming_updated_at <= item.updated_at:
        return

    if item is None:
        item = StyleProfile(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.voice_name = payload.voice_name
    item.casual_formal = payload.casual_formal
    item.punchiness = payload.punchiness
    item.emoji_level = payload.emoji_level
    item.banned_phrases = payload.banned_phrases
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _soft_delete(db: Session, model: Any, entity_id: str) -> None:
    item = db.get(model, entity_id)
    if item is None:
        return

    now = utc_now()
    item.deleted_at = now
    item.updated_at = now
    item.sync_cursor = _next_cursor(db)


@app.on_event("startup")
def startup() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        _ensure_sync_counter(db)
        db.commit()


@app.get("/health")
def health(db: Session = Depends(get_db)) -> dict[str, str]:
    db.execute(select(1))
    return {"status": "ok"}


@app.get("/integrations")
def integrations() -> dict[str, list[dict[str, Any]]]:
    return {
        "integrations": [
            {
                "platform": "x",
                "connected": False,
                "capabilities": {"direct_publish": False, "media": False},
            },
            {
                "platform": "linkedin",
                "connected": False,
                "capabilities": {"direct_publish": False},
            },
            {
                "platform": "reddit",
                "connected": False,
                "capabilities": {"direct_publish": False},
            },
            {
                "platform": "facebook",
                "connected": False,
                "capabilities": {"direct_publish": False},
            },
            {
                "platform": "youtube",
                "connected": False,
                "capabilities": {"upload": True, "metadata": True},
            },
        ]
    }


@app.get("/sync/changes")
def sync_changes(since: int = 0, db: Session = Depends(get_db)) -> dict[str, Any]:
    upserts: dict[str, list[dict[str, Any]]] = {key: [] for key in SYNC_TABLES}
    deletes: dict[str, list[str]] = {key: [] for key in SYNC_TABLES}
    max_cursor = since

    for name, model in SYNC_TABLES.items():
        rows = db.execute(
            select(model)
            .where(model.sync_cursor > since)
            .order_by(model.sync_cursor.asc())
        ).scalars()

        for row in rows:
            max_cursor = max(max_cursor, row.sync_cursor)
            if row.deleted_at is None:
                upserts[name].append(_serialize(name, row))
            else:
                deletes[name].append(row.id)

    return {"cursor": max_cursor, "upserts": upserts, "deletes": deletes}


@app.post("/sync/push")
def sync_push(payload: SyncPushRequest, db: Session = Depends(get_db)) -> dict[str, Any]:
    for item in payload.upserts.drafts:
        _apply_draft_upsert(db, item)
    for item in payload.upserts.variants:
        _apply_variant_upsert(db, item)
    for item in payload.upserts.publish_logs:
        _apply_publish_log_upsert(db, item)
    for item in payload.upserts.style_profiles:
        _apply_style_profile_upsert(db, item)

    for entity_id in payload.deletes.drafts:
        _soft_delete(db, Draft, entity_id)
    for entity_id in payload.deletes.variants:
        _soft_delete(db, Variant, entity_id)
    for entity_id in payload.deletes.publish_logs:
        _soft_delete(db, PublishLog, entity_id)
    for entity_id in payload.deletes.style_profiles:
        _soft_delete(db, StyleProfile, entity_id)

    db.commit()
    cursor = _ensure_sync_counter(db).value
    return {"cursor": cursor, "status": "ok"}
