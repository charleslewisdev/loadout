# Audit log

Measured history of this harness. Each audit adds one entry with the same metrics, so any change has a number to beat. `gear-respec` adds an entry on every retro, and `scripts/check` fails if a retro has none. The [guide](../WRITING-AN-EFFECTIVE-HARNESS.md) explains the method, and this file keeps the numbers.

Connector and account-synced skill names stay out of this file, so those surfaces appear as totals.

## 2026-11-01: baseline

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** `scripts/budget` was undercounting, and the next change is a trim that needs a number to beat.

**What changed:** nothing in the harness. This entry follows the budget fix and comes before the first trim, so Before and After match.

| Metric | Before | After |
| --- | --- | --- |
| Total at turn 0, with connectors and auto-memory | 26,681 | 26,681 |
| Harness share, with connectors | 9,016 | 9,016 |
| Harness share, without connectors | 5,986 | 5,986 |
| Vendor floor | 16,973 | 16,973 |
| Auto-memory section, outside the share | 693 | 693 |
| Account-synced skills (16) | 4,008 | 4,008 |
| Account connectors (5) | 3,030 | 3,030 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 400 | 400 |
| Personal skills and the rest | 207 | 207 |

Repeated runs agreed within 2 tokens, with no runs discarded. The share is over both the 6,000 ceiling and the 8,000 absolute ceiling, which is the measured starting point for the trim.

**Hook p95, last 90 days:**

| Hook | p95 ms |
| --- | --- |
| `format` | 185.2 |
| `notify-input` | 58.2 |
| `notify-stop` | 51.6 |
| `review-gate` | 121.2 |
| `session-start` | 43.1 |

**Skill usage:** lifetime counts from Claude Code's own `.skillUsage` record, as `scripts/retro-evidence` reports them, with uses under old names added to the current name. They have no date window, so compare entries by difference.

| Skill | Uses |
| --- | --- |
| `pr-turn-in` | 17 |
| `review-party` | 9 |
| `gear-stats` | 6 |
| `map-draw` | 3 |
| `map-scout` | 3 |
| `map-follow` | 2 |
| `bug-hunt` | 1 |
| `gear-mend`, `gear-respec`, `scribe-as-me` | 0 |

**Eval results:** of 31 cases, 21 pass, 2 score below 0.80, 5 aren't trusted because Bash fails in the eval sandbox, and 3 haven't run. See [eval-results.md](eval-results.md). This entry first said 17 and 6. That run left out `--allow-tools Edit Write`, which failed four cases that needed those tools, and the numbers here are from the rerun.

## 2026-11-01: first trim

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** the baseline share was over both ceilings, and most of it came from the claude.ai account.

**What changed:** on this machine, 14 of 16 account-synced skills moved to `name-only`, `user-invocable-only` or `off`, and 4 of 5 connectors were blocked or removed. Choices came from usage: one connector had 145 tool calls in 195 transcripts, the others none, and 2 of the 16 skills appeared in those transcripts. The user CLAUDE.md and the `peer` style were reviewed and left alone, since each is within its target.

| Metric | Before | After |
| --- | --- | --- |
| Total at turn 0, with connectors and auto-memory | 26,681 | 22,202 |
| Harness share, with connectors | 9,016 | 4,539 |
| Harness share, without connectors | 5,986 | 2,846 |
| Vendor floor | 16,973 | 16,972 |
| Auto-memory section, outside the share | 693 | 692 |
| Account-synced skills (16) | 4,008 | 868 |
| Account connectors | 3,030 | 1,693 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 400 | 400 |
| Personal skills and the rest | 207 | 207 |

The share is now under the 6,000 ceiling, and the share without connectors is under 3,000. The guide's target of about 3,000 for the full share isn't met yet. Automatic use of four `name-only` skills fell from 11 runs of 12 to 5 of 15, counting one repeated skill. I accepted that because none of the four had a tool call in those transcripts. The test itself added to their lifetime usage counts, so ignore that bump at the next retro. The two skills left `on` still fired, in 5 runs of 6.

