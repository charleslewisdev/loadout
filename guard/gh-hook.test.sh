#!/usr/bin/env bash
# Tests for guard/gh-hook: gh commands that publish text are scanned, others pass.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="$HERE/gh-hook"
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}

t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
printf '\\bzorblax\\b\n' >"$t/deny"
echo "a clean body" >"$t/clean.md"
echo "the zorblax plan" >"$t/dirty.md"
mkdir -p "$t/work" && echo "zorblax again" >"$t/work/rel.md"
# A home path that itself matches the denylist, as a real one can.
mkdir -p "$t/home-zorblax/notes" && echo "a clean body" >"$t/home-zorblax/notes/ok.md"

run() {  # run <command>: sets rc and err from the hook
  local payload
  payload=$(jq -n --arg c "$1" --arg d "$t/work" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}')
  err=$(GUARD_DENYLIST=$t/deny "$HOOK" <<<"$payload" 2>&1 >/dev/null)
  rc=$?
}
blocked() { ((rc == 2)); }
passed() { ((rc == 0)); }
quiet() { ! grep -q -i zorblax <<<"$err"; }

run "gh issue create --title t --body-file $t/dirty.md"
check "a body file with a denied term is blocked" blocked
check "the block names no denied term" quiet
run "gh issue create --title t --body-file $t/clean.md"
check "a clean body file passes" passed
run "gh issue create --title 'zorblax time' --body-file $t/clean.md"
check "a denied term in the title is blocked" blocked
run 'gh issue create --title t --body "about zorblax"'
check "a denied term in an inline body is blocked" blocked
run "gh pr create -t t -F rel.md"
check "-F resolves a relative path against the session cwd" blocked
run "gh pr edit 3 --body-file=$t/dirty.md"
check "gh pr edit with --body-file= is scanned" blocked
run "gh issue comment 4 --body-file $t/dirty.md"
check "gh issue comment is scanned" blocked
run "gh pr comment 4 --body-file $t/dirty.md"
check "gh pr comment is scanned" blocked
run "gh repo edit --description 'zorblax kit'"
check "gh repo edit is scanned" blocked
run "gh api repos/o/r/issues -f body=zorblax"
check "gh api fields are scanned" blocked
run "gh api repos/o/r/issues --input $t/dirty.md"
check "a gh api --input file is scanned" blocked
run "gh api repos/o/r/issues -F body=@$t/dirty.md"
check "a gh api -F key=@file is scanned" blocked
run "gh issue create --title t --body \"\$(cat notes.md)\""
check "shell expansion in a publishing command is blocked" blocked
check "the block says to use a body file" grep -q -- '--body-file' <<<"$err"
run "gh issue create --title t --body-file $t/missing.md"
check "an unreadable body file is blocked" blocked
run "cd $t && gh issue create --title t --body-file $t/dirty.md"
check "a gh command after && is scanned" blocked
run "gh issue create --title t --body-file $t/home-zorblax/notes/ok.md"
check "a body file path is not itself scanned" passed
run "cd $t/home-zorblax && gh issue create --title t --body-file notes/ok.md"
check "a leading cd sets where relative paths are read" passed
run "gh issue create --title t -F $t/home-zorblax/notes/ok.md"
check "an -F path is not itself scanned" passed
run "gh api repos/o/r/issues -F 'title=about zorblax'"
check "a quoted gh api field value is still scanned" blocked
run "gh api repos/o/r/issues -F body=@$t/home-zorblax/notes/ok.md"
check "a gh api -F key=@path is not itself scanned" passed
run "env GH_REPO=o/r gh issue create --title 'zorblax' --body-file $t/clean.md"
check "gh behind a wrapper is scanned" blocked
run "echo 'see gh issue create --body \"\$(cat x)\" in the docs'"
check "gh quoted inside another command passes" passed
run "gh release create v1 --notes-file $t/dirty.md"
check "release notes from a file are scanned" blocked
run "gh gist create $t/clean.md"
check "gists are refused" blocked
run "gh issue create -t t --body-file - < $t/clean.md"
check "a body redirected from stdin is refused" blocked
run "cat $t/clean.md | gh issue create -t t -F -"
check "a body piped in is refused" blocked
run "gh pr review 3 --comment -b 'zorblax'"
check "gh pr review is scanned" blocked
run "gh issue close 3 --comment 'zorblax'"
check "a closing comment is scanned" blocked
run "gh pr merge 3 --squash --body 'zorblax'"
check "a merge body is scanned" blocked
run "gh label create zorblax"
check "a label is scanned" blocked
run "gh pr merge 3 --squash"
check "a clean unlisted verb passes" passed
run "cp $t/dirty.md $t/clean.md && gh issue create -t t --body-file $t/clean.md"
check "a publishing command chained after another is refused" blocked
run "/usr/bin/gh issue create -t zorblax --body-file $t/clean.md"
check "gh by path is scanned" blocked
run "gh issue -R o/r create -t zorblax --body-file $t/clean.md"
check "flags between the group and the verb don't hide it" blocked
run "gh api repos/o/r/issues -Fbody=@$t/dirty.md"
check "an attached -Fkey=@file is scanned" blocked
run "gh api repos/o/r/issues --field=body=@$t/dirty.md"
check "--field=key=@file is scanned" blocked
run "gh api graphql -f query='query(\$n: Int!) { viewer { login } }'"
check "a graphql read passes" passed
run "gh api graphql -f query='mutation { addComment(body: \"zorblax\") }'"
check "a graphql mutation is scanned" blocked
run "gh api repos/o/r/pulls/3"
check "a gh api read passes" passed
run "$(printf 'gh issue create -t t --body-file - <<%s\nthe zorblax plan\nEOF' "'EOF'")"
check "a heredoc body is scanned" blocked
run "$(printf 'gh issue create -t t --body-file - <<%s\na clean body\nEOF' "'EOF'")"
check "a clean heredoc body passes" passed
run "$(printf 'gh issue create -t one --body-file %s\ngh issue create -t two --body-file %s' "$t/clean.md" "$t/clean.md")"
check "several clean gh lines pass" passed
run "$(printf 'gh issue create -t one --body-file %s\ngh issue create -t zorblax --body-file %s' "$t/clean.md" "$t/clean.md")"
check "a denied term on any gh line blocks" blocked
run "git status"
check "a non-gh command passes" passed
run "gh pr list --search zorblax"
check "a read-only gh command passes" passed
payload=$(jq -n --arg c "gh issue create --title t --body-file $t/clean.md" '{tool_name:"Bash",tool_input:{command:$c}}')
GUARD_DENYLIST=$t/nope "$HOOK" <<<"$payload" >/dev/null 2>&1
rc=$?
check "a missing denylist blocks publishing" blocked

exit $fail
