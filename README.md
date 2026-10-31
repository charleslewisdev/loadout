# loadout

*A Claude Code loadout you can fork: equip only what earns its slot.*

Every Claude Code session starts at level 1. It doesn't know how you like to work, where your repo breaks convention, or what you learned the hard way last month.

loadout is the gear I hand it at the door: nine skills, five hooks, and a statusline, packaged as a plugin marketplace with one installer. An optional second plugin, `bard`, adds a voice. One of the nine skills is a retro whose favorite move is deleting things.

This repo is for you if you use Claude Code every day and your CLAUDE.md has started to look like a junk drawer. Fork it and change it, because a harness is personal and this one is mine. If you're auditing a harness for a team, start with [For a team](#for-a-team).

## Character sheet

`/loadout:gear-stats` prints a longer version of this sheet. These stats are from October 31, 2026, on Claude Code 2.1.316:

| Stat | Value | In plain words |
| --- | --- | --- |
| **Encumbrance** | 5,986 of 6,000 tokens | What my whole setup adds to every session before the first prompt |
| **Inventory** | 9 skills, plus 1 in `bard` | Procedures Claude picks up when they apply, or that you type |
| **Reflexes** | 5 hooks, all under 300 ms at p95 | Things that always happen, because a script does them |
| **Class** | `bard:peer` | The output style: who Claude is talking to, and how |
| **Save point** | Every 90 days at most | A retro that opens one pull request of additions and deletions |

Yes, that's 14 tokens from the ceiling. The `loadout` plugin is about 570 of them, and the biggest piece is skills synced to my Claude account, at about 2,881 tokens before truncation. It's the first job for the next save point.

> [!NOTE]
> **About the evidence.** Every number here comes from a command I ran, or carries a link. Rules I could test had to change Claude's behavior in a with-and-without eval to stay, and [the guide](WRITING-AN-EFFECTIVE-HARNESS.md) lists the exceptions. Anything marked **opinion** is my taste, not how Claude Code behaves.

## Install

You need bash 5 or newer (on macOS, `brew install bash`), `git`, `jq`, `perl`, and the `claude` CLI. The PR and retro skills also need `gh`.

Fork the repo first, then clone your fork and run the installer:

```
git clone https://github.com/<you>/loadout ~/code/loadout
~/code/loadout/install.sh example
```

The installer reads the marketplace source from your checkout's `origin`, so your fork updates only when you push. The `example` profile enables `loadout` alone. `profiles/workstation.json` is my machine, with `bard` and its forced style, which overrides any style you pick.

<details>
<summary>What the installer changes, and how to uninstall</summary>

The installer backs up `~/.claude/settings.json` to `~/.claude/backups/`, then deep-merges the profile over it with `jq`. The example profile registers your marketplace, enables `loadout`, and points the statusline at the marketplace clone. Every other key survives, and a second run changes nothing. Your user `~/.claude/CLAUDE.md` stays yours, because a plugin can't ship it.

To uninstall:

1. Run `claude plugin uninstall loadout@loadout`, and `bard@loadout` too if you enabled it.
2. Run `claude plugin marketplace remove loadout`.
3. Restore `settings.json` from the oldest file in `~/.claude/backups/`, taken before your first install, or delete the keys the profile added, including `statusLine` and `env.LOADOUT_REPO`.

</details>

## Crystal Bridge

