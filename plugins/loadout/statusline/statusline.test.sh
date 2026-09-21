#!/usr/bin/env bash
# Preview and test the statusline against fixture payloads.
#   statusline.test.sh          preview every scenario, then assert
#   statusline.test.sh preview  preview only
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SL="$HERE/statusline.sh"
# A fixed epoch shared by the fixtures and the statusline, so countdowns are exact.
NOW=1787430000
export CLAUDE_STATUSLINE_NOW=$NOW
export CLAUDE_STATUSLINE_WIDTH=0
export LC_ALL=C.UTF-8
REPO=$(cd "$HERE/../../.." && pwd)
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
export LOADOUT_CACHE=$CACHE
budget() { printf 'result=%s\nepoch=%s\n' "$1" "$2" >"$CACHE/budget"; }
budget pass "$NOW"

# fixture <name>: the payload JSON for a scenario
fixture() {
  case "$1" in
    typical) cat <<JSON
{"model":{"display_name":"Opus 5 (1M context)"},"effort":{"level":"xhigh"},
 "fast_mode":false,"thinking":{"enabled":true},"output_style":{"name":"default"},
 "workspace":{"current_dir":"$REPO"},
 "context_window":{"used_percentage":32,"context_window_size":1000000},
 "cost":{"total_cost_usd":0.75,"total_lines_added":40,"total_lines_removed":5},
 "rate_limits":{"five_hour":{"used_percentage":9,"resets_at":$((NOW + 6120))},
                "seven_day":{"used_percentage":15,"resets_at":$((NOW + 185400))}}}
JSON
      ;;
    fresh) cat <<JSON
{"model":{"display_name":"Sonnet 5"},"effort":{"level":"medium"},
 "fast_mode":false,"thinking":{"enabled":true},"output_style":{"name":"default"},
 "workspace":{"current_dir":"$REPO"},
 "context_window":{"used_percentage":0,"context_window_size":200000},
 "cost":{"total_cost_usd":0,"total_lines_added":0,"total_lines_removed":0},
 "rate_limits":{"five_hour":{"used_percentage":0,"resets_at":$((NOW + 18000))},
                "seven_day":{"used_percentage":2,"resets_at":$((NOW + 600000))}}}
JSON
      ;;
    danger) cat <<JSON
{"model":{"display_name":"Opus 5 (1M context)"},"effort":{"level":"xhigh"},
 "workspace":{"current_dir":"$REPO"},
 "context_window":{"used_percentage":94,"context_window_size":1000000},
 "cost":{"total_cost_usd":103.925,"total_lines_added":4310,"total_lines_removed":1902},
 "rate_limits":{"five_hour":{"used_percentage":97,"resets_at":$((NOW + 480))},
                "seven_day":{"used_percentage":88,"resets_at":$((NOW + 7200))}}}
JSON
      ;;
    full) cat <<JSON
{"model":{"display_name":"Opus 5 (1M context)"},"effort":{"level":"xhigh"},
 "workspace":{"current_dir":"$REPO"},
 "context_window":{"used_percentage":100,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":100,"resets_at":$((NOW + 120))},
                "seven_day":{"used_percentage":100,"resets_at":$((NOW - 60))}}}
JSON
      ;;
    badges) cat <<JSON
{"model":{"display_name":"Opus 5 (1M context)"},"effort":{"level":"low"},
 "fast_mode":true,"thinking":{"enabled":false},"output_style":{"name":"Explanatory"},
 "workspace":{"current_dir":"$REPO"},
 "context_window":{"used_percentage":18,"context_window_size":1000000}}
JSON
      ;;
    session) cat <<JSON
{"model":{"display_name":"Opus 5 (1M context)"},"effort":{"level":"high"},
 "output_style":{"name":"loadout:peer"},
 "workspace":{"current_dir":"$REPO"},
 "worktree":{"name":"fix-parser","path":"$REPO","branch":"fix-parser"},
 "context_window":{"used_percentage":41,"context_window_size":1000000},
 "prompt_cache":{"warm":false,"expires_at":null},
 "pr":{"number":12,"url":"https://github.com/example/repo/pull/12","review_state":"changes_requested"},
 "cost":{"total_lines_added":7,"total_lines_removed":2},
 "rate_limits":{"five_hour":{"used_percentage":30,"resets_at":$((NOW + 3600))},
                "seven_day":{"used_percentage":20,"resets_at":$((NOW + 86400))}}}
