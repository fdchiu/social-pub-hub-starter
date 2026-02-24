# Releasing Checklist (MVP)

Use this checklist before cutting a release branch or tag.

## 1) Local gate
- Run `./scripts/gate.sh` from repo root.
- Confirm:
  - Flutter `analyze` passes.
  - Flutter `test` passes.
  - Backend `pytest` passes.

## 2) CI gate
- Push branch.
- Confirm GitHub Actions `CI` workflow is green:
  - `Flutter Analyze + Test`
  - `Backend Pytest`

## 3) Smoke workflow
- Open app.
- Walk this path once:
  - Inbox: add/select source items.
  - Compose: create draft, generate variants, queue at least one.
  - Queue: mark posted.
  - History: verify posted row appears.
  - Settings: run sync.

## 4) Notes + docs
- Update `README.md` if commands/paths changed.
- Update nav or workflow docs if behavior changed.

## 5) Release artifact
- Create release tag after CI green.
- Include release notes:
  - user-facing changes
  - breaking changes (if any)
  - known limitations

