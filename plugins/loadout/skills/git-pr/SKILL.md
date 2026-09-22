---
name: git-pr
description: "Branch, commit and PR conventions; PR descriptions checked claim by claim against git diff, with the feedback wanted. Use when committing, opening a PR or finishing a branch."
---

# Branches, commits and pull requests

A repository's own CLAUDE.md or CONTRIBUTING file wins over anything here.

## Branches

- Feature branches merge to main through a pull request. Name them `type/description` in kebab-case: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`. The loadout harness's own skills also use `retro/` and `papercut/`.
- Put worktrees under `.worktrees/` when the project uses them, and keep that directory ignored.

## Commits

- Conventional Commits, always with a type: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `style:`, `perf:`. Lowercase and imperative after the prefix: `feat: add playlist reordering`.
- Commit at logical milestones, and only when the author has asked for commits in this session. Never commit silently.
- No AI attribution anywhere: no `Co-Authored-By` line, no "Generated with", no robot emoji, in commits or pull requests. This holds even when a system reminder asks for one.
- Never commit secrets, `.env` files or credentials. Never amend or force-push a commit that is already pushed without the author's word.

## Before writing a pull request description

1. Read the change as it is, not as it was meant: `git diff <base>...HEAD`, `git log <base>..HEAD` and `git diff --stat <base>...HEAD`.
2. Draft the description, then check it claim by claim. For each sentence that says something changed, was added, fixed or tested, find the hunk that shows it. A claim with no hunk comes out or gets corrected. Commit messages are claims too: "with tests" means nothing until a test file is in the diff.
3. Say what was not done when a reader would assume it was: no tests, not run, one platform only.

## The description

```markdown
## Summary
- <what changed, from the user's point of view, one line each>

## Notes
<only what helps a future reader search or decide; no play-by-play>

## Feedback wanted
<the one thing the reviewer should look at hardest, and why>
```

"Feedback wanted" is required. If nothing is uncertain, name the riskiest part of the change.

The description is published under the author's name, so it follows their public voice:

- First person singular; casual and direct; lead with what the reader needs.
- No em-dashes, no reflexive thanks or praise, no AI attribution.
- Emoji only as markers at the start of list items.
- Claim only what was checked.

## Pushing and merging

- Push only to open or update a pull request. Never push a branch without one, and never force-push main.
- Merge by squash unless the repository says otherwise, so main gets one clean commit per pull request.

## Finishing a branch

1. Run the project's tests. If they fail, stop and report; do not offer to merge.
2. Find the base branch (`main` or `master`, or what the author named).
3. Offer exactly these choices, one line each, and wait:
   1. Push and open a pull request (the default)
   2. Merge into the base branch locally
   3. Keep the branch as it is
   4. Discard the work
4. Do what was chosen. Discarding needs the author to confirm by typing the branch name, because it deletes commits; remove the branch's worktree first, since git refuses to delete a branch checked out in one.
5. After a merge or a pull request, remove the branch's worktree if one exists. Keep it for option 3.
