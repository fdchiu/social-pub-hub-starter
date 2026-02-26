# Data Model — Phase I (MVP)

## 1. Conventions
- IDs: UUIDv7 recommended (sortable); UUIDv4 acceptable for MVP
- Timestamps: UTC ISO8601
- Soft-delete: `deleted_at` where needed

## 2. Entities

### 2.1 SourceItem
Represents captured raw material.

Fields:
- `id` (uuid)
- `type` enum: `url | note | pdf | image | snippet`
- `url` (nullable)
- `title` (nullable)
- `author` (nullable)
- `publisher` (nullable)
- `captured_text` (nullable)
- `user_note` (nullable)
- `tags` (string[])
- `collection_id` (nullable)
- `attachments` (json: object store keys)
- `created_at`, `updated_at`

Indexes:
- (publisher), (created_at), GIN(tags), full-text on title+captured_text+user_note

### 2.2 KnowledgeChunk
Chunked text used for retrieval.

Fields:
- `id`
- `source_item_id`
- `chunk_text`
- `embedding` (vector)
- `chunk_index` (int)
- `created_at`

### 2.3 TopicCard
Daily suggested topic.

Fields:
- `id`
- `title`
- `angle` enum: `hot_take | how_to | postmortem | leadership | vc_lens | explainer`
- `why_now` (text)
- `tags` (string[])
- `linked_source_ids` (uuid[])
- `created_at`

### 2.4 Draft
Canonical draft in Markdown.

Fields:
- `id`
- `canonical_markdown`
- `intent` enum (same as angle; plus `announcement`)
- `tone` float 0..1 (casual→formal)
- `punchiness` float 0..1
- `emoji_level` enum: `none | light | medium`
- `audience` enum: `engineers | founders | investors | general`
- `created_at`, `updated_at`

### 2.5 Variant
Platform-specific rendering of a Draft.

Fields:
- `id`
- `draft_id`
- `platform` enum: `x | linkedin | reddit | facebook | youtube | substack | medium`
- `text`
- `hook` (nullable)
- `cta` (nullable)
- `hashtags` (string[])
- `constraints_json` (json)
- `created_at`, `updated_at`

### 2.6 Bundle
Compound effect grouping.

Fields:
- `id`
- `name`
- `anchor_type` enum: `youtube | social`
- `anchor_ref` (string) # youtubeVideoId or draftId/variantId
- `related_variant_ids` (uuid[])
- `created_at`, `updated_at`

### 2.7 PublishLog
Tracks publishing actions.

Fields:
- `id`
- `variant_id`
- `platform`
- `mode` enum: `assisted | direct`
- `status` enum: `draft | posted | failed`
- `external_post_url` (nullable)
- `posted_at` (nullable)
- `error_message` (nullable)
- `notes` (nullable)
- `created_at`

### 2.8 StyleProfile
Defines your writing voice.

Fields:
- `id`
- `voice_name` (default: "David")
- `casual_formal` float 0..1
- `punchiness` float 0..1
- `emoji_level` enum
- `banned_phrases` (string[])
- `preferred_patterns` (string[]) # e.g., "Hook→Bullets→Takeaway→Question"
- `overused_words` (string[])
- `exemplar_variant_ids` (uuid[])
- `created_at`, `updated_at`

## 3. Relationships
- SourceItem 1—N KnowledgeChunk
- Draft 1—N Variant
- Variant 1—N PublishLog
- Bundle N—N Variant (store variant ids)
- StyleProfile references Variants as exemplars

## 4. Minimal constraints per platform (Phase I)
- X: character limit enforced client-side (configurable, depends on API/account)
- LinkedIn: longer form; avoid heavy hashtags
- Reddit: avoid marketing tone; encourage genuine question
- Facebook: friendly tone
- YouTube: templates for title/desc/chapters/pinned comment

