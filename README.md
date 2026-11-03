# loadout

*A Claude Code loadout you can fork: equip only what earns its slot.*

Every Claude Code session starts at level 1. It doesn't know how you like to work, where your repo breaks convention, or what you learned the hard way last month.

loadout is the gear I hand it at the door, a harness: the skills, rules and scripts you add around Claude Code so it works the way you do. It holds skills for planning, debugging, review, docs and PRs, hooks (scripts Claude Code runs on events such as a stop), and a statusline. It installs as a plugin marketplace with one script, and it measures itself. Every piece has to show what it costs and what it changes, and a scheduled retro proposes what to delete.

It's for you if you use Claude Code every day and your CLAUDE.md has started to look like a junk drawer. Fork it and change it, because a harness is personal and this one is mine. If you're auditing a harness for a team, start with [Guild rules](#guild-rules-for-a-team).

## Level 1: why a harness

Every session starts from zero: no preferences, no repo conventions, no lessons from last month. Claude Code gives that knowledge places to live, such as output styles, CLAUDE.md files, skills and hooks. A harness is your deliberate, versioned choice of what goes in each place, shared across your machines.

The thing to guard against is growth. A harness rarely fails by being wrong. It works, then it collects rules, skills and plugins until nobody can say what any one of them does. So this one stays small, and each piece pays for its slot. [The guide](WRITING-AN-EFFECTIVE-HARNESS.md) explains how, and what the measurements found.

## The pack: what's inside

loadout is a plugin marketplace. Enable only the plugins you want.

| Plugin | Scope |
| --- | --- |
| `loadout` | The core: skills for a ticket from idea to PR, skills that keep the harness itself current, the hooks and the statusline |
| `bard` | Optional: the `peer` output style, which sets how Claude talks to you, and a skill that drafts text published under your name |
| `homelab` | Optional server skills, such as deploying containers to unRAID |

A few of the skills:

| Skill | What it does |
| --- | --- |
| `/loadout:map-scout` | Turns an open idea into a decision, one question at a time |
| `/loadout:bug-hunt` | Reproduces a bug with a failing test before it changes code |
| `/loadout:review-party` | Runs your checks and the app, then sends independent reviewers |
| `/loadout:gear-respec` | The retro: proposes what to add and what to delete, in one pull request |
| `/loadout:repo-raid` | Audits any repo, read-only, and writes a private report |

`/loadout:gear-stats` prints the harness's measured state: what it adds to each session, hook timings and the last retro. The guide has [the full inventory](WRITING-AN-EFFECTIVE-HARNESS.md#the-kit), and [the audit log](docs/audit-log.md) has every measurement so far.

`map-scout` and `repo-raid` send the names and descriptions of your GitHub repos, private ones included, and the latest commit subjects of the newest ones, to your Claude session without asking. To turn that off and keep the skills, create `~/.config/loadout/no-portfolio`. The guide says [what each skill sends where](WRITING-AN-EFFECTIVE-HARNESS.md#what-sends-data-where).

## Gear up: install

You need bash 5 or newer (on macOS, `brew install bash`), `git`, `jq`, `perl`, and the `claude` CLI. The PR and retro skills also need `gh`.

Fork the repo first, then clone your fork and run the installer:

```
git clone https://github.com/<you>/loadout ~/code/loadout
~/code/loadout/install.sh example
```

The installer reads the marketplace source from your checkout's `origin`, so your fork updates only when you push. The `example` profile enables `loadout` alone. `profiles/workstation.json` is my machine, with `homelab`, `bard` and its forced style, which overrides any style you pick.

<details>
<summary>What the installer changes, and how to uninstall</summary>

The installer backs up `~/.claude/settings.json` to `~/.claude/backups/`, then deep-merges the profile over it with `jq`. The example profile registers your marketplace, enables `loadout`, and points the statusline at the marketplace clone. Arrays such as `permissions.allow` are unioned, and every other key survives, so retiring an entry or a key means deleting it by hand. Removing it from a profile doesn't remove it from a machine. A second run changes nothing. To keep one machine's settings outside your fork, add `--machine <file>`, which layers a private profile over the public one. Your user `~/.claude/CLAUDE.md` stays yours, because a plugin can't ship it.

To uninstall:

1. Run `claude plugin uninstall loadout@loadout`, and `bard@loadout` or `homelab@loadout` too if you enabled them.
2. Run `claude plugin marketplace remove loadout`.
3. Restore `settings.json` from the oldest file in `~/.claude/backups/`, taken before your first install, or delete the keys the profile added, including `statusLine`, `permissions.allow` and `env.LOADOUT_REPO`.

</details>

## Clear a dungeon: one ticket, start to finish

1. Run `map-scout` if the approach is still open.
2. Run `map-draw` if the work spans sessions, then `map-follow` to carry out the plan.
3. Run `bug-hunt` when something breaks along the way.
4. Run `review-party` before you call it done. A hook asks for it when two or more files changed.
5. Run `pr-turn-in` to commit and open the PR.

Claude picks most of these up on its own when they apply. The upkeep skills, such as `gear-respec`, run only when you type them.

## Forge a skill: add your own

1. Write the eval first, in `plugins/loadout/evals/<name>-smoke/case.yaml`.
2. Write `plugins/loadout/skills/<subject>-<flavor>/SKILL.md`, with a description under 200 characters that says what it does and when to use it.
3. Run `scripts/eval plugins/loadout --case <name>-smoke`, and keep the skill only if the with-plugin arm beats the baseline.
4. Run `scripts/check` and open a PR.

The guide has [the full steps](WRITING-AN-EFFECTIVE-HARNESS.md#add-a-skill), and [section 6](WRITING-AN-EFFECTIVE-HARNESS.md#6-write-the-eval-first) explains how evals decide what stays.

## Reroll: fork it

1. Start from `profiles/example.json`.
2. Add your commit email to `guard/allowed-emails`, or pre-commit and CI will reject your commits. Keep the existing lines, because the history you forked needs them.
3. Write a generator for your own identity guard denylist, in the shape of `guard/denylist.example`. Mine isn't published, because its sources are private. [Section 10](WRITING-AN-EFFECTIVE-HARNESS.md#fork-the-guard) says what it needs and which skills depend on it.
4. Run `git config core.hooksPath .githooks` so the guard runs, and run `scripts/check` before a PR. [CONTRIBUTING.md](CONTRIBUTING.md) has the rest.

Keep the machinery: the budget script and lint, the eval runner, the hook wrapper, the installer, and the one-store memory rule. Replace the opinions: the style's wording, the skill set, the statusline segments, the hook budgets, and the retro's cadence.

## Guild rules: for a team

A shared harness fails the same way a personal one does, only bigger, because every session of every person pays for every always-on token. The guide covers [what changes for a team](WRITING-AN-EFFECTIVE-HARNESS.md#11-share-it-with-a-team), with a six-step audit you can run on your own harness.

## Allies: Crystal Bridge

loadout grew up beside [Crystal Bridge](https://github.com/crystal-bridge/crystal-bridge), a web app that runs Claude Code sessions across all your machines and dresses them up as a 16-bit RPG. That's where the flavor here comes from. Its Inventory panel lists these skills, and their names read like gear.

Neither project needs the other. The one seam is `CRYSTAL_SESSION`: any host that sends its own notifications can set it, and the notify hook stays quiet.

## Lore: read more

- [Writing an effective harness](WRITING-AN-EFFECTIVE-HARNESS.md) is the long version: why each piece works the way it does, what I rejected, and everything I got wrong along the way.
- [The eval results](docs/eval-results.md) show the latest score for every case.
- [The public repo standard](docs/public-repo-standard.md) is the checklist every public repo here meets.

## License

MIT, see [LICENSE](LICENSE). Adapted third-party text is credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
