# API Spec — Phase I (FastAPI)

## 1. Auth & Integrations

### GET /integrations
Returns integration status and capability matrix.

Response:
```json
{
  "integrations": [
    {"platform":"x","connected":false,"capabilities":{"direct_publish":false,"media":false}},
    {"platform":"linkedin","connected":false,"capabilities":{"direct_publish":false}},
    {"platform":"reddit","connected":false,"capabilities":{"direct_publish":false}},
    {"platform":"facebook","connected":false,"capabilities":{"direct_publish":true}},
    {"platform":"youtube","connected":false,"capabilities":{"upload":true,"metadata":true}}
  ]
}
```

### GET /oauth/{platform}/start
Starts OAuth flow.

### GET /oauth/{platform}/callback
OAuth redirect handler. Stores tokens server-side (encrypted) and returns a success page.

### POST /oauth/{platform}/refresh
Refreshes token if supported.

## 2. Sync

### GET /sync/changes?since=<cursor>
Delta pull. Cursor is server-issued (monotonic).

### POST /sync/push
Batch upsert and delete events from client.

Request:
```json
{
  "upserts": {"source_items":[...], "drafts":[...], "variants":[...], "publish_logs":[...], "style_profiles":[...]},
  "deletes": {"source_items":[...], "drafts":[...], "variants":[...]}
}
```

## 3. Sources & Library

### POST /sources
Create SourceItem.

### GET /sources?query=&tags=&collection_id=
List sources.

### GET /sources/{id}
Fetch single source.

### POST /sources/{id}/extract
Optional: readable text extraction for URLs/PDFs.

### POST /sources/{id}/embed
Chunk + embed; stored to KnowledgeChunk.

### POST /search
Keyword + semantic search over SourceItems/Chunks.

Request:
```json
{"q":"voice agent latency", "tags":["voice"], "limit":20}
```

## 4. Generation

### POST /drafts/from_sources
Creates outline + canonical draft grounded in sources.

Request:
```json
{
  "source_ids":["..."],
  "intent":"how_to",
  "tone":0.6,
  "punchiness":0.7,
  "audience":"engineers",
  "length_target":"short"
}
```

Response:
```json
{"draft_id":"...", "canonical_markdown":"..."}
```

### POST /drafts/{id}/variants
Generate variants for selected platforms.

Request:
```json
{"platforms":["x","linkedin","reddit","facebook","youtube"], "style_profile_id":"..."}
```

Response:
```json
{"variants":[{"id":"...","platform":"x","text":"..."}]}
```

### POST /variants/{id}/humanize
Apply a “humanize pass” using StyleProfile + heuristics.

Request:
```json
{"style_profile_id":"...","strictness":0.7}
```

## 5. Topics (trend-lite)

### POST /topics/daily
Generates daily topic cards based on:
- your library tags
- curated feeds list
- reddit subreddit list (read-only)

Request:
```json
{"tags":["emotion-ai","voice-agents"], "subreddits":["MachineLearning","LocalLLaMA"], "feeds":["https://.../rss"]}
```

## 6. Publishing

### POST /publish/{platform}
Publishes a variant.

Request:
```json
{"variant_id":"..."}
```

Response (assisted):
```json
{"mode":"assisted","copy":"...","open_url":"https://..."}
```

Response (direct):
```json
{"mode":"direct","status":"posted","external_post_url":"https://..."}
```

### POST /publish/confirm
For assisted mode: user confirms and optionally provides external URL.

Request:
```json
{"variant_id":"...","external_post_url":"...","posted_at":"2026-02-20T21:00:00Z"}
```

## 7. Uploads
### POST /upload/sign
Returns signed URL for object upload.

Request:
```json
{"filename":"paper.pdf","content_type":"application/pdf","bytes":123456}
```

