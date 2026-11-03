# Lens: code

Find the refactors worth doing, ranked by payoff: what gets easier or safer, against what the change costs.

- Start with `log.txt` and the largest files: code changed often, and code that's hard to change, repay work first.
- Look for logic repeated where a fix must land in several places, dead code, a module doing two jobs, and a missing test around code that fails expensively.
- Name the payoff in concrete terms: which change gets cheaper, or which failure goes away.

Return at most five. A clean, small repo may have none, so say so. Skip style, and skip anything a formatter or linter would catch.
