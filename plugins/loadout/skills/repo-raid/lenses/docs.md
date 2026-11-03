# Lens: docs

Check the repo's documentation against `lore-scribe.md` in the facts directory, which holds the rules, and against the code.

- **Voice:** find a line starting `Voice:` in the repo's `CLAUDE.md`, and judge by that voice. With none, use `plain`. Never guess a voice from the subject.
- **Drift:** every command, flag, path, default and version the docs state. Check each against the tree. This is the highest-value part: a wrong command costs a reader more than a weak sentence.
- **Shape:** does the README tell a stranger what this is and whether it's for them, then get out of the way? Does each page keep to one type?

Report what would mislead or stop a reader. Skip wording you'd merely put differently.
