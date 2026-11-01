---
name: lore-scribe
description: "Writes and edits documentation by one set of rules: the point first, one page type per page, a README as a filter, the repo's own voice. Use for any Markdown or docs/ change."
paths: ["**/*.md", "docs/**"]
---

# Writing the lore

Documentation here has one job: give each reader what they came for, then get out of the way. Use these rules for READMEs, guides, how-tos and reference pages.

These rules don't apply to changelogs, generated files, memory files, plans or CLAUDE.md files, which keep their own formats. Text published under the author's name, such as PRs and issues, belongs to `/bard:scribe-as-me` when it is installed.

## 1. Find the voice

Look for a line starting `Voice:` in the repo's CLAUDE.md, and use that voice. With no line, or a name not below, use `plain`, and say so in your report. Never guess a voice from the repo's subject.

**`plain`**, the default, is professional and direct. Use first person in READMEs and explanations when one person owns the project, and "you" in how-tos and reference. No game language, jokes or mascots.

**`retro-rpg`** is `plain` in a retro RPG costume. A repo that names it wants the flavor, so apply it even to a short page:

- Every heading wears it, with the plain task beside it: `## Gear up: install`, `## Scout the map: run a scan`. The flavor comes from the framing, so it needs no new facts.
- Open the page with one short framing line in the same flavor.
- Steps, commands, warnings, errors and licensing stay plain, so a reader who skips the flavor still gets the full meaning.
- Keep it to one flourish per section. Flavor a reader has to decode has failed.
- [Crystal Bridge's `docs/THEME.md`](https://github.com/crystal-bridge/crystal-bridge/blob/main/docs/THEME.md) owns the vocabulary, so read it for a repo tied to that project. Never use a word from its table for another meaning. Quest, for example, only ever means a session.

## 2. Pick one page type

Every page is one of four types ([Diátaxis](https://diataxis.fr/)). Decide which before you write, and move anything else to a page of its own.

| Type | The reader wants to | Contains |
| --- | --- | --- |
| Tutorial | learn by doing | A guided path to one result, for a beginner |
| How-to | finish a task | Ordered steps, no background |
| Reference | look something up | Complete, dry, predictable facts |
| Explanation | understand why | Reasoning, tradeoffs, history |

A README is a fifth thing: a filter. See rule 3.

## 3. The rules

1. **Lead with the point.** The first screen says what this is, who it's for and why they'd care. History, architecture and credits come later or elsewhere.
2. **Depth is opt-in.** Summarize, then link. A reader should be able to stop at any heading with what they need.
3. **A README is a filter.** It grabs interest, orients the reader, shows how to start, and sends the curious to the guide. Move inventories, full command lists and design notes out, and keep every fact somewhere.
4. **No counts that drift.** Leave out numbers that a routine change makes stale: tests, commands, stars, contributors, benchmarks. If a number has to stay, date it, and say how to reproduce it.
5. **Docs change with the code.** When a change touches behavior, update every page that describes it in the same work. Check the README and guide for claims the change makes false.
6. **Claim only what you checked.** Run the command before you document it. Mark opinion as opinion.
7. **Keep every fact.** A rewrite moves content or removes it on purpose. Never lose a fact by accident: list what left the page and where it went.

## 4. Style

Read `references/style.md` in this skill's directory before you write more than a paragraph. It covers wording, headings, lists, links and code.

## 5. Test it on a fresh reader

For a README, or any page people arrive at first, run the test in `references/fresh-reader.md` before calling it done. Fix what the reader missed, then say what you changed. Skip this for small edits.

## 6. Report

Say which page type and voice you used, what moved and where, and what you checked. When the author corrects a doc in a way that would apply to other docs, offer `/loadout:gear-mend`, so the note outlives the session.
