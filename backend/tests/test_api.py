from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

TEST_DB_PATH = Path("./test_social_pub_hub.db")
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from app.db import Base, engine
from app.main import app


def _sync_payload(
    draft_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "upserts": {
            "drafts": draft_rows,
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [],
        },
        "deletes": {
            "drafts": [],
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [],
        },
    }


@pytest.fixture()
def client() -> TestClient:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    with TestClient(app) as test_client:
        yield test_client

    Base.metadata.drop_all(bind=engine)


def test_health_ok(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_sync_push_last_write_wins(client: TestClient) -> None:
    draft_id = "draft_sync_case"
    now = datetime.now(timezone.utc)
    older = now - timedelta(minutes=10)
    newer = now + timedelta(minutes=10)

    first_push = client.post(
        "/sync/push",
        json=_sync_payload(
            [
                {
                    "id": draft_id,
                    "canonical_markdown": "first version",
                    "intent": "how_to",
                    "audience": "builders",
                    "created_at": now.isoformat(),
                    "updated_at": now.isoformat(),
                }
            ]
        ),
    )
    assert first_push.status_code == 200
    first_cursor = first_push.json()["cursor"]
    assert isinstance(first_cursor, int)

    older_push = client.post(
        "/sync/push",
        json=_sync_payload(
            [
                {
                    "id": draft_id,
                    "canonical_markdown": "stale overwrite",
                    "intent": "how_to",
                    "audience": "builders",
                    "created_at": older.isoformat(),
                    "updated_at": older.isoformat(),
                }
            ]
        ),
    )
    assert older_push.status_code == 200

    all_changes = client.get("/sync/changes", params={"since": 0})
    assert all_changes.status_code == 200
    upserts = all_changes.json()["upserts"]["drafts"]
    matching = [row for row in upserts if row["id"] == draft_id]
    assert matching
    assert matching[-1]["canonical_markdown"] == "first version"

    newer_push = client.post(
        "/sync/push",
        json=_sync_payload(
            [
                {
                    "id": draft_id,
                    "canonical_markdown": "newest version",
                    "intent": "how_to",
                    "audience": "builders",
                    "created_at": newer.isoformat(),
                    "updated_at": newer.isoformat(),
                }
            ]
        ),
    )
    assert newer_push.status_code == 200

    delta = client.get("/sync/changes", params={"since": first_cursor})
    assert delta.status_code == 200
    delta_upserts = delta.json()["upserts"]["drafts"]
    matching_delta = [row for row in delta_upserts if row["id"] == draft_id]
    assert matching_delta
    assert matching_delta[-1]["canonical_markdown"] == "newest version"


def test_generation_and_publish_flow(client: TestClient) -> None:
    create_response = client.post(
        "/drafts/from_sources",
        json={
            "source_ids": ["src_1", "src_2"],
            "source_materials": [
                {
                    "id": "src_1",
                    "type": "note",
                    "title": "Release notes",
                    "note": "Latency dropped after cache warmup.",
                    "tags": ["perf", "ops"],
                },
                {
                    "id": "src_2",
                    "type": "url",
                    "url": "https://example.com/post",
                    "note": "Users reported better onboarding completion.",
                    "tags": ["product"],
                },
            ],
            "intent": "how_to",
            "audience": "engineers",
            "tone": 0.6,
            "punchiness": 0.7,
            "length_target": "short",
        },
    )
    assert create_response.status_code == 200
    draft_payload = create_response.json()
    draft_id = draft_payload["draft_id"]
    assert isinstance(draft_id, str) and draft_id
    assert "Hook:" in draft_payload["canonical_markdown"]

    polish_response = client.post(
        f"/drafts/{draft_id}/polish",
        json={
            "canonical_markdown": "We should leverage quick wins for this launch.",
            "source_materials": [
                {
                    "id": "src_1",
                    "note": "Real feedback: simplify steps and ship smaller changes.",
                }
            ],
            "strictness": 0.8,
            "banned_phrases": ["leverage"],
        },
    )
    assert polish_response.status_code == 200
    polished_payload = polish_response.json()
    assert polished_payload["draft_id"] == draft_id
    assert isinstance(polished_payload["canonical_markdown"], str)
    assert "leverage" not in polished_payload["canonical_markdown"].lower()

    variants_response = client.post(
        f"/drafts/{draft_id}/variants",
        json={"platforms": ["x", "linkedin"]},
    )
    assert variants_response.status_code == 200
    variants = variants_response.json()["variants"]
    assert len(variants) == 2
    variant_id = variants[0]["id"]

    humanize_response = client.post(
        f"/variants/{variant_id}/humanize",
        json={"strictness": 0.8},
    )
    assert humanize_response.status_code == 200
    humanized = humanize_response.json()
    assert humanized["id"] == variant_id
    assert isinstance(humanized["text"], str) and humanized["text"]

    external_url = "https://example.com/posts/123"
    publish_response = client.post(
        "/publish/confirm",
        json={
            "variant_id": variant_id,
            "external_post_url": external_url,
            "posted_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    assert publish_response.status_code == 200
    assert publish_response.json()["external_post_url"] == external_url

    changes_response = client.get("/sync/changes", params={"since": 0})
    assert changes_response.status_code == 200
    logs = changes_response.json()["upserts"]["publish_logs"]
    assert any(log["external_url"] == external_url for log in logs)


def test_sync_scheduled_posts_and_deletes(client: TestClient) -> None:
    row_id = "sched_case_1"
    now = datetime.now(timezone.utc)

    create_payload = {
        "upserts": {
            "drafts": [],
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [
                {
                    "id": row_id,
                    "platform": "x",
                    "content": "Ship update tonight",
                    "status": "queued",
                    "scheduled_for": now.isoformat(),
                    "created_at": now.isoformat(),
                    "updated_at": now.isoformat(),
                }
            ],
        },
        "deletes": {
            "drafts": [],
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [],
        },
    }
    push_create = client.post("/sync/push", json=create_payload)
    assert push_create.status_code == 200
    first_cursor = push_create.json()["cursor"]

    changes_after_create = client.get("/sync/changes", params={"since": 0})
    assert changes_after_create.status_code == 200
    scheduled = changes_after_create.json()["upserts"]["scheduled_posts"]
    assert any(row["id"] == row_id and row["status"] == "queued" for row in scheduled)

    delete_payload = {
        "upserts": {
            "drafts": [],
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [],
        },
        "deletes": {
            "drafts": [],
            "variants": [],
            "publish_logs": [],
            "style_profiles": [],
            "scheduled_posts": [row_id],
        },
    }
    push_delete = client.post("/sync/push", json=delete_payload)
    assert push_delete.status_code == 200
    second_cursor = push_delete.json()["cursor"]
    assert second_cursor > first_cursor

    delta = client.get("/sync/changes", params={"since": first_cursor})
    assert delta.status_code == 200
    assert row_id in delta.json()["deletes"]["scheduled_posts"]
