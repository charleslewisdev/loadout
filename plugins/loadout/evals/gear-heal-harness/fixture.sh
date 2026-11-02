#!/usr/bin/env bash
# Plants a small loadout-like checkout for the gear-heal harness-mode case: a
# marketplace manifest naming loadout, a guide with one stale quote and a claim
# resting on it, a saved copy of the source page, and stub scripts. The quote-check
# stub reports the stale quote until the manifest no longer holds it. No remote.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p .claude-plugin docs/sources plugins/loadout/skills/demo scripts
printf '{"name":"loadout","owner":{"name":"dev"},"plugins":[{"name":"loadout","source":"./plugins/loadout"}]}\n' >.claude-plugin/marketplace.json
cat >WRITING-AN-EFFECTIVE-HARNESS.md <<'MD'
# Writing an effective harness

## 2. Keep the memory file short

The docs say "keep each memory file under 500 lines", so this harness treats 500 lines as a safe size for every memory file.

## 3. Prefer hooks

The docs say "use a hook for anything that must always happen".
MD
cat >docs/sources/memory.md <<'MD'
# Memory

Claude reads memory files at the start of each session. Aim for fewer than 80 lines in each memory file, because longer files lower adherence. Use a hook for anything that must always happen.
MD
printf '# url<TAB>quote\nhttps://code.claude.com/docs/en/memory\tkeep each memory file under 500 lines\nhttps://code.claude.com/docs/en/memory\tuse a hook for anything that must always happen\n' >docs/quotes.tsv
cat >docs/audit-log.md <<'MD'
# Audit log

## 2026-06-01: baseline

**CLI:** 2.1.300.

**Why:** a starting number for later audits.

**What changed:** nothing in the harness.

| Metric | Before | After |
| --- | --- | --- |
| Harness share | 3,300 | 3,300 |
MD
printf -- '---\nname: demo\ndescription: "A demo skill."\n---\n\nDemo.\n' >plugins/loadout/skills/demo/SKILL.md
cat >scripts/quote-check <<'SH'
#!/usr/bin/env bash
if grep -q 'keep each memory file under 500 lines' docs/quotes.tsv; then
  echo 'quote-check: not on the page: https://code.claude.com/docs/en/memory (manifest line 2)'
  exit 1
fi
echo 'quote-check: every quote holds'
SH
stub() { printf '#!/usr/bin/env bash\ncat <<'"'"'OUT'"'"'\n%s\nOUT\n' "$2" >"scripts/$1"; }
stub budget 'harness share     3,300 (auto-memory off minus the floor)
PASS: highest harness share 3,300 is within the 6,000 ceiling'
stub lint-budgets 'lint-budgets: 3 files, 0 failed, 0 warnings'
stub check 'check: all passed'
chmod +x scripts/*
git add -A && git commit -q -m "chore: seed the checkout"