**Hook p95, last 90 days.** No hook changed, so these differences are measurement noise.

| Hook | Before ms | After ms |
| --- | --- | --- |
| `format` | 185.2 | 185.2 |
| `notify-input` | 58.2 | 58.2 |
| `notify-stop` | 51.6 | 48.3 |
| `review-gate` | 121.2 | 97.4 |
| `session-start` | 43.1 | 39.2 |

**Skill usage and eval results:** no kit skill changed, so there's no new table.

## 2026-11-01: private profile and `homelab`

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** the first install of the private profile and the `homelab` plugin, which took the `unraid` skill out of the personal skills.

**What changed:** `homelab` added 73 tokens, and the personal skills lost 70, so the move cost 3. The other 269 of the 272 rise is an override that stopped working. A synced skill was set to `off` under `skillOverrides` in user settings, and the profile then installed a typed-only personal copy with the same name. That key now hides the personal copy and misses the synced one. Passing the same key with `--settings` still reaches the synced skill, which is how I measured the 269. The next entry should show it gone once the synced copy is deleted from the account.

| Metric | Before | After |
| --- | --- | --- |
| Harness share, with connectors | 4,608 | 4,880 |
| Harness share, without connectors | 2,916 | 3,187 |
| Vendor floor | 16,972 | 16,972 |
| Account-synced skills (16) | 868 | 1,137 |
| Account connectors | 1,693 | 1,693 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 469 | 469 |
| `homelab` plugin | 0 | 73 |
| Personal skills and the rest | 207 | 137 |

Before takes the two shares and the `loadout` row from a 0.9.0 run, and the other rows from the first trim. The rest includes `rust-analyzer-lsp` at 4 tokens, as earlier entries do.

**Hook p95, skill usage and eval results:** no hook or kit skill changed, so there's no new table.

## 2026-11-01: kit audit

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** every kit item needs a verdict on evidence, and #31 asked for one. The audit also clears the override trouble from the previous entry.

**What changed:** no kit item was removed, and no language server has landed yet. Deleting one synced skill from the account recovered 269 tokens. Keying another by its full name recovered 169, since a bare key in user settings doesn't reach a synced skill that shares its name with another.

| Metric | Before | After |
| --- | --- | --- |
| Total at turn 0, with connectors and auto-memory | 22,545 | 22,105 |
| Harness share, with connectors | 4,880 | 4,442 |
| Harness share, without connectors | 3,187 | 2,749 |
| Vendor floor | 16,972 | 16,972 |
| Auto-memory section, outside the share | 693 | 692 |
| Account-synced skills | 1,137 (16) | 699 (15) |
| Account connectors | 1,693 | 1,693 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 469 | 469 |
| `homelab` plugin | 73 | 73 |
| Personal skills and the rest | 137 | 137 |

Before is the After column of the previous entry, plus its total and auto-memory figures from the same run. Each total is measured on its own, so it can differ from the sum of its parts by a token.

**Skill verdicts.** Invocations are `Skill` tool calls in local transcripts, under the current name, so they cover two days for the skills renamed on October 30. Older counts are from `scripts/retro-evidence --since 2026-09-20`, which reads Claude Code's lifetime usage record: "before" is the same skill under its old name, and "predecessor" is the third-party skill it replaced. Typed-only skills add nothing to the skill listing, so keeping an unused one costs a line in the README, not tokens.

