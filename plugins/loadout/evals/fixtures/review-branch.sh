#!/usr/bin/env bash
# Plants a repository whose feature branch adds a function with a counting bug
# and breaks a project rule; the branch's own test does not catch the bug.
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@localhost "$@"; }
mkdir -p app tests
cat >CLAUDE.md <<'MD'
# pages

## Conventions that differ from defaults
- Public functions validate their arguments and raise ValueError on bad input.

Tests: `python3 -m unittest`
MD
cat >app/__init__.py <<'PY'
PY
cat >app/pagination.py <<'PY'
def paginate(items, page, per_page):
    """Items on a 1-based page."""
    if page < 1 or per_page < 1:
        raise ValueError("page and per_page must be positive")
    start = (page - 1) * per_page
    return items[start:start + per_page]
PY
cat >tests/__init__.py <<'PY'
PY
cat >tests/test_pagination.py <<'PY'
import unittest

from app.pagination import paginate


class PaginateTest(unittest.TestCase):
    def test_first_page(self):
        self.assertEqual(paginate(list(range(10)), 1, 3), [0, 1, 2])


if __name__ == "__main__":
    unittest.main()
PY
git init -q -b main && git add -A && g commit -q -m "feat: paginate"
git switch -q -c feature/page-count
cat >>app/pagination.py <<'PY'


def page_count(total, per_page):
    """Number of pages needed to show total items."""
    return total // per_page
PY
cat >>tests/test_pagination.py <<'PY'


class PageCountTest(unittest.TestCase):
    def test_exact_pages(self):
        from app.pagination import page_count

        self.assertEqual(page_count(9, 3), 3)
PY
g commit -q -am "feat: add page_count"
