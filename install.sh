#!/usr/bin/env bash
# Merge a machine profile into ~/.claude/settings.json and register the marketplace.
#
#   ./install.sh <profile> [--no-register]
#
# Backs up settings.json to ~/.claude/backups/, then deep-merges
# profiles/<profile>.json over it with `jq -s '.[0] * .[1]'`: profile keys win and
# every other key is kept. "$HOME" in a profile string becomes this machine's home.
# A second run leaves settings.json byte-identical. Unless --no-register, it adds
# the loadout marketplace and installs the plugin when either is missing.
#
# The marketplace source names the author's GitHub account, so run this only on
# machines where that tie is acceptable.
set -euo pipefail

usage() { sed -n '2,13s/^# \{0,1\}//p' "$0" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
profile=''
register=1
for arg in "$@"; do
  case $arg in
    --no-register) register=0 ;;
    -*) usage ;;
    *) profile=$arg ;;
  esac
done
[[ -n $profile ]] || usage
src="$here/profiles/$profile.json"
[[ -r $src ]] || { echo "install: no profile at profiles/$profile.json" >&2; exit 2; }

settings="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude/backups"
[[ -f $settings ]] || echo '{}' >"$settings"
cp -p "$settings" "$(mktemp "$HOME/.claude/backups/settings.json.$(date +%Y%m%dT%H%M%S).XXXX")"

merged=$(jq --arg home "$HOME" 'walk(if type == "string" then gsub("\\$HOME"; $home) else . end)' "$src" |
  jq -s '.[0] * .[1]' "$settings" -)
if [[ $merged != "$(cat "$settings")" ]]; then
  printf '%s\n' "$merged" >"$settings"
  echo "install: merged profiles/$profile.json into ~/.claude/settings.json"
else
  echo "install: ~/.claude/settings.json already matches profiles/$profile.json"
fi

((register)) || exit 0
if ! claude plugin marketplace list --json | jq -e 'any(.[]; .name == "loadout")' >/dev/null; then
  source=$(jq -r '.extraKnownMarketplaces.loadout.source | .url // .repo' "$src")
  claude plugin marketplace add "$source"
fi
if ! claude plugin list --json | jq -e 'any(.[]; .id == "loadout@loadout")' >/dev/null; then
  claude plugin install loadout@loadout
fi
