# Security & Compliance — Phase I

## 1. Principles
- Least privilege and minimal token scope
- Human confirmation for posting (assisted default)
- No scraping or ToS-violating automation
- Traceability: generated claims grounded to stored sources

## 2. Token storage
### On device
- Store OAuth tokens in Keychain (iOS/macOS)
- Never store plaintext tokens in SQLite
- Consider SQLCipher for local DB encryption if threat model requires it

### Server
- Store tokens encrypted at rest (KMS or envelope encryption)
- Separate secrets from app DB where possible
- Log token refresh events (without token values)

## 3. Data handling
- SourceItems may include sensitive work notes:
  - Provide “local-only” flag per item (do not sync)
  - Provide “redact before generation” option
- Attachments stored in object storage with scoped, expiring URLs

## 4. Compliance notes
- Prefer official APIs where available
- Assisted publish avoids impersonation and reduces risk
- Keep audit log of publish actions (what/when/platform/mode)

## 5. Abuse prevention (future)
- Rate-limit generation endpoints
- Per-user quotas
- Content safety checks for public posting (optional)

