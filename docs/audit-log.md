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
