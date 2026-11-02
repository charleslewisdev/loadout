#!/usr/bin/env bash
# Plants a curated map and no gh answer, so gh fails and only the map can
# supply the repo: its name and job appear nowhere else.
set -euo pipefail
mkdir -p "$HOME/.config/loadout/notes"
cat >"$HOME/.config/loadout/notes/portfolio.md" <<'MD'
# Portfolio map

- `sample-dev/brass-ledger`: the double-entry ledger behind every app that takes money. Use it instead of writing another.
- `sample-dev/trailcam-sorter`: sorts wildlife camera photos.
MD
