from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import Base, SessionLocal, engine, get_db
from .models import (
    Draft,
    PublishLog,
    ScheduledPost,
    SYNC_TABLES,
    StyleProfile,
    SyncCounter,
    Variant,
    utc_now,
)
from .schemas import (
    DraftFromSourcesRequest,
    DraftVariantsRequest,
    DraftSyncItem,
    PublishConfirmRequest,
    PublishLogSyncItem,
    ScheduledPostSyncItem,
    StyleProfileSyncItem,
    SyncPushRequest,
    VariantHumanizeRequest,
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


def _serialize_scheduled_post(item: ScheduledPost) -> dict[str, Any]:
    return {
        "id": item.id,
        "variant_id": item.variant_id,
        "platform": item.platform,
        "content": item.content,
        "scheduled_for": item.scheduled_for,
        "status": item.status,
        "external_url": item.external_url,
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
    if name == "scheduled_posts":
        return _serialize_scheduled_post(item)
    raise ValueError(f"Unknown sync table: {name}")


def _new_id(prefix: str) -> str:
    return f"{prefix}_{uuid4().hex}"


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


def _apply_scheduled_post_upsert(db: Session, payload: ScheduledPostSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(ScheduledPost, payload.id)

    if item is not None and incoming_updated_at <= item.updated_at:
        return

    if item is None:
        item = ScheduledPost(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.variant_id = payload.variant_id
    item.platform = payload.platform
    item.content = payload.content
    item.scheduled_for = _to_utc(payload.scheduled_for)
    item.status = payload.status
    item.external_url = payload.external_url
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


def _canonical_template(intent: str, source_ids: list[str], audience: str) -> str:
    source_hint = ", ".join(source_ids[:3]) if source_ids else "recent captures"
    return (
        "# Draft\n\n"
        f"Hook: My latest {intent.replace('_', ' ')} for {audience} came from {source_hint}.\n\n"
        "- What changed\n"
        "- Why it matters now\n"
        "- One tradeoff I would watch\n\n"
        "Takeaway: Keep it simple, then iterate from feedback.\n\n"
        "Question: What would you test first?"
    )


def _variant_template(platform: str, canonical: str) -> str:
    first_line = canonical.splitlines()[2] if len(canonical.splitlines()) > 2 else "Quick take:"
    bullet = "•"

    if platform == "x":
        return f"{first_line}\n\n{bullet} One key detail\n{bullet} One tradeoff\n\nWhat would you add?"
    if platform == "linkedin":
        return (
            f"{first_line}\n\n"
            f"{bullet} Context\n{bullet} Tactic\n{bullet} Result to watch\n\n"
            "Curious how others handle this."
        )
    if platform == "reddit":
        return (
            f"Context: {first_line}\n\n"
            "I tried a lightweight approach and saw mixed results.\n"
            "What would you change first?"
        )
    if platform == "facebook":
        return f"{first_line}\n\nShort version: tested a practical flow, learned a lot.\nWhat do you think?"
    if platform == "youtube":
        return (
            "Title: A practical take on this week’s build decision\n\n"
            "Description:\n"
            "- Context\n- What changed\n- Tradeoff\n\n"
            "Pinned comment: What should I test next?"
        )
    return f"{first_line}\n\nShared summary for {platform}."


def _humanize_text(text: str, strictness: float, banned: list[str]) -> str:
    result = text
    for phrase in banned:
        if phrase:
            result = result.replace(phrase, "")
    if strictness >= 0.6:
        result = result.replace("very ", "").replace("really ", "")
    result = "\n".join(line.rstrip() for line in result.splitlines())
    result = "\n".join(line for line in result.splitlines() if line.strip())
    return result.strip()


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
    for item in payload.upserts.scheduled_posts:
        _apply_scheduled_post_upsert(db, item)

    for entity_id in payload.deletes.drafts:
        _soft_delete(db, Draft, entity_id)
    for entity_id in payload.deletes.variants:
        _soft_delete(db, Variant, entity_id)
    for entity_id in payload.deletes.publish_logs:
        _soft_delete(db, PublishLog, entity_id)
    for entity_id in payload.deletes.style_profiles:
        _soft_delete(db, StyleProfile, entity_id)
    for entity_id in payload.deletes.scheduled_posts:
        _soft_delete(db, ScheduledPost, entity_id)

    db.commit()
    cursor = _ensure_sync_counter(db).value
    return {"cursor": cursor, "status": "ok"}


@app.post("/drafts/from_sources")
def drafts_from_sources(
    payload: DraftFromSourcesRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    draft_id = _new_id("draft")
    now = utc_now()
    canonical = _canonical_template(payload.intent, payload.source_ids, payload.audience)
    draft = Draft(
        id=draft_id,
        canonical_markdown=canonical,
        intent=payload.intent,
        tone=payload.tone,
        punchiness=payload.punchiness,
        audience=payload.audience,
        created_at=now,
        updated_at=now,
        sync_cursor=_next_cursor(db),
    )
    db.add(draft)
    db.commit()
    return {"draft_id": draft_id, "canonical_markdown": canonical}


@app.post("/drafts/{draft_id}/variants")
def draft_variants(
    draft_id: str,
    payload: DraftVariantsRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    draft = db.get(Draft, draft_id)
    if draft is None:
        raise HTTPException(status_code=404, detail="Draft not found")

    platforms = payload.platforms or ["x", "linkedin"]
    variants: list[dict[str, Any]] = []

    for platform in platforms:
        variant_id = f"{draft_id}_{platform}"
        now = utc_now()
        variant_text = _variant_template(platform, draft.canonical_markdown)
        variant = db.get(Variant, variant_id)
        if variant is None:
            variant = Variant(
                id=variant_id,
                draft_id=draft_id,
                platform=platform,
                text=variant_text,
                created_at=now,
                updated_at=now,
            )
            db.add(variant)
        else:
            variant.draft_id = draft_id
            variant.platform = platform
            variant.text = variant_text
            variant.updated_at = now
            variant.deleted_at = None

        variant.sync_cursor = _next_cursor(db)
        variants.append(
            {
                "id": variant.id,
                "platform": variant.platform,
                "text": variant.text,
            }
        )

    db.commit()
    return {"variants": variants}


@app.post("/variants/{variant_id}/humanize")
def variant_humanize(
    variant_id: str,
    payload: VariantHumanizeRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    variant = db.get(Variant, variant_id)
    if variant is None:
        raise HTTPException(status_code=404, detail="Variant not found")

    banned = ["delve", "unlock", "leverage", "game-changer", "seamlessly"]
    if payload.style_profile_id:
        style = db.get(StyleProfile, payload.style_profile_id)
        if style is not None:
            banned = style.banned_phrases

    variant.text = _humanize_text(variant.text, payload.strictness, banned)
    variant.updated_at = utc_now()
    variant.sync_cursor = _next_cursor(db)
    db.commit()

    return {"id": variant.id, "platform": variant.platform, "text": variant.text}


@app.post("/publish/confirm")
def publish_confirm(
    payload: PublishConfirmRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    variant = db.get(Variant, payload.variant_id)
    if variant is None:
        raise HTTPException(status_code=404, detail="Variant not found")

    now = utc_now()
    publish_log = PublishLog(
        id=_new_id("publish"),
        variant_id=variant.id,
        platform=variant.platform,
        mode="assisted",
        status="posted",
        external_url=payload.external_post_url,
        posted_at=_to_utc(payload.posted_at) if payload.posted_at else now,
        created_at=now,
        updated_at=now,
        sync_cursor=_next_cursor(db),
    )
    db.add(publish_log)
    db.commit()

    return {
        "id": publish_log.id,
        "status": publish_log.status,
        "platform": publish_log.platform,
        "external_post_url": publish_log.external_url,
    }
