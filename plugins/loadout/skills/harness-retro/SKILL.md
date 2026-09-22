---
name: harness-retro
description: "Runs the harness retro: friction, the author's corrections, unread memory, budgets and skill usage become proposed rules, skills and deletions in one pull request."
disable-model-invocation: true
argument-hint: "[--since yyyy-mm-dd]"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git *), Bash(gh pr create *), Bash(gh pr view *), Bash(gh pr list *), Bash(scripts/*)
---

# Harness retro

The retro turns evidence into a handful of changes, proposed in one pull request the author reviews. It runs every 90 days at the latest, and earlier when /loadout:harness-status names a trigger: the skill listing over budget on the smallest model, a MEMORY.md over 100 lines, or a SKILL.md over 500 lines.

Nothing reaches memory, rules or skills until the author merges or says yes. Never print, quote or copy anything that matches the identity guard's denylist, and never write a home path; use `~`.

## 1. Find the checkout

Use `$LOADOUT_REPO`; otherwise the current repository, when its `.claude-plugin/marketplace.json` names `loadout`. If neither, stop and say: "Set LOADOUT_REPO to the loadout checkout (install.sh sets it), or run the retro from inside it."

In the checkout, stop if `git status --short --untracked-files=no` shows changes to tracked files. Untracked files stay out of the retro: stage files by name, never with `git add -A`. Then switch to `main`, pull with `--ff-only` when a remote exists, and create the branch `retro/<yyyy-mm-dd>`.

## 2. Gather the evidence

The window starts at the last `retros/<yyyy-mm-dd>.md`, or 90 days back; `$ARGUMENTS` may give `--since yyyy-mm-dd`. Run each from the checkout and keep the output:

- `scripts/retro-evidence`: the friction log (`retros/friction/`, on main and on papercut branches not yet merged), skill usage, the author's corrections and the prompts repeated across sessions. It reads interactive transcripts only and skips every project and every whole transcript that matches the denylist. Read transcripts, `~/.claude.json` and the friction log only through it, never directly: they can hold text the retro must not copy.
- `scripts/memory-reads --unread 90`: memory files no session read in 90 days. It says how many days the transcripts actually cover; a file unread over a shorter span is weak evidence.
- `scripts/budget` (about a minute), `scripts/lint-budgets`, `scripts/hook-report 90`.
- In the skill usage it reports, a loadout skill unused for 90 days is a deletion candidate, and so is one that corrections keep overriding.

If a script fails, record which one and why, and go on without it.

## 3. Decide

Rank what the evidence shows, most frequent first: a friction or correction seen twice outranks one seen once. For each item, choose the smallest change that would have prevented it, in the home that fits:

- behavior that must always happen: a hook
- a procedure used some of the time: a skill, or a step in an existing one
- a convention the model gets wrong without being told: one line in the project's CLAUDE.md, or in the style when it is about how to talk
- something no longer used or no longer true: a deletion

Prefer deletions and edits to additions. A new always-on line costs tokens in every session, so state its cost. Leave out anything the evidence does not support, however useful it sounds. A rule added to the style or a skill needs an eval case (ADR-07).

## 4. Write the retro

Write `retros/<yyyy-mm-dd>.md`:

- the window, and what each evidence source reported, as numbers and short quotes, never transcript dumps
- each proposal, most important first: what changes, where it lives, the evidence behind it with dates and counts, and its token cost
- what was considered and left out, one line each
- the memory changes proposed in step 6

This file dates the retro for /loadout:harness-status.

## 5. Open the pull request

Make the repository changes on the branch, commit following `loadout:git-pr`, run `scripts/check`, push, and open one pull request whose body lists the proposals and the feedback wanted. The guard's pre-push scan runs on the push; if it refuses, fix what it names. Never merge. With no remote, stop after the commit and say so.

## 6. Memory, only on the author's yes

Auto-memory lives outside the repository, so it is not part of the pull request. List each proposed change in the session: the project, the index line or memory file, the change (trim, merge, delete or rewrite), and the evidence (unread for 90 days, contradicted, duplicated). Apply each one only after the author says yes to it. Keep every MEMORY.md under 100 lines, one line per memory under 150 characters.
