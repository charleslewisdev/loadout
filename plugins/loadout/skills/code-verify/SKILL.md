---
name: code-verify
description: "Proves work is done before saying so: runs the tests, lint and build that cover the change and shows the output. Use before claiming anything is done, fixed or passing."
---

# Verify before you claim

Say work is done, fixed or passing only when output from this turn shows it.

## Steps

1. **Find the commands that cover the change.** Look for the project's own entry point first: a check script, `make check`, `npm test`, or what the CLAUDE.md, README, package scripts, Makefile, pyproject.toml or CI configuration name. Cover tests, lint, typecheck and build, whichever the project has.
2. **Run them after your last edit, in full.** A run from before a file changed does not count, and neither does one test file standing in for the suite.
3. **Read the output:** the exit code, how many tests ran and failed, and every error or warning the change could have caused.
4. **Report with the evidence:** each command and its result line, for example "`./check.sh`: lint clean, 14 tests, 0 failures". Quote the output; do not turn it into "all good".

## What counts as evidence

| Claim | Needs | Does not count |
|---|---|---|
| Tests pass | the test command's output with 0 failures | an earlier run, "should pass" |
| Lint is clean | the linter's own output | the tests passing |
| It builds | the build command, exit 0 | lint passing |
| The bug is fixed | the reproducing test, failing before and passing after | the code looking right |
| A subagent finished | its changes in `git diff`, checked | its own report |
| The request is met | each requirement checked against the change | tests passing |

## When a check cannot run

If a command cannot run (a missing tool, no network, a sandbox error), say so plainly: name the command and the error, and call the change unverified. Unverified work is never "done".

## Before the words

"Done", "fixed", "passing", "should work" and "looks good" come after the output, never instead of it. When some checks passed and others could not run, say which is which.
