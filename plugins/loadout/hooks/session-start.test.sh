#!/usr/bin/env bash
# Tests for hooks/session-start: silent when configured, one systemMessage otherwise.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="$HERE/session-start"
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
run() { printf '%s\n' "$1" >"$t/settings.json"; out=$(CLAUDE_CONFIG_DIR=$t "$HOOK"); }

run '{"enabledPlugins":{"loadout@loadout":true}}'
check "loadout alone, with no style, is configured" test -z "$out"
run '{"enabledPlugins":{"loadout@loadout":true,"bard@loadout":true},"outputStyle":"bard:peer"}'
check "bard with its style set is configured" test -z "$out"
run '{"enabledPlugins":{"bard@loadout":true}}'
check "bard without outputStyle is reported" grep -q 'not bard:peer' <<<"$out"
run '{"statusLine":{"command":"'"$t"'/loadout/statusline.sh"}}'
check "a missing loadout statusline is reported" grep -q 'not an executable file' <<<"$out"
run '{"enabledPlugins":{"loadout@loadout":true},"outputStyle":"loadout:peer"}'
check "the pre-0.8.0 style is reported" grep -q 'moved to bard:peer' <<<"$out"
exit $fail
