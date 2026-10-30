#!/usr/bin/env bash
# Tests for hooks/review-gate on synthetic transcripts in a throwaway repository.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="$HERE/review-gate"
fail=0
check() {  # check <description> <condition...>
  local what=$1; shift
  if "$@"; then echo "✓ $what"; else echo "✗ $what"; fail=1; fi
}
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
r=$t/repo
g=(git -C "$r" -c user.name=t -c user.email=test@localhost -c core.hooksPath=/dev/null)
git init -q -b main "$r"
echo one >"$r/a.py"; echo two >"$r/b.py"
"${g[@]}" add . && "${g[@]}" commit -q -m "chore: start" && "${g[@]}" tag start

clock=0
stamp() { clock=$((clock + 1)); printf '2026-01-01T00:00:%02dZ' "$clock"; }
use() {  # use <tool> <input json> [transcript]
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"tool_use","name":"%s","input":%s}]}}\n' "$(stamp)" "$1" "$2" >>"${3:-$t/tr.jsonl}"
}
edit() { use Edit "{\"file_path\":\"$1\"}"; }
review() { use Skill '{"skill":"loadout:review-party"}'; }
say() { printf '{"type":"user","timestamp":"%s","message":{"content":"%s"}}\n' "$(stamp)" "$1" >>"$t/tr.jsonl"; }
typed() { say '<command-name>/loadout:review-party</command-name>'; }
run() {  # run [stop_hook_active]
  out=$(jq -n --arg t "$t/tr.jsonl" --arg d "$r" --argjson a "${1:-false}" --arg s "$session" '{transcript_path:$t,cwd:$d,stop_hook_active:$a,session_id:$s}' | LOADOUT_CACHE=$t/cache "$HOOK")
}
blocked() { jq -e '.decision == "block"' <<<"$out" >/dev/null 2>&1; }
silent() { [[ -z $out ]]; }
sn=0
fresh() { : >"$t/tr.jsonl"; rm -rf "$t/tr/subagents"; "${g[@]}" reset -q --hard start; "${g[@]}" clean -qfd; session=s$((++sn)); }

