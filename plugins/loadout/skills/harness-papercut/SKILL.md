---
name: harness-papercut
description: "Logs one harness annoyance and proposes the smallest fix as a pull request to the loadout repo; the retro reads the log. Typed only."
disable-model-invocation: true
argument-hint: <what annoyed you>
allowed-tools: Bash(git status *), Bash(git switch *), Bash(git pull --ff-only *), Bash(git add *), Bash(git commit -m *), Bash(git log *), Bash(git diff *), Bash(git remote *), Bash(git push -u origin papercut/*), Bash(gh pr create *), Bash(gh pr view *), Bash(scripts/lint-budgets), Bash(scripts/budget), Bash(scripts/retro-evidence *), Bash(guard/scan text *)
---

# Log a papercut

Turn one specific annoyance into a logged line and, when the fix is clear, the smallest change that removes it. Every change traces to this friction; no general improvements.

1. **Capture** the annoyance from the arguments. If there are none, ask for it in one or two sentences. Quote it word for word from here on.
2. **Find the checkout:** `$LOADOUT_REPO`, or the current repository when its `.claude-plugin/marketplace.json` names `loadout`. If neither exists, stop and say to run `./install.sh workstation` in the checkout, which sets `LOADOUT_REPO`. If `git status --short --untracked-files=no` shows changes to tracked files, ask before going on; untracked files stay out of the papercut.
3. **Branch** `papercut/<short-slug>` from main.
4. **Decide which layer owns the fix:**
   - something that must happen every time: a hook in `plugins/loadout/hooks/`, registered through `hook-timed`
   - a procedure or knowledge needed sometimes: a skill in `plugins/loadout/skills/`
   - how Claude talks or writes: the style in `plugins/loadout/output-styles/peer.md`, with an eval case that shows the change matters
   - a setting or permission: `profiles/workstation.json`
   - a single project's convention: that project's CLAUDE.md, not this repository

   When no fix is clear, log the annoyance only; the retro decides.
5. **Make the smallest fix,** then run `scripts/lint-budgets`, and `scripts/budget` for anything always on.
6. **Log it** in a new file, `retros/friction/<yyyy-mm-dd>-<slug>.md`, holding one line: `YYYY-MM-DD <friction> -> <fix, or "logged"> (<file touched>)`. One file per papercut, so open papercut pull requests never conflict. If `scripts/retro-evidence` already lists the same friction, say so: the retro ranks repeated friction first.
7. **Commit** the files you changed, staged by name (never `git add -A`, never `--no-verify`). With no remote, stop after the commit and say so. Otherwise push with `git push -u origin papercut/<slug>`, write the title and body to a file, run `guard/scan text <file>` on it, and **open a pull request** with `gh pr create --body-file <file>` following `loadout:git-pr`, with the friction quoted. Report the link, never merge, and switch back to the branch the checkout started on.
