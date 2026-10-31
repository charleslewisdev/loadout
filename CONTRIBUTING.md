# Contributing

loadout is one person's harness, shared to be forked. Forks are the main way to use it. Issues and small PRs are welcome, and I may say no to anything that adds to the always-on budget.

## Set up

```
git config core.hooksPath .githooks
```

The hooks run the identity guard on every commit and push. Add your commit email to `guard/allowed-emails`; `guard/denylist.example` shows the shape of the optional private denylist.

## Before a PR

- Run `scripts/check`. It lints budgets, scans history, and runs the hook and statusline tests.
- A new skill or style rule needs an eval case: see "Add a skill" in the README. Run it with `scripts/eval`.
- Commits follow Conventional Commits. PRs need a "Feedback wanted" section, as `pr-turn-in` describes.

## Text that goes public

Anything posted to GitHub from this repo is a publication. In a Claude Code session here, `guard/gh-hook` scans gh commands before they run. Write long text to a file and pass it with `--body-file`.
