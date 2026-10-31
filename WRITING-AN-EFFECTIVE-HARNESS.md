# Writing an effective harness

A harness is everything you add to Claude Code so it works the way you do. Writing a good one is mostly a contest with your past self, who keeps picking things up and never puts anything down.

This guide is what I learned building [loadout](README.md). The sections run in the order I'd apply them to a new harness. If you want the story instead, skip to [How I got here](#12-how-i-got-here), which includes ten things I got wrong.

> [!NOTE]
> **About the evidence.** Numbers come from commands I ran on Claude Code 2.1.278 in September 2026, unless a date says otherwise, or they carry a link. Quotes from Anthropic are pasted, never paraphrased. **Opinion** marks my taste rather than how Claude Code behaves. [Section 6](#6-write-the-eval-first) explains how rules get tested, and the rest of the guide only reports what survived.

## The short version

1. [Count what you carry](#1-count-what-you-carry). Every session pays for what loads before the first prompt.
2. [Give each instruction one home](#2-give-each-instruction-one-home). Use the cheapest layer that does the job.
3. [Give every surface a budget](#3-give-every-surface-a-budget). Lint it in CI, and never block a session over it.
4. [Keep the voice short](#4-keep-the-voice-short). Claude already does most of what you'd write.
5. [Equip skills that fire](#5-equip-skills-that-fire). A skill the model never picks is dead weight.
6. [Write the eval first](#6-write-the-eval-first). Guidance feels useful whether or not it does anything.
7. [Time your hooks and keep memory raw](#7-time-your-hooks-and-keep-memory-raw). Delete slow hooks, and don't summarize transcripts.
8. [Keep reference material out of the pack](#8-keep-reference-material-out-of-the-pack). Load it only when someone asks.
9. [Schedule the deletion](#9-schedule-the-deletion). Nothing stays small by accident.
10. [Guard what you publish](#10-guard-what-you-publish). A setup you use every day holds private names.
11. [Share it with a team](#11-share-it-with-a-team). The mechanisms stay the same, and the shape changes.
12. [How I got here](#12-how-i-got-here). The story, and the reversals.

## 1. Count what you carry

Every RPG has a weight limit, and Claude Code's is the context window. Your **harness share** is the tokens your setup adds to every session before you type anything. One command gives you the raw total:

```
claude -p "Reply with exactly the word OK and nothing else." --model haiku --output-format json \
  | jq '.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens'
```

`scripts/budget` runs that in an empty directory in four configurations, three times each, and subtracts. It uses Haiku because Haiku has the smallest window in regular use, so truncation shows there first.

| Configuration | Added to the command | Before loadout | September 21, 2026 | October 31, 2026 (2.1.316) |
| --- | --- | --- | --- | --- |
| As configured | nothing | 25,288 to 25,843 | 23,944 | 23,653 |
| Auto-memory off | `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` | 22,333 | 20,995 | 22,959 |
| Vendor floor | `--safe-mode` | 17,859 | 17,712 | 16,973 |
| **Harness share** | auto-memory off minus the floor | **4,474** | **3,283** | **5,986** |

The floor is Claude Code's own system prompt, built-in tools, and bundled skills. The ceiling is 6,000 tokens, and the target is about 3,000. So yes, the right-hand column is a problem. The script attributes about 2,881 tokens, before truncation, to 16 skills synced to my Claude account, and about 570 to the `loadout` plugin. That's the first job for the next retro.

The number is slippery, so read yours with care. Use `--safe-mode` for the floor, because `--tools ""` also strips 15,600 tokens of built-in tools. Run it three times and take the highest, because MCP servers and health checks race the first request: one set of three runs in September gave 1,754 to 3,268. Keep the auto-memory section out of the ceiling if you've chosen to run it, so the budget doesn't punish a decision you made on purpose.

Two popular shortcuts give you the wrong answer. `claude plugin details` counts neither output styles nor session-start output, so it once showed about 0 always-on tokens while my style loaded in every session. A logging proxy is great for seeing structure, but `ANTHROPIC_BASE_URL` switches off deferred tool loading: the same prompt cost 79,181 tokens through a proxy and 25,378 without one.

## 2. Give each instruction one home

Each kind of instruction belongs in one place, chosen by how that place reaches the model and what it costs. A logging proxy showed where each layer lands:

| Layer | What it's for | How it reaches the model | Cost |
| --- | --- | --- | --- |
| Output style | Who the model is talking to, and how | A block in the first user message, plus a 32-token reminder before each prompt; never in a fresh subagent (a fork inherits it) | Every session |
| User `~/.claude/CLAUDE.md` | Hard rules for every project | A block in the first user message | Every session |
| Project `CLAUDE.md` | Build and test commands, conventions that differ from defaults | A block in the first user message | Every session in that repo |
| Rule in `.claude/rules/` with `paths:` | Guidance for one part of the code | Loaded when a matching file is read | Nothing until then |
| Skill | A procedure or domain knowledge | Name and description always; the body when used | Description always, body on use |
| Hook | A guarantee | Runs outside the model; plain output from session-start and per-prompt hooks enters context, and so does any hook's `additionalContext` or blocking reason | Milliseconds per call |
| Statusline | What you glance at | Never reaches the model | Zero tokens |

Placing something new takes one question. If it must always happen, it's a **hook**, because prose can't guarantee anything. If the model should pick it when relevant, it's a **skill**. If you run it on purpose, it's a **typed-only skill** (`disable-model-invocation: true`), which costs nothing until you type it.

Output styles feel special, but they have no system-prompt privilege. The style sits next to CLAUDE.md, which the docs say is "delivered as a user message after the system prompt" ([memory docs](https://code.claude.com/docs/en/memory)). With a style active, the system prompt changes one sentence: "You are an interactive agent that helps users according to your "Output Style", which describes how you should respond to user queries." That sentence, the per-prompt reminder, and fresh subagents going without it are the style's whole advantage over CLAUDE.md for register. It also survives `/compact`, because compaction rebuilds the first message from disk.

Be careful with session-start output. It enters context and is sent again after every compaction, so a hook that prints a skill body pays for it again and again. The superpowers plugin's injection came to 4,015 characters a session. Send configuration warnings through the hook's `systemMessage` field instead, which reaches you and never the model.

Don't rebuild what's already there, either. Claude Code puts the branch, git status, and recent commits into every session started in a repo, so a session-context hook would repeat them for about 80 tokens per session and per compaction. And I'd keep register out of per-prompt hooks unless it drifts, because they cost tokens every turn. If it does drift by turn eight, a hook of about 60 tokens per turn is the next lever.

### Ship it to every machine

An installer merges one JSON profile into `~/.claude/settings.json`, and the repo itself is a plugin marketplace. You need both, because a plugin can't set `outputStyle` or ship your user CLAUDE.md, and its own `settings.json` can set only `agent` and `subagentStatusLine`. Avoid a `directory` marketplace: it stores an absolute path in `~/.claude/plugins/known_marketplaces.json`, so it only works where the checkout sits at the same path.

If your marketplace repo is private, expect one more chore. A `github` source clones over HTTPS, and the CLI turns off credential helpers for some background git calls, so a background refresh can fail. Either register an SSH key, or use a `git` source and set `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` so a failed refresh keeps the existing clone.

## 3. Give every surface a budget

Every always-on surface gets a target and a ceiling. The "Now" column is from October 31, 2026.

| Surface | Target | Ceiling | Now | Basis |
| --- | --- | --- | --- | --- |
| Harness share | About 3,000 tokens | 6,000 tokens | 5,986 | About 3% of a 200k window above the vendor floor |
| Output style body | 60 lines, 600 tokens | 100 lines, 1,000 tokens | 24 lines, about 532 tokens | Anthropic's built-in styles run 250 to 370 tokens, more with examples |
| User CLAUDE.md | About 30 lines | 200 lines | 30 lines | The docs: "target under 200 lines per CLAUDE.md file" |
| Project CLAUDE.md | About 80 lines | 200 lines | Template under 20 | Build, test, conventions that differ, pitfalls |
| SKILL.md body | Under 150 lines | 500 lines | At most 56 lines | The docs: "Keep `SKILL.md` under 500 lines" |
| One skill description | | 200 characters | 132 to 188 | The listing budget in [section 5](#5-equip-skills-that-fire) |
| All harness descriptions | | 5,000 characters | 1,626 | The listing is window × 4 × 0.01 characters: 8,000 on a 200k model |
| Session-start output | Nothing on a configured machine | 300 characters | 0 | Re-sent after every compaction; checked by hand, not linted |

The 200-line ceiling rests on token cost, not adherence. A factorial study found compliance of 60.0, 65.2, 67.7, and 64.0% at 25, 100, 250, and 500 lines, and the size effect was not significant ([arXiv 2605.10039](https://arxiv.org/abs/2605.10039)). The docs still warn that "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!" ([best practices](https://code.claude.com/docs/en/best-practices)).

The best pruning test I know comes from that same page: "For each line, ask: *"Would removing this cause Claude to make mistakes?"* If not, cut it." It goes further: "If Claude already does something correctly without the instruction, delete it or convert it to a hook."

`scripts/lint-budgets` checks files offline, fails on a ceiling, and warns past a target, and CI runs it on every push. Keep budgets out of session start. A budget is a maintenance signal, and it should never stop you from working. You also don't need wrappers around `/doctor`, `/context`, `/skill-doctor`, or `claude plugin prune`, because they already exist.

## 4. Keep the voice short

Register lives in one forced output style, `peer`, in the optional `bard` plugin. It describes me as the reader: a senior engineer who wants a peer, except on database design and performance, where it should explain its reasoning and flag risks. It asks for plain language, sentences around twenty words, and every reference explained before it's used. It bans four habits of machine prose and six filler words. It also asks Claude to relay reviewer findings with their severity intact and to show check output before calling anything done. The wording is **opinion**, so replace it with your own.

Treat a style as a comfort trade, because it makes sessions better to work in and that's the whole claim. Across 162 personas, four model families, and 2,410 factual questions, no persona beat a no-persona control ([Zheng et al., EMNLP 2024 Findings](https://aclanthology.org/2024.findings-emnlp.888/)).

If you ship a style in a plugin, force it and set it. `force-for-plugin: true` delivers the body, but the per-prompt reminder returns nothing when `outputStyle` is unset, so you need both. The eval sandbox can't set `outputStyle`, which means only a forced style can be tested at all. Don't be alarmed when the sandbox's session record says `output_style: default`. A probe asking the model to quote its style confirmed the body arrives.

How you pack a rule matters more than how you word it. As one clause in a list of banned things, the em-dash rule held in 1 of 5 runs. As its own sentence, "Never write the em-dash character; use a comma, a colon or a new sentence.", it held in 9 of 10.

Expect most of what you want to say to be default behavior already. I started with a rule telling Claude to hold its ground under pushback, and it turned out not to need one. [Section 6](#6-write-the-eval-first) has the casualties.

A style also has limits you can't write around. A fresh subagent never gets it, while a fork inherits the parent's conversation, style included ([output styles docs](https://code.claude.com/docs/en/output-styles)). That's why `/loadout:review-party` briefs fresh subagents: a review the style could soften is worth less. A style overrides any style you pick while its plugin is enabled, and it fades in long written artifacts. A retro file written under mine still drew em-dashes.

Good lines are worth borrowing. My length rule adapts one from Dan Hopwood's example style: "Length scales with what the user has to decide, not with the work behind it – a heavy session with one decision gets a short message." ([Hopwood](https://danhopwood.com/posts/two-ways-to-change-claudes-personality)).

Keep your public voice separate from your working voice. Writing as me in public is a typed-only skill, `/bard:scribe-as-me`: first person, no em-dashes, emoji only as list markers. It drafts and never posts.

## 5. Equip skills that fire

Every enabled skill puts its name and description into every session. The space is a character budget, not a count. In the 2.1.278 binary, the budget is the context window times 4 times 0.01 characters: 8,000 on a 200k model and 40,000 on a 1M model.

Going over budget doesn't remove anything. The lowest-scoring skills lose their description and show as a bare name, and subagents on 200k models see that cut list. The score is uses times max(0.5^(days since use / 7), 0.1). A skill with `disable-model-invocation: true` stays out of the listing entirely.

So keep each description under 200 characters, and say what the skill does and when to use it. On October 31, 2026, my ten skills hold 1,626 characters, and the six the model can pick hold 1,048. The Haiku listing in September was still over budget, 34 skills and 17,981 characters against 8,000, almost all from bundled and account-synced skills. Removing skills saved little: taking out 14 cut 3,717 characters of descriptions, and the share rose by 15 tokens. The real cost of an over-budget listing is the descriptions that get cut.

Treat every outside skill as unidentified loot: it arrives with `disable-model-invocation: true` and earns its way into the listing. A practitioner's three skill audits reached the same rule: "Disable unused skills the moment they're added." ([dev.to](https://dev.to/shimo4228/15-days-of-skill-sprawl-in-claude-code-lessons-from-3-audits-27em)). A skill written here gets invoked once by name after it lands, so its usage score starts above zero.

Beware of skills that shout. superpowers cost about 2,540 tokens per session and injected: "If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill." Anthropic's guidance goes the other way: "Where you might have said "CRITICAL: You MUST use this tool when...", you can use more normal prompting like "Use this tool when..."." ([prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).

Check a new skill's name against the bundled skills before you write it, because the model will pick the bundled one. And if something must always happen, a description can't promise it. Self-review here is a hook: `review-gate` blocks a stop once per batch of work when two or more files changed since the last review.

Keep bodies short. Mine run 4 to 56 lines, and `review-party` keeps each reviewer's brief in a reference file beside `SKILL.md`, so the team costs nothing until it runs.

Name for the menu, too. My names lead with their subject (`gear-`, `map-`, `review-`), so the alphabetical slash menu groups them, and they end with a word of flavor.

## 6. Write the eval first

This is the one section about proving things work. Guidance about a repo feels useful whether or not it changes anything, so every plugin carries `claude plugin eval` cases, and each case runs twice: with the plugin and without it. The difference between the scores is what the plugin actually contributed. The docs put it plainly: "If a case scores 1.0 both with and without the plugin, the plugin isn't what made it pass." ([plugin evals docs](https://code.claude.com/docs/en/plugin-evals)). Anthropic's skill guidance says to "Create evaluations BEFORE writing extensive documentation" ([skill authoring guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)), and I wrote each skill's case before the skill.

It isn't free. A case takes about an hour to write. The docs' own example is $0.41 and 74 seconds for one case, three runs, two arms, and my style evals cost about $25 in one phase. They need Claude credentials, so they run locally before a merge, and CI only fails a plugin with no `evals/` directory.

The results were humbling:

- **Five style rules went.** I had rules to restate claims as questions, hold a recommendation under pushback, state assumptions, decline requests built on a wrong premise, and a humor sentence. Eighteen cases on Sonnet 5, and the ones with no difference again on Opus 5, scored the same with and without every one of them. The research behind the question rule is sound: non-questions drew 24 percentage points more sycophancy than questions, and asking beat an explicit "don't be sycophantic" instruction ([UK AISI, arXiv 2602.23971](https://arxiv.org/abs/2602.23971)). Both models caught my planted errors anyway.
- **The writing rules stayed**, scoring 0.97 against 0.87.
- **The verify-before-done sentence stayed**, scoring 0.17 to 0.33 against 0. It changed how replies report checks, not whether the model runs them.
- **A helpful step made things worse.** `pr-turn-in`'s claim-check step produced 3 clean PR descriptions out of 6, against 5 of 6 without the skill.
- **Two skills failed to fire.** `code-verify` fired in 0 of 6 runs, so its rule moved into the style as one sentence and the skill was retired. `code-review` lost to a bundled skill of the same name.
- **Some rules stay untested.** The filler-word rule showed no difference because the baseline already avoided those words, so it stays until a prompt can judge it. Three rules have no case at all and stay as opinion: relaying reviewer findings with their severity, the database-and-performance exception, and resolving every reference before using it.

If you run your own, these will save you an afternoon:

- A passing score isn't enough, because only a positive difference counts. At three runs, a 0.8 threshold can't reliably tell 0.67 from 0.8, so cases that must separate close scores run five times per arm.
- The cases can be wrong. A wrong-premise case looked like a failing rule until a review found a malformed code fence in its prompt.
- Grade what only the skill asks for. The first `scribe-as-me` result was mostly the style's own em-dash rule, because the style loads in the with-plugin arm.
- The Haiku judge is noisy in both directions, so read transcripts (`--keep-temp`) before you trust a surprising score.
- An `llm` grader reads the last message by default. A retro case wrote a correct file and failed 6 of 6 because the judge never saw it. The `files` target holds only uncommitted changes, and `tool_order` compares only the first matching calls.
- Use `regex` for facts and `llm` for judgment. The README's own test failed "how do I add a skill" in 6 of 6 runs on complete answers, until four `regex` graders replaced the judge.
- A document test scores about the same in both arms by design, because both get the same README. It passes when every answer is complete.
- The sandbox scrubs `HOME` and custom environment variables. On Ubuntu, sandboxed Bash needs a bubblewrap AppArmor profile, and without one every shell-dependent case tests a broken sandbox.
- `scripts/eval` always passes `--no-publish`. If you're signed in with a claude.ai subscription that has artifacts, the CLI otherwise publishes each report as a private artifact, and eval prompts are a publishing surface.

Research on tuning guidance points the same way: repository guidance tuned with synthetic bug-fix probes resolved 33.0% of SWE-bench Verified tasks, against 28.3% for the static knowledge base it started from and 25.5% unguided ([arXiv 2606.20512](https://arxiv.org/abs/2606.20512)).

## 7. Time your hooks and keep memory raw

### Hooks

Every synchronous hook runs on every matching call, and you only notice a slow one if you time it. A practitioner's 43-line wrapper found one hook at p95 3,240 ms across 127 calls ([dev.to](https://dev.to/bokuwalily/your-claude-code-hooks-are-costing-you-minutes-a-day-heres-how-i-measured-it-4im4)).

So every hook here runs through `hook-timed`, which logs its start and end, and the lint fails any hook command that bypasses it. A hook over budget for a week gets deleted. On October 31, 2026, `scripts/hook-report` showed these p95 times:

| Hook | Budget | p95 |
| --- | --- | --- |
| `session-start`: the silent configuration check | 300 ms | 29.4 ms over 74 calls |
| `notify`: desktop notifications on stop and on input needed | 100 ms | 66.3 ms over 294 calls (stop), 59.9 ms over 181 calls (input) |
| `format`: prettier or ruff, only where the repo has that tool's config | 300 ms | 85.8 ms over 181 calls |
| `review-gate`: asks for a review of multi-file work | | 193.6 ms over 62 calls |

Scope your formatter to repos that have its config, or it will rewrite whole files in repos that don't use it. For desktop notifications, return the escape sequence in the hook output's `terminalSequence` field, which the binary describes as "A terminal escape sequence (e.g. OSC 9 / OSC 777 desktop-notification) for Claude Code to emit on your behalf".

`review-gate` reads subagent transcripts too, and edits in the review's own turn count as its fixes. `LOADOUT_REVIEW_GATE=0` turns it off, and `LOADOUT_REVIEW_MIN_FILES` raises the bar. Two slots stay empty on purpose: a Bash guard, with a 50 ms budget, waits for a case `permissions.deny` can't express, and nothing runs per prompt.

### Memory

Use one store: Claude Code's native auto-memory, an index plus one file per fact, loaded per project. Transcripts are the raw record, kept 120 days (`cleanupPeriodDays`; the default is 30) and searched with grep. A vector memory server isn't worth it, because grep over a few thousand files is free. Keep other memory and notes servers out of coding sessions, in the one project that uses them.

Don't let a model summarize the record. In one study of repeated consolidation, "memory utility first rises, then degrades, and can fall below the no-memory baseline" ([arXiv 2605.12978](https://arxiv.org/abs/2605.12978)). That's ARC-AGI with GPT-5.4, not a coding workload, so the evidence is thin. I keep raw records anyway, because that's the cheaper and reversible choice.

Skip memory-retrieval orders in your style too. The system prompt already carries a 12,735-character auto-memory section, so a second directive adds a rule without adding reach. `scripts/memory-reads` counts how often sessions open memory files instead: 1 read in 8 sessions on day one. A one-line retrieval hook ships only if two weeks of that number show recall is rare.

Knowledge becomes a rule or a skill only through a pull request I review. Agents that "write and retrieve memory more aggressively are more exploitable" ([arXiv 2606.04329](https://arxiv.org/abs/2606.04329)), and a human-gated promotion step leaves a poisoned tool result no path into future sessions.

## 8. Keep reference material out of the pack

You don't carry the whole library into a dungeon. Reference material should never load by itself: a 2,000-term glossary, a map of issue-tracker boards, a table of teammates' handles. Put each piece on the first rung that fits how it's used.

| Rung | How it's used | Where it goes | What it costs |
| --- | --- | --- | --- |
| 1 | Needed every session | One pointer line in CLAUDE.md naming the file and the command to search it | The line |
| 2 | Needed for one part of the code | A rule in `.claude/rules/` with `paths:` frontmatter | Nothing until a matching file is read |
| 3 | Needed for one task | A skill body, procedure only | The body, for the rest of the session |
| 4 | Read a section at a time | Files beside `SKILL.md`, one level deep, split by topic, with a contents list past 100 lines | The sections read |
| 5 | Looked up one entry at a time | A data file (TSV or JSON) plus `grep` or a small lookup script | The matching lines |
| 6 | Owned by another system and changing | A live query through that system's CLI or MCP server | The answer |

Pick the rung by how often the material is needed, not by its size. A 40-line rule needed in one directory belongs on rung 2 whatever its length, and a 20-line table needed once a month belongs on rung 5. That same 40-line rule added 0 tokens at turn 0 when scoped with `paths`, and 978 tokens to every session without it.

The rungs rest on two lines from Anthropic's [skill authoring guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices): "Only the script's output consumes tokens", and reference files "don't consume context tokens until actually read". Every rung above 1 depends on the model choosing to look, so every pointer names the file and the command. **Opinion:** a 2,000-term glossary goes on rung 5, with one `glossary.tsv` and one pointer line in CLAUDE.md naming the file and the `grep`.

Three splits look clever and aren't:

- **`@` imports in CLAUDE.md.** "Imported files are expanded and loaded into context at launch", so the split files load anyway.
- **A reference file that links to another.** On nested references, Anthropic warns: "Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information."
- **A table in a skill body.** It stays in context after use and rides through compaction.

## 9. Schedule the deletion

Harnesses grow unless something pushes back, so the pushback gets a calendar. `/loadout:gear-respec` is the save point: a retro that runs every 90 days at most. It runs sooner if the harness's own skill descriptions pass 4,000 characters, a memory index passes 100 lines, or a skill passes 500 lines. Pick triggers the harness controls. One that watches the whole skill listing fires permanently, because bundled and account-synced skills overflow it on their own.

The retro works on a `retro/<date>` branch. It reads the friction log, my corrections in recent transcripts, memory files nobody read in 90 days, the budgets, and skill usage, then writes one dated file listing each proposal with its evidence. It ends in one pull request. Nothing reaches rules or skills until I merge it, and changes to local memory wait for my yes. Avoid scheduled rewrites of instruction files, since wholesale rewrites are exactly how files lose instructions and then regrow. If two retro dates pass with nothing produced, the fallback is a calendar reminder to run `/skill-doctor` and delete.

Give a retro skill narrow permissions. `Bash(git *)` pre-approves `git push origin HEAD:main` on an unprotected branch. Unscoped Read, Grep, and Glob pre-approve reading transcripts, and unscoped Edit and Write pre-approve memory edits the procedure said to wait for. Instructions alone don't hold: in sandbox runs the model read files the skill told it not to. List the exact commands a skill needs.

Small annoyances get their own path. `/loadout:gear-mend` writes one to its own dated file under `retros/friction/`, plus the smallest fix on a branch when the fix is clear, opened as a PR and never merged by the skill. One file per papercut keeps open PRs from conflicting, and the retro reads unmerged papercut branches too.

Keep it all in one repo as long as you can. Groups of skills ship as extra plugins in the same marketplace, and they're already enabled independently. The reasons to split are privacy (a skill describing private infrastructure can't be published) or skill commits drowning harness commits.

## 10. Guard what you publish

I publish my real harness, not a sanitized skeleton, because a setup used every day teaches better. The catch is that every commit of real configuration can leak a private name, so a guard keeps them out mechanically.

A private generator builds a denylist of regexes from private sources: every file and directory name in my old private plugin tree, a list of private terms, and a small hand-kept file for what those two miss. The denylist lives outside the repo, mode 0600, with a canary line so tests never type a real term. Then `pre-commit` scans the staged diff and the committer email, `commit-msg` scans the message, and `pre-push` scans every pushed commit, tag, and ref name. If the denylist is missing, a push to a public or unknown remote is refused. Findings name a location and a denylist line number, never the matched text.

CI never sees the denylist. It checks every author and committer email in full history against an allowlist, runs a secret scan, and checks names against a short published list of forbidden words.

Building it taught me a few things:

- **Generate the list, don't type it.** A hand-redacted inventory removed a private top-level name and still leaked two names nested inside file paths.
- **The guard will catch you, too.** A `.gitignore` pattern anchored at the repo root let eval results, which hold absolute home paths, get staged. The denylist refused its own builder's commit.
- **Word boundaries miss code.** `_` is a word character, so `\bterm\b` misses `project_term.md` and `TermClient`. The guard also scans a copy with underscores read as spaces and capitals split.
- **PR bodies skip git hooks.** `gh pr create` sends the body straight to GitHub, so the skills write it to a file and scan it with `guard/scan text` first.
- **Transcripts carry your CLAUDE.md.** Before matching transcripts against the denylist, replace the home path with `~` and drop attachment records, which carry the injected user CLAUDE.md and any private terms in it.

The last check stays human, because the guard matches strings and what counts as private is a judgment. Before a repo goes public, a person reads a full-history scan that also covers what `guard/scan --all` never sees: PR titles, bodies, and comments, CI logs, and the `refs/pull/*` heads GitHub keeps after a squash merge, which go public with the repo.

To leave a machine clean, run `guard/scan --path ~`. It reads every file under a directory as bytes, checks every name, and reports denylist line numbers only. It can't see inside archives or compressed documents, and it doesn't decode UTF-16, which some app databases use. Uninstalling isn't enough. Private terms hide where no uninstall reaches: the Docker build cache, editor and chat-app state, shell history, a pip-installed client, Claude Code's own config backups, and search queries a memory server logs in each memory's metadata. Read the findings for lines that can only mean a private term first, because denylist lines that are also ordinary words make most of the noise.

## 11. Share it with a team

A team harness fails the same way a personal one does, and every always-on token is paid by every session of every person. The mechanisms carry over, and the shape changes. Use a versioned team marketplace, with plugins enabled per role (developer, QA, DevOps) and per project. Push rules everyone shares through managed settings and a managed CLAUDE.md, not a copied user file. The same guard works for customer names, internal codenames, and secrets before anything leaves the company.

To audit a team harness, follow these steps:

1. **Find the share.** Run the four configurations from [section 1](#1-count-what-you-carry) on the smallest model your team uses, then again inside each main repository to count its CLAUDE.md and rules.
2. **Inventory the always-on surfaces:** every CLAUDE.md a session loads, output styles, session-start output, skill and agent descriptions, MCP server instructions, and any hook that returns `additionalContext` on every tool call. Put each in a row of the [layer table](#2-give-each-instruction-one-home), and ask whether it sits in the cheapest layer that does the job. Give each one a target and a ceiling from the [budget table](#3-give-every-surface-a-budget), and lint them in CI.
3. **Check the skill listing** in a debug log. The line to look for starts "Skill listing over budget". Everyone's plugins share that budget, so cap descriptions, mark typed commands `disable-model-invocation: true`, and enable stack skills only in the projects that use them.
4. **Time every hook** through a wrapper, give each event a p95 budget, and delete what stays over.
5. **Test before you trust**, as in [section 6](#6-write-the-eval-first). Add a code owner per plugin, and have CI fail any plugin without `evals/`, as this repo's CI does.
6. **Schedule the deletion:** one retro every 90 days at most, ending in one pull request with the new share in it.

A few traps are worth checking first:

- **Marketplace names collide.** Adding a marketplace under a name that already exists silently replaces the old one, so two teams must never share a marketplace name. I reproduced that in an isolated config directory.
- **Auto-memory doesn't travel.** It's one user on one machine and never propagates, however useful it looks. Knowledge the team needs belongs in the project CLAUDE.md, `.claude/rules/`, and skills in the team marketplace, and the promotion step stays a pull request.
- **A table of people is personal data.** Keep it out of public repos, and query the company directory (rung 6 in [section 8](#8-keep-reference-material-out-of-the-pack)) rather than copying it.
- **Forced styles override everyone (opinion).** Ship two or three styles people can choose from, and put shared rules in reviewed places.

**Not covered (opinion):** role workflows such as QA test plans or DevOps runbooks, permissions policy for shared infrastructure, and onboarding. A team harness will need skills for these, and the budgets decide how many it can afford.

## 12. How I got here

My earlier harnesses didn't fail by being wrong. They worked, then gathered rules, skills, and plugins for a year, until I couldn't say what any one of them cost or whether it helped. By the end I had four overlapping memory stores, written to far more often than they were read. Register rules were tangled up with project rules in one CLAUDE.md, so nothing could test them separately. superpowers was injecting its demand to be used into every session. My old formatter was rewriting whole files in repos that had never heard of prettier. The share stood at 4,474 tokens.

That's the normal path. Across 1,867 repositories, 77.3% of instructions that disappear from an instruction file go in a wholesale rewrite or a move to a sibling file, and afterwards the file grows faster, 4.9 against 4.1% per commit ([arXiv 2608.11095](https://arxiv.org/abs/2608.11095)). Files mostly shrink by being rewritten, and then they grow back faster.

Anthropic moved the other way with its own prompt: "We removed over 80% of Claude Code's system prompt for models like Claude Opus 5 and Claude Fable 5 with no measurable loss on our coding evaluations." ([claude.com blog](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)).

So I started over on September 21, 2026, and the first thing I built was a number. The identity guard, the budget script, and the eval runner landed together in the first real commit, with the one style they needed to be tested on. The first skill arrived a phase later, as `git log --reverse --name-only` shows, and every skill after that started as an eval.

Then the evals went to work on my own ideas. Five style rules fell, two skills failed to fire, and the share dropped to 3,283 tokens once the legacy setup was gone. superpowers was disabled the day its replacements landed. Uninstalling the old setup turned out to be the easy part, because private names were still scattered all over the machine, and `guard/scan --path` exists because of that. The first retro proposed no repository changes. Its work was memory, cutting the two largest indexes from 156 and 144 lines to 21 and 19.

Crystal Bridge grew up alongside it, and in late October the notify hook learned to stay quiet under its sessions. Then I got the repo ready for strangers: guardrails on anything that publishes, skills renamed to group in the slash menu, `bard` split out so the voice is optional, and the review gate. By the end of October the share had climbed back to 5,986, with skills synced to my account as the largest piece, which is exactly why the retro is on a schedule.

### What I got wrong

Every pass reversed something the previous one believed. Each reversal came from checking the platform or reading the primary source, and each is a place where a reasonable-sounding belief would have shipped.

1. **Summarizing memory.** The first draft distilled session logs into summaries and archived the originals, until I read the consolidation research.
2. **The skill ceiling, twice.** I first said skill indexing was a non-problem, then that skills past about 40 were evicted and a new one "may simply never appear". The binary shows a character budget, and over-budget skills stay listed without their description.
3. **Why the style beats CLAUDE.md, twice.** First I believed CLAUDE.md got "buried in the middle of a long context". Chroma's *Context Rot* study found no notable variation across 11 needle positions on its needle-in-a-haystack task ([Chroma](https://www.trychroma.com/research/context-rot)). Then I believed the style sat in the system prompt, which a proxy contradicted.
4. **A retrieval directive in the style.** I proposed it first in shouting caps, then in normal prose, then dropped it and wrote a counter instead.
5. **A schema claim.** No installed skill used `user-invocable` or `when_to_use`, so I concluded they were invalid fields. The binary lists both. Absence from installed files is weak evidence about a schema.
6. **The floor.** My first formula passed `--tools ""`, so the share came out too high. The same review called my community skills "never invoked", and the usage record showed five of thirteen used, one to eleven times each.
7. **The custom reviewer.** A review cut my planned reviewer in favor of the built-in `/code-review`, under the rule not to rebuild first-party tools. My own review practice runs tests, the app, and a visual check, which the built-in doesn't. Anthropic's own [`code-review` plugin](https://github.com/anthropics/claude-plugins-official/blob/4ca561fb8532594e7a5faef945e85096fcec0616/plugins/code-review/commands/code-review.md) says "Do not check build signal or attempt to build or typecheck the app." So `/loadout:review-party` runs checks first, then independent reviewers, then a verifier that drops findings under 80, the plugin's own cut: "Filter out any issues with a score less than 80."
8. **Most of the style's disagreement rules.** I treated sycophancy as the style's main job. It turned out both models already did the job.
9. **Skills the model should pick.** Both skills that failed to fire became typed-only. Later, `code-verify` was retired, and the reviewer, renamed `review-party`, became model-invoked again.
10. **Whole-transcript skipping.** Scripts that read `~/.claude` skipped every transcript matching the denylist. My old setup put private names into ordinary sessions, so nothing was left to count. Count-only scripts now withhold matching records and count the rest.

And some reviews caught me in the act. A review of an early draft of this guide found 28 errors, and every one sat in a paraphrase. None sat in the research notes it summarized. That's why Anthropic's words here are pasted.

## Sources

Token counts, timings, and eval scores come from `claude -p` token accounting, a logging proxy, greps of the installed binary, or this repo's scripts. I opened each published source below on September 21, 2026, and checked it against the claim it supports.

| Source | What it supports here |
| --- | --- |
| [The new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), Anthropic, July 24, 2026 | The vendor removed over 80% of its system prompt |
| [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices), Anthropic | The prune test; deleting instructions Claude already follows |
| [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), Anthropic | 500-line skill bodies, reference files that cost nothing until read, the nested-reference warning, evaluations first |
| [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices), Anthropic | Normal prompting instead of "CRITICAL: You MUST" |
| Claude Code docs: [memory](https://code.claude.com/docs/en/memory), [output styles](https://code.claude.com/docs/en/output-styles), [skills](https://code.claude.com/docs/en/skills), [hooks](https://code.claude.com/docs/en/hooks), [plugin evals](https://code.claude.com/docs/en/plugin-evals), [plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) | CLAUDE.md delivery and the 200-line target, imports loading at launch, style delivery, hook output, eval arms and report publishing |
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official), Anthropic | The code-review plugin's cut-off of 80 and its no-build rule |
| [arXiv 2608.11095](https://arxiv.org/abs/2608.11095), Chakrabarti, 2026 | Instructions leave mostly in wholesale rewrites, and files grow faster afterwards |
| [arXiv 2605.10039](https://arxiv.org/abs/2605.10039), McMillan, 2026 | CLAUDE.md size did not significantly move compliance between 25 and 500 lines |
| [arXiv 2606.20512](https://arxiv.org/abs/2606.20512), Shepard and Albrecht, 2026 | Probe-tuned repository guidance resolved 33.0% of SWE-bench Verified tasks, against 28.3% and 25.5% |
| [arXiv 2605.12978](https://arxiv.org/abs/2605.12978), Zhang et al., 2026 | Repeated model consolidation can take memory below the no-memory baseline |
| [arXiv 2606.04329](https://arxiv.org/abs/2606.04329), Dash et al., 2026 | Agents that write and retrieve memory aggressively are more exploitable |
| [arXiv 2602.23971](https://arxiv.org/abs/2602.23971), UK AI Security Institute, 2026 | Non-questions draw 24 points more sycophancy than questions |
| [Zheng et al., Findings of EMNLP 2024](https://aclanthology.org/2024.findings-emnlp.888/) | Personas did not beat a no-persona control |
| [Context Rot](https://www.trychroma.com/research/context-rot), Chroma, 2025 | No position effect across 11 needle positions on its needle-in-a-haystack task |
| [Two ways to change Claude's personality](https://danhopwood.com/posts/two-ways-to-change-claudes-personality), Dan Hopwood, July 18, 2026 | The length rule; an output style for voice |
| [Your Claude Code hooks are costing you minutes a day](https://dev.to/bokuwalily/your-claude-code-hooks-are-costing-you-minutes-a-day-heres-how-i-measured-it-4im4), August 20, 2026 | The 43-line timing wrapper and the 3,240 ms hook |
| [15 days of skill sprawl in Claude Code](https://dev.to/shimo4228/15-days-of-skill-sprawl-in-claude-code-lessons-from-3-audits-27em) | Disabling unused skills the moment they're added |
