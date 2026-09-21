---
name: code-debug
description: "Finds the root cause before changing code: reproduces the bug with a failing test, tests one hypothesis at a time, then fixes. Use for any failing test, crash or unexpected behavior."
---

# Debugging

Find the cause before you change code, and prove it with a failing test before you write the fix.

## 1. Reproduce it with a failing test

Before touching the code under suspicion, write the smallest automated test that shows the bug, run it, and watch it fail for the reported reason.

- Read the whole error and stack trace first; note the files, lines and codes it names.
- Use the project's test framework. If it has none, a one-file script that exits non-zero on the bug is enough.
- A test that fails for another reason (an import error, a typo) does not reproduce the bug. Fix the test until its failure matches the report.
- If the test cannot run at all (no runtime, a sandbox error), say so, keep the test, and go on from the evidence you have. Never report a failure you did not see.
- If the bug will not reproduce, gather data instead of guessing: the exact inputs, the environment, and recent changes (`git log -p`, `git diff`).

## 2. Find the cause

- Trace the bad value backwards. Where does it come from, and what called this with it? Fix it at its source, not where it surfaced.
- Compare with similar code that works and list every difference, however small.
- For a bug that crosses components (CI to build, API to service to database), log what enters and leaves each boundary once, then read where it breaks.
- Check what changed recently: commits, dependencies, configuration.

## 3. One hypothesis at a time

State it in one sentence: "X causes this because Y." Test it with the smallest change or probe that could prove it wrong. If it fails, form a new hypothesis from what you learned, and undo the probe; never stack a second fix on the first.

When you do not understand something, say so and find out.

## 4. Fix it and prove it

- Make one change that addresses the cause, with no unrelated clean-ups alongside.
- Run the new test: it passes now. Run the whole suite: nothing else broke.
- Report the cause, the evidence for it, the fix, and the test output.

## When fixes keep failing

After three failed fixes, stop. When each fix surfaces a new problem somewhere else, the design is the likely cause. Tell the author what you tried, what each attempt showed and what you think is structurally wrong, and ask before a fourth attempt.

## Signs you skipped a step

- "Quick fix now, investigate later."
- "Let me just try changing X."
- Several changes before one test run.
- A fix written before the failing test exists.

Each one means: go back to step 1.
