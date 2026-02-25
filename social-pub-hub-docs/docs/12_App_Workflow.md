# App Workflow (How To Use)

Read when:
- onboarding a new operator
- validating end-to-end UX across screens
- implementing missing actions screen-by-screen

## 1) Daily happy path (short version)
1. Select/create Project scope (optional) and Post workspace (required).
2. Inbox: capture/select source items for active post (optionally save as global).
3. Library: refine source set and pull reusable global sources.
4. Compose: create/edit canonical draft for active post.
5. Variant Studio (in Compose): generate per-platform variants.
6. Publish Checklist: run quality gate.
7. Publish/Queue: assisted publish now or queue.
8. History/Analytics: verify outcome and reuse winners.

## 2) Screen-by-screen flow

### Project + Post Scope (top of Inbox/Library/Compose/Queue/History)
Goal: keep writing operations focused and reusable.
- Pick project scope (`all` or specific project).
- Pick active post inside that scope.
- Create project/post on the fly.
- Delete project/post when needed (linked rows are unscoped and deletion syncs across devices).
Exit criteria:
- active post selected before drafting/publishing/auditing steps.

### Inbox (`/inbox`)
Goal: collect evidence and start a draft.
- Add source (`url`, `note`, `snippet`).
- Scope source to active post or global reusable pool.
- Source items sync across devices in the sync loop (including deletions).
- Draft-from-selected applies style traits, tone/punchiness, differentiation points, and banned phrase guardrails.
- Select one or more sources.
- Trigger “create draft from selected sources”.
Exit criteria:
- canonical draft opened in Compose.

### Library (`/library`)
Goal: improve source quality before drafting.
- Search/filter by text, tag, type, date.
- Keep current-post sources + optional global sources in one scoped list.
- Bundle assignment dialog is scoped to active post bundles (plus legacy unscoped bundles).
- Open source detail; adjust note/tags.
- Start draft from one source or all filtered sources (LLM first, template fallback), or assign to bundle.
- Move a source to active post or promote it to global.
Exit criteria:
- source set is clean and relevant.

### Compose (`/compose`)
Goal: produce canonical draft.
- Edit markdown.
- Optional polish pass.
- Content type drives structure (`general_post`, `coding_guide`, `ai_tool_guide`).
- Style profile traits + differentiation + custom prompt feed LLM.
- Generate variants.
- Delete draft when needed (linked variants are removed and deletion syncs).
Exit criteria:
- canonical draft approved by user.

### Variant Studio (Compose subflow)
Goal: produce publish-ready platform versions.
- Generate variants for selected platforms using style profile cues (LLM first, template fallback).
- Variant deletions sync across devices and safely unlink queue/history/bundle references.
- Check hard constraints (length/format).
- Humanize pass if needed.
- Manual final edits.
Exit criteria:
- each target platform has an approved variant.

### Bundles (`/bundles`) + Bundle Checklist (`/bundle-checklist`)
Goal: coordinated distribution around an anchor post.
- Bundle records now carry `post_id` and default to active post scope; use “Include all posts” for cross-post review.
- Bundle records sync across devices with the main sync flow (including deletions).
- Create bundle (`youtube` or `social` anchor).
- Link variants/sources.
- Canonical draft generation from bundle sources is LLM-first (template fallback) and inherits post content type + audience.
- Run checklist and backfill missing platforms (LLM first, template fallback).
Exit criteria:
- bundle is complete and ready to distribute.

### Publish Checklist (`/publish-checklist`)
Goal: quality gate before posting.
- Scope drafts to active post by default; toggle “Include all posts” for cross-post review.
- Run rubric checks (hook, specifics, stance, CTA/question), plus content-type checks for coding/AI guides.
- Confirm assisted publish steps.
Exit criteria:
- checklist pass, no blockers.

### Publish (`/publish`)
Goal: execute publishing safely.
- Scope recent publish logs to active post by default; toggle “Include all posts” when needed.
- Review integration capability/connection state.
- For each variant: assisted publish (copy/open/confirm) or direct publish if available.
- Confirm final status in publish logs.
- Delete stale publish logs when needed (syncs deletion).
Exit criteria:
- post status recorded (`posted`/`queued`/`failed` with reason).

### Queue (`/queue`)
Goal: manage scheduled execution.
- Scope queue to active post by default; toggle “Include all posts” when needed.
- Filter queued/overdue.
- Copy/open composer for manual assisted posting.
- Mark posted or cancel.
- Remove posted/canceled rows to keep queue clean (syncs deletion).
- Queue rows carry `post_id` for linked variants and post-scoped manual queue entries, enabling per-post audits.
Exit criteria:
- no stale overdue items.

### Sync Conflicts (`/sync-conflicts`)
Goal: resolve local/remote divergence.
- Compare local vs remote summaries.
- Keep remote or local.
Exit criteria:
- conflict count returns to zero.

### History (`/history`)
Goal: audit + reuse.
- Scope history to active post by default; toggle “Include all posts” when needed.
- Filter by platform/status.
- Open posted URL.
- Clone winning variant into a post-scoped draft while preserving content type intent.
- Delete stale history rows when needed (syncs deletion).
- Publish logs carry `post_id` when variant is linked.
Exit criteria:
- learnings captured and reusable.

### Analytics (`/analytics`)
Goal: quick health check.
- Scope metrics to active post by default; toggle “Include all posts” for cross-post view.
- Check posted count, queue health, platform split.
Exit criteria:
- KPI snapshot reviewed for next iteration.

### Settings (`/settings`)
Goal: keep system stable and style consistent.
- Diagnostics can be scoped to active post or toggled to all posts.
- Sync diagnostics include pushed upserts, pushed deletes, pulled upserts, and pulled deletes.
- Sync run CSV export includes per-run push/pull/delete totals and conflict count.
- Run sync now.
- Refresh integrations.
- Tune style profile/sliders/banned phrases.
Exit criteria:
- sync healthy + style defaults aligned.

## 3) Recommended operating cadence
- Start: Inbox/Library triage.
- Midday: Compose + variants.
- Before publish: Publish Checklist.
- End of day: Queue cleanup + History/Analytics review.

## 4) Failure handling flow
1. Publish fails -> inspect Publish log reason.
2. If auth/integration issue -> Settings (refresh/reconnect), retry.
3. If content issue -> Compose/Variant edit, rerun checklist.
4. If sync issue -> Sync Conflicts resolve, then retry publish.
