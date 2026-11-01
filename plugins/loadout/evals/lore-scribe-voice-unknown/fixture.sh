#!/usr/bin/env bash
# Plants a tiny repo whose CLAUDE.md names a voice the skill does not know.
set -euo pipefail
mkdir -p docs
cat >CLAUDE.md <<'MD'
# tidemark

Build with `go build`.
Voice: pirate
MD
cat >README.md <<'MD'
# tidemark

Tracks what changed in a large directory of files, without git.

Install with `go install example.com/tidemark@latest`.
MD
