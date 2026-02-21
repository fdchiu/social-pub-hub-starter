# UX / Product Design — Phase I

## 1. Information architecture
Top-level tabs:
1) **Inbox** (captured SourceItems)
2) **Library** (search, tags, collections)
3) **Compose** (drafts, variants, bundles)
4) **Publish** (integration status + publish logs)
5) **Settings** (style profile, feeds, subreddits, defaults)

## 2. Key screens (macOS)
### 2.1 Inbox
- List of recently captured items
- Quick tag + add “why this matters”
- One-click: “Suggest angles”

### 2.2 Library
- Search bar (keyword + semantic toggle)
- Filters: tags, collection, type, date
- Source detail view:
  - title, URL, extracted text
  - your notes
  - “Create draft from this” + “Add to bundle”

### 2.3 Composer (canonical)
- Markdown editor
- Sidebar: selected sources + retrieved snippets
- Controls:
  - intent/angle
  - audience
  - tone slider
  - punchiness slider
  - emoji level

Buttons:
- Generate outline
- Generate canonical
- Generate variants

### 2.4 Variant Studio
- Tabs per platform
- Hard constraints indicators (length, hashtags, formatting)
- Humanize pass toggle + strictness slider
- “Final edit” mode with diffs vs generated

### 2.5 Bundle Builder (YouTube compound)
- Choose anchor: YouTube / Social
- Attach variants
- Generate: YouTube metadata + cross-post set
- Publish checklist

### 2.6 Publish Console
- Integration status cards (connected/capabilities)
- Publish button per variant:
  - assisted: copy + open composer + confirm
  - direct (if available): post and show URL

### 2.7 History
- Timeline of published posts
- Filters: platform, tags, intent
- “Clone as new draft”

## 3. Key screens (iOS)
- Share Sheet capture (URL/text/image)
- Quick tag + note
- Inbox list
- Read-only variant preview
- Assisted publish shortcuts

## 4. “Human-sounding” rubric (in-app checklist)
- Hook in first 1–2 lines
- Short sentences; avoid corporate filler
- One specific detail (number, constraint, tradeoff)
- A personal stance (what you’d do again / avoid)
- End with a genuine question or CTA

## 5. Default style profile (starter)
- casual_formal: 0.6
- punchiness: 0.7
- emoji: light
- preferred pattern: Hook → 2–4 bullets → takeaway → question
- banned phrases: “delve”, “unlock”, “leverage”, “fast-paced world”, “game-changer”
