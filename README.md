# loadout

loadout is my Claude Code harness: one plugin marketplace, one always-on plugin, and the scripts that measure what the harness costs every session. It holds an output style, eleven skills (one of them a retro that proposes deletions), four hooks and a statusline. A new machine runs one installer and gets the same setup.

I wrote this README for two readers:

- **Someone building a personal harness.** Each section gives the mechanism, why I chose it, and the measurement behind it, so you can copy it or reject it on the evidence.
- **A team auditing a shared harness.** A harness shared by developers, QA and DevOps engineers fails the same way a personal one does, only bigger. Most sections end with what a team would do differently, and [For a team](#for-a-team) has an audit you can run on yours.

Fork it and edit it; don't install it as-is. It encodes one person's taste. Where a paragraph is my taste and not how Claude Code behaves, it says **opinion**. Every number comes from a command run on my machine on Claude Code 2.1.278 in September 2026, or carries a link. The long form, with the evidence, the alternatives I rejected and what I got wrong, is [Writing an effective harness](WRITING-AN-EFFECTIVE-HARNESS.md).

## Install

Fork the repo first. The profile's marketplace source names my repo and tracks its `main`, so set `repo` in `profiles/workstation.json` to your fork before the first install; otherwise you get my plugin, forced style included, updating whenever I push.

```
git clone https://github.com/<you>/loadout ~/code/loadout
~/code/loadout/install.sh workstation
```

The installer backs up `~/.claude/settings.json` to `~/.claude/backups/`, then deep-merges `profiles/workstation.json` over it with `jq`. The profile registers this marketplace, enables the `loadout` plugin, sets `outputStyle: "loadout:peer"`, points the statusline at the marketplace clone, keeps transcripts 120 days and turns off AI attribution in commits and PRs. Every other key you have survives, and a second run changes nothing. A plugin cannot ship your user `~/.claude/CLAUDE.md`, so that file stays yours.

To change the repo itself, run `git config core.hooksPath .githooks` so the identity guard runs, and `scripts/check` before a PR.

## Why a harness exists

Every Claude Code session starts from zero. The model doesn't know how you want to be spoken to, which conventions in your repo differ from the defaults, or what you learned last month. Claude Code gives that knowledge places to live: output styles, CLAUDE.md files, rules, skills, hooks, memory. A harness is a deliberate choice of what goes in each place, versioned and shared across machines.

The failure to guard against is growth. My earlier harnesses worked, then gathered rules, skills and plugins for a year until I couldn't say what each one cost or whether it helped. That's the normal path: across 1,867 repositories, 77.3 percent of instructions that disappear from an instruction file go in a wholesale rewrite or a move to a sibling file, and afterwards the file grows faster, 4.9 against 4.1 percent per commit ([arXiv 2608.11095](https://arxiv.org/abs/2608.11095)). Anthropic went the other way with its own prompt: "We removed over 80% of Claude Code's system prompt for models like Claude Opus 5 and Claude Fable 5 with no measurable loss on our coding evaluations." ([claude.com blog](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)).

So this harness is small, and the tools that keep it small came first. The identity guard, the budget script and the eval runner landed together in the first real commit, with the one style they needed to be tested on; the first skill arrived a phase later, as `git log --reverse --name-only` shows.

## What it costs, measured

Every session pays for what loads before your first prompt. I measure that with a command, never an estimate:

```
claude -p "Reply with exactly the word OK and nothing else." --model haiku --output-format json \
  | jq '.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens'
```

`scripts/budget` runs it in four configurations in an empty directory, three times each, and subtracts. Haiku is the measuring model because it has the smallest window in regular use, so truncation shows there first.

| Configuration | Added to the command | Before loadout | Legacy removed, 2026-09-21 |
| --- | --- | --- | --- |
| As configured | nothing | 25,288 to 25,843 | 23,944 |
| Auto-memory off | `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` | 22,333 | 20,995 |
| Vendor floor | `--safe-mode` | 17,859 | 17,712 |
| **Harness share** | auto-memory off minus the floor | **4,474** | **3,283** |

The floor is Claude Code's own system prompt, built-in tools and bundled skills. The auto-memory section (about 2,950 tokens) is vendor text I keep on by choice, so it has its own line outside the ceiling. A fourth run, with an empty strict MCP config, shows that 1,514 of the 3,283 are the claude.ai connectors. The ceiling is 6,000 and the target is about 3,000.

Four things I learned about reading the number:

- **Runs disagree.** Before loadout, runs varied by up to 827 tokens: a legacy hook's health check and two local MCP servers sometimes finished before the first request. Now the claude.ai connectors race it: one set of three runs gave 1,754 to 3,268. So the script checks the ceiling against the highest of three runs.
- **The skill listing overflows.** On Haiku, 34 skills put 17,981 characters into a listing budgeted at 8,000, so most descriptions get cut. loadout's five model-invoked skills are 860 of those characters; most of the rest are bundled and account-synced skills. Past the budget, descriptions are cut to fit, so removing skills saves little: taking out 14 cut 3,717 characters of descriptions, and the share rose by 15 tokens.
- **`claude plugin details` under-reports.** It counts neither the output style nor anything a session-start hook prints. Before loadout had skills, it showed about 0 always-on tokens while the style was already loading in every session.
- **A logging proxy is wrong for totals.** With `ANTHROPIC_BASE_URL` set, deferred tool loading switches off, and the same prompt cost 79,181 tokens against 25,378 without it. Use a proxy to see structure, never to count.

**For a team:** every always-on token is paid by every session of every person. Run the same four configurations on the smallest model your team uses, then again inside each main repository to count its CLAUDE.md and rules.

## The layers

Each kind of instruction has one home, chosen by how that home reaches the model and what it costs. A logging proxy on 2.1.278 showed where each one lands.

| Layer | What it's for | How it reaches the model | Cost |
| --- | --- | --- | --- |
| Output style | who the model is talking to and how | a block in the first user message, plus a 32-token reminder before each prompt; never in a fresh subagent (a fork inherits it) | every session |
| User `~/.claude/CLAUDE.md` | hard rules for every project | a block in the first user message | every session |
| Project `CLAUDE.md` | build and test commands, conventions that differ from defaults | a block in the first user message | every session in that repo |
| Rule in `.claude/rules/` with `paths:` | guidance for one part of the code | loaded when a matching file is read | nothing until then |
| Skill | a procedure or domain knowledge | name and description always; the body when used | description always, body on use |
| Hook | a guarantee | runs outside the model; plain output from session-start and per-prompt hooks enters context, and so does any hook's `additionalContext` or blocking reason | milliseconds per call |
| Statusline | what you glance at | never reaches the model | zero tokens |

Three rules place a new piece. If it must always happen, it's a **hook**, because prose can't guarantee anything. If the model should pick it when relevant, it's a **skill**. If you run it on purpose, it's a **typed-only skill** (`disable-model-invocation: true`), which costs nothing until you type it.

The style has no system-prompt privilege. Its body and CLAUDE.md sit in the same cached block, and the docs say CLAUDE.md is "delivered as a user message after the system prompt" ([memory docs](https://code.claude.com/docs/en/memory)). The style wins for register on three narrower facts: the per-prompt reminder, one system-prompt sentence that tells the model to follow its "Output Style", and subagents never inheriting it. It also survives `/compact`, because compaction rebuilds that block from disk.

One cost trap: session-start output is sent again after every compaction, so a hook that prints a skill body pays for it again and again. The superpowers plugin's injection measured 4,015 characters a session. loadout's only session-start hook prints nothing on a configured machine; when something is wrong, it uses `systemMessage`, which reaches you and never the model.

**For a team:** the same table works as an inventory. List every file and plugin a session loads, put each in its row, and ask whether it sits in the cheapest layer that does the job.

## Budgets for each surface

Every always-on surface has a target and a ceiling. `scripts/budget` measures the total; `scripts/lint-budgets` checks files offline, failing on a ceiling and warning past a target, and CI runs it on every push. Budgets never block a coding session.

| Surface | Target | Ceiling | Now | Basis |
| --- | --- | --- | --- | --- |
| Harness share | about 3,000 tokens | 6,000 tokens | 3,283 | about 3 percent of a 200k window above the vendor floor |
| Output style body | 60 lines, 600 tokens | 100 lines, 1,000 tokens | 24 lines, about 506 tokens | Anthropic's built-in styles run 250 to 370 tokens, more when they carry examples |
| User CLAUDE.md | about 30 lines | 200 lines | 41 lines (warning) | the docs: "target under 200 lines per CLAUDE.md file" |
| Project CLAUDE.md | about 80 lines | 200 lines | template under 20 | build, test, conventions that differ, pitfalls |
| SKILL.md body | under 150 lines | 500 lines | at most 65 lines | the docs: "Keep `SKILL.md` under 500 lines" |
| One skill description | | 200 characters | 132 to 182 | the listing budget below |
| All harness descriptions | | 5,000 characters | 1,782 | the listing is window × 4 × 0.01 characters: 8,000 on a 200k model |
| Session-start output | nothing on a configured machine | 300 characters | 0 | re-sent after every compaction; checked by hand, not linted |

The 200-line ceiling rests on token cost, not adherence. A factorial study measured compliance of 60.0, 65.2, 67.7 and 64.0 percent at 25, 100, 250 and 500 lines, and the size effect was not significant ([arXiv 2605.10039](https://arxiv.org/abs/2605.10039)).

**For a team:** the listing budget is shared by everyone's plugins. Over budget, nothing is removed: the lowest-scoring skills lose their description and show as a bare name, and subagents on 200k models see that cut list. Cap descriptions, mark typed commands `disable-model-invocation: true`, and enable stack skills only in the projects that use them.

## Identity and voice

Register lives in one forced output style, `peer`. It describes me as the reader: a senior engineer who wants a peer, with an exception for database design and performance, where it should explain its reasoning and flag risks. It asks for plain language, sentences around twenty words, and every reference explained before it's used. It bans four habits of machine prose and six filler words, asks it to relay reviewer findings with their severity intact, and asks it to run the project's checks and show the output before calling anything done. The wording is **opinion**; replace it with your own.

**How it's delivered.** The style ships in the plugin with `force-for-plugin: true`, and the installer also sets `outputStyle`. Both are needed. The per-prompt reminder is skipped when `outputStyle` is unset, before Claude Code looks at forced styles, so forcing alone delivers the body without the reminder. The eval sandbox can't set `outputStyle`, so only a forced style can be tested at all.

**What it can do.** Make sessions better to work in. That's the whole claim: it's a comfort trade. Across 162 personas, four model families and 2,410 factual questions, no persona beat a no-persona control ([Zheng et al., EMNLP 2024 Findings](https://aclanthology.org/2024.findings-emnlp.888/)).

**What it can't do.** It never reaches a fresh subagent, which is why reviews run in fresh subagents it can't soften; a forked subagent inherits the parent's conversation and the style with it. It overrides any style you pick while the plugin is enabled. It doesn't hold up in long written artifacts: a retro file written under the forced style still drew em-dashes.

**What the evals cut.** Each rule I could test got a case that runs with and without the plugin, and a rule whose case showed no difference went, with one exception noted below. Two lessons came out of that:

- **Packing matters.** As one clause in a list of banned things, the em-dash rule held in 1 of 5 runs. As its own sentence, "Never write the em-dash character; use a comma, a colon or a new sentence.", it held in 9 of 10.
- **Most anti-sycophancy rules were already default behavior.** I started with rules to restate claims as questions, hold a recommendation under pushback, state assumptions, decline requests built on a wrong premise, and a humor sentence. Eighteen cases on Sonnet 5, and the ones with no delta again on Opus 5, scored the same with and without every one of them, so all five went. Asking in place of asserting does reduce sycophancy in the literature ([UK AISI, arXiv 2602.23971](https://arxiv.org/abs/2602.23971)); on these cases both models already caught the planted errors without the rule. Only the writing rules still show a positive delta (0.97 against 0.87). The verify-before-done sentence scored 0.17 to 0.33 against 0, but what it changed is how replies report checks, not whether the model runs them. The filler-word rule showed no difference because the baseline already avoided those words on the test prompt, and it stays until a prompt that elicits them can judge it.

Writing as me in public is a separate, typed-only skill, `/loadout:write-as-me`: first person, no em-dashes, emoji only as list markers. It drafts and never posts.

**For a team (opinion):** don't force a style. A forced style overrides everyone's choice while its plugin is enabled. Ship two or three styles people can pick, and put shared rules in reviewed places instead.

## Skills

| Skill | Invoked by | What it does |
| --- | --- | --- |
| `code-debug` | model | reproduces the bug with a failing test before changing code |
| `git-pr` | model | branch, commit and PR conventions, checking each PR claim against `git diff` |
| `plan-brainstorm`, `plan-write`, `plan-run` | model | open idea to decision; decision to a plan with a test per task; the plan run task by task in fresh subagents |
| `code-review` | typed | runs checks and the app, sends independent reviewers, then a verifier drops findings under 80 of 100 |
| `code-verify` | typed | runs the checks that cover a change and shows the output |
| `write-as-me` | typed | drafts text published under my name |
| `harness-status`, `harness-retro`, `harness-papercut` | typed | the harness's measured state; the 90-day retro; one line of friction for the retro to read |

Names are `<domain>-<action>`, so the slash menu groups them. Two skills became typed-only after their evals. `code-verify` fired in 0 of 6 runs as a model-invoked skill, so its rule moved into the style as one sentence. `code-review` collided with a bundled skill of the same name, and the model picked the bundled one.

### Adding a skill

1. Write the eval first: `plugins/loadout/evals/<name>-smoke/case.yaml`, with a `tool_used: Skill` grader marked `arm: with-only` and at least one grader for the result.
2. Create `plugins/loadout/skills/<domain>-<action>/SKILL.md`. The description stays under 200 characters and says what it does and when to use it; the body stays under 150 lines. Add `disable-model-invocation: true` if people type it rather than the model picking it.
3. Run `scripts/eval plugins/loadout --case <name>-smoke` (add `--scaffold --allow-tools Bash Edit Write` when the case plants files). Keep the skill only if the with-plugin arm beats the baseline.
4. Run `scripts/check`, open a PR, and after the merge invoke the skill once by name, so its usage score starts above zero.

A skill from outside arrives with `disable-model-invocation: true` and earns its place in the listing.

**For a team:** add a code owner per plugin, and make the eval a CI requirement the way this repo's CI fails any plugin without `evals/`.

## When reference material outgrows the budgets

The budgets cover what loads by itself. Reference material never should: a 2,000-term glossary, a map of issue-tracker boards, a table of teammates' handles. Put each piece on the first rung that fits how it's used.

| Rung | How it's used | Where it goes | What it costs |
| --- | --- | --- | --- |
| 1 | needed every session | one pointer line in CLAUDE.md naming the file and the command to search it | the line |
| 2 | needed for one part of the code | a rule in `.claude/rules/` with `paths:` frontmatter | nothing until a matching file is read |
| 3 | needed for one task | a skill body, procedure only | the body, for the rest of the session |
| 4 | read a section at a time | files beside `SKILL.md`, one level deep, split by topic, with a contents list past 100 lines | the sections read |
| 5 | looked up one entry at a time | a data file (TSV or JSON) plus `grep` or a small lookup script | the matching lines |
| 6 | owned by another system and changing | a live query through that system's CLI or MCP server | the answer |

Measured: a 40-line rule scoped with `paths` added 0 tokens at turn 0 and loaded only after a matching file was read. The same rule without `paths` added 978 tokens to every session. The rungs rest on two lines from Anthropic's [skill authoring guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices): "Only the script's output consumes tokens", and reference files "don't consume context tokens until actually read".

Three splits save nothing or lose data:

- **`@` imports in CLAUDE.md.** "Imported files are expanded and loaded into context at launch", so the split files load anyway.
- **A reference file that links to another.** On nested references, Anthropic warns: "Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information."
- **A table in a skill body.** It stays in context after use and rides through compaction.

**Opinion.** A 2,000-term glossary goes on rung 5: one `glossary.tsv`, one pointer line in CLAUDE.md naming the file and the `grep`, and nothing loaded until a term comes up. The price of every rung above 1 is that the model has to choose to look, so every pointer names the file and the command.

**For a team:** a table of people is personal data. Keep it out of public repos, and query the company directory (rung 6) rather than copying it.

## Hooks, memory and the retro

**Hooks.** Five slots, four with a p95 budget: session start 300 ms, notifications 100 ms, a formatter 300 ms that runs only where the repo configures prettier or ruff, and a Bash guard 50 ms. The Bash guard and the per-prompt slot are empty. Every hook runs through `hook-timed`, which logs its start and end, and `scripts/hook-report` prints p50, p95 and max; the lint fails a hook that bypasses the wrapper. Over the 30 days to 2026-09-21: session start p95 20.9 ms over 167 calls, the stop notification 12.0 ms over 141. A hook over budget for a week gets deleted.

**Memory.** One store: Claude Code's native auto-memory. Transcripts are the raw record, kept 120 days and never summarized, because repeated model consolidation of memory "can fall below the no-memory baseline" ([arXiv 2605.12978](https://arxiv.org/abs/2605.12978)). Knowledge becomes a rule or a skill only through a pull request I review, so a poisoned tool result has no path into future sessions. My MCP memory server and notes server moved out of coding sessions into the one project that uses them.

**The retro.** `/loadout:harness-retro` runs every 90 days at most, sooner if the harness's own skill descriptions pass 4,000 characters, near their ceiling, a memory index passes 100 lines or a skill passes 500. It reads the friction log, my corrections in transcripts, unread memory, the budgets and skill usage, and opens one pull request of proposed additions and deletions. The first one cut two memory indexes from 156 and 144 lines to 21 and 19.

**For a team:** auto-memory is one user on one machine and never propagates. Knowledge the team needs belongs where review already happens: the project CLAUDE.md, `.claude/rules/`, and skills in the team marketplace. The promotion step stays a reviewed pull request.

## For a team

The shape changes more than the mechanisms:

| Concern | One developer (loadout) | A team |
| --- | --- | --- |
| Distribution | one marketplace, one installer, one profile | a versioned team marketplace; plugins enabled per role (developer, QA, DevOps) and per project |
| Rules for everyone | my user CLAUDE.md, copied by hand | managed settings and a managed CLAUDE.md pushed to every machine |
| Shared knowledge | auto-memory, personal by design | reviewed places only: project CLAUDE.md, `.claude/rules/`, skills in the team marketplace |
| Voice | one forced style (opinion) | styles people pick |
| Private strings | a generated denylist of my private names | the same guard for customer names, internal codenames and secrets |

An audit a team harness can run on itself:

1. **Measure the share** as in [What it costs](#what-it-costs-measured). Don't use `claude plugin details` for totals.
2. **Inventory the always-on surfaces:** every CLAUDE.md a session loads, output styles, session-start output, skill and agent descriptions, MCP server instructions, and any hook that returns `additionalContext` on every tool call. Give each a target and a ceiling from the budget table, and lint them in CI.
3. **Check the skill listing** in a debug log. The line to look for starts "Skill listing over budget".
4. **Time every hook** through a wrapper, give each event a p95 budget, and delete what stays over.
5. **Test before trusting.** Every plugin carries `claude plugin eval` cases; a rule with no with-minus-without difference gets cut. Pass `--no-publish` if you're signed in with a claude.ai subscription, or the report is published there as a private artifact ([plugin evals docs](https://code.claude.com/docs/en/plugin-evals)).
6. **Schedule the deletion:** one retro every 90 days at most, ending in one pull request with the new share in it.

Two traps worth checking first. A marketplace added under a name that already exists silently replaces the old one, so two teams must never share a marketplace name. And the identity guard matches strings; what counts as private stays a human call, so a person reads the full-history scan before anything goes public.

**Not covered (opinion):** role workflows such as QA test plans or DevOps runbooks, permissions policy for shared infrastructure, and onboarding. A team harness will need skills for these; the budgets decide how many it can afford.

## If you fork it

Point `repo` in `profiles/workstation.json` at your fork before the first install. Keep the mechanisms: the budget script and lint, the eval runner with `--no-publish`, the hook wrapper, the installer, the one-store memory rule and the reference ladder. Replace the opinions: the style's wording, the skill set, the statusline segments, the hook budgets and the retro's cadence.

The identity guard needs your own denylist. Its generator isn't published, because its sources are private. Write one that prints one extended regex per line to `~/.config/loadout-guard/denylist` (mode 0600), plus a canary line of your own, so the guard's tests can prove it works without typing a real term.

How each decision was reached, what it rejected, and every place the design reversed itself are in [Writing an effective harness](WRITING-AN-EFFECTIVE-HARNESS.md#11-what-i-got-wrong).
