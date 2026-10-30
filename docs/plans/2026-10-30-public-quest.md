# Public quest plan

Goal: make the already-public loadout repo safe to work on in the open, then ready for strangers to fork, with a light sprite-RPG flavor that suits Crystal Bridge.
Approach: Phase 0 puts guardrails on everything that publishes (commits, issues, PR bodies) before any issue exists. Phases 1 to 3 then become GitHub issues, one per task, each drafted to a file and scanned before posting. The theme lives in names, headings and ceremonial output, never in place of a fact or a measurement.
Run with: /loadout:plan-run (Phase 0 only; later phases run from their issues)

Source: the 2026-10-30 audit in `.private/QUEST-NOTES.md`, items 1 to 12. Findings that name private terms stay in that file; this plan and the issues cite them by item number only.

## Ground rules for working in the open

1. Every issue, PR title, PR body and comment is a publication. Write it to a file, run `GUARD_REQUIRE_DENYLIST=1 guard/scan text FILE`, show the owner, then post with `--body-file`.
2. An issue describes the fix, never the leaked text. "Replace two internal project names in a retro with counts" is fine; the names are not.
3. History rewrites and PR-body edits are the owner's call. List them; don't apply them.
4. Theme rule: flavor may rename a heading or decorate ceremonial output (status, retro, papercut). It never replaces the plain fact, the command or the number, and it never enters engineering prose in the always-on style.

## Phase 0: guardrails (before any issue is created)

### Task 1: turn CI green on `main`

Files: modify `guard/allowed-emails`

Test first: `guard/scan --all` currently exits 1 with "author email of commit 97e9d82afc is not in guard/allowed-emails". That merge came from the GitHub merge button, which signs with the account's primary email.
Change: add the merge author's address (already public in that commit) as a line in `guard/allowed-emails`. Owner step, outside the repo: turn on GitHub's "Keep my email addresses private" and "Block command line pushes that expose my email", so the web button signs with the noreply address from now on.
Run: `scripts/check --ci`, which ends with `check: all passed`.

Commit: `fix: allow the address on the button-merged commit so CI passes`

### Task 2: block `gh` publications that fail the guard

Files: create `guard/gh-hook`, `guard/gh-hook.test.sh`, `.claude/settings.json`; modify `scripts/check` (add a step)

Test first: `guard/gh-hook.test.sh`, in the style of `hooks/notify.test.sh`, with a synthetic denylist holding `\bzorblax\b`. It feeds PreToolUse JSON on stdin and asserts:
- `gh issue create --title t --body-file F` where F contains "zorblax" exits 2 and prints no "zorblax";
- the same with a clean F exits 0;
- `gh issue create --body "x"` (inline body) exits 2 with "use --body-file";
- a title holding "zorblax" exits 2;
- `gh pr edit`, `gh issue comment`, `gh pr comment`, `gh repo edit --description` are all covered;
- `git status` and `gh pr list` exit 0 untouched;
- a missing denylist exits 2 (fail closed, as `.githooks/pre-push` does for public remotes).
Run: `guard/gh-hook.test.sh`, which fails with "guard/gh-hook: not found".

Change: `guard/gh-hook` reads the hook JSON, takes `.tool_input.command`, and acts only on `gh (issue|pr) (create|edit|comment)` and `gh repo edit`. It refuses inline `--body`/`-b`, writes the title and description values plus the body file to a temp file, and runs `GUARD_REQUIRE_DENYLIST=1 guard/scan text` on it; any finding exits 2 with the scanner's output (line numbers only). `.claude/settings.json` registers it as a project PreToolUse hook on `Bash`. `scripts/check` gains `step 'gh publication hook tests' guard/gh-hook.test.sh`.
Run: `guard/gh-hook.test.sh && scripts/check --ci`, both passing.

Commit: `feat: scan issue and PR text before gh publishes it`

### Task 3: tell every session here that the repo is public

Files: create `CLAUDE.md` (repo root, under 15 lines)

Check: the file states the four ground rules above in imperative form and names `guard/gh-hook`. `scripts/budget` shows the in-repo cost (run it from the repo, compare against the README table); the delta must stay under 300 tokens.

Commit: `docs: add the working-in-public rules for this repo`

### Task 4: scrub the retro (audit item 2)

Files: modify `retros/2026-09-21.md` (lines 30 to 31)

Test first: owner step: add the two terms to the guard's private sources and regenerate the denylist. Then `GUARD_REQUIRE_DENYLIST=1 guard/scan --path retros` exits 1 on that file.
Change: replace the two names with counts, as `harness-retro/SKILL.md:50` requires.
Run: the same scan exits 0. `guard/scan --all` will still report the old commits; that is the history decision below, not a failure of this task.

Commit: `docs: keep the first retro to counts`

### Task 5: CI on pull requests, and protect `main`

