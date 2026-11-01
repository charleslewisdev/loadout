#!/usr/bin/env bash
# Plants a tiny repo with no voice line, so the default applies.
set -euo pipefail
mkdir -p docs
cat >CLAUDE.md <<'MD'
# tidemark

Build with `go build`.

MD
cat >README.md <<'MD'
# tidemark

Tracks what changed in a large directory of files, without git.

Install with `go install example.com/tidemark@latest`.
MD
