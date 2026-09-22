#!/usr/bin/env bash
# Merge a machine profile into ~/.claude/settings.json and register the marketplace.
#
#   ./install.sh <profile> [--no-register] [--ref <branch>]
#
# Backs up settings.json to ~/.claude/backups/, then deep-merges
# profiles/<profile>.json over it with `jq -s '.[0] * .[1]'`: profile keys win and
# every other key is kept, except the marketplace source, which is replaced whole.
# "$HOME" in a profile string becomes this machine's home.
# It also sets LOADOUT_REPO to this checkout, where the harness skills open PRs.
# A second run leaves settings.json byte-identical. Unless --no-register, it adds
# the loadout marketplace (again, when its source or ref changed) and installs or
# updates the plugin.
# --ref tracks another branch than the profile's, to run an unmerged branch.
#
# The marketplace source names the author's GitHub account, so run this only on
# machines where that tie is acceptable.
set -euo pipefail

usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0" >&2; exit 2; }

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

wanted=$(jq --arg home "$HOME" --arg ref "$ref" --arg repo "$here" '
  walk(if type == "string" then gsub("\\$HOME"; $home) else . end)
  | if $ref != "" then .extraKnownMarketplaces.loadout.source.ref = $ref else . end
  | .env.LOADOUT_REPO = $repo' "$src")
# The marketplace source is replaced whole: merged key by key, a git source's url
# would survive next to a github source's repo.
merged=$(jq -s '.[1] as $p | (.[0] * $p) | .extraKnownMarketplaces.loadout.source = $p.extraKnownMarketplaces.loadout.source' "$settings" - <<<"$wanted")
if [[ $merged != "$(cat "$settings")" ]]; then
  printf '%s\n' "$merged" >"$settings"
  echo "install: merged profiles/$profile.json into ~/.claude/settings.json"
else
  echo "install: ~/.claude/settings.json already matches profiles/$profile.json"
fi

((register)) || exit 0
kind=$(jq -r '.extraKnownMarketplaces.loadout.source.source' <<<"$wanted")
url=$(jq -r '.extraKnownMarketplaces.loadout.source | .url // .repo' <<<"$wanted")
want_ref=$(jq -r '.extraKnownMarketplaces.loadout.source.ref // empty' <<<"$wanted")
# Re-add when the registered source differs in kind, location or ref: adding under
# the same name replaces the old registration.
if ! claude plugin marketplace list --json |
  jq -e --arg kind "$kind" --arg url "$url" --arg ref "$want_ref" '
    any(.[]; .name == "loadout" and .source == $kind and ((.url // .repo) == $url) and ((.ref // "") == $ref))' >/dev/null; then
  claude plugin marketplace add "$url${want_ref:+#$want_ref}"
fi
if claude plugin list --json | jq -e 'any(.[]; .id == "loadout@loadout")' >/dev/null; then
  claude plugin update loadout@loadout
else
  claude plugin install loadout@loadout
fi
