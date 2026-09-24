---
name: plan-run
description: "Carries out a written plan task by task, each task in a fresh subagent, checking after each and stopping on failure. Use when asked to execute an existing plan file."
---

# Run a written plan

You coordinate and subagents do the work. A fresh subagent per task keeps each task's context clean and yours small.

## 1. Read and check the plan

Read the whole plan once. Before starting, name any task that cannot be done from its text alone, any task without a test, and any task that depends on a later one, and settle them with the person. If the plan does not say whether tasks end in a commit and the person has not asked for commits, ask once. Put the tasks in a todo list.

## 2. One subagent per task

For each task, dispatch a fresh subagent with the Agent tool. Set its `model` every time, since a subagent left without one runs on this session's model: `sonnet` for a task whose text says what to build, `opus` for one that leaves a design choice open or repeats a failed attempt. Its prompt carries everything it needs, so it never reads the plan itself:

- the task's full text, pasted
- where it fits: what earlier tasks built and which files they touched
- the rule: write the task's test first, see it fail, make it pass, then commit only if the plan or the person asked for commits, with no AI attribution
- what to return: files changed, the test command with its output, the commit, and anything it could not do

Implementation tasks run one at a time: subagents that commit in one working tree collide on the git index and pick up each other's files. Independent tasks may run in parallel only when each gets its own git worktree under `.worktrees/`, merged back one at a time. Read-only work, such as investigation or review, can always run in parallel.

## 3. Check each result yourself

A report is a claim until you check it. After each task:

- run its test command and read the output
- read the diff against the task's text: everything asked for, nothing extra
- run the suite or build the plan names, if any

## 4. Stop on failure

When a test fails, a check disagrees with the report, or a subagent could not finish, stop. Do not start the next task and do not patch the work yourself. Tell the person what failed, with the output, and suggest the next step: a fix subagent with specific instructions, or a change to the plan.

## 5. Finish

After the last task, run the full test suite and report task by task: done, its test, its commit. Then tell the person they can type `/loadout:code-review` for a team review before a pull request, and offer to open one following `loadout:git-pr`.
