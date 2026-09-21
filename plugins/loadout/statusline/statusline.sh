#!/usr/bin/env bash
# loadout statusline. Reads the session JSON on stdin and prints one line.
#
# Segments, highest priority first (ADR-13): model and effort; context meter;
# branch or worktree; budget health; 5-hour limit; cold prompt cache; pull
# request; 7-day limit; output style; line churn. When the line is wider than the
# terminal, segments drop from the end of that list. Every field is optional, and
# junk input prints an empty line. NO_COLOR turns off colour and hyperlinks.
#
# CLAUDE_STATUSLINE_NOW    pinned clock for tests
# CLAUDE_STATUSLINE_WIDTH  terminal width; else $COLUMNS, else the tty, else no limit
# LOADOUT_CACHE            where scripts/budget caches its result (~/.cache/loadout)
set -uo pipefail
shopt -s extglob

IN=$(cat)
NOW=${CLAUDE_STATUSLINE_NOW:-$(date +%s)}
CACHE=${LOADOUT_CACHE:-$HOME/.cache/loadout}
WIDTH=${CLAUDE_STATUSLINE_WIDTH:-${COLUMNS:-}}
[ -z "$WIDTH" ] && WIDTH=$( { stty size </dev/tty; } 2>/dev/null | awk '{ print $2 }')
# Show the style name even when it is peer, until the register evals pass.
SHOW_PEER=1

# ---- palette ---------------------------------------------------------------
if [ -n "${NO_COLOR:-}" ]; then
  C_RST= C_SEP= C_DIM= C_MODEL= C_EFFORT= C_BRANCH= C_DIRTY= C_LBL= C_ADD= C_DEL=
  C_GRN= C_YEL= C_RED= C_FAST= C_COLD=
else
  C_RST=$'\033[0m'
  C_SEP=$'\033[38;5;238m'     # separators recede
  C_DIM=$'\033[38;5;245m'     # secondary text
  C_MODEL=$'\033[1;38;5;252m' # model name, the brightest thing on the line
  C_EFFORT=$'\033[38;5;80m'
  C_BRANCH=$'\033[38;5;176m'
  C_DIRTY=$'\033[38;5;203m'
  C_LBL=$'\033[38;5;243m'
  C_ADD=$'\033[38;5;114m'
  C_DEL=$'\033[38;5;203m'
  C_GRN=$'\033[38;5;114m'
  C_YEL=$'\033[38;5;179m'
  C_RED=$'\033[38;5;203m'
  C_FAST=$'\033[38;5;221m'
  C_COLD=$'\033[38;5;111m'
fi

# ---- payload ---------------------------------------------------------------
# One jq call, emitted as shell-quoted assignments. Defaults come first so a
# missing jq or a junk payload leaves every field empty.
MODEL= CTXPCT= CTXSIZE= EFFORT= FAST= THINK= STYLE= CWD= ADD= DEL=
R5= R5AT= R7= R7AT= WARM= PRNUM= PRURL= PRSTATE= WTNAME=

eval "$(printf '%s' "$IN" | jq -r '
  def q: (. // "") | tostring | @sh;
  def b: tostring | @sh;
  "MODEL=\(.model.display_name | q)",
  "CTXPCT=\(.context_window.used_percentage | q)",
  "CTXSIZE=\(.context_window.context_window_size | q)",
  "EFFORT=\(.effort.level | q)",
  "FAST=\(.fast_mode | b)",
  "THINK=\(.thinking.enabled | b)",
  "STYLE=\(.output_style.name | q)",
  "CWD=\((.workspace.current_dir // .cwd) | q)",
  "ADD=\(.cost.total_lines_added | q)",
  "DEL=\(.cost.total_lines_removed | q)",
  "R5=\(.rate_limits.five_hour.used_percentage | q)",
  "R5AT=\(.rate_limits.five_hour.resets_at | q)",
  "R7=\(.rate_limits.seven_day.used_percentage | q)",
  "R7AT=\(.rate_limits.seven_day.resets_at | q)",
  "WARM=\(.prompt_cache.warm | if . == null then "" else tostring end | @sh)",
  "PRNUM=\(.pr.number | q)",
  "PRURL=\(.pr.url | q)",
  "PRSTATE=\(.pr.review_state | q)",
  "WTNAME=\(.worktree.name | q)"
' 2>/dev/null)"

# ---- helpers ---------------------------------------------------------------

# Truncate to an integer; anything non-numeric fails.
int() {
  local v=${1%%.*}
  case "$v" in '' | *[!0-9]*) return 1 ;; *) printf '%s' "$v" ;; esac
}

