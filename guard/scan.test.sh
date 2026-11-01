#!/usr/bin/env bash
# Tests for guard/scan on a second repository, run from outside the loadout checkout.
# The guard is copied, so the test controls its allowlist. Terms are made up.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
mkdir -p "$t/kit/guard" "$t/other"
cp "$HERE/scan" "$t/kit/guard/scan"
echo 'test@localhost' >"$t/kit/guard/allowed-emails"
printf '\\bzorblax\\b\n\\bwibble\\b\n' >"$t/deny"
: >"$t/exceptions"
r=$t/other
g=(git -C "$r" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
git init -q -b main "$r"
scan() {  # scan <args...>: sets rc, out and err from the working directory of the repo
  rc=0
  err=$(cd "$r" && GUARD_DENYLIST=$t/deny GUARD_EXCEPTIONS=$t/exceptions "${env_extra[@]}" "$t/kit/guard/scan" "$@" 2>&1 >/dev/null) || rc=$?
}
env_extra=(env)
commit() { "${g[@]}" add . && "${g[@]}" commit -q -m "$1"; }
add_exception() {  # adds the key the guard offers for the current findings
  env_extra=(env GUARD_SHOW_KEYS=1); scan --all; env_extra=(env)
  sed -n 's/.*exception key: //p' <<<"$err" >>"$t/exceptions"
}
quiet() { ! grep -q -i -e zorblax -e wibble <<<"$err"; }

echo 'a clean line' >"$r/notes.md"; commit "chore: start"
scan --all
check "a clean second repo exits 0 from outside the checkout" test "$rc" = 0
check "it reports no email findings" bash -c "! grep -q 'guard/allowed-emails' <<<\"\$1\"" _ "$err"

echo 'the zorblax plan' >>"$r/notes.md"; commit "docs: add a line"
scan --all
check "a match without an exception exits 1" test "$rc" = 1
check "the finding withholds the term" quiet
add_exception
check "the guard offers one key" test "$(grep -c . "$t/exceptions")" = 1
check "the offered key holds no term" bash -c "! grep -qi zorblax '$t/exceptions'"
scan --all
check "an excepted match exits 0" test "$rc" = 0
check "the scan reports the excepted count" grep -q '1 finding excepted' <<<"$err"
check "the count withholds the term" quiet

"${g[@]}" commit -q --amend -m "docs: reworded message"
scan --all
check "an exception survives a rewritten commit" test "$rc" = 0

echo 'the wibble plan' >>"$r/notes.md"; commit "docs: a new match"
scan --all
check "a new match still exits 1 beside an exception" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1

cp "$r/notes.md" "$r/copy.md"; commit "docs: same line, another file"
scan --all
check "the same line in another file isn't excepted" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1

sed -i 's/the zorblax plan/the zorblax plans/' "$r/notes.md"; commit "docs: reworded"
scan --all
check "a changed line isn't excepted" grep -q 'denylist line' <<<"$err"
"${g[@]}" reset -q --hard HEAD~1

# One line, two terms, one exception: the second term must still be found. A repo of
# its own, so nothing else can explain the failure.
kept=$r kept_exceptions=$(cat "$t/exceptions")
r=$t/three
g=(git -C "$r" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
git init -q -b main "$r"
: >"$t/exceptions"
echo 'zorblax meets wibble' >"$r/both.md"; commit "docs: both"
env_extra=(env GUARD_SHOW_KEYS=1); scan --all; env_extra=(env)
sed -n 's/.*exception key: //p' <<<"$err" | head -1 >"$t/exceptions"
scan --all
check "an exception for one term doesn't hide another on the line" grep -q 'denylist line 2 ' <<<"$err"
add_exception
scan --all
check "excepting both terms clears the line" test "$rc" = 0

# Each part of the key counts: a term, and a repository.
printf '\\bwibble\\b\n\\bzorblax\\b\n' >"$t/deny"
scan --all
check "reordering the denylist keeps exceptions" test "$rc" = 0
cp "$t/exceptions" "$t/exceptions.keep"
sed -i '1d' "$t/exceptions"
scan --all
check "dropping one term's exception finds that term" test "$rc" = 1
cp "$t/exceptions.keep" "$t/exceptions"
"${g[@]}" remote add origin git@example.com:acme/renamed.git
scan --all
check "an exception doesn't follow a repo to another origin" grep -q 'denylist line' <<<"$err"
"${g[@]}" remote remove origin
printf '\\bzorblax\\b\n\\bwibble\\b\n' >"$t/deny"

# A line added twice gives one key twice, and both lines count as used.
head -1 "$t/exceptions" >>"$t/exceptions"
scan --all
check "a repeated exception isn't called stale" test "$rc" = 0

r=$kept
g=(git -C "$r" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
printf '%s\n' "$kept_exceptions" >"$t/exceptions"

# The line is gone from history, so the exception is stale.
"${g[@]}" checkout -q --orphan fresh
"${g[@]}" rm -rfq --cached .
rm -f "$r"/*.md
echo 'clean again' >"$r/notes.md"; commit "chore: restart"
"${g[@]}" branch -q -D main
scan --all
check "a stale exception fails a full scan" test "$rc" = 1
check "the failure names the exception line" grep -q 'exception on line 1 of' <<<"$err"
check "a partial scan can't judge staleness" bash -c "
  cd '$r' && echo 'clean' >>notes.md && git add notes.md &&
  GUARD_DENYLIST='$t/deny' GUARD_EXCEPTIONS='$t/exceptions' GIT_AUTHOR_NAME=t GIT_COMMITTER_NAME=t GIT_AUTHOR_EMAIL=test@localhost GIT_COMMITTER_EMAIL=test@localhost '$t/kit/guard/scan' diff"
"${g[@]}" reset -q --hard

# An exception for another repo isn't this repo's to judge, and can't apply here.
printf 'elsewhere\t%064d\tnote\n' 0 >"$t/exceptions"
scan --all
check "another repo's exception is left alone" test "$rc" = 0

echo 'not a real line' >"$t/exceptions"
scan --all
check "a malformed exceptions file is an error" test "$rc" = 2
: >"$t/exceptions"

# Secrets are never excepted.
printf 'ghp_%s\n' "$(printf 'a%.0s' {1..36})" >"$r/key.txt"; commit "chore: a planted token"
env_extra=(env GUARD_SHOW_KEYS=1); scan --all; env_extra=(env)
check "a secret offers no key" bash -c "! grep -q 'exception key' <<<\"\$1\"" _ "$err"
"${g[@]}" reset -q --hard HEAD~1

# Text headed straight for GitHub takes no exceptions.
: >"$t/exceptions"
"${g[@]}" commit -q --allow-empty -m "fix zorblax"
add_exception
echo 'fix zorblax' >"$t/pr.md"
scan text "$t/pr.md"
check "an exception never covers text" test "$rc" = 1
: >"$t/exceptions"
"${g[@]}" reset -q --hard HEAD~1

# The repo name stays private, and so does a term in it.
g2=(git -C "$t/zorblax-tools" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
git init -q -b main "$t/zorblax-tools"
echo 'wibble' >"$t/zorblax-tools/a.md"; "${g2[@]}" add .; "${g2[@]}" commit -q -m "chore: start"
err=$(cd "$t/zorblax-tools" && GUARD_DENYLIST=$t/deny GUARD_EXCEPTIONS=$t/exceptions GUARD_SHOW_KEYS=1 "$t/kit/guard/scan" --all 2>&1 >/dev/null) || true
check "a key never prints the repo name" quiet

# A path that holds ' b/' keeps its first part, and its own exception.
mkdir -p "$r/other b"
echo 'wibble here' >"$r/notes2.md"; commit "docs: one"
add_exception
scan --all
check "excepted before the twin file exists" test "$rc" = 0
cp "$r/notes2.md" "$r/other b/notes2.md"; commit "docs: the same line elsewhere"
scan --all
check "a path with ' b/' isn't another file's exception" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~2
: >"$t/exceptions"
mkdir -p "$r/zorblax b"
echo fine >"$r/zorblax b/n.md"; commit "docs: a term in the path"
scan --all
check "a term before ' b/' in a path is found" test "$rc" = 1
check "that path stays withheld" quiet
"${g[@]}" reset -q --hard HEAD~1

# Git quotes unusual paths, which must not hide a term or print one.
printf 'fine\n' >"$r/$(printf 'x\tzorblax.md')"; commit "docs: a tab in the path"
scan --all
check "a term after a tab in a path is found" test "$rc" = 1
check "that path stays withheld" quiet
"${g[@]}" reset -q --hard HEAD~1
printf '\\bz\xc3\xb6rblax\\b\n' >"$t/deny"
printf 'fine\n' >"$r/$(printf 'z\xc3\xb6rblax.md')"; commit "docs: non-ASCII in the path"
scan --all
check "a non-ASCII term in a path is found" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1
printf '\\bzorblax\\b\n\\bwibble\\b\n' >"$t/deny"

# Text can't forge the marker that ends a scan.
printf 'ok\n\001ENDMSG\nthe zorblax plan\n' >"$t/forged.md"
scan text "$t/forged.md"
check "a forged end marker in text doesn't stop the scan" test "$rc" = 1
"${g[@]}" commit -q --allow-empty -F "$t/forged.md"
scan --all
check "a forged end marker in a message doesn't stop the scan" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1

# A NUL byte can't make a changed line hash like the excepted one.
: >"$t/exceptions"
echo 'zorblax xwibble' >"$r/nul.md"; commit "docs: before"
add_exception
scan --all
check "the plain line is excepted" test "$rc" = 0
printf 'zorblax x\000wibble\n' >"$r/nul.md"; commit "docs: a NUL in the line"
scan --all
check "a NUL changes the line" grep -q 'denylist line' <<<"$err"
"${g[@]}" reset -q --hard HEAD~2
: >"$t/exceptions"

# Exceptions never live in the repo they would excuse.
mkdir -p "$r/.g"; : >"$r/.g/exceptions"
env_extra=(env GUARD_EXCEPTIONS="$r/.g/exceptions"); rc=0
err=$(cd "$r" && GUARD_DENYLIST=$t/deny GUARD_EXCEPTIONS=$r/.g/exceptions "$t/kit/guard/scan" --all 2>&1 >/dev/null) || rc=$?
env_extra=(env)
check "an exceptions file inside the repo is an error" test "$rc" = 2
rm -f "$r/.g/exceptions"; rmdir "$r/.g"

# A word boundary holds beside a byte that isn't valid UTF-8, in a UTF-8 locale.
printf 'quxfrob\n' >"$t/deny"
printf '\\bquxfrob\\b\n' >"$t/deny"
printf 'caf\xe9quxfrob\n' >"$t/bytes.md"
env_extra=(env LC_ALL=C.UTF-8 LANG=C.UTF-8); scan text "$t/bytes.md"; env_extra=(env)
check "a term beside an invalid byte is found" test "$rc" = 1
printf '\\bzorblax\\b\n\\bwibble\\b\n' >"$t/deny"

# Local git config can't hide content.
echo 'the zorblax plan' >"$r/hidden.md"; commit "docs: the term"
for cfg in log.showRoot=false diff.relative=true i18n.logOutputEncoding=UTF-16; do
  "${g[@]}" config "${cfg%%=*}" "${cfg#*=}"
  scan --all
  check "$cfg doesn't hide a term" test "$rc" = 1
  "${g[@]}" config --unset "${cfg%%=*}"
done
"${g[@]}" reset -q --hard HEAD~1

# The first commit of a repo is the one most at risk before it goes public.
git init -q -b main "$t/rooted"
g3=(git -C "$t/rooted" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
echo 'the zorblax plan' >"$t/rooted/a.md"; "${g3[@]}" add .; "${g3[@]}" commit -q -m "chore: start"
"${g3[@]}" config log.showRoot false
rc=0; (cd "$t/rooted" && GUARD_DENYLIST=$t/deny GUARD_EXCEPTIONS=$t/exceptions "$t/kit/guard/scan" --all >/dev/null 2>&1) || rc=$?
check "log.showRoot=false doesn't hide a first commit" test "$rc" = 1

# The scan also reads names, tags and refs.
"${g[@]}" -c user.name=Zorblax commit -q --allow-empty -m "chore: a named author"
scan --all
check "a term in an author name is found" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1
"${g[@]}" tag -a v1 -m 'tag zorblax'
scan --all
check "a term in a tag message is found" test "$rc" = 1
"${g[@]}" tag -d v1 >/dev/null
"${g[@]}" branch zorblax-branch
scan --all
check "a term in a branch name is found" test "$rc" = 1
check "the branch name stays withheld" quiet
"${g[@]}" branch -q -D zorblax-branch

# A secret in a path isn't printed, and neither are control bytes.
s=AKIA$(printf 'ABCDEFGHIJKLMNOP')
: >"$r/$s"; commit "chore: a secret name"
scan --all
check "a secret in a path is found" test "$rc" = 1
check "the secret isn't printed" bash -c "! grep -q '$s' <<<\"\$1\"" _ "$err"
"${g[@]}" reset -q --hard HEAD~1
printf 'wibble\n' >"$r/$(printf 'a\033[2Kb.md')"; commit "docs: control bytes"
scan --all
check "control bytes in a path don't reach the terminal" bash -c "! grep -q \$'\\033' <<<\"\$1\"" _ "$err"
"${g[@]}" reset -q --hard HEAD~1

# A stricter pattern keeps an everyday word out of ordinary prose.
printf 'bramble[-/.]\n' >"$t/deny"
echo 'The path ran through a bramble and on past the gate. Bramble hedges grow fast.' >"$r/prose.md"; commit "docs: prose"
scan --all
check "a stricter pattern passes ordinary prose" test "$rc" = 0
echo 'see bramble-api for details' >>"$r/prose.md"; commit "docs: the project name"
scan --all
check "a stricter pattern still finds the name" test "$rc" = 1
"${g[@]}" reset -q --hard HEAD~1
printf '\\bzorblax\\b\n' >"$t/deny"

rm "$t/kit/guard/allowed-emails"
scan --all
check "a missing allowlist exits 2" test "$rc" = 2
check "it says what's missing" grep -q 'allowed-emails' <<<"$err"
echo 'a clean line' >"$t/body.md"
scan text "$t/body.md"
check "text needs no allowlist" test "$rc" = 0

exit $fail
