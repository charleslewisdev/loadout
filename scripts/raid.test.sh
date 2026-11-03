#!/usr/bin/env bash
# Tests repo-raid's raid helper on synthetic repositories, with a synthetic HOME and a
# stub gh, so no network, no Claude and no real denylist.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
raid=$root/plugins/loadout/skills/repo-raid/raid
tmp=$(mktemp -d)
trap 'chmod -R u+rwx "${tmp:?}" 2>/dev/null; rm -rf "${tmp:?}"' EXIT
failed=0
fail() { echo "FAIL: $1"; failed=1; }
has() { grep -qF -- "$2" <<<"$1" || fail "${3:-missing}: $2"; }
lacks() { ! grep -qF -- "$2" <<<"$1" || fail "${3:-unexpected}: $2"; }
expect() { ((rc == $1)) || fail "$2: exit $rc, wanted $1: $out"; }
run() { rc=0; out=$("$raid" "$@" 2>&1) || rc=$?; }
field() { sed -n "s/^$1=//p" <<<"$out"; }

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE LOADOUT_REPO GUARD_DENYLIST GUARD_REQUIRE_DENYLIST
export HOME=$tmp/home GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME/.claude" "$tmp/bin"
echo '# conventions' >"$HOME/.claude/CLAUDE.md"
echo 'outside the repo' >"$HOME/secret.txt"
raids=$HOME/.cache/loadout/raids

# A stub gh. Visibility comes from a file, clone copies the seed repository, and api
# prints an error body to stdout and exits 1 unless told otherwise, as the real one does.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
echo "gh $*" >>"$HOME/gh.log"
case "$1 ${2:-}" in
  'repo view') [[ -r $HOME/visibility ]] && cat "$HOME/visibility" || exit 1 ;;
  'repo clone') shift 3; dest=$1; shift; shift; exec git clone "$@" -- "$HOME/seed" "$dest" ;;
  'api '*)
    case $2 in
      repos/*/*/vulnerability-alerts) exit 0 ;;
      repos/*/*/commits/*) [[ -e $HOME/no-root ]] && { echo '{"message":"Not Found"}'; exit 1; }; echo "${2##*/}" ;;
      repos/*/*/community/profile) echo 87 ;;
      repos/*/*/branches/*/protection) echo '{"message":"Branch not protected"}'; exit 1 ;;
      repos/*/*) [[ $* == *default_branch* ]] && echo main || echo enabled ;;
    esac
    ;;
esac
SH
chmod +x "$tmp/bin/gh"
export PATH=$tmp/bin:$PATH

# ---- a repository trying what a hostile one tries ---------------------------------
r=$tmp/target
git init -q -b main "$r"
git -C "$r" config user.name t
git -C "$r" config user.email t@localhost
echo '# target' >"$r/README.md"
echo 'tracked' >"$r/changed.txt"
ln -s "$HOME/secret.txt" "$r/escape"
printf '* filter=pwn\n' >"$r/.gitattributes"
git -C "$r" add README.md changed.txt escape .gitattributes
git -C "$r" commit -q -m $'chore: start\e[31m'
printf '#!/bin/sh\ntouch "$HOME/hook-ran"\n' >"$tmp/hook"
chmod +x "$tmp/hook"
cp "$tmp/hook" "$r/.git/hooks/post-index-change"
git -C "$r" config filter.pwn.clean "sh -c 'touch $HOME/filter-ran; cat'"
# Your own git config may hold a template with hooks, and the clone must not take it.
mkdir -p "$tmp/template/hooks"
cp "$tmp/hook" "$tmp/template/hooks/post-checkout"
printf '[init]\n\ttemplateDir = %s\n[user]\n\tname = t\n\temail = t@localhost\n' "$tmp/template" >"$HOME/.gitconfig"
git -C "$r" config core.fsmonitor "$tmp/fsmonitor-ran"
printf '#!/bin/sh\ntouch "$HOME/fsmonitor-ran"\n' >"$tmp/fsmonitor-ran"
chmod +x "$tmp/fsmonitor-ran"
echo 'LEDGER_KEY=not-a-real-key' >"$r/.env"
echo 'edited, not committed' >>"$r/changed.txt"