# bar <pct> <width>: solid fill on a shaded track.
bar() {
  local pct=$1 width=$2 filled i out=''
  filled=$(((pct * width + 50) / 100))
  [ "$filled" -gt "$width" ] && filled=$width
  # any usage lights one cell, and the last cell means full, so 94% never reads as 100%
  [ "$filled" -eq 0 ] && [ "$pct" -gt 0 ] && filled=1
  [ "$filled" -ge "$width" ] && [ "$pct" -lt 100 ] && filled=$((width - 1))
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then out+='█'; else out+='░'; fi
  done
  printf '%s' "$out"
}

# Green below 60%, amber to 85%, red above.
hue() {
  if [ "$1" -ge 85 ]; then printf '%s' "$C_RED"
  elif [ "$1" -ge 60 ]; then printf '%s' "$C_YEL"
  else printf '%s' "$C_GRN"; fi
}

# meter <label> <pct> <width> [countdown]
meter() {
  local label=$1 pct=$2 width=$3 until=${4:-} col
  col=$(hue "$pct")
  printf '%s' "${C_LBL}${label}${C_RST} ${col}$(bar "$pct" "$width")${C_RST} ${col}$(printf '%3d' "$pct")%${C_RST}"
  [ -n "$until" ] && printf '%s' " ${C_DIM}↺${until}${C_RST}"
}

# Unix epoch to compact time remaining.
countdown() {
  local delta d h m
  delta=$(($1 - NOW))
  [ "$delta" -le 0 ] && { printf 'now'; return; }
  d=$((delta / 86400)) h=$(((delta % 86400) / 3600)) m=$(((delta % 3600) / 60))
  if [ "$d" -gt 0 ]; then printf '%dd' "$d"; [ "$h" -gt 0 ] && printf '%dh' "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh' "$h"; [ "$m" -gt 0 ] && printf '%dm' "$m"
  else printf '%dm' "$m"; fi
  return 0
}

# 1000000 -> 1M, 200000 -> 200k
human_ctx() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then printf '%dM' "$((n / 1000000))"
  elif [ "$n" -ge 1000 ]; then printf '%dk' "$((n / 1000))"
  else printf '%d' "$n"; fi
}

# OSC 8 hyperlink, left out under NO_COLOR.
link() {
  if [ -n "${NO_COLOR:-}" ] || [ -z "$1" ]; then printf '%s' "$2"
  else printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$1" "$2"; fi
}

