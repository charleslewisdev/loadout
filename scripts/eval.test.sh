#!/usr/bin/env bash
# scripts/eval against a stub claude: a broken sandbox must fail a passing score.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
mkdir -p "$t/bin"
cat >"$t/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Plants the kept directory `claude plugin eval --keep-temp` leaves, then reports it.
[[ " $* " == *' --keep-temp '* ]] || { echo 'score 1.0'; exit 0; }
echo "${TMPDIR:-}" >"$STUB_TMP/tmpdir-seen"
command -v gh >"$STUB_TMP/gh-seen"
echo "$PATH" >"$STUB_TMP/path-seen"
dir=$STUB_TMP/claude-eval-$RANDOM
mkdir -p "$dir/config" "$dir/sealed"
[[ ${STUB_BROKEN:-} ]] && echo "$STUB_BROKEN" >"$dir/config/trace.jsonl"
echo 'apply-seccomp in text the plugin wrote' >"$dir/sealed/ignored"
chmod 000 "$dir/sealed"
[[ ${STUB_NO_CASES:-} ]] && { rm -rf "$dir"; echo 'No eval cases found matching --case'; exit 1; }
if [[ ${STUB_REWORDED:-} ]]; then echo "⚠ preserved $dir"; else echo "⚠ kept $dir: home/ and tmp/ in it are sealed"; fi
# Grader text can quote anything a plugin wrote, so it must never choose a path.
[[ ${STUB_VICTIM:-} ]] && echo "    ✓ grader (weight 1): kept $STUB_TMP/claude-eval-stale/../${STUB_VICTIM##*/}: and more"
exit "${STUB_RC:-0}"
STUB
chmod +x "$t/bin/claude"
run() { rc=0; out=$(env PATH="$t/bin:$PATH" STUB_TMP="$t" "$@" 2>&1) || rc=$?; }
left() { ls -d "$t"/claude-eval-* >/dev/null 2>&1; }

run STUB_X=1 "$here/eval" plugins/x
check 'a clean run keeps its exit code' test "$rc" = 0
check 'the eval gets the stub gh, ahead of any real one' test "$(cat "$t/gh-seen")" = "$here/eval-bin/gh"
check 'it cleans up the trace it kept' bash -c "! ls -d '$t'/claude-eval-* 2>/dev/null | grep -q ."

run env PATH="$t/bin:$t/.pyenv/shims:/usr/bin:$t/.asdf/shims/:/bin" STUB_TMP="$t" "$here/eval" plugins/x
check 'version-manager shims move to the end of PATH, behind the system python3' grep -q ":$t/bin:/usr/bin:/bin:$t/.pyenv/shims:$t/.asdf/shims/\$" "$t/path-seen"

mkdir -p "$t/mise/shims"
cp "$t/bin/claude" "$t/mise/shims/claude"
run env PATH="$t/mise/shims:/usr/bin:/bin" STUB_TMP="$t" "$here/eval" plugins/x
check 'a claude reachable only through a shim still runs' test "$rc" = 0
rm -rf "$t/mise"

run STUB_BROKEN='apply-seccomp: Permission denied' "$here/eval" plugins/x
check 'a broken sandbox exits 3 even at a passing score' test "$rc" = 3
check 'it says why' grep -q 'scores are invalid' <<<"$out"

run STUB_BROKEN='bwrap: setting up uid map: Permission denied' "$here/eval" plugins/x
check 'a bwrap failure counts as a broken sandbox' test "$rc" = 3

run STUB_BROKEN='/bin/bash: line 1: /tmp/claude-eval-x/tmp/claude-1000/cwd-0339: Read-only file system' "$here/eval" plugins/x
check 'an unwritable workspace counts as a broken sandbox' test "$rc" = 3

run STUB_BROKEN="fatal: Unable to create '/tmp/claude-eval-x/home/cwd/.git/index.lock': Read-only file system" "$here/eval" plugins/x
check 'an unwritable .git counts as a broken sandbox' test "$rc" = 3

run STUB_BROKEN='OSError: [Errno 30] Read-only file system' "$here/eval" plugins/x
check 'a read-only error from a case itself is not a broken sandbox' test "$rc" = 0

run HOME="$t/home" XDG_CACHE_HOME= TMPDIR=/tmp "$here/eval" plugins/x
check 'the workspace stays out of /tmp, which the eval sandbox makes read-only' test "$(cat "$t/tmpdir-seen")" = "$t/home/.cache/loadout/eval-tmp"
check 'that directory exists' test -d "$t/home/.cache/loadout/eval-tmp"

run STUB_REWORDED=1 "$here/eval" plugins/x
check 'a run it cannot check exits 3, not the score' test "$rc" = 3
check 'it says the check did not run' grep -q 'could not check' <<<"$out"
chmod -R u+rwx "$t"/claude-eval-*; rm -rf "$t"/claude-eval-*

run STUB_NO_CASES=1 "$here/eval" plugins/x
check 'no matching cases keeps the CLI exit code' test "$rc" = 1

mkdir -p "$t/victim" "$t/claude-eval-stale"
run STUB_VICTIM="$t/victim" "$here/eval" plugins/x
check 'grader text cannot pick what gets deleted' test -d "$t/victim"

cache=$t/cache/loadout/eval-tmp
mkdir -p "$cache/claude-eval-old/sealed" "$cache/claude-eval-new" "$cache/keep-me" "$t/victim2"
chmod 000 "$cache/claude-eval-old/sealed"
ln -s "$t/victim2" "$cache/claude-eval-link"
touch -d '2 days ago' "$cache/claude-eval-old" "$cache/keep-me" "$t/victim2"
touch -h -d '2 days ago' "$cache/claude-eval-link"
run XDG_CACHE_HOME="$t/cache" "$here/eval" plugins/x
check 'a workspace left over a day ago is cleared at start, sealed parts too' test ! -e "$cache/claude-eval-old"
check 'a workspace from today stays, since another run may own it' test -d "$cache/claude-eval-new"
check 'only claude-eval-* directories are cleared' test -d "$cache/keep-me"
check 'a symlink is not followed' test -d "$t/victim2"

run STUB_RC=1 "$here/eval" plugins/x
check 'a low score still exits 1' test "$rc" = 1

run STUB_X=1 "$here/eval" plugins/x --keep-temp
check 'a kept trace stays when asked for' left
chmod -R u+rwx "$t"/claude-eval-*

run STUB_X=1 "$here/eval" plugins/x --publish-report
check 'publishing is refused' test "$rc" = 2

exit "$fail"
