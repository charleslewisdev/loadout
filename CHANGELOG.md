# Changelog

## Unreleased

### Added

- Twin eval cases for `map-scout-smoke`: fixed replies with two questions, or with only an offer to start, which its grader must fail. `scripts/check` fails if a twin's criteria differ from the smoke case's.

### Changed

- `verify-before-done` grades three things: tests ran after the last edit, the run used `check.sh`, and the reply's claims match the output. A run that tests directly no longer fails outright, and a Bash command that writes `app/cli.py` counts as an edit.
- `map-scout-smoke` counts a same-choice follow-up, such as "or is it a mix?", as one question. It fails a reply whose only question asks permission to start.
- `gear-mend-smoke` allows 30 turns.

### Fixed

- `scripts/eval` moves version-manager shim directories to the end of `PATH`. In the sandbox a shimmed `python3` failed, and runs spent turns fixing it. A `claude` reachable only through a shim still runs.
- `scripts/eval` removes workspaces more than a day old from `~/.cache/loadout/eval-tmp` when it starts, since no reboot clears that directory.

## 0.13.0, 2026-11-02

### Added

- `repo-raid`, a typed-only, read-only audit of a local repo or a GitHub repo. Lenses cover principles, security, public readiness, docs, code and portfolio, and `--focus` limits a run. A verifier built for audits scores each finding. Lenses read a write-protected snapshot of committed work, and the report stays in `~/.cache/loadout/raids`. A new `PreToolUse` hook, `raid-gate`, limits Explore subagents to Read, Grep and Glob inside the raid while one is live, and it returns at once otherwise. On a GitHub target it sends the repo's settings, and with the portfolio lens your repo list, to the session.
- Eval cases on a fixture with planted problems and on a clean one, and an offline test of the helper in `scripts/check`.
- `scripts/check` fails if the skill's copy of the public repo standard differs from `docs/public-repo-standard.md`.

## 0.12.1, 2026-11-02

### Fixed

- The guide's six stale Anthropic quotes match their live pages again. The best-practices page changed its pruning test, so the guide's claim changed with it.
- `gear-respec` copies the audit log's latest entry format, the same as `gear-heal`. The log runs oldest first, so "first entry" named the baseline.
- `CLAUDE.md` says what `guard/gh-hook` does: it scans each publishing gh command, and doesn't check that the file-and-show flow ran.

## 0.12.0, 2026-11-02

### Added

- `gear-heal`, a typed-only audit. In a `loadout` checkout it compares the harness with Anthropic's docs. In any other repo it gives each line of the instruction files a verdict. Both modes propose every change in one pull request on `heal/<yyyy-mm-dd>`. Its evidence and its publishing need the denylist: without one, it says so and stops at a local commit.
- `scripts/quote-check` compares each Anthropic quote in `docs/quotes.tsv` with its live page. It reaches the network, so it stays out of `scripts/check` and CI. Its offline test runs in `scripts/check`.
- `scripts/retro-evidence --project <dir>` limits the evidence to one project, with a default window of 90 days.
- Eval cases for both `gear-heal` modes, and for stopping when the scan can't run.
- The guide teaches CLAUDE.md writing, in a new subsection of section 2.

### Changed

- `templates/CLAUDE.md` follows the docs' Commands, Conventions and Gotchas headings, and asks for a one-file test command.

## 0.11.0, 2026-11-02

### Added

- `map-scout` checks your other repos before its first question, using live `gh` data and an optional map at `~/.config/loadout/notes/portfolio.md`. That sends repo names, descriptions and commit subjects to the session, private and organization repos included, with no prompt, until you create `~/.config/loadout/no-portfolio`. It's told to report a repo only when one relates, and to leave private repos out of what it writes.
- Eval cases for that check: with a map, with no map, with nothing related, and for what reaches a written design record.
- `map-draw` leaves private repos out of a plan.
- `scripts/eval` puts `scripts/eval-bin` first on `PATH`, so a case can fake a command the sandbox can't reach.

### Changed

- `docs/plans/` is ignored, and the one plan tracked there is no longer in the repo. Plans are working files for Claude.
- `review-party` verifiers report a blocked command, and never route around it.

## 0.10.1, 2026-11-02

### Fixed

- `scripts/eval` runs the eval workspace outside `/tmp`, where the sandbox blocks Bash from writing, and exits 3 on those errors.
- `pr-turn-in` fires on a request to write a PR description.
- `map-scout-smoke` no longer fails a reply for repeating its one question.

### Changed

- `docs/eval-results.md` has a real score for every case, and records why two stay below the pass mark.

## 0.10.0, 2026-11-01

### Changed

- CI pins its action to a commit, runs Vale and `reuse lint`, and verifies Vale by checksum.

### Fixed

- The README says that removing a key from a profile doesn't remove it from a machine, since the installer only merges.
- The guide explains how a `skillOverrides` key misses a synced skill that shares its name.
- The public repo standard covers rulesets as well as classic branch protection, since each endpoint sees only its own kind.
- `guard/scan` no longer misses a term after a forged end marker, in a path holding ` b/`, or in a path git quotes, and no longer prints a quoted path that matches.
- `guard/scan` no longer depends on the locale or on local git config, reads author and committer names, ref names and tag messages, and withholds a path that matches a secret pattern.
- `guard/scan` reads its allowlist from beside the script, so it can scan another repo, and exits 2 if the list is missing.

### Added

- `gear-outfit`, a typed-only configurator. It reports denials by rule label, recommends settings and the narrowest permission fix, shows every change, and leaves applying the plan to you.
- `install.sh --machine <file>` layers a private profile over a public one, and array settings are now unioned instead of replaced.
- The `homelab` plugin, with a generic `unraid` skill that reads local notes from `~/.config/loadout/notes/`. The profiles allow reading that path.
- `docs/public-repo-standard.md`, one checklist for every public repo, with `scripts/check` enforcing the items a script can check.
- A code of conduct, issue and pull request templates, Dependabot for actions, and REUSE licensing.
- Reviewed exceptions for `guard/scan`, kept beside the private denylist and keyed on content.
- Prose lint with Vale in `scripts/check`, where Vale is installed, with rules in `.vale/styles`.

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
