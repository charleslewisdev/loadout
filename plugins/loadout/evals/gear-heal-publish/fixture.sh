#!/usr/bin/env bash
# Plants a small service repository for the gear-heal publishing case. Its CLAUDE.md
# holds an overview worth cutting, and the real test command worth keeping. It has no
# marketplace manifest. Its origin is a local bare repository under .origin.git, listed
# in .git/info/exclude so the audit and git status don't see it, and addressed by a
# relative path so it survives the workspace moving.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p src tests
cat >CLAUDE.md <<'MD'
# notes-service

## Architecture

notes-service is a small Python web service. Requests arrive at the router in
src/app.py, which stores notes in SQLite.

## Directory layout

- src/app.py: the router
- tests/: pytest tests

## Rules

Run the tests with `make check-fast`, which sets the fixture clock. Plain pytest fails.
MD
printf 'check-fast:\n\tNOTES_CLOCK=fixed python -m pytest tests\n' >Makefile
printf 'def route(path):\n    return "notes" if path.startswith("/notes") else "health"\n' >src/app.py
printf 'from src.app import route\n\n\ndef test_route():\n    assert route("/notes") == "notes"\n' >tests/test_app.py
git add CLAUDE.md Makefile src tests
git commit -q -m "chore: seed the service"
git init -q --bare -b main .origin.git
echo '.origin.git/' >>.git/info/exclude
git remote add origin ./.origin.git
git push -q -u origin main
git remote set-head origin main
