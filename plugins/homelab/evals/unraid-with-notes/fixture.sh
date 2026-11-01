#!/usr/bin/env bash
# Plants a notes file naming a pool the skill doesn't mention.
set -euo pipefail
mkdir -p "$HOME/.config/loadout/notes"
cat >"$HOME/.config/loadout/notes/unraid.md" <<'MD'
# unRAID notes

- Cache pool: `saltmarsh_fast`
MD
