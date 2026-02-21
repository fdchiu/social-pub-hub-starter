# PRD — Phase I (MVP)

## 1. Product summary
Build a **local-first social publishing hub** that turns your daily work artifacts into **human-sounding** posts and **platform-specific variants** for:
- **X**
- **LinkedIn**
- **Reddit**
- **Facebook Pages**
- **YouTube** (as an anchor: metadata + optional upload pipeline)

Primary UX: macOS for writing + library management; iOS for capture + quick edits.

## 2. Target user and content domains
**Primary persona:** technical founder/leader posting from a personal account.

Domains:
- Emotional AI, ML models, voice agents
- Human-AI interaction, AI perception
- Product development lessons
- Team leadership
- VC trends and startup advice
- LLM systems and applied AI engineering

## 3. Goals (Phase I)
### 3.1 Core outcomes
1) Capture and accumulate raw material (links, snippets, notes, PDFs, screenshots)
2) Maintain a **local knowledge pool** with tags, collections, and semantic search
3) Generate canonical drafts and **variants per network** with constraints
4) Ensure outputs feel **human** (personal cadence, concise, non-corporate)
5) Track post history with sources and “what worked” notes
6) Topic discovery “lite”: daily topic cards derived from your library + curated feeds

### 3.2 Success metrics
- **Idea → ready-to-post** for 3 networks in < **15 minutes**
- ≥ **80%** drafts need only minor edits
- “Sounds like me” self-rating ≥ **4/5**
- ≥ **10** captured items/week reused in drafts within 30 days

## 4. Non-goals (Phase I)
- Full scheduling/analytics for every network
- Team collaboration/approvals
- IG/TikTok direct publishing
- Automated scraping of platforms (ToS risk)

## 5. Key differentiators
- **Local-first + RAG** over your personal knowledge pool
- **Style Engine** that learns from your accepted posts (not raw generations)
- **Bundle workflow** to compound YouTube ↔ social distribution

## 6. Primary user journeys
### Journey A — Capture → Draft → Publish
1. Save a link/snippet with a one-line note (“why this matters”)
2. Select sources → generate outline → canonical draft
3. Generate variants (X/LI/Reddit/FB)
4. Humanize pass + quick edit
5. Publish (assisted or direct) + confirm
6. Saved in history with sources

### Journey B — YouTube anchor bundle
1. Create a “Bundle” with YouTube as anchor (or social post as anchor)
2. Generate YouTube metadata: title/desc/chapters/pinned comment
3. Generate platform variants referencing the anchor
4. Publish in a coordinated burst or sequence

### Journey C — Topic discovery
1. Daily topic cards: “why now” + suggested angle + sources
2. One-click to draft from a topic card

## 7. Functional requirements
### 7.1 Content capture & library
- Add SourceItem: URL, note, tags, attachments (PDF/image)
- Auto-fetch title/description; optional readable text extraction
- Collections (e.g., “Voice Agents”, “Perception Models”, “Leadership”)
- Full-text + semantic search
- “Angles” suggestions per SourceItem (hot take, how-to, postmortem, leadership, VC lens)

### 7.2 Drafting and variants
- Canonical draft editor (Markdown + simple blocks)
- Generate platform variants with constraints:
  - X: 1-3 short paragraphs; optional thread skeleton
  - LinkedIn: hook + 2–4 bullets + takeaway + question CTA
  - Reddit: context-first, minimal marketing; genuine question
  - Facebook: friendly, accessible
  - YouTube: title/desc/chapters/pinned comment templates
- Humanize pass (cadence, banned phrases, “personal touch” insertion)

### 7.3 Publishing & history
- Integration status (connected / not)
- Assisted publish for all networks
- Direct publish where feasible/approved (configurable)
- PublishLog with: mode, status, timestamp, external URL, notes
- Post history with filtering and reuse (“clone draft”)

### 7.4 Style Engine
- StyleProfile sliders: casual↔formal, punchiness, emoji level
- Banned phrase list and “overused words”
- Exemplar posts (manual selection from your history)
- “Sounds like me” rating feedback loop

### 7.5 Trend discovery (lite)
- Curated feeds list (RSS/Atom)
- Reddit read-only endpoints (hot/top) for selected subreddits
- Optional: platform searches if API access allows
- Output: 10 topic cards/day

## 8. Platform requirements
- macOS/iOS priority via Flutter desktop + Flutter iOS
- Offline-first: library and drafts usable offline
- iOS Share Sheet capture
- macOS “Add from clipboard” and URL capture
- Secure token storage (Keychain), encrypted local DB where appropriate

## 9. Risks and mitigations
- **API access/permission gating:** use assisted publish as default.
- **Style drift / AI tell:** style engine learns from accepted posts; ban phrases.
- **Compliance:** avoid scraping; keep human confirmation for posting.
- **Media pipeline scope creep:** YouTube upload optional Phase I.

## 10. Out of scope for now (explicit)
- Automated comment replies, DMs, or engagement bots
- Cross-posting without user review
- Full social analytics dashboard with scraping
