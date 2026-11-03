#!/usr/bin/env bash
# Copies the repository README's first screen: everything above its first
# second-level heading. The scaffold runs from its own path, so the README is
# four levels up.
set -euo pipefail
sed '/^## /,$d' "$(dirname "$0")/../../../../README.md" >README.md
