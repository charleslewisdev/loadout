# Changelog

## 0.9.0, 2026-11-01

### Fixed

- `scripts/budget` no longer undercounts. Connector runs wait for connectors, runs that miss them are discarded and repeated, and a machine where they never arrive exits 2 and keeps the last good result.
- `scripts/eval` exits 3 when Bash failed in the eval sandbox, because such a run can still score 1.0.

### Changed

- `scripts/budget` reports connectors, synced skills, each plugin and the user CLAUDE.md from real on and off runs, replacing the character estimate. The headline share now includes connectors, so it can fail where it used to pass.
- `review-gate` skips work that's nothing but prose docs, and still counts skills, rules, plans and instruction files.
- `scribe-as-me` covers text published under your name, and READMEs moved to `lore-scribe`.
- The guide explains what a claude.ai account adds to each session, how to trim it per machine, and what `name-only` costs.

### Added

- `lore-scribe`, one documentation skill with per-repo voices, which loads when Claude works on Markdown or `docs/` files. A repo picks a voice with a `Voice:` line in its CLAUDE.md.
- `docs/audit-log.md`, one entry per harness audit, which `gear-respec` adds to and `scripts/check` enforces.
- `docs/eval-results.md`, written by `scripts/eval-summary`.

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
