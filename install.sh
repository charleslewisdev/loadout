#!/usr/bin/env bash
# Merge a machine profile into ~/.claude/settings.json and register the marketplace.
#
#   ./install.sh <profile> [--no-register] [--ref <branch>]
#
# Backs up settings.json to ~/.claude/backups/, then deep-merges
# profiles/<profile>.json over it with `jq -s '.[0] * .[1]'`: profile keys win and
# every other key is kept. "$HOME" in a profile string becomes this machine's home.
# A second run leaves settings.json byte-identical. Unless --no-register, it adds
# the loadout marketplace (again, when its ref changed) and installs the plugin.
# --ref tracks another branch than the profile's, to run an unmerged branch.
#
# The marketplace source names the author's GitHub account, so run this only on
# machines where that tie is acceptable.
set -euo pipefail

usage() { sed -n '2,14s/^# \{0,1\}//p' "$0" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
profile=''
register=1
ref=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-register) register=0; shift ;;
    --ref) [[ $# -ge 2 ]] || usage; ref=$2; shift 2 ;;
    -*) usage ;;
    *) profile=$1; shift ;;
  esac
done
[[ -n $profile ]] || usage
src="$here/profiles/$profile.json"
[[ -r $src ]] || { echo "install: no profile at profiles/$profile.json" >&2; exit 2; }

settings="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude/backups"
[[ -f $settings ]] || echo '{}' >"$settings"
cp -p "$settings" "$(mktemp "$HOME/.claude/backups/settings.json.$(date +%Y%m%dT%H%M%S).XXXX")"

wanted=$(jq --arg home "$HOME" --arg ref "$ref" '
  walk(if type == "string" then gsub("\\$HOME"; $home) else . end)
  | if $ref != "" then .extraKnownMarketplaces.loadout.source.ref = $ref else . end' "$src")
merged=$(jq -s '.[0] * .[1]' "$settings" - <<<"$wanted")
if [[ $merged != "$(cat "$settings")" ]]; then
  printf '%s\n' "$merged" >"$settings"
  echo "install: merged profiles/$profile.json into ~/.claude/settings.json"
else
  echo "install: ~/.claude/settings.json already matches profiles/$profile.json"
fi

((register)) || exit 0
url=$(jq -r '.extraKnownMarketplaces.loadout.source | .url // .repo' <<<"$wanted")
want_ref=$(jq -r '.extraKnownMarketplaces.loadout.source.ref // empty' <<<"$wanted")
if ! claude plugin marketplace list --json |
  jq -e --arg ref "$want_ref" 'any(.[]; .name == "loadout" and ((.ref // "") == $ref))' >/dev/null; then
  claude plugin marketplace add "$url${want_ref:+#$want_ref}"
fi
if ! claude plugin list --json | jq -e 'any(.[]; .id == "loadout@loadout")' >/dev/null; then
  claude plugin install loadout@loadout
fi
