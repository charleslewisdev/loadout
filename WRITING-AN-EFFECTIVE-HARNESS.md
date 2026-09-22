# Writing an effective harness

This is the long form of the [README](README.md): why each part of loadout works the way it does, what I tried instead, what it costs, and where a measurement proved me wrong. The README is the map. This is the argument, in the order I'd apply it to a new harness.

Every number here comes from a command run on my machine on Claude Code 2.1.278 in September 2026, or carries a link. Where a paragraph is my taste and not how Claude Code behaves, it says **opinion**. Sources are listed at the end; I opened each one and checked it against the claim it supports.

Contents:

1. [The failure is growth](#1-the-failure-is-growth)
2. [Where instructions live](#2-where-instructions-live)
3. [Budgets](#3-budgets)
4. [Voice](#4-voice)
5. [Skills](#5-skills)
6. [Evals before content](#6-evals-before-content)
7. [Hooks and memory](#7-hooks-and-memory)
8. [Reference material](#8-reference-material)
9. [Keeping it small](#9-keeping-it-small)
10. [For a team](#10-for-a-team)
11. [What I got wrong](#11-what-i-got-wrong)

## 1. The failure is growth

My earlier harnesses didn't fail by being wrong. They worked, then gathered rules, skills and plugins for a year, until I couldn't say what any one of them cost or whether it helped. Research on instruction files finds the same pattern. Across 1,867 repositories, 77.3 percent of instructions that disappear from a file go in a wholesale rewrite or a move to a sibling file, and afterwards the file grows faster, 4.9 against 4.1 percent per commit ([arXiv 2608.11095](https://arxiv.org/abs/2608.11095)). Files mostly shrink by being rewritten, and then they grow back faster.

Anthropic moved the other way with its own prompt: "We removed over 80% of Claude Code's system prompt for models like Claude Opus 5 and Claude Fable 5 with no measurable loss on our coding evaluations." ([claude.com blog](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)).

So the first thing I built was a number. The harness share is the tokens my setup adds to every session before the first prompt, and one command measures it:

```
claude -p "Reply with exactly the word OK and nothing else." --model haiku --output-format json \
  | jq '.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens'
```

Run it three ways in an empty directory. `--safe-mode` gives the vendor floor: the system prompt, built-in tools and bundled skills, with every customization dropped. `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` gives the floor plus everything I added. Plain gives both plus the auto-memory section. The share is the second minus the first. `scripts/budget` does this, adds a fourth run with an empty strict MCP config to isolate MCP servers, and caches the result for the statusline.

Before loadout the share was 4,474 tokens. With loadout installed, and one legacy plugin and some community skills still loading until I remove them, three runs gave 1,754 to 3,268; the high run includes 1,514 tokens of claude.ai connectors. The ceiling is 6,000.

What I learned about reading that number:

- **Pick the floor carefully.** My first formula passed `--tools ""`, which also strips 15,600 tokens of built-in tools, so the "floor" was too low and the share too high. `--safe-mode` is the clean floor.
- **Keep the auto-memory section on its own line.** It's about 2,950 tokens of vendor text (12,735 characters), on by choice. Counting it against the harness ceiling would punish a decision I made on purpose.
- **Run three times and take the highest.** Runs varied by up to 827 tokens. The debug logs showed two races: a legacy session-start hook whose health check sometimes finished inside its timeout (555 to 601 tokens) and two local MCP servers that sometimes connected before the first request (272 tokens). With both gone, the claude.ai connectors race it instead: the latest three runs gave 1,754 to 3,268.
- **Account-synced skills load in print mode too.** 14 of 59 skills on the first day came from the account, and the only switch for them deletes them.
- **`claude plugin details` under-reports.** It counts neither output styles nor what a session-start hook prints. Before loadout had skills, it showed about 0 always-on tokens while the style was already loading in every session.
- **A proxy is for structure, never totals.** With `ANTHROPIC_BASE_URL` set, deferred tool loading switches off. The same prompt cost 79,181 tokens through a logging proxy and 25,378 without it.

Haiku is the measuring model because it has the smallest window in regular use, so truncation shows there first.

**Two evidence rules.** A number comes from a command run on my machine or carries a source. A sentence attributed to Anthropic is pasted, never paraphrased. A review of an early draft found 28 errors, and every one sat in a paraphrase; none sat in the research notes it summarized. I'd keep both rules for any harness you intend to publish.

## 2. Where instructions live

Each kind of instruction gets one home, chosen by how that home reaches the model and what it costs per session. The layer table is in the [README](README.md#the-layers). Here is why it looks the way it does.

I put a logging proxy in front of the API and read what each layer actually sends. The output style arrives as a `# Output Style:` block in the first user message, next to CLAUDE.md. The docs say the same about CLAUDE.md: it is "delivered as a user message after the system prompt" ([memory docs](https://code.claude.com/docs/en/memory)). With a style active, the system prompt changes one sentence: "You are an interactive agent that helps users according to your "Output Style", which describes how you should respond to user queries." A 32-token reminder of the style runs before each prompt. A fresh subagent never gets the style; a fork inherits it with the parent's conversation. It survived `/compact` in a probe, because compaction rebuilds the first message from disk.

So the style has no system-prompt privilege. It wins over CLAUDE.md for register on three narrower facts: the reminder, that one sentence, and fresh subagents going without it. I originally believed the style sat in the system prompt, and before that, that CLAUDE.md got "buried in the middle of a long context". Chroma's *Context Rot* study found no notable variation across 11 needle positions on its needle-in-a-haystack task ([Chroma](https://www.trychroma.com/research/context-rot)), so position wasn't the reason either.

Alternatives I rejected:

- **Everything in CLAUDE.md**, as my old setup did. Register rules mixed with project rules, and nothing could test them separately.
- **Register injected by a per-prompt hook.** It costs tokens every turn. I keep it as the next lever: if register drifts by turn eight, a hook of about 60 tokens per turn is the fix.

Three rules place anything new. If it must always happen, it's a hook, because prose can't guarantee anything. If the model should pick it when relevant, it's a skill. If you run it on purpose, it's a typed-only skill with `disable-model-invocation: true`, which costs nothing until you type it.

One trap: session-start hook output enters context and is sent again after every compaction. A hook that prints a skill body pays for it again and again; the superpowers plugin's injection measured 4,015 characters a session. Configuration warnings belong in the hook's `systemMessage` field, which I tested with a marker through the proxy: it reaches the user and never the model.

I also dropped a planned session-context hook (branch, dirty count, worktree). Claude Code already puts the current branch, main branch, git status and recent commits into every session started in a repo. The hook would have repeated them for about 80 tokens per session and per compaction.

**Shipping it.** The repo is a plugin marketplace, and an installer merges one JSON profile into `~/.claude/settings.json`. A plugin alone can't do it: a plugin can't set `outputStyle` or ship your user CLAUDE.md, and its own `settings.json` can set only `agent` and `subagentStatusLine`. I rejected a `directory` marketplace, which my old setup used, because it stores an absolute path in `~/.claude/plugins/known_marketplaces.json` and works only where the checkout sits at the same path. A private marketplace repo is harder than a public one. A `github` source clones over HTTPS, and the CLI turns off credential helpers for some background git calls, so a background refresh of a private repo can fail. Either register an SSH key, or use a `git` source and set `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` so a failed refresh keeps the existing clone. A public repo needs neither.

## 3. Budgets

Every always-on surface has a target and a ceiling. The table with current values is in the [README](README.md#budgets-for-each-surface). The bases:

- **Harness share: 6,000 tokens, target about 3,000.** About 3 percent of a 200k window above the floor. The target is what's left once the legacy setup is gone.
- **Output style: 100 lines and 1,000 tokens, target 60 lines and 600.** Anthropic's built-in styles run 250 to 370 tokens, more when they carry examples. Mine is 24 lines, about 506 tokens.
- **CLAUDE.md: 200 lines.** The docs say "target under 200 lines per CLAUDE.md file". I keep the ceiling for token cost, not adherence: a factorial study measured compliance of 60.0, 65.2, 67.7 and 64.0 percent at 25, 100, 250 and 500 lines, and the size effect was not significant ([arXiv 2605.10039](https://arxiv.org/abs/2605.10039)). The docs still warn that "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!" ([best practices](https://code.claude.com/docs/en/best-practices)).
- **SKILL.md: 500 lines, target 150.** The docs: "Keep `SKILL.md` under 500 lines." A used skill body stays in context for the rest of the session and rides through compaction.
- **Skill descriptions: 200 characters each, 5,000 for the whole harness.** See [Skills](#5-skills).
- **Session-start output: 300 characters.** It's re-sent after every compaction.

The prune test comes from Anthropic's best practices: "For each line, ask: *"Would removing this cause Claude to make mistakes?"* If not, cut it." The same page goes further: "If Claude already does something correctly without the instruction, delete it or convert it to a hook." My evals turned that second line into a procedure (see [Voice](#4-voice)).

**How they're enforced.** `scripts/lint-budgets` checks files offline, fails on a ceiling and warns past a target, and CI runs it on every push. I rejected hooks that enforce budgets at session start: a budget is a maintenance signal, and it should never block a coding session. The harness wraps none of `/doctor`, `/context`, `/skill-doctor` or `claude plugin prune`; they already exist.

## 4. Voice

The README covers [what the style asks for and what the evals cut](README.md#identity-and-voice). This section is for anyone writing their own style.

**Force it and set it.** The style ships in the plugin with `force-for-plugin: true`, and the installer also sets `outputStyle`. In the binary, the per-prompt reminder returns nothing when `outputStyle` is unset, before it looks at forced styles, so forcing alone delivers the body without the reminder. The eval sandbox can't set `outputStyle`, so only a forced style can be evaluated at all. One trap: the sandbox's session record says `output_style: default` even when the forced style is applied. A probe asking the model to quote its style confirmed the body arrives.

**Test each rule on its own.** Give each rule a with-and-without case and one grader, so its effect shows alone. Packing mattered more than wording: the em-dash rule held in 1 of 5 runs as a clause in a list and 9 of 10 as its own sentence. A case can be wrong too. My wrong-premise case first looked like a rule that failed to fire; a review then found a malformed code fence in its prompt, and after the fix it scored the same in both arms.

**Expect most of it to be default already.** Anthropic's best practices say it outright: "If Claude already does something correctly without the instruction, delete it or convert it to a hook." ([best practices](https://code.claude.com/docs/en/best-practices)). The research behind my question rule is sound: non-questions (statements of belief or conviction) drew 24 percentage points more sycophancy than questions, and asking beat an explicit "don't be sycophantic" instruction ([UK AISI, arXiv 2602.23971](https://arxiv.org/abs/2602.23971)). On my cases, Sonnet 5 and Opus 5 caught the planted errors without it, so it went, with four other rules. Three rules have no case at all: relaying reviewer findings with their severity, the database-and-performance exception, and resolving every reference before using it. They stay as untested opinion. The filler-word rule stays without a delta, because the baseline already avoided those words on the test prompt.

**Know what it can't reach.** A fresh subagent never gets the style; a fork inherits the parent's conversation, style included ([output styles docs](https://code.claude.com/docs/en/output-styles)). That's why `/loadout:code-review` briefs fresh subagents: a review the style could soften is worth less. The style also doesn't hold up in long written artifacts: a retro file written under it still drew em-dashes.

**Borrow, and keep public voice separate.** The length rule adapts a line from Dan Hopwood's example style: "Length scales with what the user has to decide, not with the work behind it – a heavy session with one decision gets a short message." ([Hopwood](https://danhopwood.com/posts/two-ways-to-change-claudes-personality)). Writing as me in public is a separate, typed-only skill, `/loadout:write-as-me`. Its first eval's delta turned out to be mostly the style's own em-dash rule, because the style loads in the with-plugin arm. Grade what only the skill asks for.

## 5. Skills

Every enabled skill puts its name and description into every session. The space is a character budget, not a count. From the 2.1.278 binary: the budget is the context window times 4 times 0.01 characters, so 8,000 on a 200k model and 40,000 on a 1M model. Over budget, nothing is removed: the lowest-scoring skills lose their description and show as a bare name. The score is uses times max(0.5^(days since use / 7), 0.1). Subagents on 200k models see the cut list. A skill with `disable-model-invocation: true` is left out entirely.

I first believed skills past about 40 were evicted and a new one "may simply never appear". The binary shows neither.

So each description stays under 200 characters and says what the skill does and when to use it; all eleven together are 1,782 characters, and the five the model can pick are 860. The listing on Haiku is still over budget, 48 skills and 21,698 characters against 8,000, almost all from bundled skills, account-synced skills and a legacy plugin I'm removing. I rejected a custom skill index and a raised budget: capping descriptions is cheaper than either.

**Intake.** A skill from outside arrives with `disable-model-invocation: true` and earns its place. A practitioner's three skill audits reached the same rule: "Disable unused skills the moment they're added." ([dev.to](https://dev.to/shimo4228/15-days-of-skill-sprawl-in-claude-code-lessons-from-3-audits-27em)). A skill written here is invoked once by name after it lands, so its usage score starts above zero. superpowers was disabled the day its replacements landed. It cost about 2,540 tokens per session and injected: "If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill." Anthropic's guidance goes the other way: "Where you might have said "CRITICAL: You MUST use this tool when...", you can use more normal prompting like "Use this tool when..."." ([prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).

**When a skill never fires.** Two of my skills became typed-only after their evals:

- `code-verify` fired in 0 of 6 runs across two descriptions. Without superpowers' "MUST invoke" injection, nothing prompted the model to call a verification skill. Its rule moved into the style as one sentence, which changed how replies report checks, though not whether the model runs them.
- `code-review` collided with a bundled skill of the same name, and the model picked the bundled one. Check a new name against the bundled skills before writing the skill.

A skill can also make things worse. `git-pr`'s claim-check step, meant to stop PR descriptions from repeating false claims in commit messages, produced 3 clean descriptions out of 6, against 5 of 6 without the skill. Only the with-and-without eval showed it.

**Bodies stay short.** Mine run 11 to 65 lines. `code-review` keeps each reviewer's brief in a reference file beside `SKILL.md`, so the team costs nothing until it runs.

## 6. Evals before content

Guidance about a repo feels useful whether or not it changes anything. So every plugin carries `claude plugin eval` cases, and each case runs with and without the plugin; the score difference is the plugin's own contribution. The docs say it plainly: "If a case scores 1.0 both with and without the plugin, the plugin isn't what made it pass." ([plugin evals docs](https://code.claude.com/docs/en/plugin-evals)). Anthropic's skill guidance says to "Create evaluations BEFORE writing extensive documentation" ([skill authoring guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)), and I wrote each skill's case before the skill.

I rejected writing guidance first and a custom eval harness. The accepted cost is about an hour per case and real money: the docs' own example is $0.41 and 74 seconds for one case, three runs, two arms, and my style evals cost about $25 in one phase. Evals need Claude credentials, so they run locally before a merge; CI runs only the free checks and fails any plugin without an `evals/` directory.

`scripts/eval` pins the model and always passes `--no-publish`. When you're signed in with a claude.ai subscription that has artifacts, the CLI publishes each report as a private artifact unless you pass it, and eval prompts are a publishing surface.

Lessons from running them:

- **"Passes" means a positive delta.** At three runs a 0.8 threshold can't tell 0.67 from 0.8 reliably, so I treat it as advisory. Cases that must separate close scores run five times per arm.
- **The Haiku judge is noisy both ways.** It failed a reply that said plainly no tests were included, and passed one that claimed a function already on main. Read transcripts (`--keep-temp`) before trusting a surprising score.
- **Check what the grader reads.** An `llm` grader reads the last message by default. My retro case wrote a correct file and failed 6 of 6 because the judge never saw the file. The `files` target holds only uncommitted changes, and `tool_order` compares only the first matching calls.
- **Use `regex` for facts, `llm` for judgment.** The README's own test, a fresh session answering four questions from the README alone, failed "how do I add a skill" in 6 of 6 runs while every answer was complete. A reworded criterion still failed 2 of 6, again on complete answers. That question now uses four `regex` graders, one per fact the answer needs.
- **A document test has no delta.** The README test gives both arms the same README, so its with-minus-without delta is about zero by design. It passes when every answer is complete, not on a delta.
- **Know the sandbox.** It scrubs `HOME` and custom environment variables. Scaffold scripts run from their own path, so a fixture can copy files from the repo. On Ubuntu, sandboxed Bash needs a bubblewrap AppArmor profile; without it, every shell-dependent case measures a broken sandbox.

Research on tuning guidance points the same way: repository guidance tuned with synthetic bug-fix probes resolved 33.0 percent of SWE-bench Verified tasks, against 28.3 for the static knowledge base it started from and 25.5 unguided ([arXiv 2606.20512](https://arxiv.org/abs/2606.20512)).

## 7. Hooks and memory

**Hooks.** Every synchronous hook is paid on every matching call, and a slow hook is only noticed if it's timed. A practitioner's 43-line wrapper found one hook at p95 3,240 ms across 127 calls ([dev.to](https://dev.to/bokuwalily/your-claude-code-hooks-are-costing-you-minutes-a-day-heres-how-i-measured-it-4im4)). So loadout has five hook slots, each with a p95 budget:

| Slot | Budget | What runs there | p95, last 30 days |
| --- | --- | --- | --- |
| Session start | 300 ms, 300 characters | the silent configuration check | 23.8 ms over 158 calls |
| Notifications | 100 ms | a desktop notification on stop and on input needed | 11.5 ms over 129 calls |
| Formatter | 300 ms | prettier or ruff, only where the repo has that tool's config | 64.1 ms over 2 calls |
| Bash guard | 50 ms | nothing yet | |
| Per prompt | | nothing | |

Every hook runs through `hook-timed`, which logs its start and end, and the lint fails any hook command that bypasses it. A hook over budget for a week gets deleted. The formatter is scoped because my old global formatter rewrote whole files in repos that don't use prettier. The notification hook returns its escape sequence in the hook output's `terminalSequence` field, which the binary describes as "A terminal escape sequence (e.g. OSC 9 / OSC 777 desktop-notification) for Claude Code to emit on your behalf". The Bash guard stays empty until a case appears that `permissions.deny` can't express.

**Memory.** I had four overlapping memory stores installed, and knowledge was written far more often than it was read. Now there's one: Claude Code's native auto-memory, an index plus one file per fact, loaded per project. Transcripts are the raw record, kept 120 days (`cleanupPeriodDays`; the default is 30) and searched with grep. Nothing summarizes them.

I rejected model-written summaries, which the first draft of the design had. In one study of repeated consolidation, "memory utility first rises, then degrades, and can fall below the no-memory baseline" ([arXiv 2605.12978](https://arxiv.org/abs/2605.12978)). That's ARC-AGI with GPT-5.4, not a coding workload, so the evidence is thin. I keep raw records anyway, because that's the cheaper and reversible choice. I also rejected a vector memory server: grep over a few thousand files is free.

Knowledge becomes a rule or a skill only through a pull request I review. Agents that "write and retrieve memory more aggressively are more exploitable" ([arXiv 2606.04329](https://arxiv.org/abs/2606.04329)), and a human-gated promotion step leaves a poisoned tool result no path into future sessions.

I also rejected a memory-retrieval order in the style. The system prompt already carries a 12,735-character auto-memory section, so a second directive adds a rule without adding reach. `scripts/memory-reads` counts how often sessions open memory files instead: 1 read in 8 sessions on day one. A one-line retrieval hook ships only if two weeks of that number show recall is rare.

## 8. Reference material

The six-rung ladder, the measurement behind it and the three splits that don't work are in the [README](README.md#when-reference-material-outgrows-the-budgets). Two points behind it:

- **Pick the rung by how often it's needed, not by size.** A 40-line rule needed in one directory belongs on rung 2 whatever its length; a 20-line table needed once a month belongs on rung 5. Size decides only whether a rung-4 file needs a contents list, which Anthropic suggests past 100 lines so a partial read still shows the file's scope.
- **Every rung above 1 depends on the model choosing to look.** So every pointer names the file and the command, and a pointer nobody follows is worth checking in the retro's unread-memory list.

## 9. Keeping it small

Maintenance is a few tools, all built before the first skill.

**The retro.** `/loadout:harness-retro` runs every 90 days at most, and sooner when the skill listing overflows on the smallest model, a memory index passes 100 lines or a skill passes 500. Pick triggers the harness controls: my listing trigger fires permanently, because bundled and account-synced skills alone overflow the Haiku budget. It works on a `retro/<date>` branch, reads the friction log, my corrections in recent transcripts, memory files nobody read in 90 days, the budgets and skill usage, and writes one dated file that lists each proposal with its evidence. It ends in one pull request; nothing reaches rules or skills until I merge it, and changes to local memory are applied in the session only on my yes. The first retro proposed no repository changes; its work was memory, cutting the two largest indexes from 156 and 144 lines to 21 and 19.

I rejected scheduled rewrites of instruction files, since wholesale rewrites are exactly how files lose instructions and then regrow. If two retro dates pass with nothing produced, the fallback is a calendar reminder to run `/skill-doctor` and delete.

A retro skill needs narrow permissions. Its first draft allowed `Bash(git *)`, which pre-approved `git push origin HEAD:main` on an unprotected branch; unscoped Read, Grep and Glob pre-approved reading transcripts, and unscoped Edit and Write pre-approved memory edits the procedure said to wait for. Instructions alone didn't hold: in sandbox runs the model read files the skill told it not to. List the exact commands a skill needs.

**Papercut.** `/loadout:harness-papercut` writes one annoyance to its own dated file under `retros/friction/`, plus the smallest fix on a branch when the fix is clear, opened as a PR and never merged by the skill. One file per papercut keeps open papercut PRs from conflicting, and the retro reads unmerged papercut branches too.

**The identity guard.** I publish my real harness, not a sanitized skeleton, because a setup used every day teaches better. The cost is that every commit of real configuration can leak a private name, so a guard keeps them out mechanically:

- A generator, private and never committed, builds a denylist of regexes from private sources: every file and directory name in my old private plugin tree, a list of private terms, and a small hand-kept file for what those two miss. It lives outside the repo, mode 0600, with a canary line so tests never type a real term.
- `pre-commit` scans the staged diff and the committer email, `commit-msg` scans the message, and `pre-push` scans every pushed commit, tag and ref name. With the denylist missing, a push to a public or unknown remote is refused. Findings name a location and a denylist line number, never the matched text.
- CI never sees the denylist. It checks every author and committer email in full history against an allowlist, runs a secret scan, and checks names against a short published list of forbidden words.

What the guard taught me:

- **Generated beats typed.** A hand-redacted inventory removed a private top-level name and still leaked two names nested inside file paths. A generated list covers every nested name.
- **It caught its builder.** A `.gitignore` pattern anchored at the repo root let eval results, which hold absolute home paths, get staged, and the denylist refused the commit.
- **Word boundaries miss code.** `_` is a word character, so `\bterm\b` misses `project_term.md` and `TermClient`. The guard also scans a copy with underscores read as spaces and capitals split.
- **PR bodies skip git hooks.** `gh pr create` sends the body straight to GitHub, so the skills write it to a file and scan it with `guard/scan text` first.
- **Transcripts carry your CLAUDE.md.** Before matching transcripts against the denylist, replace the home path with `~` and drop attachment records, which carry the injected user CLAUDE.md and any private terms in it.

The last check stays human: the guard matches strings, and what counts as private is a judgment. So before a repo goes public, a person reads a full-history scan that also covers what `guard/scan --all` never sees: PR titles, bodies and comments, CI logs, and the `refs/pull/*` heads GitHub keeps after a squash merge, which go public with the repo.

**One repo.** Groups of skills ship as extra plugins in the same marketplace, which are already enabled independently. I rejected a second marketplace from day one; the triggers for a split are privacy (a skill describing private infrastructure can't be published) or skill commits drowning harness commits.

## 10. For a team

A team harness fails the same way a personal one does, and every always-on token is paid by every session of every person. The [README](README.md#for-a-team) has an audit a team can run on itself and a table of what changes. Four things matter more at team scale:

- **Shared knowledge lives in reviewed places.** Auto-memory is one user on one machine and never propagates, however useful it looks in one person's sessions. Knowledge the team needs belongs in the project CLAUDE.md, path-scoped rules in `.claude/rules/`, and skills in a team marketplace, each changed through review. The promotion step stays a pull request, now with a code owner per plugin.
- **Organization-wide instructions are managed.** Claude Code supports managed settings and a managed CLAUDE.md pushed to every machine. Use those for the rules everyone shares, not a copied user CLAUDE.md.
- **Distribution is a versioned team marketplace**, with plugins enabled per role (developer, QA, DevOps) and per project. Never reuse a marketplace name: adding a marketplace under a name that already exists silently replaces the old one. I reproduced that in an isolated config directory.
- **Voice is a choice (opinion).** Don't force a style on a team. A forced style overrides everyone's pick while its plugin is enabled. Ship two or three styles people can choose from.

The guard generalizes: the same generated denylist works for customer names, internal codenames and secrets before anything leaves the company. And the reference ladder matters more for a team than for one person, because teams accumulate glossaries, board maps and directories.

What loadout doesn't cover (**opinion**): role workflows such as QA test plans or DevOps runbooks, permissions policy for shared infrastructure, and onboarding. A team harness will need skills for these; the budgets decide how many it can afford.

## 11. What I got wrong

Every pass reversed something the previous one believed. Each reversal came from measuring the platform or reading the primary source, and each is a place where a reasonable-sounding belief would have shipped.

1. **Summarizing memory.** The first draft distilled session logs into summaries and archived the originals. The consolidation research reversed it; the evidence is one study on a non-coding benchmark, and the rejection stands because raw records are the cheaper, reversible choice.
2. **The skill ceiling, twice.** I first said skill indexing was a non-problem, then that skills past about 40 were evicted. The binary shows a character budget, and over-budget skills stay listed without their description. See section 5.
3. **Why the style beats CLAUDE.md, twice.** First "CLAUDE.md gets buried mid-context", which the Context Rot study contradicts. Then "the style sits in the system prompt", which the proxy contradicts. See section 2.
4. **A retrieval directive in the style.** Proposed first in shouting caps, then in normal prose, then dropped: the system prompt already carries an auto-memory section. It became a measurement. See section 7.
5. **A schema claim.** No installed skill used `user-invocable` or `when_to_use`, so I concluded they were invalid fields. The binary lists both. Absence from installed files is weak evidence about a schema.
6. **The floor.** `--tools ""` stripped 15,600 tokens of built-in tools from the floor; `--safe-mode` is the clean one. The same review called my community skills "never invoked"; the usage record showed five of thirteen used, one to eleven times each.
7. **The custom reviewer.** A review cut my planned reviewer in favor of the built-in `/code-review`, under the rule not to rebuild first-party tools. My own review practice runs tests, the app and a visual check, which the built-in doesn't, and Anthropic's own [`code-review` plugin](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-review/commands/code-review.md) says "Do not check build signal or attempt to build or typecheck the app." So `/loadout:code-review` runs checks first, then independent reviewers, then a verifier that drops findings under 80, the plugin's own cut: "Filter out any issues with a score less than 80."
8. **Most of the style's disagreement rules.** I treated sycophancy as the style's main job. With-and-without evals showed both models already correcting planted errors, holding recommendations and stating assumptions.
9. **Skills the model should pick.** `code-verify` never fired once superpowers' injection was gone, and `code-review` lost to a bundled skill of the same name. Both became typed-only.
10. **Whole-transcript skipping.** Scripts that read `~/.claude` skipped every transcript matching the denylist. My old setup put private names into ordinary sessions, so nothing was left to measure. Count-only scripts now withhold matching records and count the rest.

## Sources

Measurements come first: every token count, timing and eval score here was produced on my machine on Claude Code 2.1.278 in September 2026, by `claude -p` token accounting, a logging proxy, greps of the installed binary, or this repo's scripts. I opened each published source below on 2026-09-21 and checked it against the claim it supports.

| Source | What it supports here |
| --- | --- |
| [The new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), Anthropic, 2026-07-24 | the vendor removed over 80 percent of its system prompt |
| [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices), Anthropic | the prune test; deleting instructions Claude already follows |
| [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), Anthropic | 500-line skill bodies, reference files that cost nothing until read, the nested-reference warning, evaluations first |
| [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices), Anthropic | normal prompting instead of "CRITICAL: You MUST" |
| Claude Code docs: [memory](https://code.claude.com/docs/en/memory), [output styles](https://code.claude.com/docs/en/output-styles), [skills](https://code.claude.com/docs/en/skills), [hooks](https://code.claude.com/docs/en/hooks), [plugin evals](https://code.claude.com/docs/en/plugin-evals), [plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) | CLAUDE.md delivery and the 200-line target, imports loading at launch, style delivery, hook output, eval arms and report publishing |
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official), Anthropic | the code-review plugin's cut-off of 80 and its no-build rule |
| [arXiv 2608.11095](https://arxiv.org/abs/2608.11095), Chakrabarti, 2026 | instructions leave mostly in wholesale rewrites, and files grow faster afterwards |
| [arXiv 2605.10039](https://arxiv.org/abs/2605.10039), McMillan, 2026 | CLAUDE.md size did not significantly move compliance between 25 and 500 lines |
| [arXiv 2606.20512](https://arxiv.org/abs/2606.20512), Shepard and Albrecht, 2026 | probe-tuned repository guidance resolved 33.0 percent of SWE-bench Verified tasks, against 28.3 and 25.5 |
| [arXiv 2605.12978](https://arxiv.org/abs/2605.12978), Zhang et al., 2026 | repeated model consolidation can take memory below the no-memory baseline |
| [arXiv 2606.04329](https://arxiv.org/abs/2606.04329), Dash et al., 2026 | agents that write and retrieve memory aggressively are more exploitable |
| [arXiv 2602.23971](https://arxiv.org/abs/2602.23971), UK AI Security Institute, 2026 | non-questions draw 24 points more sycophancy than questions |
| [Zheng et al., Findings of EMNLP 2024](https://aclanthology.org/2024.findings-emnlp.888/) | personas did not beat a no-persona control |
| [Context Rot](https://www.trychroma.com/research/context-rot), Chroma, 2025 | no position effect across 11 needle positions on its needle-in-a-haystack task |
| [Two ways to change Claude's personality](https://danhopwood.com/posts/two-ways-to-change-claudes-personality), Dan Hopwood, 2026-07-18 | the length rule; an output style for voice |
| [Your Claude Code hooks are costing you minutes a day](https://dev.to/bokuwalily/your-claude-code-hooks-are-costing-you-minutes-a-day-heres-how-i-measured-it-4im4), 2026-08-20 | the 43-line timing wrapper and the 3,240 ms hook |
| [15 days of skill sprawl in Claude Code](https://dev.to/shimo4228/15-days-of-skill-sprawl-in-claude-code-lessons-from-3-audits-27em) | disabling unused skills the moment they're added |
