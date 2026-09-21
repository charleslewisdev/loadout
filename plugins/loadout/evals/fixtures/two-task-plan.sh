#!/usr/bin/env bash
# Plants a two-task implementation plan in the eval workspace (the current directory).
# The tasks are independent, and each check reads a file instead of running a command:
# Bash fails at sandbox setup inside eval runs on some machines.
set -euo pipefail
mkdir -p docs/plans src
cat >docs/plans/two-helpers.md <<'MD'
# Two helpers

Goal: add two small helper modules. The tasks are independent.

### Task 1: slugify

Files: create `src/text_utils.py`.

Change: `slugify(text)` lowercases the text, replaces every run of characters that
are not letters or digits with a single hyphen, and strips hyphens from both ends.

Check: `src/text_utils.py` defines `slugify`, and its docstring gives the example
`slugify("Hello, World!") == "hello-world"`.

### Task 2: clamp

Files: create `src/math_utils.py`.

Change: `clamp(value, low, high)` returns `low` when value is below it, `high` when
above, and `value` otherwise.

Check: `src/math_utils.py` defines `clamp`, and its docstring gives the example
`clamp(5, 0, 3) == 3`.
MD
