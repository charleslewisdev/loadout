#!/usr/bin/env bash
# Tests for hooks/notify: a terminal notification normally, nothing under Crystal Bridge.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NOTIFY="$HERE/notify"
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}

payload='{"cwd":"/work/app","message":"Claude needs your permission"}'

out=$(env -u CRYSTAL_SESSION "$NOTIFY" "needs input" <<<"$payload")
check "a terminal session gets an OSC 777 notification naming the project" \
  grep -q "777;notify;Claude Code;\[app\] Claude needs your permission" <<<"$(jq -r .terminalSequence <<<"$out")"

out=$(CRYSTAL_SESSION=0f0f0f0f-0000-4000-8000-000000000000 "$NOTIFY" "needs input" <<<"$payload"); rc=$?
check "under Crystal Bridge it prints nothing (the bridge notifies instead)" test -z "$out"
check "and exits 0" test "$rc" -eq 0

exit "$fail"
