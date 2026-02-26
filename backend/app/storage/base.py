from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import datetime
from typing import Any

from app.schemas import SyncPushRequest


class DataStore(ABC):
    backend_name: str

    @abstractmethod
    def setup(self) -> None:
        pass

    @abstractmethod
    def healthcheck(self) -> None:
        pass

    @abstractmethod
    def sync_changes(self, since: int = 0) -> dict[str, Any]:
        pass

    @abstractmethod
    def sync_push(self, payload: SyncPushRequest) -> dict[str, Any]:
        pass

    @abstractmethod
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
        pass

    @abstractmethod
    def get_draft(self, draft_id: str) -> dict[str, Any] | None:
        pass

    @abstractmethod
    def update_draft_markdown(
        self,
        *,
        draft_id: str,
        canonical_markdown: str,
    ) -> dict[str, Any] | None:
        pass

    @abstractmethod
    def get_style_profile(self, style_profile_id: str) -> dict[str, Any] | None:
        pass

    @abstractmethod
    def upsert_variant(
        self,
        *,
        variant_id: str,
        draft_id: str,
        platform: str,
        text: str,
    ) -> dict[str, Any]:
        pass

    @abstractmethod
    def get_variant(self, variant_id: str) -> dict[str, Any] | None:
        pass

    @abstractmethod
    def update_variant_text(
        self,
        *,
        variant_id: str,
        text: str,
    ) -> dict[str, Any] | None:
        pass

    @abstractmethod
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
        pass