touch -d '2020-01-01' "$r/README.md" # a stat change, so status has to read the file
state() { (cd "$r" && find . -type f -print0 | sort -z | xargs -0 sha256sum); }
before=$(state)

# ---- a local target ----------------------------------------------------------------
run start "$r"
expect 0 'a local target'
snap=$(field snapshot) dir=$(field raid)
has "$(field target)" "$r" 'target not printed'
has "$(field visibility)" local
has "$(field uncommitted_files)" 2 # the edited file and the untracked .env
has "$(field unconfirmed_origin)" none
lacks "$(field lenses)" public-readiness 'public readiness ran on a repo with no origin'
has "$(field skipped)" 'public-readiness (visibility is local)'
[[ $(field report) == "$dir/report.md" ]] || fail 'the report path is outside the raid directory'
[[ $dir == "$raids"/* ]] || fail 'the raid is outside the cache'
[[ $(stat -c %a "$raids") == 700 ]] || fail 'the raids directory is not private'

# The guarantees: the real repo is untouched, and the snapshot can't be written.
[[ $before == "$(state)" ]] || fail 'a run changed the target'
[[ ! -e $HOME/hook-ran ]] || fail "a hook ran"
[[ ! -e $HOME/filter-ran ]] || fail "the target's filter ran"
[[ ! -e $HOME/fsmonitor-ran ]] || fail "the target's fsmonitor ran"
[[ -f $snap/README.md ]] || fail 'the snapshot is empty'
[[ ! -e $snap/.env ]] || fail 'an untracked file reached the snapshot'
grep -q 'edited, not committed' "$snap/changed.txt" && fail 'uncommitted work reached the snapshot'
[[ ! -L $snap/escape ]] || fail 'a symlink reached the snapshot'
grep -q 'outside the repo' "$snap/escape" && fail 'a symlink led out of the snapshot'
if ((EUID != 0)); then
  (echo x >>"$snap/README.md") 2>/dev/null && fail 'the snapshot is writable'
  (touch "$snap/new") 2>/dev/null && fail 'the snapshot takes new files'
fi
[[ -z $(find "$snap/.git/hooks" -type f 2>/dev/null) ]] || fail 'the snapshot has hooks'
[[ -e $dir/active ]] || fail 'the raid is not marked live'

# Facts: what each lens reads.
f=$dir/facts
has "$(cat "$f/log.txt")" 'chore: start'
grep -q $'\e' "$f/log.txt" && fail 'a control character reached the log'
has "$(cat "$f/tree.txt")" 'changed.txt'
has "$(cat "$f/conventions.md")" '# conventions'
has "$(cat "$f/lore-scribe.md")" 'Writing the lore' 'docs lens has no rules'
has "$(cat "$f/portfolio.txt")" 'Curated map'
lacks "$(cat "$f/portfolio.txt")" 'End of lookup' "map-scout's closing line reached the lens"
has "$(cat "$f/guard.txt")" 'guard: unavailable' 'no checkout should say so'
has "$(cat "$f/settings.txt")" 'no confirmed GitHub origin'
[[ ! -e $f/standard.md ]] || fail 'the standard was copied with the lens off'

# clean keeps the report and removes the rest, read-only files included.
rc=0; out=$(echo report | "$raid" save "$dir" 2>&1) || rc=$?
expect 0 'save'
[[ $(cat "$dir/report.md") == report ]] || fail 'save lost the report'
[[ $(stat -c %a "$dir/report.md") == 600 ]] || fail 'the report is not private'
rc=0; out=$(: | "$raid" save "$dir" 2>&1) || rc=$?
expect 3 'an empty report'
rc=0; out=$(echo x | "$raid" save "$tmp" 2>&1) || rc=$?
expect 2 'save outside the raids directory'
echo report >"$dir/report.md"
run clean "$dir"
expect 0 'clean'
[[ -f $dir/report.md ]] || fail 'clean removed the report'
[[ ! -e $dir/src && ! -e $dir/facts ]] || fail 'clean left the snapshot'
[[ ! -e $dir/active ]] || fail 'clean left the raid live'
run clean "$tmp"
expect 2 'clean outside the raids directory'
[[ -d $tmp ]] || fail 'clean removed a directory it was not given'
run clean "$raids/../.."
expect 2 'clean by climbing out'

# ---- focus -------------------------------------------------------------------------
run start "$r" --focus docs
expect 0 '--focus docs'
[[ $(field lenses) == docs ]] || fail "--focus ran: $(field lenses)"
[[ $(field skipped) == none ]] || fail 'a focused run reported a skip'
d=$(field raid)
[[ ! -e $d/facts/guard.txt && ! -e $d/facts/settings.txt && ! -e $d/facts/portfolio.txt ]] || fail '--focus docs gathered facts for lenses it skipped'
run start "$r" --focus=code,security,code
expect 0 '--focus='
[[ $(field lenses) == 'code security' ]] || fail "--focus= list ran: $(field lenses)"
run start "$r" --focus public-readiness
expect 0 '--focus public-readiness'
[[ $(field lenses) == public-readiness ]] || fail 'naming public-readiness on a local repo did not run it'
[[ -r $(field raid)/facts/standard.md ]] || fail 'the standard is missing'
count=$(find "$raids" -mindepth 1 -maxdepth 1 | wc -l)
for bad in 'nope' 'code,nope' ''; do
  run start "$r" --focus "$bad"
  expect 2 "--focus '$bad'"
done
run start "$r" --delete
expect 2 'an unknown option'
run start "$r" "$tmp"
expect 2 'two targets'
run start '--upload-pack=touch x'
expect 2 'an option as a target'
run start "$tmp/missing dir"
expect 2 'a bad target'
mkdir "$tmp/plain"
run start "$tmp/plain"
expect 3 'a directory outside git'
git init -q "$tmp/empty"
run start "$tmp/empty"
expect 3 'a repository with no commits'
[[ $count == "$(find "$raids" -mindepth 1 -maxdepth 1 | wc -l)" ]] || fail 'a failed start left a raid behind'

# ---- GitHub targets ----------------------------------------------------------------
# A target that points somewhere else. Each of these used to snapshot the victim.
v=$tmp/code/victim
git init -q -b main --template= "$v"
echo PRIVATE-CANARY >"$v/secret.txt"
git -C "$v" add secret.txt
git -C "$v" commit -q -m 'chore: private'
mkdir "$tmp/gitfile" "$tmp/gitlink" "$tmp/worktree"
echo "gitdir: $v/.git" >"$tmp/gitfile/.git"
ln -s "$v/.git" "$tmp/gitlink/.git"
git init -q -b main "$tmp/worktree"
git -C "$tmp/worktree" config core.worktree "$v"
git -C "$v" worktree add -q "$tmp/linked" 2>/dev/null
mkdir -p "$tmp/common/.git" && cp -r "$r/.git/." "$tmp/common/.git/"
echo "$v/.git" >"$tmp/common/.git/commondir"
# Repos with no objects of their own, reaching for the victim's.
git init -q -b main --template= "$tmp/alt"
mkdir -p "$tmp/alt/.git/objects/info" "$tmp/alt/.git/refs/heads"
echo "$v/.git/objects" >"$tmp/alt/.git/objects/info/alternates"
git -C "$v" rev-parse HEAD >"$tmp/alt/.git/refs/heads/main"
git init -q -b main --template= "$tmp/packlink"
git -C "$v" pack-refs --all
ln -s "$v/.git/packed-refs" "$tmp/packlink/.git/packed-refs"
mkdir -p "$tmp/packlink/.git/objects/info"
echo "$v/.git/objects" >"$tmp/packlink/.git/objects/info/alternates"
git init -q -b main --template= "$tmp/objlink"
rm -rf "$tmp/objlink/.git/refs/heads"
mkdir -p "$tmp/objlink/.git/refs/heads"
git -C "$v" rev-parse HEAD >"$tmp/objlink/.git/refs/heads/main"
for o in $(cd "$v/.git/objects" && find . -type f -path './??/*'); do
  mkdir -p "$tmp/objlink/.git/objects/$(dirname "$o")"
  ln -s "$v/.git/objects/$o" "$tmp/objlink/.git/objects/$o"
done
git clone -q --template= "$r" "$tmp/fifo"
rm "$tmp/fifo/.git/config" && mkfifo "$tmp/fifo/.git/config"
nl=$tmp/$'odd\nreport=/tmp/forged'
git init -q -b main "$nl"
git -C "$nl" -c user.name=t -c user.email=t@localhost commit -q --allow-empty -m 'chore: start'
# An empty .git, with a repository one step away: git clone would fall back to either.
mkdir -p "$tmp/fallback/.git"
git clone -q --bare --template= "$v" "$tmp/fallback.git"
git clone -q --bare --template= "$v" "$tmp/bare-here"
mkdir "$tmp/bare-here/.git"
# Unlistable directories, which a scan can't see into.
git clone -q --template= "$r" "$tmp/locked"
chmod 311 "$tmp/locked/.git/refs/heads"
# A symlinked objects directory: pruning its info/ would delete the victim's.
git init -q -b main --template= "$tmp/linkobj"
rm -rf "$tmp/linkobj/.git/objects"
ln -s "$tmp/outside" "$tmp/linkobj/.git/objects"
mkdir -p "$tmp/outside/info"
echo keep >"$tmp/outside/info/keep"
# Read-only directories, so that pruning fails unless it's made to work.
git init -q -b main --template= "$tmp/ro"
mkdir -p "$tmp/ro/.git/objects/info" "$tmp/ro/.git/refs/heads"
echo "$v/.git/objects" >"$tmp/ro/.git/objects/info/alternates"
git -C "$v" rev-parse HEAD >"$tmp/ro/.git/refs/heads/main"
chmod 500 "$tmp/ro/.git/objects/info" "$tmp/ro/.git/objects" "$tmp/ro/.git/refs/heads" "$tmp/ro/.git/refs"
for hostile in "$tmp/gitfile" "$tmp/gitlink" "$tmp/linked" "$nl" "$tmp/alt" "$tmp/packlink" "$tmp/objlink" \
  "$tmp/fallback" "$tmp/bare-here" "$tmp/locked" "$tmp/worktree" "$tmp/linkobj" "$tmp/ro"; do
  run start "$hostile" --focus docs
  expect 3 "a target that isn't itself: $hostile"
  grep -q '^report=' <<<"$out" && fail 'a path forged a line'
done
chmod 755 "$tmp/locked/.git/refs/heads"
chmod -R u+rwx "$tmp/ro/.git"
[[ -e $tmp/outside/info/keep ]] || fail 'pruning reached a directory outside the target'
# commondir is simply left behind: this raids the repo's own commits, not the victim's.
run start "$tmp/common" --focus docs
expect 0 'a commondir file'
run start "$tmp/fifo" --focus docs
expect 0 'a FIFO for a config, which is never opened'
if grep -rqs PRIVATE-CANARY "$raids"; then fail 'a target reached another repository'; fi

# A clean checkout reads as clean, symlinks included.
git init -q -b main --template= "$tmp/tidy"
echo a >"$tmp/tidy/a.txt"
ln -s a.txt "$tmp/tidy/link"
git -C "$tmp/tidy" add -A
git -C "$tmp/tidy" -c user.name=t -c user.email=t@localhost commit -q -m 'chore: start'
run start "$tmp/tidy" --focus docs
expect 0 'a clean checkout'
[[ $(field uncommitted_files) == 0 ]] || fail "a clean checkout reads as $(field uncommitted_files) uncommitted"

# A FIFO in the work tree stops status, which then says so.
git clone -q --template= "$r" "$tmp/pipe"
mkfifo "$tmp/pipe/.gitignore"
run start "$tmp/pipe" --focus docs
expect 0 'a FIFO in the work tree'
has "$(field uncommitted_files)" unknown

# A dotted name must not hide the raid from the gate's glob.
git clone -q --template= "$r" "$tmp/.dotted"
run start "$tmp/.dotted" --focus docs
expect 0 'a dotted target'
[[ $(basename "$(field raid)") != .* ]] || fail 'a dotted target made a dot directory'

# A submodule's own config, and a filter from your own config, stay out of it.
s=$tmp/withsub
git init -q -b main --template= "$s"
git -C "$s" -c user.name=t -c user.email=t@localhost commit -q --allow-empty -m 'chore: inner'
git init -q -b main --template= "$s/sub"
git -C "$s/sub" -c user.name=t -c user.email=t@localhost commit -q --allow-empty -m 'chore: sub'
printf '* filter=mine\n' >"$s/.gitattributes"
echo a >"$s/a.txt"
git -C "$s" add -A 2>/dev/null
git -C "$s" -c user.name=t -c user.email=t@localhost commit -q -m 'chore: gitlink'
git -C "$s/sub" config core.fsmonitor "$tmp/fsmonitor-ran"
git config --global filter.mine.clean "sh -c 'touch $HOME/user-filter-ran; cat'"
git config --global filter.mine.smudge "sh -c 'touch $HOME/user-filter-ran; cat'"
rm -f "$HOME/user-filter-ran"
touch -d '2020-01-01' "$s/a.txt"
run start "$s" --focus docs
expect 0 'a repository with a gitlink'
[[ ! -e $HOME/fsmonitor-ran ]] || fail "a submodule's fsmonitor ran"
[[ ! -e $HOME/user-filter-ran ]] || fail 'your own filter ran on a hostile file'
git config --global --unset filter.mine.clean
git config --global --unset filter.mine.smudge

for bad in -b/x https://github.com/-b/x https://github.com/octo/-x; do
  run start "$bad" --focus docs
  ((rc != 0)) || fail "$bad was read as a repo"
done
lacks "$(cat "$HOME/gh.log")" 'clone -b/x' 'a slug became a flag'

git clone -q --bare "$r" "$HOME/seed" 2>/dev/null
git -C "$HOME/seed" branch only-on-github
git -C "$HOME/seed" update-ref refs/pull/1/head HEAD
git config --global url."$HOME/seed".insteadOf https://github.com/octo/widget
echo PUBLIC >"$HOME/visibility"
for form in octo/widget octo/widget.git https://github.com/octo/widget https://github.com/octo/widget.git git@github.com:octo/widget.git; do
  run start "$form" --focus docs
  expect 0 "target $form"
  [[ $(field target) == octo/widget ]] || fail "$form read as: $(field target)"
done
run start octo/widget
expect 0 'a public GitHub target'
has "$(field lenses)" public-readiness 'public readiness skipped on a public repo'
s=$(cat "$(field raid)/facts/settings.txt")
snap=$(field snapshot)
[[ ! -L $snap/escape ]] || fail 'a GitHub target kept a symlink'
[[ -z $(find "$snap/.git/hooks" -type f 2>/dev/null) ]] || fail 'a GitHub target has hooks'
if ((EUID != 0)); then (touch "$snap/new") 2>/dev/null && fail 'a GitHub snapshot takes new files'; fi
git -C "$snap" rev-parse -q --verify refs/pr/1 >/dev/null || fail 'pull request refs were not fetched'
has "$s" 'dependabot alerts: on'
has "$s" 'community profile percent: 87'
has "$s" 'classic protection, required checks: unavailable' 'a failed call should say so'
lacks "$s" 'Branch not protected' "gh's error body reached the facts"
echo PRIVATE >"$HOME/visibility"
run start octo/widget
has "$(field skipped)" 'visibility is private'
rm "$HOME/visibility"
run start octo/widget
has "$(field visibility)" unknown
has "$(field skipped)" 'visibility is unknown'

# A clone that can't be made says so.
rm -rf "$HOME/seed.bak"; mv "$HOME/seed" "$HOME/seed.bak"
run start octo/widget --focus docs
expect 3 'a failed clone'
mv "$HOME/seed.bak" "$HOME/seed"

# A local checkout of a GitHub repo keeps its origin, and takes the remote's refs.
git -C "$r" remote add origin git@github.com:octo/widget.git
echo PUBLIC >"$HOME/visibility"
run start "$r" --focus security
[[ $(field target) == octo/widget ]] || fail 'a confirmed origin was not used'
snap=$(field snapshot)
[[ $(git -C "$snap" remote get-url origin) == git@github.com:octo/widget.git ]] || fail 'the snapshot lost the origin'
git -C "$snap" rev-parse -q --verify refs/remotes/origin/only-on-github >/dev/null || fail 'a remote branch was not fetched'
lacks "$(cat "$(field raid)/facts/guard.txt")" 'fetch failed'

# An origin GitHub doesn't confirm gets no gh call past the check, and no fetch.
touch "$HOME/no-root"
: >"$HOME/gh.log"
run start "$r" --focus security
expect 0 'an unconfirmed origin'
has "$(field unconfirmed_origin)" octo/widget
has "$(field visibility)" local
[[ $(field target) == "$r" ]] || fail 'an unconfirmed origin named the target'
lacks "$(cat "$HOME/gh.log")" 'gh api repos/octo/widget/branches' 'settings read for an unconfirmed origin'
lacks "$(cat "$HOME/gh.log")" 'repo view' 'visibility read for an unconfirmed origin'
git -C "$(field snapshot)" rev-parse -q --verify refs/pr/1 >/dev/null && fail 'pull request refs fetched for an unconfirmed origin'
has "$(cat "$(field raid)/facts/settings.txt")" 'no confirmed GitHub origin'
rm "$HOME/no-root"

# A failed fetch is on the record.
git config --global --unset url."$HOME/seed".insteadOf
git config --global url."$HOME/gone".insteadOf https://github.com/octo/widget
run start "$r" --focus security
has "$(cat "$(field raid)/facts/guard.txt")" 'guard: unavailable for remote branches'

# With a checkout, the guard runs, and its exit is on record.
mkdir -p "$tmp/co/guard"
printf '#!/bin/sh\necho "scanned in $PWD"\nexit 1\n' >"$tmp/co/guard/scan"
chmod +x "$tmp/co/guard/scan"
LOADOUT_REPO=$tmp/co run start "$r" --focus security
g=$(cat "$(field raid)/facts/guard.txt")
has "$g" "scanned in $(field snapshot)"
has "$g" 'guard exit: 1'
printf '#!/bin/sh\necho "require=$GUARD_REQUIRE_DENYLIST"\nexit 2\n' >"$tmp/co/guard/scan"
LOADOUT_REPO=$tmp/co run start "$r" --focus security
g=$(cat "$(field raid)/facts/guard.txt")
has "$g" 'require=1' 'a missing denylist would read as a pass'
has "$g" 'guard: unavailable, the scan stopped with exit 2'
LOADOUT_REPO=relative/path run start "$r" --focus security
has "$(cat "$(field raid)/facts/guard.txt")" 'guard: unavailable'

# ---- the gate ----------------------------------------------------------------------
gate() {  # expected allow or deny, JSON
  local got=allow o
  o=$("$raid" gate <<<"$2") || fail "the gate exited nonzero on: $2"
  if grep -q '"permissionDecision": "deny"' <<<"$o"; then got=deny; fi
  [[ $got == "$1" ]] || fail "gate: wanted $1, got $got: $2"
}
call() {  # agent type, tool, input JSON
  printf '{"session_id":"s1","agent_type":"%s","tool_name":"%s","tool_input":%s}' "$1" "$2" "$3"
}
find "$raids" -name active -delete
CLAUDE_CODE_SESSION_ID=s1 run start "$r" --focus docs
in=$(field snapshot)
other=$raids/other-raid
gate allow "$(call Explore Read "{\"file_path\":\"$in/README.md\"}")"
gate allow "$(call Explore Grep "{\"pattern\":\"a\",\"path\":\"$in\"}")"
gate allow "$(call Explore Glob "{\"pattern\":\"**/*.md\",\"path\":\"$in\"}")"
gate allow "$(call Explore SubagentHandback '{}')"
gate deny "$(call Explore Bash '{"command":"ls"}')"
gate deny "$(call Explore WebFetch '{"url":"https://example.com"}')"
gate deny "$(call Explore mcp__any__tool '{}')"
gate deny "$(call Explore Write "{\"file_path\":\"$in/x\"}")"
gate deny "$(call Explore Read "{\"file_path\":\"$HOME/secret.txt\"}")"
gate deny "$(call Explore Read "{\"file_path\":\"$in/../../../../secret.txt\"}")"
gate deny "$(call Explore Grep '{"pattern":"a"}')" # no path means the current directory
gate deny "$(call Explore Glob '{"pattern":"*"}')"
gate deny "$(call Explore Glob "{\"pattern\":\"/home/**\",\"path\":\"$in\"}")"
gate deny "$(call Explore Glob "{\"pattern\":\"../../**\",\"path\":\"$in\"}")"
gate deny "$(call Explore Glob "{\"pattern\":\"{/home/**,a}\",\"path\":\"$in\"}")"
gate deny "$(call Explore Grep "{\"pattern\":\"a\",\"path\":\"$in\",\"glob\":\"../../**\"}")"
gate deny "$(call Explore Read "{\"file_path\":\"$other/report.md\"}")"
gate allow "$(call Explore Read "{\"file_path\":\"$in/odd..name.txt\"}")"
gate allow "$(call Explore Read "{\"file_path\":\"$(cd -P "$in" && pwd -P)/README.md\"}")"
# With no jq, it still denies.
mkdir "$tmp/nojq"; for b in bash sh cat find dirname readlink; do ln -s "$(command -v "$b")" "$tmp/nojq/"; done
o=$(PATH=$tmp/nojq "$raid" gate <<<"$(call Explore Bash '{"command":"ls"}')")
grep -q '"permissionDecision":"deny"' <<<"$o" || fail 'the gate let a call through with no jq'
gate deny 'not json'
gate allow "$(call general-purpose Bash '{"command":"ls"}')"
gate allow '{"session_id":"s2","agent_type":"Explore","tool_name":"Bash","tool_input":{"command":"ls"}}' # another session
gate allow '{"tool_name":"Bash","tool_input":{"command":"ls"}}' # the main session
# With no raid live, or only a stale one, it stands aside for the rest of the session.
find "$raids" -name active -exec touch -d '2 days ago' {} +
gate allow "$(call Explore Bash '{"command":"ls"}')"
find "$raids" -name active -delete
gate allow "$(call Explore Bash '{"command":"ls"}')"

# Every run above left the real repository alone. .git/config and refs gain only what
# this test added, so compare the work tree, and hooks stayed out.
[[ ! -e $HOME/hook-ran && ! -e $HOME/filter-ran ]] || fail 'a later run ran target code'

# The standard travels with the plugin, unchanged.
cmp -s "$root/docs/public-repo-standard.md" "${raid%/*}/public-repo-standard.md" || fail 'the copy of the standard has drifted'

((failed == 0)) && echo 'raid: all passed'
exit "$failed"
