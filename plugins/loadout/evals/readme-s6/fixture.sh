#!/usr/bin/env bash
# Copies the repository's README.md, and nothing else, into the case directory.
# The scaffold runs from its own path, so the README is four levels up.
set -euo pipefail
cp "$(dirname "$0")/../../../../README.md" README.md
