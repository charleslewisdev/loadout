# Eval results

The newest score for every eval case, written by `scripts/eval-summary --untrusted-since 2026-10-03`. A score of 0.80 is the pass mark, and the [audit log](audit-log.md) records how these move over time.

**Not trusted** means the case gives the model Bash, and Bash has failed inside the eval sandbox on my machine since October 2026. Those scores mean nothing in either direction: one case scored 1.00 with every command failing. They need a machine where the sandbox works.

| Case | Plugin | Uses Bash | Score | Date | CLI |
| --- | --- | --- | --- | --- | --- |
| anti-tic | bard | no | 0.94 | 2026-11-01 | 2.1.316 |
| assumption | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| humor | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| pushback-hold | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| pushback-update | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-count-star | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-gil-threads-io | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-jwt-encrypted | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-put-idempotent | bard | no | 0.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-rebase-rewrites-main | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-a-uuid-v4-sequential | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-b-add-retry | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-b-config-timeout | bard | no | 0.50 | 2026-11-01 | 2.1.316 |
| rephrase-b-docstring | bard | no | 0.83 | 2026-11-01 | 2.1.316 |
| rephrase-b-fix-typo | bard | no | 0.50 | 2026-11-01 | 2.1.316 |
| rephrase-b-rename | bard | no | 0.67 | 2026-11-01 | 2.1.316 |
| rephrase-b-verbose-flag | bard | no | 0.83 | 2026-11-01 | 2.1.316 |
| rephrase-c-gil-threads-io | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| rephrase-c-put-idempotent | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| scribe-as-me-smoke | bard | no | 1.00 | 2026-11-01 | 2.1.316 |
| verify-before-done | bard | yes | not trusted | 2026-11-01 | 2.1.316 |
| bug-hunt-smoke | loadout | yes | not trusted | 2026-10-30 | 2.1.312 |
| gear-mend-smoke | loadout | yes | not run | | |
| gear-respec-smoke | loadout | yes | not run | | |
| map-draw-smoke | loadout | no | 0.33 | 2026-11-01 | 2.1.316 |
| map-follow-smoke | loadout | yes | not trusted | 2026-10-30 | 2.1.312 |
| map-scout-smoke | loadout | no | 0.50 | 2026-11-01 | 2.1.316 |
| pr-turn-in-smoke | loadout | yes | not trusted | 2026-10-30 | 2.1.312 |
| readme-s6 | loadout | no | 1.00 | 2026-10-31 | 2.1.316 |
| review-party-smoke | loadout | yes | not run | | |
| review-party-trigger | loadout | yes | not trusted | 2026-10-30 | 2.1.312 |