| Skill | Invocations in transcripts | Evidence beyond that | Verdict |
| --- | --- | --- | --- |
| `review-party` | 12 | 16 uses of the bundled `code-review` it overlaps, but it adds the project's checks and verifies each finding. Caught a false claim in the draft of #45. Eval not run | Keep |
| `pr-turn-in` | 5 | 13 before the rename, eval not trusted | Keep |
| `unraid` | 1 | 42 before the move, evals 1.00 | Keep, per machine in `homelab` |
| `map-scout` | 1 | 2 before the rename, predecessor 131, eval 0.50 in #38 | Keep, fix the eval in #38 |
| `map-draw` | 0 | 3 before the rename, predecessor 79, eval 1.00 | Keep |
| `map-follow` | 0 | 2 before the rename, predecessor 69, eval not trusted | Keep |
| `lore-scribe` | 0 | New on November 1, four evals at 0.89 or better | Keep |
| `gear-stats` | 0 | 6 before the rename, typed only | Keep |
| `gear-respec` | 0 | Runs the retro this log depends on, typed only, eval not run | Keep |
| `bug-hunt` | 0 | 1 before the rename, predecessor 23, eval not trusted | Keep until the next retro, then remove if still unused |
| `gear-mend` | 0 | Nothing logged yet, typed only, eval not run | Keep on the same test |
| `scribe-as-me` | 0 | Eval 1.00, typed only, and no use recorded under this name | Keep on the same test |

**Output style: keep.** `bard:peer` is most of the 728-token `bard` plugin, and every session uses it. 19 of its plugin's 21 eval cases pass, one isn't trusted, and `rephrase-a-put-idempotent` at 0.00 goes with #38.

**Hooks and statusline: keep.** All five hooks fired in the last 7 days, and all are under the 300 ms target at p95. No hook changed, so the differences below are noise. `session-start` was killed once in 90 days, and not in the last 7. The statusline has no usage record, so it stays by default.

| Hook | Calls, 90 days | Before ms | After ms |
| --- | --- | --- | --- |
| `format` | 478 | 185.2 | 185.2 |
| `notify-input` | 253 | 58.2 | 58.2 |
| `notify-stop` | 1,210 | 48.3 | 46.8 |
| `review-gate` | 742 | 97.4 | 84.7 |
| `session-start` | 941 | 39.2 | 35.5 |

**Instruction files: no change.** The project CLAUDE.md has 10 lines and the user file has 30, both within target. I read both against the test, and found no line to cut.

**Language servers.** The code on this machine is 1,225 TypeScript files, 95 JavaScript, 79 Python and 17 Rust, with no Go. So `rust-analyzer-lsp` stays at 4 tokens, TypeScript and Python get a language server chosen per machine, and Go doesn't. Those two aren't installed or measured yet, and #31 stays open until they are.

**Shared kit:** 18 of 20 items are on every machine of mine: 11 skills, 5 hooks, the statusline and the output style. `unraid` and `rust-analyzer-lsp` are chosen per machine. With the two new language servers it's 18 of 22, or 82%.

**Eval results:** of 37 cases, 27 pass, 2 score below 0.80, 5 aren't trusted and 3 haven't run. See [eval-results.md](eval-results.md).

## 2026-11-01: language servers

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** the kit audit chose TypeScript and Python language servers, and needed their measured cost.

**What changed:** `typescript-lsp` and `pyright-lsp` from the official marketplace are enabled, with `typescript`, `typescript-language-server` and `pyright` installed globally with npm. The account also dropped from 15 synced skills to 11, at no cost change.

| Metric | Before | After |
| --- | --- | --- |
| Total at turn 0, with connectors and auto-memory | 22,105 | 22,107 |
| Harness share, with connectors | 4,442 | 4,442 |
| Harness share, without connectors | 2,749 | 2,750 |
| Vendor floor | 16,972 | 16,972 |
| Auto-memory section, outside the share | 692 | 693 |
| Account-synced skills | 699 (15) | 699 (11) |
| Account connectors | 1,693 | 1,693 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 469 | 469 |
| `homelab` plugin | 73 | 73 |
| Personal skills and the rest | 137 | 137 |

The rest includes the language servers. With all three on, each measures 0 when it's the only one turned off, and the 4 tokens `rust-analyzer-lsp` showed alone moved into the rest. I didn't measure all three off together, so the servers may share that cost.

**Language servers:** the TypeScript and Python servers each answered a `documentSymbol` request. The TypeScript server needs a project-level `typescript` that ships `tsserver`, which TypeScript 7 doesn't. It fails to start in a project on 7.x, in a project with none, and with only a global install. It worked on 5.9.3. Five of my eight TypeScript projects are on 5.x, and the other three get no language server until the plugin supports 7.

