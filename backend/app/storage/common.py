from __future__ import annotations

from datetime import datetime, timezone
import re
from typing import Any

SYNC_TABLE_NAMES: tuple[str, ...] = (
    "source_items",
    "projects",
    "posts",
    "bundles",
    "drafts",
    "variants",
    "publish_logs",
    "style_profiles",
    "scheduled_posts",
)

TABLE_FIELDS: dict[str, tuple[str, ...]] = {
    "source_items": (
        "id",
        "type",
        "url",
        "title",
        "user_note",
        "tags",
        "bundle_id",
        "post_id",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "projects": (
        "id",
        "name",
        "description",
        "status",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "posts": (
        "id",
        "project_id",
        "title",
        "content_type",
        "goal",
        "audience",
        "status",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "bundles": (
        "id",
        "name",
        "anchor_type",
        "anchor_ref",
        "canonical_draft_id",
        "post_id",
        "related_variant_ids",
        "notes",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "drafts": (
        "id",
        "canonical_markdown",
        "intent",
        "tone",
        "punchiness",
        "emoji_level",
        "audience",
        "post_id",
        "content_type",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "variants": (
        "id",
        "draft_id",
        "platform",
        "text",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "publish_logs": (
        "id",
        "variant_id",
        "post_id",
        "platform",
        "mode",
        "status",
        "external_url",
        "posted_at",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "style_profiles": (
        "id",
        "voice_name",
        "casual_formal",
        "punchiness",
        "emoji_level",
        "banned_phrases",
        "personal_traits",
        "differentiation_points",
        "custom_prompt",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
    "scheduled_posts": (
        "id",
        "variant_id",
        "post_id",
        "platform",
        "content",
        "scheduled_for",
        "status",
        "external_url",
        "created_at",
        "updated_at",
        "deleted_at",
    ),
}


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_utc(value: datetime | None) -> datetime:
    if value is None:
        return utc_now()
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def normalize_content_type(content_type: str | None) -> str:
    raw = (content_type or "general_post").strip().lower()
    sanitized = re.sub(r"[^a-z0-9]+", "_", raw)
    collapsed = re.sub(r"_+", "_", sanitized).strip("_")
    return collapsed or "general_post"


def model_to_dict(item: Any, table_name: str) -> dict[str, Any]:
    fields = TABLE_FIELDS[table_name]
    return {field: getattr(item, field) for field in fields}