JSON
      ;;
    warm) printf '%s' '{"model":{"display_name":"Opus 5"},"prompt_cache":{"warm":true},"pr":{"number":3,"review_state":"approved"}}' ;;
    nogit) printf '%s' '{"model":{"display_name":"Haiku 4.5"},"effort":{"level":"low"},"workspace":{"current_dir":"/nonexistent"},"context_window":{"used_percentage":11,"context_window_size":200000}}' ;;
    sparse) printf '%s' '{"model":{"display_name":"Opus 5"}}' ;;
    empty) printf '%s' '{}' ;;
    garbage) printf '%s' 'not json at all' ;;
    blank) printf '%s' '' ;;
  esac
}

SCENARIOS=(typical fresh danger full badges session warm nogit sparse empty garbage blank)

echo
echo "  ── statusline preview ─────────────────────────────────────────────"
echo
for s in "${SCENARIOS[@]}"; do
  printf '  \033[38;5;240m%-8s\033[0m %s\n' "$s" "$(fixture "$s" | bash "$SL")"
done
echo
printf '  \033[38;5;240m%-8s\033[0m %s\n' "NO_COLOR" "$(fixture session | NO_COLOR=1 bash "$SL")"
printf '  \033[38;5;240m%-8s\033[0m %s\n' "80 cols" "$(fixture session | CLAUDE_STATUSLINE_WIDTH=80 bash "$SL")"
echo

[ "${1:-}" = "preview" ] && exit 0

# ---- assertions ------------------------------------------------------------
fail=0
check() { # check <description> <status>
  if [ "$2" -eq 0 ]; then printf '  \033[38;5;114m✓\033[0m %s\n' "$1"
  else printf '  \033[38;5;203m✗\033[0m %s\n' "$1"; fail=1; fi
}
render() { fixture "$1" | NO_COLOR=1 bash "$SL"; }

echo "  ── assertions ─────────────────────────────────────────────────────"
echo

for s in "${SCENARIOS[@]}"; do
  fixture "$s" | bash "$SL" >/dev/null 2>&1
  check "exits 0 on '$s'" $?
done

out=$(render typical)
grep -q 'Opus 5 1M' <<<"$out"; check "strips the (1M context) parenthetical" $?
grep -q 'xhigh' <<<"$out"; check "shows the effort level" $?
grep -q '⎇ ' <<<"$out"; check "shows the git branch (the payload has none)" $?
grep -q 'ctx' <<<"$out"; check "shows the context meter" $?
grep -q '5h' <<<"$out"; check "shows the 5-hour limit" $?
grep -q '7d' <<<"$out"; check "shows the 7-day limit" $?
grep -q '↺1h42m' <<<"$out"; check "renders the 5h reset countdown" $?
grep -q '↺2d3h' <<<"$out"; check "renders the 7d reset countdown" $?
grep -q '\$' <<<"$out"; check "drops the cost segment" $((1 - $?))
grep -q '+40/-5' <<<"$out"; check "shows churn when non-zero" $?
grep -q '█' <<<"$out"; check "draws a filled bar" $?
grep -q '░' <<<"$out"; check "draws the empty track" $?
grep -qE 'budget|cache cold|PR #' <<<"$out"; check "hides health, cache and PR markers when there is nothing to say" $((1 - $?))
grep -qE 'think:off|Explanatory|⚡' <<<"$out"; check "hides every badge when default" $((1 - $?))

out=$(render fresh)
grep -q '+0' <<<"$out"; check "hides churn when zero" $((1 - $?))
grep -q '200k' <<<"$out"; check "renders a 200k context window" $?
grep -q 'ctx ░░░░░░░░   0%' <<<"$out"; check "0%% draws an empty bar" $?
grep -q '↺5h0m' <<<"$out"; check "drops a zero minor unit (5h0m -> 5h)" $((1 - $?))
grep -q '↺5h' <<<"$out"; check "still renders the hour countdown" $?

out=$(render badges)
grep -q '⚡' <<<"$out"; check "shows the fast-mode badge" $?
grep -q 'think:off' <<<"$out"; check "flags disabled thinking" $?
grep -q 'Explanatory' <<<"$out"; check "shows a non-default output style" $?

out=$(render danger)
grep -q '↺8m' <<<"$out"; check "renders a minutes-only countdown" $?
grep -q '  94%' <<<"$out"; check "right-pads percentages for stable width" $?
grep -q 'ctx ███████░  94%' <<<"$out"; check "94%% leaves the last cell unlit" $?

out=$(render full)
grep -q 'ctx ████████ 100%' <<<"$out"; check "100%% fills every cell" $?
grep -q '↺now' <<<"$out"; check "an elapsed reset reads 'now'" $?

