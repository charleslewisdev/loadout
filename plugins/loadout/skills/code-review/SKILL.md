---
name: code-review
description: "Reviews a change as a team: runs tests and the app, checks UI in Chrome, sends independent reviewers, verifies each finding. Use before opening a PR or when asked for a review."
disable-model-invocation: true
---

# Review a change as a team

Four stages: run the checks, send independent reviewers, verify every finding, report. Post nothing to a pull request or issue until the author says so.

## 0. Scope

Find what is under review: a branch against its base (`git merge-base`), a pull request (`gh pr diff`), or the working tree. Note the changed files, the base commit, and every CLAUDE.md that applies: the root one and those in directories the change touches.

## 1. Run the checks

Run what the project uses: tests, lint, typecheck, build. Find them in CLAUDE.md, the README, package scripts, the Makefile or CI configuration. Record each command and its result; a failure here is a finding. If a check cannot run, say which and why; do not guess its result.

When the change touches UI, start the app with the built-in `run` skill and look at each changed screen in Claude in Chrome. Note what differs from what the change intends.

## 2. Independent reviewers

Start one subagent per reviewer below, all in parallel. Give each only its brief (the file under `reviewers/` in this skill's directory), the scope from stage 0, and the check results from stage 1. No reviewer sees another's work.

Always:

- `reviewers/correctness.md`: bugs in the changed lines
- `reviewers/history.md`: the change against the history of the code it touches
- `reviewers/project-rules.md`: CLAUDE.md files and code comments that apply
- `reviewers/tests.md`: whether tests prove the change, and what fails silently

When the diff calls for it:

- security, when the change touches input handling, authentication, secrets, file or network access, or dependencies: run the built-in `/security-review`
- `reviewers/ux.md`, when the change touches UI or user-facing text

Each reviewer returns findings as: file and line, what is wrong, the concrete input or state that makes it fail, its evidence, and a severity from stage 4 (Blocking, Should fix, Consider).

## 3. Verify every finding

First merge duplicates across reviewers, keeping the strongest evidence and the highest severity. Then send the findings to verifiers with `reviewers/verifier.md`, a few findings per verifier and the verifiers in parallel. Each finding gets a score from 0 to 100 on that rubric, checked on the verifier's own evidence. Drop findings under 80, except a finding confirmed against a rule its CLAUDE.md states: the rubric puts those at 75, so keep them at 75 and above.

## 4. Report

Group what is left by severity:

- **Blocking**: wrong behavior, data loss, security, a failing check
- **Should fix**: a real problem on an uncommon path, or a broken project rule
- **Consider**: a clear improvement a senior reviewer would mention

For each: file and line, the failure in one sentence, and the evidence. Then list the checks from stage 1 with their results, and the reviewers that ran. If nothing survived verification, say so and name what was checked.

Keep each finding's severity as its reviewer set it, or as the verifier lowered it with a reason. Add your own view after the list, never in place of it. Ask before posting anything to a pull request.