# Visible width: escape sequences removed, characters counted in UTF-8, in bash
# alone because this runs on every render.
visible() {
  local s=$1
  { local LC_ALL=C.UTF-8; } 2>/dev/null
  s=${s//$'\033'\[*([0-9;])m/}
  s=${s//$'\033]8;;'*([!$'\033'])$'\033\\'/}
  printf '%s' "${#s}"
}

# ---- segments, highest priority first ---------------------------------------
segs=()

# 1. model and effort; badges only when not default
s=''
if [ -n "$MODEL" ]; then
  s="${C_MODEL}${MODEL%% (*}${C_RST}"
  if size=$(int "$CTXSIZE"); then s+=" ${C_DIM}$(human_ctx "$size")${C_RST}"; fi
fi
[ -n "$EFFORT" ] && s+="${s:+ }${C_EFFORT}${EFFORT}${C_RST}"
[ "$FAST" = 'true' ] && s+="${s:+ }${C_FAST}⚡${C_RST}"
[ "$THINK" = 'false' ] && s+="${s:+ }${C_DIM}think:off${C_RST}"
[ -n "$s" ] && segs+=("$s")

# 2. context meter
if v=$(int "$CTXPCT"); then segs+=("$(meter ctx "$v" 8)"); fi

# 3. worktree name, else branch; the payload carries no branch, so ask git
if [ -n "$CWD" ] && [ -d "$CWD" ] && command -v git >/dev/null 2>&1; then
  BR=$WTNAME
  [ -z "$BR" ] && { BR=$(git -C "$CWD" symbolic-ref --quiet --short HEAD 2>/dev/null) \
    || BR=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null) || BR=; }
  if [ -n "$BR" ]; then
    s="${C_BRANCH}⎇ ${BR}${C_RST}"
    # --quiet diff beats `status --porcelain` on large trees
    if git -C "$CWD" rev-parse --verify --quiet HEAD >/dev/null 2>&1 &&
      ! git -C "$CWD" diff --quiet --ignore-submodules HEAD 2>/dev/null; then
      s+="${C_DIRTY}*${C_RST}"
    fi
    segs+=("$s")
  fi
fi

# 4. budget health: only when the last scripts/budget run failed, is older than
# 30 days, or never ran
if [ -r "$CACHE/budget" ]; then
  result=$(sed -n 's/^result=//p' "$CACHE/budget")
  epoch=$(sed -n 's/^epoch=//p' "$CACHE/budget")
  if [ "$result" != pass ]; then segs+=("${C_RED}budget over${C_RST}")
  elif ! e=$(int "$epoch") || [ $((NOW - e)) -gt 2592000 ]; then segs+=("${C_YEL}budget stale${C_RST}"); fi
else
  segs+=("${C_YEL}budget unmeasured${C_RST}")
fi

# 5. five-hour limit
if v=$(int "$R5"); then
  until=; if t=$(int "$R5AT"); then until=$(countdown "$t"); fi
  segs+=("$(meter 5h "$v" 6 "$until")")
fi

# 6. cold prompt cache: the next request pays to rebuild it
[ "$WARM" = 'false' ] && segs+=("${C_COLD}cache cold${C_RST}")

# 7. pull request, linked, with its review state
if n=$(int "$PRNUM"); then
  case "$PRSTATE" in
    approved) col=$C_GRN ;;
    changes_requested) col=$C_RED ;;
    *) col=$C_DIM ;;
  esac
  s="$(link "$PRURL" "PR #$n")"
  [ -n "$PRSTATE" ] && s+=" ${col}${PRSTATE//_/ }${C_RST}"
  segs+=("$s")
fi

# 8. seven-day limit
if v=$(int "$R7"); then
  until=; if t=$(int "$R7AT"); then until=$(countdown "$t"); fi
  segs+=("$(meter 7d "$v" 6 "$until")")
fi

# 9. output style, without the plugin prefix
if [ -n "$STYLE" ] && [ "$STYLE" != default ]; then
  if [ "$SHOW_PEER" = 1 ] || [ "$STYLE" != loadout:peer ]; then segs+=("${C_DIM}${STYLE##*:}${C_RST}"); fi
fi

# 10. line churn, hidden when nothing changed
a=$(int "${ADD:-0}") || a=0
d=$(int "${DEL:-0}") || d=0
if [ "$a" -gt 0 ] || [ "$d" -gt 0 ]; then
  segs+=("${C_ADD}+${a}${C_RST}${C_SEP}/${C_RST}${C_DEL}-${d}${C_RST}")
fi

# ---- fit and render ----------------------------------------------------------
n=${#segs[@]}
if w=$(int "$WIDTH") && [ "$w" -gt 0 ] && [ "$n" -gt 1 ]; then
  total=0
  widths=()
  for s in "${segs[@]}"; do
    v=$(visible "$s")
    widths+=("$v")
    total=$((total + v))
  done
  total=$((total + 3 * (n - 1)))
  while [ "$n" -gt 1 ] && [ "$total" -gt "$w" ]; do
    n=$((n - 1))
    total=$((total - widths[n] - 3))
  done
fi

out=''
for ((i = 0; i < n; i++)); do
  out+="${out:+${C_SEP} │ ${C_RST}}${segs[i]}"
done
printf '%s\n' "$out"
