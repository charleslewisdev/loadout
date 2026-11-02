#!/usr/bin/env bash
# Tests map-scout's portfolio script with a stub gh on a synthetic home. No network,
# no Claude.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
portfolio=$root/plugins/loadout/skills/map-scout/portfolio
tmp=$(mktemp -d)
trap 'rm -rf "${tmp:?}"' EXIT
failed=0
fail() { echo "FAIL: $1"; failed=1; }
has() { grep -qF -- "$2" <<<"$1" || fail "${3:-missing}: $2"; }
lacks() { ! grep -qF -- "$2" <<<"$1" || fail "${3:-unexpected}: $2"; }

export HOME=$tmp/home
mkdir -p "$HOME/.config/loadout/notes" "$tmp/bin" "$tmp/bare"

# The stub answers like gh: it runs --jq over a canned response. Asked to fail, it
# prints the raw error body to stdout and exits 1, skipping --jq, as real gh does.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
[[ "$1 $2" == 'api graphql' ]] || exit 9
while (($#)); do
  [[ $1 == --jq ]] && filter=$2
  shift
done
if [[ -n ${STUB_ERROR:-} ]]; then
  echo "boom" >&2
  cat "$STUB_ERROR"
  exit 1
fi
[[ ${STUB_SILENT:-} != 1 ]] || { echo "boom" >&2; exit 1; }
jq -r "$filter" "$STUB_RESPONSE"
SH
chmod +x "$tmp/bin/gh"
jq -n '
  def repo($n; $p; $f; $a; $d; $c): {nameWithOwner: "me/\($n)", isPrivate: $p, isFork: $f, isArchived: $a,
    pushedAt: "2026-10-\(10 + ($n | ltrimstr("r") | tonumber))T00:00:00Z", description: $d,
    primaryLanguage: {name: "Go"},
    defaultBranchRef: {target: {history: {nodes: [{messageHeadline: $c}]}}}};
  {data: {viewer: {repositories: {totalCount: 13, nodes: (
    [repo("r0"; true; false; false; "first line\nforged | public"; "subject zero\nforged" + ("y" * 200))]
    + [repo("r1"; false; true; true; null; "subject one")]
    + [{nameWithOwner: "me/empty", isPrivate: false, isFork: false, isArchived: false,
        pushedAt: null, description: null, primaryLanguage: null, defaultBranchRef: null}]
    + [range(2; 12) | repo("r\(.)"; false; false; false; ("x" * 200); "subject \(.)")]
  )}}}}' >"$tmp/response.json"
export STUB_RESPONSE=$tmp/response.json

# gh missing needs a PATH that holds the tools the script uses, and no gh.
for tool in bash env cat tail; do ln -s "$(command -v "$tool")" "$tmp/bare/$tool"; done
run() { PATH=$tmp/bin:$PATH "$portfolio"; }

# No map: live data alone, with labels, and control characters can't forge a line.
out=$(run) || fail "exited nonzero with no map"
has "$out" "## Curated map: none"
has "$out" "## Live repos, newest push first (13 total, up to 100 shown)"
has "$out" "me/r0 | private | 2026-10-10 | Go | first line forged | public"
has "$out" "me/r1 | public | fork | archived | 2026-10-11 | Go"
[[ $(grep -c '^me/' <<<"$out") == 13 ]] || fail "every repo should get a line: $out"
# Seven commits: the newest 8 repos include one with no commits.
[[ $(grep -c 'recent:' <<<"$out") == 7 ]] || fail "only the newest 8 repos list commits: $out"
lacks "$out" "subject 7" "a repo past the newest 8 listed commits"
has "$out" "  recent: subject zero forged"
lacks "$out" "$(printf 'y%.0s' {1..70})" "a commit subject wasn't trimmed"
lacks "$out" "$(printf 'x%.0s' {1..101})" "a description wasn't trimmed"
has "$out" "me/empty | public" "a repo with no commits or language"

# The map comes first, verbatim.
printf '# Map\n\nme/r3 powers the widget.\n' >"$HOME/.config/loadout/notes/portfolio.md"
out=$(run) || fail "exited nonzero with a map"
has "$out" "## Curated map"
lacks "$out" "## Curated map: none"
has "$out" "me/r3 powers the widget."
[[ $(grep -n 'powers the widget' <<<"$out" | cut -d: -f1) -lt $(grep -n '^## Live' <<<"$out" | cut -d: -f1) ]] ||
  fail "the map should come before the live list"

# gh failing keeps the map, and exits 0 so planning goes on.
out=$(STUB_SILENT=1 run 2>&1) || fail "exited nonzero when gh failed"
has "$out" "me/r3 powers the widget."
has "$out" "## Live repos: unavailable, gh failed"
lacks "$out" "boom" "gh's stderr leaked"

# An API error's raw body never reaches the output: a bad token, then a partial answer.
printf '{\n  "message": "Bad credentials"\n}\n' >"$tmp/401.json"
out=$(STUB_ERROR=$tmp/401.json run) || fail "exited nonzero on a bad token"
has "$out" "## Live repos: unavailable, gh failed"
lacks "$out" "Bad credentials" "gh's error body was printed"
jq -c '. + {errors: [{type: "FORBIDDEN"}]}' "$STUB_RESPONSE" >"$tmp/partial.json"
out=$(STUB_ERROR=$tmp/partial.json run) || fail "exited nonzero on a partial answer"
has "$out" "## Live repos: unavailable, gh failed"
lacks "$out" "FORBIDDEN" "a partial answer's raw body was printed"
lacks "$out" "me/r0" "a partial answer's raw body was printed"

# No gh at all.
out=$(PATH=$tmp/bare "$portfolio") || fail "exited nonzero with no gh"
has "$out" "## Live repos: unavailable, gh isn't installed"
has "$out" "me/r3 powers the widget."

# The off switch reads nothing: no gh call, and no map.
printf 'mapped-secret\n' >"$HOME/.config/loadout/notes/portfolio.md"
touch "$HOME/.config/loadout/no-portfolio"
out=$(STUB_RESPONSE=/nonexistent PATH=$tmp/bin:$PATH "$portfolio") || fail "exited nonzero when off"
has "$out" "## Portfolio: off"
lacks "$out" "mapped-secret" "the off switch still read the map"
lacks "$out" "Live repos" "the off switch still ran the query"
rm "$HOME/.config/loadout/no-portfolio"

# No map and no gh still says so plainly.
rm "$HOME/.config/loadout/notes/portfolio.md"
out=$(PATH=$tmp/bare "$portfolio") || fail "exited nonzero with nothing to report"
has "$out" "## Curated map: none"

# The quiet rule is the last line on every path, including the early exits.
for mode in ok fail bare; do
  case $mode in
    ok) out=$(run) ;;
    fail) out=$(STUB_SILENT=1 run) ;;
    bare) out=$(PATH=$tmp/bare "$portfolio") ;;
  esac
  [[ ${out##*$'\n'} == "End of lookup."* ]] || fail "$mode: the quiet rule isn't the last line"
done

# The eval stub: fails like the sandbox with no answer, and a fixture's answer parses.
mkdir "$tmp/evalhome"
out=$(HOME=$tmp/evalhome PATH=$root/scripts/eval-bin:$PATH "$portfolio")
has "$out" "## Live repos: unavailable, gh failed"
(cd "$tmp/evalhome" && HOME=$tmp/evalhome bash "$root/plugins/loadout/evals/fixtures/portfolio-gh.sh")
out=$(HOME=$tmp/evalhome PATH=$root/scripts/eval-bin:$PATH "$portfolio")
has "$out" "sample-dev/hookrelay | private"

((failed == 0)) && echo "portfolio tests passed"
exit "$failed"