out=$(render session)
grep -q '⎇ fix-parser' <<<"$out"; check "shows the worktree name instead of the branch" $?
grep -q 'cache cold' <<<"$out"; check "marks a cold prompt cache" $?
grep -q 'PR #12 changes requested' <<<"$out"; check "shows the PR number and review state" $?
grep -q '│ peer │' <<<"$out"; check "shows the peer style without its plugin prefix" $?
fixture session | bash "$SL" | grep -q $'\033]8;;https://github.com/example/repo/pull/12\033\\\\PR #12'
check "links the PR with OSC 8" $?
fixture session | NO_COLOR=1 bash "$SL" | grep -q $'\033]8'; check "NO_COLOR drops the hyperlink" $((1 - $?))

out=$(render warm)
grep -q 'cache cold' <<<"$out"; check "no cache marker while the cache is warm" $((1 - $?))
grep -q 'PR #3 approved' <<<"$out"; check "shows an approved PR without a link when the URL is missing" $?

budget fail "$NOW"; out=$(render sparse)
grep -q 'budget over' <<<"$out"; check "flags a failed budget run" $?
budget pass $((NOW - 31 * 86400)); out=$(render sparse)
grep -q 'budget stale' <<<"$out"; check "flags a budget run older than 30 days" $?
rm -f "$CACHE/budget"; out=$(render sparse)
grep -q 'budget unmeasured' <<<"$out"; check "flags a machine with no budget run" $?
budget pass "$NOW"

out=$(fixture session | NO_COLOR=1 CLAUDE_STATUSLINE_WIDTH=80 bash "$SL")
[ "${#out}" -le 80 ]; check "fits 80 columns" $?
grep -q '+7/-2' <<<"$out"; check "drops churn first when narrow" $((1 - $?))
grep -q 'Opus 5' <<<"$out"; check "keeps the model when narrow" $?
out=$(fixture session | NO_COLOR=1 CLAUDE_STATUSLINE_WIDTH=10 bash "$SL")
[ "$out" = 'Opus 5 1M high' ]; check "never drops the first segment" $?
colored=$(fixture session | CLAUDE_STATUSLINE_WIDTH=80 bash "$SL" | sed $'s/\033\\[[0-9;]*m//g; s/\033]8;;[^\033]*\033\\\\//g')
plain=$(fixture session | NO_COLOR=1 CLAUDE_STATUSLINE_WIDTH=80 bash "$SL")
[ "$colored" = "$plain" ]; check "colour and links do not change which segments fit" $?

# A render must never refresh .git/index: that takes index.lock and can collide
# with a commit the agent is making.
T=$(mktemp -d)
git -C "$T" init -q && printf 'a\n' >"$T/f" && git -C "$T" add f &&
  git -C "$T" -c user.name=t -c user.email=test@localhost commit -q -m t && sleep 1 && touch "$T/f"
before=$(stat -c %Y "$T/.git/index" 2>/dev/null || stat -f %m "$T/.git/index")
printf '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"%s"}}' "$T" | NO_COLOR=1 bash "$SL" >/dev/null
after=$(stat -c %Y "$T/.git/index" 2>/dev/null || stat -f %m "$T/.git/index")
[ "$before" = "$after" ]; check "a render leaves .git/index untouched" $?
rm -rf "$T"

out=$(render nogit)
grep -q '⎇' <<<"$out"; check "omits the branch outside a repo" $((1 - $?))
grep -q '11%' <<<"$out"; check "still renders meters without git" $?
grep -q '7d' <<<"$out"; check "omits 7d when rate_limits is absent" $((1 - $?))

for s in "${SCENARIOS[@]}"; do
  render "$s" | grep -q '%%'; check "no doubled %% in '$s'" $((1 - $?))
done

out=$(render sparse); [ "$out" = 'Opus 5' ]; check "a sparse payload degrades to just the model" $?
out=$(render blank); [ -z "$out" ]; check "blank stdin renders an empty line" $?
out=$(render garbage); [ -z "$out" ]; check "malformed stdin renders an empty line" $?

fixture typical | bash "$SL" | grep -q $'\033\['; check "emits ANSI colour by default" $?
fixture typical | NO_COLOR=1 bash "$SL" | grep -q $'\033\['; check "NO_COLOR suppresses ANSI" $((1 - $?))

echo
if [ "$fail" -eq 0 ]; then printf '  \033[38;5;114mall checks passed\033[0m\n\n'
else printf '  \033[38;5;203mFAILURES\033[0m\n\n'; fi
exit "$fail"
