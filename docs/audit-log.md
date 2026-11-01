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

**Eval results:** of 31 cases, 17 pass, 6 score below 0.80, 5 aren't trusted because Bash fails in the eval sandbox, and 3 haven't run. See [eval-results.md](eval-results.md).
