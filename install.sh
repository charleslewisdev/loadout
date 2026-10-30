#!/usr/bin/env bash
# Merge a machine profile into ~/.claude/settings.json and register the marketplace.
#
#   ./install.sh <profile> [--no-register] [--ref <branch>]
#
# Backs up settings.json to ~/.claude/backups/, then deep-merges
# profiles/<profile>.json over it with `jq -s '.[0] * .[1]'`: profile keys win and
# every other key is kept, except the marketplace source, which is replaced whole.
# "$HOME" in a profile string becomes this machine's home.
# The marketplace source comes from this checkout's origin remote, so a fork
# installs from the fork: a GitHub origin becomes a github source, anything else
# a git source. The profile sets only its ref.
# It also sets LOADOUT_REPO to this checkout, where the harness skills open PRs.
# A second run leaves settings.json byte-identical. Unless --no-register, it adds
# the loadout marketplace (again, when its source or ref changed) and installs or
# updates every @loadout plugin the profile enables.
# --ref tracks another branch than the profile's, to run an unmerged branch.
set -euo pipefail

((BASH_VERSINFO[0] >= 5)) || { echo "install: loadout needs bash 5 or newer; this is $BASH_VERSION (on macOS: brew install bash)" >&2; exit 2; }
for tool in git jq perl; do
  command -v "$tool" >/dev/null || { echo "install: $tool is required" >&2; exit 2; }
done

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

origin=$(git -C "$here" remote get-url origin 2>/dev/null) ||
  { echo "install: this checkout has no origin remote to install from" >&2; exit 2; }
gh_repo=$(sed -nE 's#^(https://([^/@]*@)?github\.com/|git@github\.com:|ssh://git@github\.com/)([^/]+/[^/]+)$#\3#p' <<<"$origin")
gh_repo=${gh_repo%.git}
wanted=$(jq --arg home "$HOME" --arg ref "$ref" --arg repo "$here" --arg origin "$origin" --arg gh "$gh_repo" '
  walk(if type == "string" then gsub("\\$HOME"; $home) else . end)
  | .extraKnownMarketplaces.loadout.source = (
      (if $gh != "" then {source: "github", repo: $gh} else {source: "git", url: $origin} end)
      + {ref: (.extraKnownMarketplaces.loadout.source.ref // "main")})
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
command -v claude >/dev/null || { echo "install: settings are merged, but the claude CLI is required to register the plugins" >&2; exit 2; }
kind=$(jq -r '.extraKnownMarketplaces.loadout.source.source' <<<"$wanted")
url=$(jq -r '.extraKnownMarketplaces.loadout.source | .url // .repo' <<<"$wanted")
want_ref=$(jq -r '.extraKnownMarketplaces.loadout.source.ref // empty' <<<"$wanted")
# Re-add when the registered source differs in kind, location or ref: adding under
# the same name replaces the old registration. This must come after the merge above:
# the CLI refuses a source that differs from the one settings declare for the name.
# The add also rewrites that settings entry, so extra keys beside its source (such
# as autoUpdate) do not survive a re-add.
if ! claude plugin marketplace list --json |
  jq -e --arg kind "$kind" --arg url "$url" --arg ref "$want_ref" '
    any(.[]; .name == "loadout" and .source == $kind and ((.url // .repo) == $url) and ((.ref // "") == $ref))' >/dev/null; then
  claude plugin marketplace add "$url${want_ref:+#$want_ref}"
fi
# A profile can enable a plugin added since this marketplace clone last updated.
claude plugin marketplace update loadout
installed=$(claude plugin list --json)
for id in $(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true and (.key | endswith("@loadout"))) | .key' <<<"$wanted"); do
  if jq -e --arg id "$id" 'any(.[]; .id == $id)' >/dev/null <<<"$installed"; then
    claude plugin update "$id"
  else
    claude plugin install "$id"
  fi
done
