from __future__ import annotations

from datetime import datetime
import os
from typing import Any
from urllib.parse import urlparse

from app.schemas import SyncPushRequest

from .base import DataStore
from .common import (
    SYNC_TABLE_NAMES,
    TABLE_FIELDS,
    normalize_content_type,
    to_utc,
    utc_now,
)


class MongoDataStore(DataStore):
    backend_name = "mongo"

    def __init__(self) -> None:
        try:
            from pymongo import MongoClient  # type: ignore
            from pymongo.collection import Collection  # type: ignore
            from pymongo.database import Database  # type: ignore
            from pymongo import ReturnDocument  # type: ignore
        except ImportError as exc:  # pragma: no cover - depends on runtime env
            raise RuntimeError(
                "DB_BACKEND=mongo requires pymongo. Install with: pip install pymongo"
            ) from exc

        self._MongoClient = MongoClient
        self._Collection = Collection
        self._Database = Database
        self._ReturnDocument = ReturnDocument

        uri = os.getenv("MONGODB_URI", "mongodb://127.0.0.1:27017/social_pub_hub")
        db_name = os.getenv("MONGODB_DB") or self._db_name_from_uri(uri)

        self._client = self._MongoClient(uri, tz_aware=True)
        self._db = self._client[db_name]
        self._meta = self._db["_meta"]

    def setup(self) -> None:
        self._meta.update_one(
            {"_id": "sync_counter"},
            {"$setOnInsert": {"value": 0}},
            upsert=True,
        )
        for table_name in SYNC_TABLE_NAMES:
            self._collection(table_name).create_index("sync_cursor")

    def healthcheck(self) -> None:
        self._client.admin.command("ping")

    def sync_changes(self, since: int = 0) -> dict[str, Any]:
        upserts: dict[str, list[dict[str, Any]]] = {
            key: [] for key in SYNC_TABLE_NAMES
        }
        deletes: dict[str, list[str]] = {key: [] for key in SYNC_TABLE_NAMES}
        max_cursor = since

        for table_name in SYNC_TABLE_NAMES:
            rows = self._collection(table_name).find(
                {"sync_cursor": {"$gt": since}}
            ).sort("sync_cursor", 1)

            for row in rows:
                cursor = int(row.get("sync_cursor", 0))
                max_cursor = max(max_cursor, cursor)
                if row.get("deleted_at") is None:
                    upserts[table_name].append(self._to_public_row(row, table_name))
                else:
                    deletes[table_name].append(row["id"])

        return {"cursor": max_cursor, "upserts": upserts, "deletes": deletes}

    def sync_push(self, payload: SyncPushRequest) -> dict[str, Any]:
        for table_name in SYNC_TABLE_NAMES:
            for item in getattr(payload.upserts, table_name):
                self._apply_upsert(table_name, item.model_dump())

        for table_name in SYNC_TABLE_NAMES:
            for entity_id in getattr(payload.deletes, table_name):
                self._soft_delete(table_name, entity_id)

        counter = self._meta.find_one({"_id": "sync_counter"})
        cursor = int(counter.get("value", 0)) if counter else 0
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
        row = {
            "_id": draft_id,
            "id": draft_id,
            "canonical_markdown": canonical_markdown,
            "intent": intent,
            "tone": tone,
            "punchiness": punchiness,
            "emoji_level": emoji_level,
            "audience": audience,
            "post_id": post_id,
            "content_type": normalize_content_type(content_type),
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
            "sync_cursor": self._next_cursor(),
        }
        self._collection("drafts").replace_one({"_id": draft_id}, row, upsert=True)
        return self._to_public_row(row, "drafts")

    def get_draft(self, draft_id: str) -> dict[str, Any] | None:
        row = self._collection("drafts").find_one({"_id": draft_id, "deleted_at": None})
        if row is None:
            return None
        return self._to_public_row(row, "drafts")

    def update_draft_markdown(
        self,
        *,
        draft_id: str,
        canonical_markdown: str,
    ) -> dict[str, Any] | None:
        now = utc_now()
        cursor = self._next_cursor()
        result = self._collection("drafts").find_one_and_update(
            {"_id": draft_id, "deleted_at": None},
            {
                "$set": {
                    "canonical_markdown": canonical_markdown,
                    "updated_at": now,
                    "sync_cursor": cursor,
                }
            },
            return_document=self._ReturnDocument.AFTER,
        )
        if result is None:
            return None
        return self._to_public_row(result, "drafts")

    def get_style_profile(self, style_profile_id: str) -> dict[str, Any] | None:
        row = self._collection("style_profiles").find_one(
            {"_id": style_profile_id, "deleted_at": None}
        )
        if row is None:
            return None
        return self._to_public_row(row, "style_profiles")

    def upsert_variant(
        self,
        *,
        variant_id: str,
        draft_id: str,
        platform: str,
        text: str,
    ) -> dict[str, Any]:
        now = utc_now()
        existing = self._collection("variants").find_one({"_id": variant_id})
        created_at = existing.get("created_at") if existing else now
        row = {
            "_id": variant_id,
            "id": variant_id,
            "draft_id": draft_id,
            "platform": platform,
            "text": text,
            "created_at": created_at,
            "updated_at": now,
            "deleted_at": None,
            "sync_cursor": self._next_cursor(),
        }
        self._collection("variants").replace_one({"_id": variant_id}, row, upsert=True)
        return self._to_public_row(row, "variants")

    def get_variant(self, variant_id: str) -> dict[str, Any] | None:
        row = self._collection("variants").find_one(
            {"_id": variant_id, "deleted_at": None}
        )
        if row is None:
            return None
        return self._to_public_row(row, "variants")

    def update_variant_text(
        self,
        *,
        variant_id: str,
        text: str,
    ) -> dict[str, Any] | None:
        now = utc_now()
        cursor = self._next_cursor()
        result = self._collection("variants").find_one_and_update(
            {"_id": variant_id, "deleted_at": None},
            {"$set": {"text": text, "updated_at": now, "sync_cursor": cursor}},
            return_document=self._ReturnDocument.AFTER,
        )
        if result is None:
            return None
        return self._to_public_row(result, "variants")

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
        row = {
            "_id": log_id,
            "id": log_id,
            "variant_id": variant_id,
            "post_id": post_id,
            "platform": platform,
            "mode": mode,
            "status": status,
            "external_url": external_url,
            "posted_at": to_utc(posted_at) if posted_at else now,
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
            "sync_cursor": self._next_cursor(),
        }
        self._collection("publish_logs").replace_one({"_id": log_id}, row, upsert=True)
        return self._to_public_row(row, "publish_logs")

    def _apply_upsert(self, table_name: str, payload: dict[str, Any]) -> None:
        now = utc_now()
        entity_id = payload["id"]
        collection = self._collection(table_name)
        row = collection.find_one({"_id": entity_id})
        incoming_updated_at = to_utc(payload.get("updated_at"))

        if row is not None and incoming_updated_at <= to_utc(row.get("updated_at")):
            return

        created_at_value = payload.get("created_at")
        created_at = to_utc(created_at_value) if created_at_value else now
        if row and row.get("created_at"):
            created_at = to_utc(row["created_at"])

        next_row = dict(row or {})
        next_row["_id"] = entity_id
        next_row["id"] = entity_id
        next_row["created_at"] = created_at

        for field, value in payload.items():
            if field in {"id", "created_at", "updated_at", "deleted_at"}:
                continue
            if field == "content_type":
                value = normalize_content_type(value)
            elif field in {"scheduled_for", "posted_at"} and value is not None:
                value = to_utc(value)
            next_row[field] = value

        deleted_at = payload.get("deleted_at")
        next_row["updated_at"] = incoming_updated_at
        next_row["deleted_at"] = to_utc(deleted_at) if deleted_at else None
        next_row["sync_cursor"] = self._next_cursor()

        collection.replace_one({"_id": entity_id}, next_row, upsert=True)

    def _soft_delete(self, table_name: str, entity_id: str) -> None:
        collection = self._collection(table_name)
        row = collection.find_one({"_id": entity_id})
        if row is None:
            return

        now = utc_now()
        collection.update_one(
            {"_id": entity_id},
            {
                "$set": {
                    "deleted_at": now,
                    "updated_at": now,
                    "sync_cursor": self._next_cursor(),
                }
            },
        )

    def _to_public_row(self, row: dict[str, Any], table_name: str) -> dict[str, Any]:
        fields = TABLE_FIELDS[table_name]
        return {field: row.get(field) for field in fields}

    def _next_cursor(self) -> int:
        row = self._meta.find_one_and_update(
            {"_id": "sync_counter"},
            {"$inc": {"value": 1}},
            upsert=True,
            return_document=self._ReturnDocument.AFTER,
        )
        return int(row.get("value", 0))

    def _collection(self, table_name: str):
        return self._db[table_name]

    @staticmethod
    def _db_name_from_uri(uri: str) -> str:
        parsed = urlparse(uri)
        if parsed.path and parsed.path != "/":
            return parsed.path.lstrip("/")
        return "social_pub_hub"