**Shared kit:** 18 of 22 items, or 82%, are on every machine of mine: 11 skills, 5 hooks, the statusline and the output style. `unraid` and the three language servers are chosen per machine. The two new servers are enabled in a private machine profile, and `install.sh` installs only this repo's plugins, so a new machine also needs `claude plugin install` for each.

**Hook p95, skill usage and eval results:** no hook or kit skill changed, so there's no new table.

## 2026-11-02: evals running again

**CLI:** 2.1.316, on Sonnet 5, three runs per case unless a case sets its own.

**Why:** every Bash case had been untrustworthy since October, so a low score could mean a bad skill or a broken sandbox.

**Causes:** two faults stacked. An AppArmor update took capabilities away from everything `bwrap` starts, which broke the sandbox outright. Once that was lifted, the sandbox still made `/tmp` read-only for Bash, and the eval workspace lives in `/tmp`, so `git add`, `git commit` and shell redirects failed while the Write and Edit tools kept working.

**Fixes:** `scripts/eval` now puts the workspace under the cache directory, and exits 3 on the read-only errors, which it used to miss. `pr-turn-in` now names PR descriptions in its trigger, so it fires on that request. `map-scout-smoke` no longer lets a judge count a reworded question as a second one.

| Case | Before | After | Baseline after |
| --- | --- | --- | --- |
| `map-follow-smoke` | 0.22 | 1.00 | 0.67 |
| `gear-respec-smoke` | 0.20 | 1.00 | 0.00 |
| `gear-outfit-smoke` | 0.67 | 1.00 | 0.00 |
| `gear-mend-smoke` | 0.50 | 0.92 | 0.42 |
| `pr-turn-in-smoke` | 0.72 | 1.00 | 0.61 |
| `map-scout-smoke` | 0.50 | 1.00 | 0.00 |

The "before" column is a same-day run with the workspace in `/tmp`, except `map-scout-smoke`, which is its recorded score from 2026-11-01. In its "after" run, one of three replies never fired the skill and only offered to, which the `with-only` grader reports but doesn't score.

**Eval results:** of 38 cases, 36 pass and 2 score below 0.80, each with a reason in [eval-results.md](eval-results.md). No case is left untrusted or unrun.

## 2026-11-02: first heal

**CLI:** 2.1.316, on Haiku, three usable runs per configuration.

**Why:** the first `/loadout:gear-heal` run in harness mode, with `/doctor prompt-audit` run just before it.

**What changed:** six quotes in the guide went stale after Anthropic rewrote its pages, and all six now match. The best-practices page replaced its pruning test, so the guide now teaches the new one. `CLAUDE.md` now says `guard/gh-hook` scans each publishing gh command, since it can't check that the file-and-show flow ran, and `gear-respec` now names the audit log's latest entry format. Claude Code's changelog has nothing newer than 2.1.316.

| Metric | Before | After |
| --- | --- | --- |
| Total at turn 0, with connectors and auto-memory | 22,107 | 22,115 |
| Harness share, with connectors | 4,442 | 4,449 |
| Harness share, without connectors | 2,750 | 2,756 |
| Vendor floor | 16,972 | 16,972 |
| Auto-memory section, outside the share | 693 | 694 |
| Account-synced skills | 699 (11) | 699 (11) |
| Account connectors | 1,693 | 1,693 |
| `bard` plugin | 728 | 728 |
| User CLAUDE.md | 643 | 643 |
| `loadout` plugin | 469 | 476 |
| `homelab` plugin | 73 | 73 |
| Personal skills and the rest | 137 | 137 |

The 7-token rise in `loadout` is the `pr-turn-in` description change from 0.10.1, which reverting it on a scratch copy of the plugin confirmed. Typed-only skills such as `gear-heal` measured 0.

**Hook p95, skill usage and eval results:** no hook changed, and the one skill edit doesn't affect what triggers it, so there's no new table.
