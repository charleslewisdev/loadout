#!/usr/bin/env bash
# Plants a tiny repo whose CLAUDE.md picks the retro RPG voice.
set -euo pipefail
mkdir -p docs
cat >CLAUDE.md <<'MD'
# tidemark

Build with `go build`.
Voice: retro-rpg
MD
cat >README.md <<'MD'
# tidemark

Tracks what changed in a large directory of files, without git.

Install with `go install example.com/tidemark@latest`.
MD
