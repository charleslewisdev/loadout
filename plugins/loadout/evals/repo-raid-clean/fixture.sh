#!/usr/bin/env bash
# Plants a small tidy library with nothing to report under the principles, docs and
# code lenses: its rule holds, its commands work and it has no duplication. The repo
# has no GitHub origin, so the raid must not reach for one.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p src tests
cat >CLAUDE.md <<'MD'
# slug

Keep `slugify` free of dependencies: standard library only.

Run the tests with `make check`.
MD
cat >README.md <<'MD'
# slug

Turns a title into a URL slug, using only the Python standard library.

```python
from src.slug import slugify

slugify("Hello, World!")  # "hello-world"
```

Run the tests with `make check`.
MD
printf 'check:\n\tpython -m pytest tests\n' >Makefile
cat >src/slug.py <<'PY'
import re


def slugify(title):
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
PY
touch src/__init__.py
cat >tests/test_slug.py <<'PY'
from src.slug import slugify


def test_slugify():
    assert slugify("Hello, World!") == "hello-world"


def test_empty():
    assert slugify("") == ""
PY
git add CLAUDE.md Makefile README.md src tests
git commit -q -m "feat: add slugify"