fresh; edit "$r/a.py"; echo x >>"$r/a.py"; run
check "one changed file passes" silent
fresh; edit "$r/a.py"; edit "$r/b.py"; echo x >>"$r/a.py"; echo x >>"$r/b.py"; run
check "two changed files block" blocked
check "the block names the review" grep -q 'review-party' <<<"$out"
run true
check "stop_hook_active lets the next stop through" silent
run
check "a later stop with no new events passes" silent
say "ok thanks"; run
check "a later turn with no new work passes" silent
edit "$r/a.py"; run
check "new work after a declined review blocks again" blocked
review; run
check "a review after the edits passes" silent
edit "$r/a.py"; edit "$r/b.py"; run
check "edits in the review's own turn are its fixes" silent
say '<task-notification><task-id>a1</task-id></task-notification>'; edit "$r/a.py"; edit "$r/b.py"; run
check "a background agent's notification doesn't end the review's turn" silent
say "one more thing"; edit "$r/a.py"; edit "$r/b.py"; run
check "edits in a later turn block" blocked
say "go on"; typed; run
check "a typed review counts" silent
fresh; edit "$r/a.py"; edit "$r/b.py"; echo x >>"$r/a.py"; review; say "and this"; edit "$r/a.py"; run
check "one file after a review passes on a branch of many" silent
fresh; edit "$t/outside.md"; edit "$t/other.md"; run
check "edits outside the repository pass" silent
fresh; edit "$r/a.py"; edit "$r/b.py"; run
check "edits that left no difference pass" silent
fresh; mkdir -p "$r/build"; echo 'build/' >"$r/.git/info/exclude"; echo x >"$r/build/x"; echo x >"$r/build/y"; edit "$r/build/x"; edit "$r/build/y"; run
check "ignored files pass" silent
fresh; : >"$r/.git/info/exclude"; mkdir -p "$t/tr/subagents"; echo x >>"$r/a.py"; echo x >>"$r/b.py"
use Edit "{\"file_path\":\"$r/a.py\"}" "$t/tr/subagents/agent-1.jsonl"; use Edit "{\"file_path\":\"$r/b.py\"}" "$t/tr/subagents/agent-1.jsonl"; run
check "work done in subagents blocks" blocked
fresh; mkdir -p "$t/tr/subagents"; edit "$r/a.py"; edit "$r/b.py"; echo x >>"$r/a.py"; echo x >>"$r/b.py"
use Skill '{"skill":"loadout:review-party"}' "$t/tr/subagents/agent-2.jsonl"; run
check "a review run in a subagent counts" silent
fresh; use Bash '{"command":"sed -i s/one/uno/ a.py b.py"}'; echo x >>"$r/a.py"; echo x >>"$r/b.py"; run
check "in-place edits from Bash block" blocked
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"grep \"git commit\" docs"}'; run
check "a command that only mentions git commit passes" silent
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"git -C sub commit -m x"}'; run
check "git -C dir commit counts" blocked
fresh; edit "$r/a.py"; edit "$r/b.py"; echo x >>"$r/a.py"; echo x >>"$r/b.py"; printf 'not json\n' >>"$t/tr.jsonl"; run
check "a malformed line doesn't turn the gate off" blocked
fresh; ln -s "$r" "$t/link"; edit "$t/link/a.py"; edit "$t/link/b.py"; echo x >>"$r/a.py"; echo x >>"$r/b.py"; run
check "a path through a symlink still counts" blocked
rm -f "$t/link"
fresh; edit "$r/a.py"; edit "$r/b.py"; echo x >>"$r/a.py"; echo x >>"$r/b.py"
out=$(jq -n --arg t "$t/tr.jsonl" --arg d "$r" '{transcript_path:$t,cwd:$d}' | LOADOUT_REVIEW_GATE=0 "$HOOK")
check "LOADOUT_REVIEW_GATE=0 turns it off" silent
out=$(jq -n --arg t "$t/tr.jsonl" --arg d "$r" '{transcript_path:$t,cwd:$d}' | LOADOUT_REVIEW_MIN_FILES=3 "$HOOK")
check "LOADOUT_REVIEW_MIN_FILES raises the bar" silent
out=$(jq -n --arg t "$t/tr.jsonl" --arg d "$r" '{transcript_path:$t,cwd:$d}' | LOADOUT_REVIEW_MIN_FILES=abc "$HOOK")
check "a bad LOADOUT_REVIEW_MIN_FILES falls back to the default" blocked
fresh; mkdir -p "$r/feat"; echo x >"$r/feat/one.py"; echo x >"$r/feat/two.py"; edit "$r/feat/one.py"; edit "$r/feat/two.py"; run
check "two new files in a new directory block" blocked
fresh; echo x >"$r/my file.py"; echo x >"$r/your file.py"; edit "$r/my file.py"; edit "$r/your file.py"; run
check "file names with spaces block" blocked
fresh; "${g[@]}" mv a.py c.py; "${g[@]}" mv b.py d.py; echo x >>"$r/c.py"; echo x >>"$r/d.py"; edit "$r/c.py"; edit "$r/d.py"; run
check "renamed files block" blocked
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"git add .\ngit commit -m x"}'; run
check "git commit on a later line counts" blocked
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"git -c user.name=x commit -m x"}'; run
check "git -c key=value commit counts" blocked
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"perl -MFile::Basename -e 1"}'; run
check "a read-only perl command passes" silent
fresh; echo x >>"$r/a.py"; echo x >>"$r/b.py"; use Bash '{"command":"sed -E -i s/a/b/ a.py"}'; run
check "sed -E -i counts" blocked
fresh; git init -q --bare "$t/up.git"; "${g[@]}" remote add origin "$t/up.git"; "${g[@]}" push -q origin main
"${g[@]}" switch -q -c feature; echo x >>"$r/a.py"; echo x >>"$r/b.py"; "${g[@]}" add .; "${g[@]}" commit -q -m "feat: work"; "${g[@]}" push -q -u origin feature
edit "$r/a.py"; edit "$r/b.py"; run
check "work that was committed and pushed still blocks" blocked
exit $fail