loadout grew up beside [Crystal Bridge](https://github.com/crystal-bridge/crystal-bridge), a web app that runs Claude Code sessions across all your machines and dresses them up as a 16-bit RPG. That's where the flavor here comes from. Its Inventory panel lists these skills, and their names read like gear.

Neither project needs the other. The one seam is `CRYSTAL_SESSION`: any host that sends its own notifications can set it, and the notify hook stays quiet.

## Why a harness

Every session starts from zero: no preferences, no repo conventions, no lessons from last month. Claude Code gives that knowledge places to live, such as output styles, CLAUDE.md files, skills, and hooks. A harness is your deliberate, versioned choice of what goes in each place, shared across your machines.

The thing to guard against is growth. A harness rarely fails by being wrong. It works, then it collects rules, skills, and plugins until nobody can say what any one of them does. So this one stays small and measured, and everything in it pays for its slot.

## What goes where

Each kind of instruction has one home.

| Layer | Use it for | What it costs |
| --- | --- | --- |
| Output style | Who Claude is talking to, and how | Every session |
| User `~/.claude/CLAUDE.md` | Hard rules for every project | Every session |
| Project `CLAUDE.md` | Build and test commands, conventions that differ from defaults | Every session in that repo |
| Rule in `.claude/rules/` with `paths:` | Guidance for one part of the code | Nothing until a matching file is read |
| Skill | A procedure or domain knowledge | The description always, the body when used |
| Hook | A guarantee, run outside the model | Milliseconds per call |
| Statusline | What you glance at | Zero tokens |

To place something new, ask three questions:

- **Must it always happen?** Make it a hook, because prose can't guarantee anything.
- **Should Claude pick it when relevant?** Make it a skill.
- **Do you run it on purpose?** Make it a typed-only skill (`disable-model-invocation: true`), which costs nothing until you type it.

## Inventory

| Skill | Invoked by | What it does |
| --- | --- | --- |
| `map-scout` | Claude | Turns an open idea into a decision |
| `map-draw` | Claude | Turns a decision into a plan, with a test per task |
| `map-follow` | Claude | Runs the plan task by task in fresh subagents |
| `bug-hunt` | Claude | Reproduces a bug with a failing test before it changes code |
| `review-party` | Claude | Runs your checks and the app, sends independent reviewers, and keeps findings a verifier scores 80 of 100 or higher |
| `pr-turn-in` | Claude | Handles branches, commits, and PRs, and checks each PR claim against `git diff` |
| `gear-stats` | You | Prints the character sheet |
| `gear-mend` | You | Logs one annoyance for the next retro, plus the fix when it's clear |
| `gear-respec` | You | Runs the retro and proposes what to add and delete |
| `scribe-as-me` (`bard`) | You | Drafts text published under your name, and never posts it |

The five hooks check your configuration at session start, send desktop notifications on stop and on input needed (two hooks), format files where the repo uses prettier or ruff, and run `review-gate`. That last one blocks a stop once per batch of work when two or more files changed since the last `review-party`, so Claude reviews multi-file work before calling it done.

### One ticket, start to finish

1. Run `map-scout` if the approach is still open.
2. Run `map-draw` if the work spans sessions, then `map-follow` to carry out the plan.
3. Run `bug-hunt` when something breaks along the way.
4. Run `review-party` before you call it done.
5. Run `pr-turn-in` to commit and open the PR.

Outside the ticket, `gear-stats` reads the sheet, `gear-mend` handles anything that annoys you, and `gear-respec` is the periodic save point.

### Add a skill

1. Write the eval first: `plugins/loadout/evals/<name>-smoke/case.yaml`, with a `tool_used: Skill` grader marked `arm: with-only` and at least one grader for the result.
2. Create `plugins/loadout/skills/<subject>-<flavor>/SKILL.md`. Keep the description under 200 characters, and say what the skill does and when to use it. Keep the body under 150 lines. If people type it rather than Claude picking it, add `disable-model-invocation: true`.
3. Run `scripts/eval plugins/loadout --case <name>-smoke`. If the case plants files, add `--scaffold --allow-tools Bash Edit Write`. Keep the skill only if the with-plugin arm beats the baseline.
4. Run `scripts/check` and open a PR. After the merge, invoke the skill once by name so its usage score starts above zero.

A skill from outside arrives with `disable-model-invocation: true` and earns its place in the listing.

## Big reference material

Reference material should never load by itself. Take a 2,000-term glossary. My answer (**opinion**): put it in a data file such as `glossary.tsv`, and add one pointer line to CLAUDE.md that names the file and the `grep` command to search it. Nothing loads until a term comes up. The guide has [the full ladder](WRITING-AN-EFFECTIVE-HARNESS.md#8-keep-reference-material-out-of-the-pack), from a pointer line up to a live query, and three splits that don't work.

## If you fork it

1. Start from `profiles/example.json`.
2. Add your commit email to `guard/allowed-emails`, or pre-commit and CI will reject your commits. Keep the existing lines, because the history you forked needs them.
3. Write a generator for your own identity guard denylist. It prints one extended regex per line to `~/.config/loadout-guard/denylist` (mode 0600), in the shape of `guard/denylist.example`, plus a canary line of your own. Mine isn't published, because its sources are private.
4. Run `git config core.hooksPath .githooks` so the guard runs, and run `scripts/check` before a PR. [CONTRIBUTING.md](CONTRIBUTING.md) has the rest.

Keep the machinery: the budget script and lint, the eval runner, the hook wrapper, the installer, and the one-store memory rule. Replace the opinions: the style's wording, the skill set, the statusline segments, the hook budgets, and the retro's cadence.

## For a team

A shared harness fails the same way a personal one does, only bigger, because every session of every person pays for every always-on token. The guide covers [what changes for a team](WRITING-AN-EFFECTIVE-HARNESS.md#11-share-it-with-a-team) and includes a six-step audit you can run on your own harness.

## Read more

[Writing an effective harness](WRITING-AN-EFFECTIVE-HARNESS.md) is the long version: why each piece works the way it does, what I rejected, and [how I got here](WRITING-AN-EFFECTIVE-HARNESS.md#12-how-i-got-here), including everything I got wrong along the way.

## License

MIT, see [LICENSE](LICENSE). Adapted third-party text is credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