Files: modify `.github/workflows/ci.yml` (line 2)

Change: `on: [push, pull_request]`. Owner step: a branch rule on `main` that requires the `check` status and blocks force-pushes, without requiring a PR, so the command-line fast-forward merge keeps working.
Check: open a draft PR from this branch; `gh pr checks` lists `check` passing.

Commit: `ci: run checks on pull requests`

### Owner decisions before Phase 1

- **History:** the retro names (item 2) live in old commits. Rewrite `main` and force-push, or accept them as public. Recommendation: accept; they are not identity-tied and the guard was clean over all history and all ten PR bodies on 2026-10-30.
- **PR bodies (item 6):** approve or skip the `gh pr edit` list in the notes.
- **Issue creation:** once Tasks 1 to 3 are merged, issues for the tasks below are safe to draft, scan and post.

## Phase 1: main quest, fit for strangers (one issue each)

- **LICENSE and notices (items 3, 4):** MIT `LICENSE`; `THIRD_PARTY_NOTICES.md` crediting the MIT and Apache-2.0 sources the audit traced; pin the rubric link to commit `4ca561fb8`.
- **The split (Proposed split in the notes):** `plugins/loadout/` generic with an unforced style; an optional plugin holding the forced sample style and `write-as-me`; `profiles/example.json` beside the owner's profile; `guard/allowed-emails.example` and `guard/denylist.example`.
- **Install from your fork (item 7):** derive `repo` from `origin` in `install.sh`; add uninstall steps.
- **Requirements and portability (item 5):** README lists bash 5+, jq, gh, claude; either fix bash 3.2 and BSD sed or declare macOS needs Homebrew bash.
- **Stale and conflicting text (items 8 to 11):** descriptions that omit skills, hooks and the statusline; ADR, S# and "Appendix F" references; the two hook p95 figures; the optics list.
- **Contributor scaffolding:** CONTRIBUTING, CHANGELOG with a `v0.8.0` tag, SECURITY.

## Phase 2: the Crystal Bridge theme (one issue each)

Guideline: themed name first, literal meaning beside it, the first time it appears.

- **Repo description and topics:** for example "A measured Claude Code loadout you can fork: equip only what earns its slot." Topics: `claude-code`, `claude-code-plugin`, `agent-harness`.
- **README flavor:** a one-line tagline; "What it costs, measured" becomes "Encumbrance: what it costs, measured"; the skill list becomes an inventory table; retros become save points. Keep every anchor the `readme-s6` eval and links use, or update them in the same change.
- **Crystal Bridge as companion:** a short README section naming it, linking https://github.com/crystal-bridge/crystal-bridge, and documenting `CRYSTAL_SESSION` as a generic seam (a host that sends its own notifications sets it). Crystal Bridge itself must never depend on loadout.
- **Ceremonial output:** `harness-status` renders as a character sheet (the same numbers, labelled stats); the retro calls itself a save point; papercut entries read as a quest log. Covered by the `humor` and smoke evals.
- **Skill renames (proposal, owner to pick):** verb first, so each name still says what it does. Descriptions stay plain, so triggering and the slash menu stay usable. None reuses a Crystal Bridge term (Quest, Side Quest, Recruit, Chronicle, Inventory), and Crystal Bridge's Inventory panel will list them as `loadout:<name>`.

  | Now | Proposed | What it does |
  | --- | --- | --- |
  | `code-debug` | `track-bug` | reproduce, then test one hypothesis at a time |
  | `code-review` | `party-review` | a party of reviewer subagents, each finding verified |
  | `code-verify` | `appraise-work` | run tests, lint and build before claiming done |
  | `git-pr` | `turn-in-pr` | branch, commit and PR conventions |
  | `plan-brainstorm` | `choose-path` | settle an open design, one question at a time |
  | `plan-write` | `draw-map` | write the step-by-step plan |
  | `plan-run` | `follow-map` | execute a plan task by task |
  | `harness-status` | `check-stats` | the measured state, as a character sheet |
  | `harness-retro` | `camp-retro` | the periodic retro and its pull request |
  | `harness-papercut` | `mend-gear` | log one annoyance, propose the smallest fix |
  | `write-as-me` | `scribe-as-me` | draft text published under the owner's name |

  Cost of the rename: eval `case.yaml` files, cross-references between skills, README, the long-form guide, all change in the same PR, and the smoke evals re-run after it. Usage history restarts: `retro-evidence` reads `skillUsage` from `~/.claude.json`, keyed by skill name.
- **Labels:** `main-quest`, `side-quest`, `papercut` on the issues themselves.

## Phase 3: side quests

- Commit eval results or a summary, so the "measured" claim has evidence in the repo, not only in PR prose.
- Re-measure on the current CLI and update the README numbers in one change.
- Port what is worth keeping from the older private setup repo the notes mention.
