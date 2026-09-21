#!/usr/bin/env bash
# Plants a git repository with a two-task implementation plan in the eval workspace
# (the current directory). Each task carries its test, so plan-run can follow its
# own flow: test first, make it pass, commit.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p docs/plans src tests
touch src/__init__.py tests/__init__.py
cat >docs/plans/two-helpers.md <<'MD'
# Two helpers

Goal: add two small helper modules. Run the tests with `python3 -m unittest`. Each task ends in its own commit.

### Task 1: slugify

Files: create `src/text_utils.py` and `tests/test_text_utils.py`.

Change: `slugify(text)` lowercases the text, replaces every run of characters that
are not letters or digits with a single hyphen, and strips hyphens from both ends.

Test: `tests/test_text_utils.py` asserts `slugify("Hello, World!") == "hello-world"`.

Commit: `feat: add slugify`.

### Task 2: clamp

Files: create `src/math_utils.py` and `tests/test_math_utils.py`.

Change: `clamp(value, low, high)` returns `low` when value is below it, `high` when
above, and `value` otherwise.

Test: `tests/test_math_utils.py` asserts `clamp(5, 0, 3) == 3` and `clamp(-1, 0, 3) == 0`.

Commit: `feat: add clamp`.
MD
git add -A && git commit -q -m "docs: add the two-helpers plan"
