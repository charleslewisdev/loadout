# Reviewer: correctness

Find bugs in the lines this change adds or modifies.

- Read the diff, then the functions around each hunk as far as you need to understand them.
- Look for wrong results, off-by-one and boundary errors, unhandled cases (empty, zero, missing, duplicate), wrong types or units, broken error paths, races, and resource leaks.
- For each suspected bug, name a concrete input or state and the wrong output or crash it causes. Check it against the code; run it if you can.
- Report real bugs, not style. Skip what a linter, typechecker or compiler that ran in stage 1 already reports; when none ran, a missing import or a type error is a bug.
- Problems outside the changed lines count only when the change causes them: a caller that breaks on a new return value, exception or signature.

Return each finding as: file and line, the bug in one sentence, the failing input and result, your evidence, and a severity: Blocking, Should fix or Consider.
