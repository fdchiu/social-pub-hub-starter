from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class DraftSyncItem(BaseModel):
    id: str
    canonical_markdown: str = ""
    intent: str | None = None
    tone: float | None = None
    punchiness: float | None = None
    emoji_level: str | None = None
    audience: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class VariantSyncItem(BaseModel):
    id: str
    draft_id: str = ""
    platform: str = ""
    text: str = ""
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class PublishLogSyncItem(BaseModel):
    id: str
    variant_id: str | None = None
    platform: str = ""
    mode: str = "assisted"
    status: str = "draft"
    external_url: str | None = None
    posted_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class StyleProfileSyncItem(BaseModel):
    id: str
    voice_name: str = "David"
    casual_formal: float = 0.6
    punchiness: float = 0.7
    emoji_level: str = "light"
    banned_phrases: list[str] = Field(default_factory=list)
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class ScheduledPostSyncItem(BaseModel):
    id: str
    variant_id: str | None = None
    platform: str = ""
    content: str = ""
    scheduled_for: datetime | None = None
    status: str = "queued"
    external_url: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class SyncUpserts(BaseModel):
    drafts: list[DraftSyncItem] = Field(default_factory=list)
    variants: list[VariantSyncItem] = Field(default_factory=list)
    publish_logs: list[PublishLogSyncItem] = Field(default_factory=list)
    style_profiles: list[StyleProfileSyncItem] = Field(default_factory=list)
    scheduled_posts: list[ScheduledPostSyncItem] = Field(default_factory=list)
    source_items: list[dict] = Field(default_factory=list)


class SyncDeletes(BaseModel):
    drafts: list[str] = Field(default_factory=list)
    variants: list[str] = Field(default_factory=list)
    publish_logs: list[str] = Field(default_factory=list)
    style_profiles: list[str] = Field(default_factory=list)
    scheduled_posts: list[str] = Field(default_factory=list)
    source_items: list[str] = Field(default_factory=list)


class SyncPushRequest(BaseModel):
    upserts: SyncUpserts = Field(default_factory=SyncUpserts)
    deletes: SyncDeletes = Field(default_factory=SyncDeletes)


class DraftFromSourcesRequest(BaseModel):
    source_ids: list[str] = Field(default_factory=list)
    intent: str = "how_to"
    tone: float = 0.6
    punchiness: float = 0.7
    audience: str = "engineers"
    length_target: str = "short"


class DraftVariantsRequest(BaseModel):
    platforms: list[str] = Field(default_factory=lambda: ["x", "linkedin"])
    style_profile_id: str | None = None


class VariantHumanizeRequest(BaseModel):
    style_profile_id: str | None = None
    strictness: float = 0.7


class PublishConfirmRequest(BaseModel):
    variant_id: str
    external_post_url: str | None = None
    posted_at: datetime | None = None
