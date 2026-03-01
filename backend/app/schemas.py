from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class SourceMaterial(BaseModel):
    id: str
    type: str | None = None
    title: str | None = None
    url: str | None = None
    note: str | None = None
    tags: list[str] = Field(default_factory=list)


class SourceItemSyncItem(BaseModel):
    id: str
    type: str = "note"
    url: str | None = None
    title: str | None = None
    user_note: str | None = None
    tags: list[str] = Field(default_factory=list)
    bundle_id: str | None = None
    project_id: str | None = None
    post_id: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class ProjectSyncItem(BaseModel):
    id: str
    name: str = ""
    description: str | None = None
    status: str = "active"
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class PostSyncItem(BaseModel):
    id: str
    project_id: str | None = None
    title: str = ""
    content_type: str = "general_post"
    goal: str | None = None
    audience: str | None = None
    status: str = "active"
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class BundleSyncItem(BaseModel):
    id: str
    name: str = ""
    anchor_type: str = "youtube"
    anchor_ref: str | None = None
    canonical_draft_id: str | None = None
    post_id: str | None = None
    related_variant_ids: list[str] = Field(default_factory=list)
    notes: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class DraftSyncItem(BaseModel):
    id: str
    canonical_markdown: str = ""
    intent: str | None = None
    tone: float | None = None
    punchiness: float | None = None
    emoji_level: str | None = None
    audience: str | None = None
    post_id: str | None = None
    content_type: str | None = None
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
    post_id: str | None = None
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
    personal_traits: list[str] = Field(default_factory=list)
    differentiation_points: list[str] = Field(default_factory=list)
    custom_prompt: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class ScheduledPostSyncItem(BaseModel):
    id: str
    variant_id: str | None = None
    post_id: str | None = None
    platform: str = ""
    content: str = ""
    scheduled_for: datetime | None = None
    status: str = "queued"
    external_url: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class SyncUpserts(BaseModel):
    source_items: list[SourceItemSyncItem] = Field(default_factory=list)
    projects: list[ProjectSyncItem] = Field(default_factory=list)
    posts: list[PostSyncItem] = Field(default_factory=list)
    bundles: list[BundleSyncItem] = Field(default_factory=list)
    drafts: list[DraftSyncItem] = Field(default_factory=list)
    variants: list[VariantSyncItem] = Field(default_factory=list)
    publish_logs: list[PublishLogSyncItem] = Field(default_factory=list)
    style_profiles: list[StyleProfileSyncItem] = Field(default_factory=list)
    scheduled_posts: list[ScheduledPostSyncItem] = Field(default_factory=list)


class SyncDeletes(BaseModel):
    source_items: list[str] = Field(default_factory=list)
    projects: list[str] = Field(default_factory=list)
    posts: list[str] = Field(default_factory=list)
    bundles: list[str] = Field(default_factory=list)
    drafts: list[str] = Field(default_factory=list)
    variants: list[str] = Field(default_factory=list)
    publish_logs: list[str] = Field(default_factory=list)
    style_profiles: list[str] = Field(default_factory=list)
    scheduled_posts: list[str] = Field(default_factory=list)


class SyncPushRequest(BaseModel):
    upserts: SyncUpserts = Field(default_factory=SyncUpserts)
    deletes: SyncDeletes = Field(default_factory=SyncDeletes)


class DraftFromSourcesRequest(BaseModel):
    source_ids: list[str] = Field(default_factory=list)
    source_materials: list[SourceMaterial] = Field(default_factory=list)
    intent: str = "how_to"
    tone: float = 0.6
    punchiness: float = 0.7
    audience: str = "engineers"
    length_target: str = "short"
    post_id: str | None = None
    post_title: str | None = None
    post_goal: str | None = None
    content_type: str = "general_post"
    style_traits: list[str] = Field(default_factory=list)
    differentiation_points: list[str] = Field(default_factory=list)
    personal_prompt: str | None = None
    banned_phrases: list[str] = Field(default_factory=list)


class DraftPolishRequest(BaseModel):
    canonical_markdown: str = ""
    source_materials: list[SourceMaterial] = Field(default_factory=list)
    style_profile_id: str | None = None
    banned_phrases: list[str] = Field(default_factory=list)
    style_traits: list[str] = Field(default_factory=list)
    differentiation_points: list[str] = Field(default_factory=list)
    personal_prompt: str | None = None
    polish_instruction: str | None = None
    strictness: float = 0.7


class DraftVariantsRequest(BaseModel):
    platforms: list[str] = Field(
        default_factory=lambda: ["x", "linkedin", "substack", "medium"]
    )
    style_profile_id: str | None = None
    content_type: str | None = None


class VariantHumanizeRequest(BaseModel):
    style_profile_id: str | None = None
    strictness: float = 0.7


class PublishConfirmRequest(BaseModel):
    variant_id: str
    external_post_url: str | None = None
    posted_at: datetime | None = None
