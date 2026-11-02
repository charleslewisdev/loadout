#!/usr/bin/env bash
# Tests gear-heal's heal helper on synthetic repositories, with a synthetic denylist
# and HOME, so the real denylist is never read. No network, no Claude.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
heal=$root/plugins/loadout/skills/gear-heal/heal
tmp=$(mktemp -d)
trap 'chmod -R u+rwx "${tmp:?}" 2>/dev/null; rm -rf "${tmp:?}"' EXIT
failed=0
fail() { echo "FAIL: $1"; failed=1; }
has() { grep -qF -- "$2" <<<"$1" || fail "${3:-missing}: $2"; }
lacks() { ! grep -qF -- "$2" <<<"$1" || fail "${3:-unexpected}: $2"; }
expect() { ((rc == $1)) || fail "$2: exit $rc, wanted $1"; }
in_dir() {  # directory, command...; sets out and rc
  local d=$1
  shift
  rc=0
  out=$(cd "$d" && "$@" 2>&1) || rc=$?
}

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE LOADOUT_REPO GUARD_DENYLIST GUARD_REQUIRE_DENYLIST
export HOME=$tmp/home
mkdir -p "$HOME"

[[ -x $heal ]] || { echo "FAIL: heal is missing or not executable"; exit 1; }

# ---- synthetic repositories and a stand-in checkout ---------------------------
marketplace() {  # dir, marketplace name
  git init -q -b main "$1"
  mkdir -p "$1/.claude-plugin"
  printf '{"name":"%s","plugins":[]}\n' "$2" >"$1/.claude-plugin/marketplace.json"
}
marketplace "$tmp/checkout" loadout
marketplace "$tmp/other-market" something-else
marketplace "$tmp/broken-market" loadout
printf 'not json\n' >"$tmp/broken-market/.claude-plugin/marketplace.json"
git init -q -b main "$tmp/plain"
mkdir -p "$tmp/checkout/sub/dir" "$tmp/not-a-repo"
ln -s "$tmp/checkout" "$tmp/link"

mkdir -p "$tmp/kit/guard" "$tmp/kit/scripts"
printf '#!/usr/bin/env bash\necho "scan require=${GUARD_REQUIRE_DENYLIST:-unset} args=$*"\n' >"$tmp/kit/guard/scan"
printf '#!/usr/bin/env bash\necho "evidence args=$*"\n' >"$tmp/kit/scripts/retro-evidence"
chmod +x "$tmp/kit/guard/scan" "$tmp/kit/scripts/retro-evidence"

# ---- heal mode -----------------------------------------------------------------
in_dir "$tmp/checkout" "$heal" mode
expect 0 'mode, a loadout marketplace'
[[ $out == harness ]] || fail "a loadout marketplace with LOADOUT_REPO unset printed: $out"

in_dir "$tmp/checkout" env LOADOUT_REPO="$tmp/checkout" "$heal" mode
[[ $out == harness ]] || fail "LOADOUT_REPO at this repo printed: $out"

in_dir "$tmp/checkout/sub/dir" env LOADOUT_REPO="$tmp/checkout" "$heal" mode
[[ $out == harness ]] || fail "a subdirectory of the checkout printed: $out"

in_dir "$tmp/checkout" env LOADOUT_REPO="$tmp/link" "$heal" mode
[[ $out == harness ]] || fail "LOADOUT_REPO through a symlink printed: $out"

in_dir "$tmp/checkout" env LOADOUT_REPO="$tmp/kit" "$heal" mode
expect 0 'mode, LOADOUT_REPO elsewhere'
[[ $out == repo ]] || fail "a loadout marketplace with LOADOUT_REPO elsewhere printed: $out"

in_dir "$tmp/checkout" env LOADOUT_REPO="$tmp/no-such-dir" "$heal" mode
[[ $out == repo ]] || fail "LOADOUT_REPO that doesn't exist printed: $out"

for d in other-market broken-market plain not-a-repo; do
  in_dir "$tmp/$d" "$heal" mode
  expect 0 "mode in $d"
  [[ $out == repo ]] || fail "$d printed: $out"
done

# A relative value is whatever the current repo makes of it.
in_dir "$tmp/checkout" env LOADOUT_REPO=. "$heal" mode
[[ $out == repo ]] || fail "a relative LOADOUT_REPO printed: $out"
in_dir "$tmp/checkout" env LOADOUT_REPO=. "$heal" scan "$tmp/checkout/.claude-plugin/marketplace.json"
expect 3 'scan with a relative LOADOUT_REPO'

