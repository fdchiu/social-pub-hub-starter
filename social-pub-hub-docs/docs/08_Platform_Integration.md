# Platform Integration Notes (Phase I)

## Default stance
- Assisted publish everywhere.
- Direct publish is feature-flagged per platform and enabled only when approved/available.

## X
- Direct publish may require specific API access/tiers.
- MVP: assisted composer open + copy text.
- Optional: direct post adapter behind flag.

## LinkedIn
- Permissions can be gated; often requires app review.
- MVP: assisted publish.

## Reddit
- OAuth + posting endpoints exist, but policy/access can change.
- MVP: assisted publish into subreddit composer.

## Facebook Pages
- Page posting supported via Pages API (permissions required).
- Candidate for direct publish in Phase I if you set up a FB App + Page token flow.

## YouTube
- Phase I recommended: templates for title/desc/chapters/pinned comment.
- Optional: direct upload via resumable upload protocol (adds complexity).
- Compound effect: treat YouTube as “anchor” and generate social wave from it.

