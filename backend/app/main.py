from __future__ import annotations

from contextlib import asynccontextmanager
import os
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

import httpx
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import Base, SessionLocal, engine, get_db
from .models import (
    Bundle,
    Draft,
    Post,
    Project,
    PublishLog,
    ScheduledPost,
    SourceItem,
    SYNC_TABLES,
    StyleProfile,
    SyncCounter,
    Variant,
    utc_now,
)
from .schemas import (
    BundleSyncItem,
    DraftFromSourcesRequest,
    DraftPolishRequest,
    DraftVariantsRequest,
    DraftSyncItem,
    PublishConfirmRequest,
    PublishLogSyncItem,
    PostSyncItem,
    ProjectSyncItem,
    ScheduledPostSyncItem,
    SourceItemSyncItem,
    StyleProfileSyncItem,
    SyncPushRequest,
    SourceMaterial,
    VariantHumanizeRequest,
    VariantSyncItem,
)


@asynccontextmanager
async def _lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        _ensure_sync_counter(db)
        db.commit()
    yield


app = FastAPI(title="Social Pub Hub API", lifespan=_lifespan)


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


def _serialize_project(item: Project) -> dict[str, Any]:
    return {
        "id": item.id,
        "name": item.name,
        "description": item.description,
        "status": item.status,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_post(item: Post) -> dict[str, Any]:
    return {
        "id": item.id,
        "project_id": item.project_id,
        "title": item.title,
        "content_type": item.content_type,
        "goal": item.goal,
        "audience": item.audience,
        "status": item.status,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_source_item(item: SourceItem) -> dict[str, Any]:
    return {
        "id": item.id,
        "type": item.type,
        "url": item.url,
        "title": item.title,
        "user_note": item.user_note,
        "tags": item.tags,
        "bundle_id": item.bundle_id,
        "post_id": item.post_id,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_bundle(item: Bundle) -> dict[str, Any]:
    return {
        "id": item.id,
        "name": item.name,
        "anchor_type": item.anchor_type,
        "anchor_ref": item.anchor_ref,
        "canonical_draft_id": item.canonical_draft_id,
        "post_id": item.post_id,
        "related_variant_ids": item.related_variant_ids,
        "notes": item.notes,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_draft(item: Draft) -> dict[str, Any]:
    return {
        "id": item.id,
        "canonical_markdown": item.canonical_markdown,
        "intent": item.intent,
        "tone": item.tone,
        "punchiness": item.punchiness,
        "emoji_level": item.emoji_level,
        "audience": item.audience,
        "post_id": item.post_id,
        "content_type": item.content_type,
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
        "post_id": item.post_id,
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
        "personal_traits": item.personal_traits,
        "differentiation_points": item.differentiation_points,
        "custom_prompt": item.custom_prompt,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "deleted_at": item.deleted_at,
    }


def _serialize_scheduled_post(item: ScheduledPost) -> dict[str, Any]:
    return {
        "id": item.id,
        "variant_id": item.variant_id,
        "post_id": item.post_id,
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
    if name == "source_items":
        return _serialize_source_item(item)
    if name == "projects":
        return _serialize_project(item)
    if name == "posts":
        return _serialize_post(item)
    if name == "bundles":
        return _serialize_bundle(item)
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


def _apply_source_item_upsert(db: Session, payload: SourceItemSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(SourceItem, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = SourceItem(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.type = payload.type
    item.url = payload.url
    item.title = payload.title
    item.user_note = payload.user_note
    item.tags = payload.tags
    item.bundle_id = payload.bundle_id
    item.post_id = payload.post_id
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_project_upsert(db: Session, payload: ProjectSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Project, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = Project(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.name = payload.name
    item.description = payload.description
    item.status = payload.status
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_post_upsert(db: Session, payload: PostSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Post, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = Post(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.project_id = payload.project_id
    item.title = payload.title
    item.content_type = payload.content_type
    item.goal = payload.goal
    item.audience = payload.audience
    item.status = payload.status
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_bundle_upsert(db: Session, payload: BundleSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Bundle, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = Bundle(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.name = payload.name
    item.anchor_type = payload.anchor_type
    item.anchor_ref = payload.anchor_ref
    item.canonical_draft_id = payload.canonical_draft_id
    item.post_id = payload.post_id
    item.related_variant_ids = payload.related_variant_ids
    item.notes = payload.notes
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_draft_upsert(db: Session, payload: DraftSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Draft, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
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
    item.post_id = payload.post_id
    item.content_type = payload.content_type
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_variant_upsert(db: Session, payload: VariantSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(Variant, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
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

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = PublishLog(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.variant_id = payload.variant_id
    item.post_id = payload.post_id
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

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
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
    item.personal_traits = payload.personal_traits
    item.differentiation_points = payload.differentiation_points
    item.custom_prompt = payload.custom_prompt
    item.updated_at = incoming_updated_at
    item.deleted_at = _to_utc(payload.deleted_at) if payload.deleted_at else None
    item.sync_cursor = _next_cursor(db)


def _apply_scheduled_post_upsert(db: Session, payload: ScheduledPostSyncItem) -> None:
    now = utc_now()
    incoming_updated_at = _to_utc(payload.updated_at)
    item = db.get(ScheduledPost, payload.id)

    if item is not None and incoming_updated_at <= _to_utc(item.updated_at):
        return

    if item is None:
        item = ScheduledPost(
            id=payload.id,
            created_at=_to_utc(payload.created_at) if payload.created_at else now,
        )
        db.add(item)

    item.variant_id = payload.variant_id
    item.post_id = payload.post_id
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


def _source_material_snippet(material: SourceMaterial) -> str:
    if material.note and material.note.strip():
        return material.note.strip()
    if material.title and material.title.strip():
        return material.title.strip()
    if material.url and material.url.strip():
        return material.url.strip()
    if material.tags:
        return ", ".join(material.tags[:4])
    return material.id


def _canonical_template(
    intent: str,
    source_ids: list[str],
    audience: str,
    source_materials: list[SourceMaterial],
    content_type: str,
    post_title: str | None,
    post_goal: str | None,
    style_traits: list[str],
    differentiation_points: list[str],
    personal_prompt: str | None,
) -> str:
    source_hint = ", ".join(source_ids[:3]) if source_ids else "recent captures"
    evidence_lines = [
        f"- {_source_material_snippet(material)}"
        for material in source_materials[:3]
        if _source_material_snippet(material)
    ]
    evidence_block = (
        "\n".join(evidence_lines)
        if evidence_lines
        else "- What changed\n- Why it matters now\n- One tradeoff I would watch"
    )
    normalized_type = (content_type or "general_post").strip().lower()
    title_line = f"Title: {post_title.strip()}\n\n" if post_title and post_title.strip() else ""
    goal_line = f"Goal: {post_goal.strip()}\n\n" if post_goal and post_goal.strip() else ""
    traits_line = (
        f"Style traits: {', '.join(style_traits[:6])}\n"
        if style_traits
        else ""
    )
    diff_line = (
        f"Differentiation points: {', '.join(differentiation_points[:6])}\n"
        if differentiation_points
        else ""
    )
    prompt_line = (
        f"Personal prompt: {personal_prompt.strip()}\n"
        if personal_prompt and personal_prompt.strip()
        else ""
    )
    style_block = (
        f"{traits_line}{diff_line}{prompt_line}".strip()
        if (traits_line or diff_line or prompt_line)
        else "Style traits: practical, direct, specific"
    )

    if normalized_type == "coding_guide":
        return (
            "# Draft\n\n"
            f"{title_line}{goal_line}"
            f"Hook: Practical coding guide for {audience}; source baseline from {source_hint}.\n\n"
            "## Problem and context\n"
            f"{evidence_block}\n\n"
            "## Prerequisites\n"
            "- Environment\n- Dependencies\n- Constraints\n\n"
            "## Step-by-step implementation\n"
            "- Step 1\n- Step 2\n- Step 3\n\n"
            "## Pitfalls and tradeoffs\n"
            "- What can fail\n- What to monitor\n\n"
            "## Verification checklist\n"
            "- Test case\n- Expected output\n\n"
            f"{style_block}\n"
        )
    if normalized_type == "ai_tool_guide":
        return (
            "# Draft\n\n"
            f"{title_line}{goal_line}"
            f"Hook: Applied AI tool guide for {audience}; evidence from {source_hint}.\n\n"
            "## Use-case\n"
            f"{evidence_block}\n\n"
            "## Tool setup\n"
            "- Account/model/config\n\n"
            "## Prompt template\n"
            "```text\nRole:\nInput:\nConstraints:\nOutput format:\n```\n\n"
            "## Parameters and iteration loop\n"
            "- Temperature / tokens / retries\n- Quality checks\n\n"
            "## Failure modes and guardrails\n"
            "- Hallucination control\n- Privacy boundaries\n\n"
            "## Cost/time notes\n"
            "- Approximate run cost\n- Latency tradeoffs\n\n"
            f"{style_block}\n"
        )
    return (
        "# Draft\n\n"
        f"{title_line}{goal_line}"
        f"Hook: My latest {intent.replace('_', ' ')} for {audience} came from {source_hint}.\n\n"
        f"{evidence_block}\n\n"
        "Takeaway: Keep it simple, then iterate from feedback.\n\n"
        f"{style_block}\n"
        "Question: What would you test first?"
    )


def _variant_template(platform: str, canonical: str, content_type: str) -> str:
    first_line = canonical.splitlines()[2] if len(canonical.splitlines()) > 2 else "Quick take:"
    bullet = "•"
    normalized_type = (content_type or "general_post").strip().lower()

    if normalized_type == "coding_guide" and platform == "x":
        return (
            f"{first_line}\n\n"
            f"{bullet} Problem\n{bullet} Fix\n{bullet} Verify\n\n"
            "Need a deeper walkthrough?"
        )
    if normalized_type == "ai_tool_guide" and platform == "x":
        return (
            f"{first_line}\n\n"
            f"{bullet} Prompt shape\n{bullet} Guardrail\n{bullet} Cost note\n\n"
            "What tool should I benchmark next?"
        )

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


def _generate_variant_with_llm(
    platform: str,
    canonical: str,
    content_type: str,
    style: StyleProfile | None,
) -> tuple[str | None, str | None, str | None]:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None, None, "OPENAI_API_KEY missing"

    model = os.getenv("OPENAI_MODEL", "gpt-5.3-codex")
    style_traits = ", ".join(style.personal_traits) if style else ""
    differentiation = ", ".join(style.differentiation_points) if style else ""
    custom_prompt = style.custom_prompt.strip() if style and style.custom_prompt else ""
    banned = ", ".join(style.banned_phrases) if style and style.banned_phrases else "none"

    system_prompt = (
        "You rewrite canonical markdown into platform-ready social variants. "
        "Output plain text only. Keep it concrete and human."
    )
    user_prompt = (
        f"Platform: {platform}\n"
        f"Content type: {content_type}\n"
        f"Style traits: {style_traits or 'practical, direct, specific'}\n"
        f"Differentiation points: {differentiation or 'none'}\n"
        f"Personal prompt: {custom_prompt or 'none'}\n"
        f"Banned phrases: {banned}\n\n"
        "Canonical draft:\n"
        f"{canonical}\n\n"
        "Constraints:\n"
        "- keep to one platform-ready post\n"
        "- preserve claims from source draft\n"
        "- concise, specific, no fluff\n"
        "- include one natural CTA/question at the end"
    )

    payload = {
        "model": model,
        "temperature": 0.5,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }

    try:
        with httpx.Client(timeout=35.0) as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        if response.status_code < 200 or response.status_code >= 300:
            return None, model, f"OpenAI HTTP {response.status_code}"

        parsed = response.json()
        choices = parsed.get("choices")
        if not isinstance(choices, list) or not choices:
            return None, model, "No choices returned"
        message = choices[0].get("message", {})
        text = _content_to_text(message.get("content")).strip()
        if not text:
            return None, model, "LLM returned empty content"
        return text, model, None
    except Exception as exc:  # pragma: no cover - network/runtime dependent
        return None, model, f"{exc}"


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


def _fallback_polish(
    canonical_markdown: str,
    strictness: float,
    banned: list[str],
) -> str:
    return _humanize_text(canonical_markdown, strictness, banned)


def _content_to_text(value: Any) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        parts: list[str] = []
        for part in value:
            if isinstance(part, str):
                parts.append(part)
                continue
            if isinstance(part, dict):
                text = part.get("text")
                if isinstance(text, str):
                    parts.append(text)
        return "\n".join(part for part in parts if part.strip()).strip()
    return ""


def _polish_with_llm(
    canonical_markdown: str,
    source_materials: list[SourceMaterial],
    strictness: float,
    banned: list[str],
) -> tuple[str | None, str | None, str | None]:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None, None, "OPENAI_API_KEY missing"

    model = os.getenv("OPENAI_MODEL", "gpt-5.3-codex")
    evidence_lines = []
    for index, material in enumerate(source_materials[:8], start=1):
        snippet = _source_material_snippet(material)
        evidence_lines.append(
            f"[S{index}] id={material.id} type={material.type or 'unknown'} "
            f"url={material.url or 'n/a'} :: {snippet}"
        )
    evidence_block = (
        "\n".join(evidence_lines)
        if evidence_lines
        else "[S1] No explicit source material provided."
    )
    banned_block = ", ".join(phrase for phrase in banned if phrase) or "none"

    system_prompt = (
        "You edit social content drafts for clarity and human voice. "
        "Use only the provided evidence. "
        "If evidence is thin, keep statements cautious. "
        "Return markdown only."
    )
    user_prompt = (
        "Polish this draft for publish readiness.\n\n"
        f"Strictness: {strictness:.1f}\n"
        f"Banned phrases: {banned_block}\n\n"
        f"Evidence pack:\n{evidence_block}\n\n"
        f"Draft:\n{canonical_markdown}\n\n"
        "Output requirements:\n"
        "- keep core meaning\n"
        "- remove banned phrasing\n"
        "- concise, concrete, personal tone\n"
        "- no extra preface, markdown only"
    )

    payload = {
        "model": model,
        "temperature": 0.4,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }

    try:
        with httpx.Client(timeout=35.0) as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        if response.status_code < 200 or response.status_code >= 300:
            return None, model, f"OpenAI HTTP {response.status_code}"

        parsed = response.json()
        choices = parsed.get("choices")
        if not isinstance(choices, list) or not choices:
            return None, model, "No choices returned"
        message = choices[0].get("message", {})
        content = _content_to_text(message.get("content"))
        text = content.strip()
        if not text:
            return None, model, "LLM returned empty content"
        return text, model, None
    except Exception as exc:  # pragma: no cover - network/runtime dependent
        return None, model, f"{exc}"


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
    for item in payload.upserts.source_items:
        _apply_source_item_upsert(db, item)
    for item in payload.upserts.projects:
        _apply_project_upsert(db, item)
    for item in payload.upserts.posts:
        _apply_post_upsert(db, item)
    for item in payload.upserts.bundles:
        _apply_bundle_upsert(db, item)
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

    for entity_id in payload.deletes.source_items:
        _soft_delete(db, SourceItem, entity_id)
    for entity_id in payload.deletes.projects:
        _soft_delete(db, Project, entity_id)
    for entity_id in payload.deletes.posts:
        _soft_delete(db, Post, entity_id)
    for entity_id in payload.deletes.bundles:
        _soft_delete(db, Bundle, entity_id)
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
    canonical_template = _canonical_template(
        payload.intent,
        payload.source_ids,
        payload.audience,
        payload.source_materials,
        payload.content_type,
        payload.post_title,
        payload.post_goal,
        payload.style_traits,
        payload.differentiation_points,
        payload.personal_prompt,
    )
    polished, model, fallback_reason = _polish_with_llm(
        canonical_markdown=canonical_template,
        source_materials=payload.source_materials,
        strictness=max(payload.punchiness, 0.7),
        banned=[],
    )
    canonical = polished or canonical_template
    draft = Draft(
        id=draft_id,
        canonical_markdown=canonical,
        intent=payload.intent,
        tone=payload.tone,
        punchiness=payload.punchiness,
        audience=payload.audience,
        post_id=payload.post_id,
        content_type=payload.content_type,
        created_at=now,
        updated_at=now,
        sync_cursor=_next_cursor(db),
    )
    db.add(draft)
    db.commit()
    return {
        "draft_id": draft_id,
        "canonical_markdown": canonical,
        "llm_used": polished is not None,
        "model": model,
        "fallback_reason": fallback_reason,
    }


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
    content_type = payload.content_type or draft.content_type or "general_post"
    style: StyleProfile | None = None
    if payload.style_profile_id:
        style = db.get(StyleProfile, payload.style_profile_id)
    variants: list[dict[str, Any]] = []

    for platform in platforms:
        variant_id = f"{draft_id}_{platform}"
        now = utc_now()
        llm_text, model, fallback_reason = _generate_variant_with_llm(
            platform,
            draft.canonical_markdown,
            content_type,
            style,
        )
        variant_text = llm_text or _variant_template(
            platform,
            draft.canonical_markdown,
            content_type,
        )
        banned_phrases = style.banned_phrases if style is not None else []
        if banned_phrases:
            variant_text = _humanize_text(variant_text, 0.7, banned_phrases)
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
                "llm_used": llm_text is not None,
                "model": model,
                "fallback_reason": fallback_reason,
            }
        )

    db.commit()
    return {"variants": variants}


@app.post("/drafts/{draft_id}/polish")
def polish_draft(
    draft_id: str,
    payload: DraftPolishRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    draft = db.get(Draft, draft_id)
    if draft is None:
        raise HTTPException(status_code=404, detail="Draft not found")

    base_text = payload.canonical_markdown.strip() or draft.canonical_markdown
    banned = [phrase for phrase in payload.banned_phrases if phrase.strip()]
    if payload.style_profile_id:
        style = db.get(StyleProfile, payload.style_profile_id)
        if style is not None:
            banned = list({*banned, *style.banned_phrases})

    polished, model, fallback_reason = _polish_with_llm(
        canonical_markdown=base_text,
        source_materials=payload.source_materials,
        strictness=payload.strictness,
        banned=banned,
    )
    canonical = polished or _fallback_polish(
        canonical_markdown=base_text,
        strictness=payload.strictness,
        banned=banned,
    )

    draft.canonical_markdown = canonical
    draft.updated_at = utc_now()
    draft.sync_cursor = _next_cursor(db)
    db.commit()

    return {
        "draft_id": draft.id,
        "canonical_markdown": canonical,
        "llm_used": polished is not None,
        "model": model,
        "fallback_reason": fallback_reason,
    }


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
    draft = db.get(Draft, variant.draft_id)
    publish_log = PublishLog(
        id=_new_id("publish"),
        variant_id=variant.id,
        post_id=draft.post_id if draft is not None else None,
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