# The audited repo chooses its own scripts, so publishing and repo-relative commands
# have to ask.
grants=$(sed -n 's/^allowed-tools: //p' "$root/plugins/loadout/skills/gear-heal/SKILL.md")
[[ -n $grants ]] || fail 'no allowed-tools line'
for banned in 'git push' 'gh pr create' 'Bash(scripts/' 'Bash(guard/'; do
  [[ $grants != *"$banned"* ]] || fail "allowed-tools grants $banned"
done

in_dir "$tmp/checkout" "$heal" mode extra
expect 2 'mode with an argument'

# ---- heal evidence: no arguments, or exactly --since <date> ---------------------
in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" "$heal" evidence
expect 0 'evidence, no arguments'
has "$out" "evidence args=--project $(cd "$tmp/plain" && pwd -P)" 'evidence lost the current repo'

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" "$heal" evidence --since 2026-01-01
expect 0 'evidence --since'
has "$out" "--since 2026-01-01" 'evidence lost --since'

for args in '--project /elsewhere' '--since 2026-01-01 --project /elsewhere' '--project /elsewhere --since 2026-01-01' '--since' '2026-01-01' '--since 2026-01-01 extra'; do
  # shellcheck disable=SC2086
  in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" "$heal" evidence $args
  expect 2 "evidence $args"
  lacks "$out" 'evidence args=' "evidence ran with: $args"
done

# Rejected before it looks for the checkout, so a bad call can't read as out of reach.
in_dir "$tmp/plain" "$heal" evidence --project /elsewhere
expect 2 'evidence --project with LOADOUT_REPO unset'

in_dir "$tmp/plain" "$heal" evidence
expect 3 'evidence with LOADOUT_REPO unset'

# ---- heal scan: fails closed without a denylist ---------------------------------
printf '\\bzorblax\\b\n' >"$tmp/deny"
printf 'a clean body\n' >"$tmp/clean.md"
printf 'the zorblax plan\n' >"$tmp/dirty.md"

scan_refused() {  # label; out and rc already set
  expect 3 "$1"
  [[ $(wc -l <<<"$out") -eq 1 ]] || fail "$1: more than one line: $out"
  has "$out" 'denylist' "$1: the line doesn't name the denylist"
  lacks "$out" zorblax "$1: printed the denylist's contents"
  lacks "$out" 'scan require=' "$1: guard/scan ran"
}

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" "$heal" scan "$tmp/clean.md"
scan_refused 'no denylist at the default path'

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" GUARD_DENYLIST="$tmp/no-such-deny" "$heal" scan "$tmp/clean.md"
scan_refused 'GUARD_DENYLIST points at nothing'

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" GUARD_DENYLIST="$tmp/not-a-repo" "$heal" scan "$tmp/clean.md"
scan_refused 'GUARD_DENYLIST points at a directory'

if ((EUID != 0)); then
  cp "$tmp/deny" "$tmp/locked"
  chmod 000 "$tmp/locked"
  in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" GUARD_DENYLIST="$tmp/locked" "$heal" scan "$tmp/clean.md"
  scan_refused 'an unreadable denylist'
fi

in_dir "$tmp/plain" env GUARD_DENYLIST="$tmp/deny" "$heal" scan "$tmp/clean.md"
expect 3 'scan with LOADOUT_REPO unset'

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" GUARD_DENYLIST="$tmp/deny" "$heal" scan
expect 2 'scan with no file'

in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" GUARD_DENYLIST="$tmp/deny" "$heal" scan "$tmp/clean.md"
expect 0 'scan with GUARD_DENYLIST'
has "$out" "scan require=1 args=text $tmp/clean.md" 'guard/scan did not get GUARD_REQUIRE_DENYLIST=1'

mkdir -p "$HOME/.config/loadout-guard"
cp "$tmp/deny" "$HOME/.config/loadout-guard/denylist"
in_dir "$tmp/plain" env LOADOUT_REPO="$tmp/kit" "$heal" scan "$tmp/clean.md"
expect 0 'scan with a denylist at the default path'
has "$out" 'scan require=1' "the default path wasn't honored"
rm "$HOME/.config/loadout-guard/denylist"

# Through the real guard/scan: a finding is exit 1, and a clean file is exit 0.
in_dir "$tmp/plain" env LOADOUT_REPO="$root" GUARD_DENYLIST="$tmp/deny" GUARD_EXCEPTIONS="$tmp/exceptions" "$heal" scan "$tmp/dirty.md"
expect 1 'the real guard on a match'
lacks "$out" 'zorblax' 'the real guard printed the match'
in_dir "$tmp/plain" env LOADOUT_REPO="$root" GUARD_DENYLIST="$tmp/deny" GUARD_EXCEPTIONS="$tmp/exceptions" "$heal" scan "$tmp/clean.md"
expect 0 'the real guard on a clean file'

((failed == 0)) && echo "heal: all passed"
exit "$failed"
