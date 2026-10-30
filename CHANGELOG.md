# Changelog

## 0.8.0, 2026-10-30

### Changed

- Skills are named by subject so they group in the menu:
  - `code-debug` is `bug-hunt`
  - `harness-papercut` is `gear-mend`, `harness-retro` is `gear-respec`, `harness-status` is `gear-stats`
  - `plan-write` is `map-draw`, `plan-run` is `map-follow`, `plan-brainstorm` is `map-scout`
  - `git-pr` is `pr-turn-in`, `code-review` is `review-party`, `write-as-me` is `scribe-as-me`
- The output style and `scribe-as-me` moved to an optional `bard` plugin.
- `install.sh` takes the marketplace source from `origin` and checks for bash 5, git, jq and perl.

### Added

- `review-gate`, a Stop hook that blocks once on multi-file work with no `review-party` since the last change.
- `guard/gh-hook`, which scans text gh is about to publish.
- `profiles/example.json`, `guard/allowed-emails.example`, `guard/denylist.example`, MIT `LICENSE`, `THIRD_PARTY_NOTICES.md`, CONTRIBUTING and SECURITY.

### Removed

- `code-verify`. Its rule lives in the `peer` style, and `review-party` runs the same checks.
