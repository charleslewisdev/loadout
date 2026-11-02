#!/usr/bin/env bash
# Plants a canned answer for scripts/eval-bin/gh, and no curated map.
set -euo pipefail
cat >"$HOME/gh-answer.json" <<'JSON'
{"data":{"viewer":{"repositories":{"totalCount":3,"nodes":[
{"nameWithOwner":"sample-dev/hookrelay","isPrivate":true,"isFork":false,"isArchived":false,"pushedAt":"2026-10-20T00:00:00Z","description":"Delivers outbound webhooks: signed payloads, retries with backoff, a dead-letter queue","primaryLanguage":{"name":"Go"},"defaultBranchRef":{"target":{"history":{"nodes":[{"messageHeadline":"feat: replay from the dead-letter queue"}]}}}},
{"nameWithOwner":"sample-dev/trailcam-sorter","isPrivate":false,"isFork":false,"isArchived":false,"pushedAt":"2026-09-02T00:00:00Z","description":"Sorts wildlife camera photos by species","primaryLanguage":{"name":"Python"},"defaultBranchRef":{"target":{"history":{"nodes":[{"messageHeadline":"fix: skip empty frames"}]}}}},
{"nameWithOwner":"sample-dev/pantry-tracker","isPrivate":true,"isFork":false,"isArchived":false,"pushedAt":"2026-07-11T00:00:00Z","description":"Tracks household pantry stock and expiry dates","primaryLanguage":{"name":"TypeScript"},"defaultBranchRef":{"target":{"history":{"nodes":[{"messageHeadline":"chore: bump deps"}]}}}}
]}}}}
JSON
