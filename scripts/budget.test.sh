#!/usr/bin/env bash
# scripts/budget against a stub claude: no network, no credentials.
#
# The stub prices a run from its flags, so every surface has a known cost, and it
# misses connectors on odd-numbered attempts unless told otherwise. That reproduces
# the race: connectors arrive in some runs of a configuration and not in others.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
pass=0
fail=0
ok() { echo "✓ $1"; pass=$((pass + 1)); }
no() { echo "✗ $1"; fail=$((fail + 1)); }
has() { if grep -q -- "$3" <<<"$2"; then ok "$1"; else no "$1 (wanted: $3)"; fi; }
hasnt() { if grep -q -- "$3" <<<"$2"; then no "$1 (found: $3)"; else ok "$1"; fi; }
field() { sed -n "s/^$1=//p" "$2"; }

t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
mkdir -p "$t/bin" "$t/home/.claude/skills/synced/acct/alpha" "$t/home/.claude/skills/synced/acct/beta"
touch "$t/home/.claude/skills/synced/acct/alpha/SKILL.md" "$t/home/.claude/skills/synced/acct/beta/SKILL.md"
echo '{"enabledPlugins":{"kit@market":true,"voice@market":true,"gone@market":false}}' >"$t/home/.claude/settings.json"

cat >"$t/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Floor 1,000. Skills 400, kit 50, voice 70, CLAUDE.md 30, auto-memory 80.
# Connectors: Mail 300 and Docs 900 when they arrive, each adding deferred names,
# plus 20 shared by any connector set. Stale, which needs authentication, costs 10.
case ${1:-} in
  --version) echo '9.9.9 (Claude Code)'; exit 0 ;;
  mcp)
    printf 'Checking MCP server health…\n\n'
    case ${STUB_CONNECTORS:-1} in
      1) printf '%s\n' \
        'acct Mail: https://example.test/a - ✔ Connected' \
        'acct Docs: https://example.test/b --header X-A: 1 --header X-B: 2 - ✔ Connected' \
        'acct Stale: https://example.test/c - ! Needs authentication' ;;
      failed) printf '%s\n' \
        'acct Mail: https://example.test/a - ✘ Failed to connect' \
        'acct Docs: https://example.test/b - ✔ Connected' ;;
      reworded) echo 'acct Mail: https://example.test/a (ok)' ;;
      none) echo 'No MCP servers configured. Use `claude mcp add` to add a server.' ;;
    esac
    exit 0 ;;
esac
cat >/dev/null  # the real CLI reads stdin, so a loop around it must not share its input
log='' settings='' strict=0 safe=0
while (($#)); do
  case $1 in
    --debug-file) log=$2; shift ;;
    --settings) settings=$2; shift ;;
    --strict-mcp-config) strict=1 ;;
    --safe-mode) safe=1 ;;
  esac
  shift
