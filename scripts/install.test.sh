#!/usr/bin/env bash
# Tests install.sh's profile layering on a synthetic home, without registering
# anything. Needs a checkout with an origin remote, which CI has.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "${tmp:?}"' EXIT
failed=0
home=$tmp/home

fail() { echo "FAIL: $1"; failed=1; }
install() { HOME=$home "$root/install.sh" "$@" --no-register >"$tmp/out" 2>&1; }
settings() { jq -c "$1" "$home/.claude/settings.json"; }

mkdir -p "$home/.claude"
cat >"$tmp/machine.json" <<'JSON'
{
  "model": "from-machine",
  "outputStyle": "machine-wins",
  "permissions": {"allow": ["Bash(machine:*)", "Bash(both:*)"]},
  "env": {"NOTE_PATH": "$HOME/notes"}
}
JSON
cat >"$home/.claude/settings.json" <<'JSON'
{"kept": 1, "permissions": {"allow": ["Bash(local:*)", "Bash(both:*)"]}}
JSON

install example --machine "$tmp/machine.json" || fail "install with a machine profile exited nonzero: $(cat "$tmp/out")"
[[ $(settings .kept) == 1 ]] || fail "an existing key was lost"
[[ $(settings .model) == '"from-machine"' ]] || fail "the machine profile's key is missing"
[[ $(settings .statusLine.type) == '"command"' ]] || fail "the public profile's key is missing"
[[ $(settings .env.NOTE_PATH) == "\"$home/notes\"" ]] || fail "\$HOME in a machine profile wasn't expanded"
[[ $(settings .permissions.allow) == '["Bash(local:*)","Bash(both:*)","Read(~/.config/loadout/notes/**)","Bash(machine:*)"]' ]] ||
  fail "arrays weren't unioned in order: $(settings .permissions.allow)"

before=$(cat "$home/.claude/settings.json")
install example --machine "$tmp/machine.json" || fail "the second install exited nonzero"
[[ $before == "$(cat "$home/.claude/settings.json")" ]] || fail "a second install changed settings.json"

# The machine layer wins over the public one.
cat >"$tmp/base-over.json" <<'JSON'
{"outputStyle": "machine-wins"}
JSON
install workstation --machine "$tmp/base-over.json" || fail "install over workstation exited nonzero"
[[ $(settings .outputStyle) == '"machine-wins"' ]] || fail "the public profile beat the machine profile"

# With no machine profile, nothing else is needed, so a fork works alone.
home=$tmp/fresh
mkdir -p "$home/.claude"
install example || fail "install with no machine profile exited nonzero: $(cat "$tmp/out")"
[[ $(settings '.enabledPlugins | keys') == '["loadout@loadout"]' ]] || fail "the example profile enabled more than loadout"
[[ $(settings .permissions.allow) == '["Read(~/.config/loadout/notes/**)"]' ]] || fail "the example profile doesn't allow reading notes"

# Empty settings get the whole profile, and settings that aren't an object stay put.
for empty in '' $'  \n'; do
  printf '%s' "$empty" >"$home/.claude/settings.json"
  install example || fail "install over empty settings exited nonzero: $(cat "$tmp/out")"
  [[ $(settings '.enabledPlugins | keys') == '["loadout@loadout"]' ]] || fail "install over empty settings lost the profile"
done
echo '[]' >"$home/.claude/settings.json"
if install example; then
  fail "settings that aren't an object didn't fail"
fi
[[ $(settings .) == '[]' ]] || fail "settings that aren't an object were changed"

rm -f "${home:?}/.claude/settings.json"
echo '{bad' >"$tmp/malformed.json"
if install example --machine "$tmp/malformed.json"; then
  fail "a malformed machine profile didn't fail"
fi

if install example --machine "$tmp/absent.json"; then
  fail "a missing machine profile didn't fail"
fi
grep -q 'no machine profile' "$tmp/out" || fail "a missing machine profile gave the wrong message: $(cat "$tmp/out")"

((failed == 0)) && echo "install tests: passed"
exit "$failed"
