from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import JSON, BigInteger, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class SyncCounter(Base):
    __tablename__ = "sync_counters"

    id: Mapped[int] = mapped_column(primary_key=True)
    value: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)


class Draft(Base):
    __tablename__ = "drafts"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    canonical_markdown: Mapped[str] = mapped_column(Text, default="", nullable=False)
    intent: Mapped[str | None] = mapped_column(String, nullable=True)
    tone: Mapped[float | None] = mapped_column(Float, nullable=True)
    punchiness: Mapped[float | None] = mapped_column(Float, nullable=True)
    emoji_level: Mapped[str | None] = mapped_column(String, nullable=True)
    audience: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_cursor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False, index=True)


class Variant(Base):
    __tablename__ = "variants"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    draft_id: Mapped[str] = mapped_column(String, ForeignKey("drafts.id"), nullable=False)
    platform: Mapped[str] = mapped_column(String, nullable=False)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_cursor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False, index=True)


class PublishLog(Base):
    __tablename__ = "publish_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    variant_id: Mapped[str | None] = mapped_column(String, ForeignKey("variants.id"), nullable=True)
    platform: Mapped[str] = mapped_column(String, nullable=False)
    mode: Mapped[str] = mapped_column(String, nullable=False)
    status: Mapped[str] = mapped_column(String, default="draft", nullable=False)
    external_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    posted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_cursor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False, index=True)


class StyleProfile(Base):
    __tablename__ = "style_profiles"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    voice_name: Mapped[str] = mapped_column(String, default="David", nullable=False)
    casual_formal: Mapped[float] = mapped_column(Float, default=0.6, nullable=False)
    punchiness: Mapped[float] = mapped_column(Float, default=0.7, nullable=False)
    emoji_level: Mapped[str] = mapped_column(String, default="light", nullable=False)
    banned_phrases: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_cursor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False, index=True)


class ScheduledPost(Base):
    __tablename__ = "scheduled_posts"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    variant_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("variants.id"), nullable=True
    )
    platform: Mapped[str] = mapped_column(String, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    scheduled_for: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[str] = mapped_column(String, default="queued", nullable=False)
    external_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_cursor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False, index=True)


SYNC_TABLES = {
    "drafts": Draft,
    "variants": Variant,
    "publish_logs": PublishLog,
    "style_profiles": StyleProfile,
    "scheduled_posts": ScheduledPost,
}