done
attempt=${log%.log}; attempt=${attempt##*.}
[[ $settings == *SessionStart* ]] && echo "${log##*/}" >>"$STUB_HELD"
tokens=1000 deferred=10
if ((!safe)); then
  denied() { grep -q "\"serverName\":\"acct $1\"" <<<"$settings"; }
  [[ $settings == *skillOverrides* ]] || tokens=$((tokens + 400))
  tokens=$((tokens + ${STUB_EXTRA:-0}))
  [[ $settings == *'"kit@market":false'* ]] || tokens=$((tokens + 50))
  [[ $settings == *'"voice@market":false'* ]] || tokens=$((tokens + 70))
  [[ -n ${CLAUDE_CODE_DISABLE_CLAUDE_MDS:-} ]] || tokens=$((tokens + 30))
  [[ -n ${CLAUDE_CODE_DISABLE_AUTO_MEMORY:-} ]] || tokens=$((tokens + 80))
  if ((!strict)) && [[ ${STUB_CONNECTORS:-1} == 1 ]]; then
    late=$((attempt % 2))
    [[ ${STUB_MISS:-} == always ]] && late=1
    [[ ${STUB_MISS:-} == never ]] && late=0
    if ((!late)); then
      any=0
      denied Mail || { tokens=$((tokens + 300)); deferred=$((deferred + 20)); any=1; }
      denied Docs || { tokens=$((tokens + 900)); deferred=$((deferred + 40)); any=1; }
      denied Stale || tokens=$((tokens + 10))
      ((any)) && tokens=$((tokens + 20))
    fi
  fi
fi
echo "2026-01-01T00:00:00.000Z [DEBUG] Dynamic tool loading: 0/$deferred deferred tools included" >"$log"
printf '{"is_error":false,"usage":{"input_tokens":2,"cache_creation_input_tokens":%d,"cache_read_input_tokens":0}}\n' $((tokens - 2))
STUB
chmod +x "$t/bin/claude"

run() { env PATH="$t/bin:$PATH" HOME="$t/home" CLAUDE_CONFIG_DIR= LOADOUT_CACHE="$t/cache" STUB_HELD="$t/held" "$@" "$here/budget" 2>"$t/err"; }

# Connectors arrive on even attempts: the odd ones must be discarded, not averaged in.
out=$(run env); rc=$?
c=$t/cache/budget
[[ $rc == 0 ]] && ok 'a share under the ceiling passes' || no "exit $rc, wanted 0 under the ceiling"
hasnt 'no line shows a range caused by the race' "$out" ' to '
has 'the headline share counts connectors' "$(field share "$c")" '^1780-1780$'
has 'the share without connectors stands alone' "$(field share_without_connectors "$c")" '^550-550$'
has 'connector cost is on its own line' "$out" 'connectors  *1,230'
has 'connector cost reaches the cache' "$(field connectors "$c")" '^1230$'
has 'auto-memory is free of connector cost' "$(field automemory "$c")" '^80-80$'
has 'the first connector is split out' "$out" 'acct Mail  *300'
has 'the second connector is split out' "$out" 'acct Docs  *900'
hasnt 'server arguments stay out of the name' "$out" 'X-A'
has 'an unauthenticated connector is still split out' "$out" 'acct Stale  *10'
has 'what connectors share is reported' "$out" 'shared  *20'
has 'synced skills are measured on and off' "$out" 'synced skills  *400  *(2 skills)'
has 'each enabled plugin has a line' "$out" 'kit@market  *50'
has 'the second plugin has a line' "$out" 'voice@market  *70'
hasnt 'a disabled plugin has no line' "$out" 'gone@market'
has 'the user CLAUDE.md has a line' "$out" 'user CLAUDE.md  *30'
has 'discarded runs are counted' "$(field missed_runs "$c")" '^[1-9]'
has 'runs agree once misses are dropped' "$(field spread "$c")" '^0$'
held=$(cat "$t/held")
has 'connector runs hold the first request' "$held" 'empty-configured'
has 'runs that split connectors hold it too' "$held" 'connector-1'
hasnt 'runs without connectors skip the wait' "$held" 'empty-floor'

# The result must not depend on how the race went.
first=$(field share "$c")
run env STUB_MISS=never >/dev/null
has 'a run with no misses gives the same share' "$(field share "$c")" "^$first\$"
has 'a run with no misses discards nothing' "$(field missed_runs "$c")" '^0$'

# Connectors count toward the ceiling, so a heavy set fails without being an error.
out=$(run env STUB_EXTRA=7000 STUB_MISS=never); rc=$?
[[ $rc == 1 ]] && ok 'a share over the ceiling exits 1' || no "exit $rc, wanted 1 over the ceiling"
has 'that failure is cached' "$(field result "$c")" '^fail$'
run env STUB_MISS=never >/dev/null

# A machine where connectors never arrive has not been measured: keep the old result.
cp "$c" "$t/before"
out=$(run env STUB_MISS=always); rc=$?
[[ $rc == 2 ]] && ok 'connectors that never arrive exit 2' || no "exit $rc, wanted 2 when connectors never arrive"
has 'the failure says why' "$(cat "$t/err")" 'connectors never arrived'
cmp -s "$c" "$t/before" && ok 'a failed measurement keeps the last good result' || no 'a failed measurement overwrote the cache'

# A failed connector would drop out of the share, turning an outage into a pass.
out=$(run env STUB_CONNECTORS=failed); rc=$?
[[ $rc == 2 ]] && ok 'a failed connector exits 2' || no "exit $rc, wanted 2 for a failed connector"
has 'that failure names the cause' "$(cat "$t/err")" 'failed to connect'
cmp -s "$c" "$t/before" && ok 'a failed connector keeps the last good result' || no 'a failed connector overwrote the cache'

# A list this script can't read is not the same as an empty list.
out=$(run env STUB_CONNECTORS=reworded); rc=$?
[[ $rc == 2 ]] && ok 'an unreadable connector list exits 2' || no "exit $rc, wanted 2 for an unreadable list"
cmp -s "$c" "$t/before" && ok 'an unreadable list keeps the last good result' || no 'an unreadable list overwrote the cache'

# No connectors at all: nothing to wait for, and no connector line to print.
rm -f "$c"
out=$(run env STUB_CONNECTORS=none); rc=$?
[[ $rc == 0 ]] && ok 'a machine with no connectors passes' || no "exit $rc with no connectors"
has 'its connector cost is zero' "$(field connectors "$c")" '^0$'
hasnt 'it prints no connector split' "$out" 'acct '

echo
echo "budget tests: $pass passed, $fail failed"
((fail == 0))
