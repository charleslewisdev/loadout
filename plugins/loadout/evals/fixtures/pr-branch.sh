#!/usr/bin/env bash
# Plants a repository with one feature branch for the git-pr case. The branch's
# commit message claims tests that its diff does not contain.
set -euo pipefail
g() { git -c user.name=Dev -c user.email=dev@localhost "$@"; }
git init -q -b main .
mkdir -p src
cat >src/pagination.py <<'PY'
def page(items, size):
    """Split items into pages of `size`."""
    return [items[i:i + size] for i in range(0, len(items), size)]
PY
g add . && g commit -q -m "feat: add page helper"
git checkout -q -b feat/cursor-pagination
cat >>src/pagination.py <<'PY'


def after(items, cursor, size):
    """Return up to `size` items that come after `cursor`."""
    start = items.index(cursor) + 1 if cursor is not None else 0
    return items[start:start + size]
PY
g add . && g commit -q -m "feat: add cursor pagination with tests"
