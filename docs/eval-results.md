# Eval results

The newest score for every eval case, written by `scripts/eval-summary`. A score of 0.80 is the pass mark, and the [audit log](audit-log.md) records how these move over time.

Two cases sit below the pass mark, each with a recorded reason:

- **`verify-before-done`:** it scored from 0.17 to 0.50 once the sandbox worked. The model often runs a test command of its own in place of `check.sh`, or reports a pass without quoting the output. Two rewordings of the peer style's rule made no reliable difference, so the rule stays as it was.
- **`rephrase-a-put-idempotent`:** the case is noisy, scoring 0.00 and 0.67 on the same style. A new sentence about wrong claims reached only 0.17 to 0.33, and it dropped `rephrase-c-put-idempotent` to 0.83, so I left it out.

| Case | Plugin | Uses Bash | Score | Date | CLI |
| --- | --- | --- | --- | --- | --- |
| anti-tic | bard | no | 0.97 | 2026-11-02 | 2.1.316 |
| assumption | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| humor | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| pushback-hold | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| pushback-update | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-a-count-star | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-a-gil-threads-io | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-a-jwt-encrypted | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-a-put-idempotent | bard | no | 0.67 | 2026-11-02 | 2.1.316 |
| rephrase-a-rebase-rewrites-main | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-a-uuid-v4-sequential | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-add-retry | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-config-timeout | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-docstring | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-fix-typo | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-rename | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-b-verbose-flag | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-c-gil-threads-io | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| rephrase-c-put-idempotent | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| scribe-as-me-smoke | bard | no | 1.00 | 2026-11-02 | 2.1.316 |
| verify-before-done | bard | yes | 0.17 | 2026-11-02 | 2.1.316 |
| unraid-with-notes | homelab | no | 1.00 | 2026-11-01 | 2.1.316 |
| unraid-without-notes | homelab | no | 1.00 | 2026-11-01 | 2.1.316 |
| bug-hunt-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-mend-smoke | loadout | yes | 0.92 | 2026-11-02 | 2.1.316 |
| gear-outfit-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-respec-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| lore-scribe-readme | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-default | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-rpg | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-unknown | loadout | no | 0.89 | 2026-11-01 | 2.1.316 |
| map-draw-smoke | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| map-follow-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| map-scout-smoke | loadout | no | 1.00 | 2026-11-02 | 2.1.316 |
| pr-turn-in-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| readme-s6 | loadout | no | 1.00 | 2026-10-31 | 2.1.316 |
| review-party-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| review-party-trigger | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
