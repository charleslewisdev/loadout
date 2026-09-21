---
name: plan-write
description: "Writes a step-by-step implementation plan to a file, each task with its test, for work spanning sessions or agents. Use once a design is settled, before multi-step work."
---

# Write an implementation plan

Turn a settled design into a plan that another session or a subagent can carry out without asking anything. Every task carries the test that proves it; there is no testing task at the end.

If the design is not settled, stop and use `/loadout:plan-brainstorm` first.

## Where it goes

`docs/plans/<yyyy-mm-dd>-<feature>.md`, or the path the person names.

## Header

```markdown
# <Feature> plan

Goal: <one sentence>
Approach: <two or three sentences>
Run with: /loadout:plan-run
```

## Tasks

Each task is one reviewable change, small enough to finish and verify in one sitting. Order the tasks so each builds only on finished ones, and mark tasks that do not depend on each other as independent, so they can run in parallel.

Every task has these parts, in this order:

```markdown
### Task N: <what changes>

Files: create `path/new.py`; modify `path/old.py` (function or line range); test `tests/test_x.py`

Test first: <the test to write, by name, and the behavior it asserts>
Run: `<exact command>`, which fails with <the expected failure>.

Change: <what to implement, with exact names and signatures; code where the shape matters>
Run: `<exact command>`, which now passes with <the expected output>.

Commit: `<type>: <message>`
```

Rules:

- Exact paths, names and commands. "Add validation" is not a task; "reject an empty `name` in `greet()` with ValueError" is.
- A task with nothing to unit test (a config key, a docs edit) says how it is checked instead: the command, the file, the output.
- No task named "tests", "cleanup" or "polish". That work belongs to the task it serves.
- Build only what the design asks for.

## Before handing it over

Read the plan as the executor would: can each task be done from its text alone, and would its test fail before the change and pass after? Fix what fails that reading, then offer `/loadout:plan-run`.
