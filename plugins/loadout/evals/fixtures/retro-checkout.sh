#!/usr/bin/env bash
# Plants a small loadout-like checkout for the harness-retro case: a marketplace
# manifest naming loadout, a friction log with one friction logged twice, and stub
# scripts that print fixed measurements, so the case needs no real transcripts,
# budget runs or Claude calls. No remote.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p .claude-plugin retros/friction scripts plugins/loadout/hooks
printf '{"name":"loadout","owner":{"name":"dev"},"plugins":[{"name":"loadout","source":"./plugins/loadout"}]}\n' >.claude-plugin/marketplace.json
printf '2026-08-02 the formatter rewrote a whole JSON file in a repo that has no prettier config -> logged (none)\n' >retros/friction/2026-08-02-formatter-json.md
printf '2026-08-19 a PR description ended by asking whether to open the PR -> logged (none)\n' >retros/friction/2026-08-19-pr-question.md
printf '2026-09-05 the formatter again rewrote a whole file in another repo without prettier config -> logged (none)\n' >retros/friction/2026-09-05-formatter-again.md
printf '#!/usr/bin/env bash\n# stub formatter hook\nexit 0\n' >plugins/loadout/hooks/format
stub() { printf '#!/usr/bin/env bash\ncat <<'"'"'OUT'"'"'\n%s\nOUT\n' "$2" >"scripts/$1"; chmod +x "scripts/$1"; }
stub budget "harness share     3,400 (auto-memory off minus the floor)
PASS: highest harness share 3,400 is within the 6,000 ceiling"
stub lint-budgets "lint-budgets: 12 files, 0 failed, 0 warnings"
stub hook-report "hook       calls  p50 ms  p95 ms  max ms  killed
format        40    60.0   410.0   900.0       0
notify-stop   80     7.0    11.0    14.0       0"
stub memory-reads "Auto-memory files not read by an interactive session in the last 90 days
  ~-code-app: 2 of 5 files unread
    old-deploy-notes.md
    retired-api-keys-howto.md"
stub retro-evidence "Retro evidence since 2026-06-23: 6 sessions read, 0 skipped (denylist), 3 print-mode runs excluded

## Friction log
- 2026-08-02 the formatter rewrote a whole JSON file in a repo that has no prettier config -> logged (none)
- 2026-08-19 a PR description ended by asking whether to open the PR -> logged (none)
- 2026-09-05 the formatter again rewrote a whole file in another repo without prettier config -> logged (none)

## Skill usage (uses, days since last use)
- loadout:git-pr: 14 uses, 2 days
- loadout:plan-run: 0 uses, 91 days

## Corrections (the author redirecting the model)
- 2026-09-05 ~-code-app: no, revert that, the formatter should not touch files in this repo

## Repeated in two or more sessions"
stub check "check: all passed"
git add -A && git commit -q -m "chore: seed the checkout"
