# Prompt/Style System Spec — Phase I

## 1. Prompt layers
1) **System rules** (always on)
- Be concise, specific, and grounded.
- Prefer short sentences and active voice.
- Avoid corporate filler and hedging.
- Mark opinions as opinions.

2) **StyleProfile** (user-configurable)
- casual_formal (0..1)
- punchiness (0..1)
- emoji_level
- preferred_patterns
- banned_phrases
- exemplar variants (few-shot)

3) **Platform constraints**
- X: short, hook-first, optional thread skeleton
- LinkedIn: hook + bullets + takeaway + question
- Reddit: context + real question; avoid marketing
- Facebook: friendly, accessible
- YouTube: title/desc/chapters/pinned comment templates

## 2. Generation pipeline
### Step A: Angle selection
Given sources → propose 3 angles:
- hot take
- how-to
- leadership lesson
- VC lens
- postmortem

### Step B: Outline
Return outline with:
- hook options (3)
- key bullets
- one “specific detail” from sources
- suggested CTA question

### Step C: Canonical draft
Write canonical in Markdown with:
- short intro
- bullets
- takeaway line
- question

### Step D: Variants
Render canonical into platform variants.

### Step E: Humanize pass
Apply heuristics:
- vary sentence starts
- add one short aside (optional)
- reduce over-qualification
- remove banned phrases
- replace generic nouns with specifics

## 3. Anti-AI tells checklist
- Too many “However/Therefore/Moreover”
- Excessive hedging (“It might be”, “could be” everywhere)
- Overly symmetrical bullet lists
- Buzzwords without specifics
- No personal stance

## 4. Default banned phrases (starter)
- “In today’s fast-paced world”
- “delve”
- “unlock”
- “leverage”
- “game-changer”
- “seamlessly”

