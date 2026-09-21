# Reviewer: history

Judge the change against the history of the code it touches.

- Run `git log -p` and `git blame` on the changed regions. Read the commit messages and any linked pull requests or issues (`gh pr list --search`, `gh pr view`).
- Look for a change that reverts or undoes an earlier fix, reintroduces a bug an earlier commit removed, or breaks an assumption a past commit relied on.
- Check earlier review comments on the same files for advice that applies here too.

Return each finding as: file and line, what the history shows (commit and quote), and why this change conflicts with it.
