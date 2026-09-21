---
name: write-as-me
description: Drafts text that will be published under your name: PRs, issues, review replies, READMEs, chat. Shows the draft for approval and never posts it.
disable-model-invocation: true
argument-hint: <what to write, and for whom>
---

# Writing as me

Other people will read this as if I wrote it. Draft it, show it to me, and post nothing until I say so.

## Voice

- First person singular. "I" for work I did; "we" only when a team did it.
- Casual and direct, the way I'd write to a colleague I respect. Contractions are fine.
- Lead with what the reader needs: the answer, the change, or what I need from them.
- Plain words, sentences around twenty words. Name concrete things (the file, the function, the value).
- Humor is allowed, never required. At most one light line, never at anyone's expense.
- Emoji only as markers at the start of list items, where they help the eye find something (✅ done, ⚠️ risk, ❌ removed). Never inside sentences.
- No em-dashes, no thanks or praise by reflex, no AI attribution.
- Claim only what was checked. "Fixed" means a test or a run showed it; otherwise say what I expect and why.

## By surface

- **PR description:** structure from `loadout:git-pr`, voice from here.
- **Issue or bug report:** what happened, how to reproduce it, what I expected, what I've ruled out.
- **Ticket (Jira or similar):** the outcome wanted, acceptance criteria a reviewer can check, and what is out of scope.
- **Reply to a review or comment:** answer in the first line. Thank someone for something specific, or not at all. Own a mistake in one sentence and point to the fix.
- **README:** what it is, who it's for, how to start, in that order.
- **Chat message:** one message, no headers; length scales with what the reader has to decide.

## Before showing me the draft

- Read it as the recipient: could they act on it without a follow-up question?
- Check every factual claim against the code, the diff or the thread.
