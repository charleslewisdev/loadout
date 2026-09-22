#!/usr/bin/env bash
# Plants a small checkout shaped like the loadout repository, with no remote, for
# the harness skills' cases.
set -euo pipefail
git init -q -b main .
git config user.name Dev
git config user.email dev@localhost
mkdir -p .claude-plugin plugins/loadout/.claude-plugin plugins/loadout/hooks plugins/loadout/statusline retros/friction scripts
printf '{"name":"loadout","owner":{"name":"dev"},"plugins":[{"name":"loadout","source":"./plugins/loadout"}]}\n' >.claude-plugin/marketplace.json
printf '{"name":"loadout","version":"0.1.0"}\n' >plugins/loadout/.claude-plugin/plugin.json
printf '#!/usr/bin/env bash\n# Prints one line per segment.\necho "model | branch | branch"\n' >plugins/loadout/statusline/statusline.sh
printf '#!/usr/bin/env bash\necho "lint-budgets: 0 failed"\n' >scripts/lint-budgets
chmod +x plugins/loadout/statusline/statusline.sh scripts/lint-budgets
printf '2026-09-01 the notify hook fires twice after a compaction -> logged (none)\n' >retros/friction/2026-09-01-notify-twice.md
git add -A && git commit -q -m "chore: start"
