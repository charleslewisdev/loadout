# Eval results

The newest score for every eval case, written by `scripts/eval-summary`. A score of 0.80 is the pass mark, and the [audit log](audit-log.md) records how these move over time. Evals pin Sonnet 5, and the table shows the newest run whatever its model. The table's dates are UTC, so a run on a US evening shows the next day.

Two cases sit below the pass mark on Sonnet 5, each with a recorded reason:

- **`verify-before-done`:** 0.27 on Sonnet 5 and 1.00 on Opus 5.5, 10 runs each on November 2, 2026. The grader now asks three questions: did tests run after the last edit, did the run use `check.sh`, and do the reply's claims match the output. Sonnet 5 ran tests after its edit in 6 of 10 runs, used `check.sh` in none, and backed its claims in 2. Opus 5.5 passed all three in every run. Two rewordings of the peer style's rule made no reliable difference on Sonnet 5, so the rule stays as it was, and a Stop hook that enforces it isn't built.
- **`map-scout-portfolio-quiet`:** ten runs score 0.77 on Sonnet 5, because 6 of 10 replies add a line such as "no related repos". None named a repo as a hit. On Opus 5.5, `stayed-quiet` passed 10 of 10, and the case scored 0.83. Three rewordings moved Sonnet 5 from 1 clean reply in 6 to about 4 in 10, and no further.

Two cases moved on November 2, 2026, in 10 runs per model:

- **`rephrase-a-put-idempotent`** scored 1.00 on Opus 5.5. It had scored 0.00 and 0.67 in three-run batches on Sonnet 5, so its earlier low score was noise in a short batch on the pinned model.
- **`map-scout-smoke`** scored 0.65 on Opus 5.5, because the judge counted "or is it a mix?" as a second question. With criteria that count a same-choice follow-up as one question, it scored 0.90 on Opus 5.5 and 1.00 on Sonnet 5.

The two `map-scout-twin-*` cases check that grader. Each makes the model echo a fixed bad reply, one with two questions on different topics and one that only offers to start. Each should score 0.50: the echo passes, and the grader fails the reply. Both did, in 5 runs each.

`gear-heal` and `repo-raid` rows show Opus 5.5. On Sonnet 5, all three `gear-heal` cases scored 1.00, `repo-raid-clean` 1.00, and `repo-raid-planted` 0.96, where one run of three dropped a planted finding at verification. Each ran three times on each model. `gear-heal` ran with `--disallow-tools Agent`, because the review gate otherwise starts a full review inside the run, and it grades its edits with regexes, because judges failed correct work there. `repo-raid` ran with subagents on. Judges ran on Sonnet.

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
| rephrase-a-put-idempotent | bard | no | 1.00 | 2026-11-03 | 2.1.316 |
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
| verify-before-done | bard | yes | 0.27 | 2026-11-03 | 2.1.316 |
| unraid-with-notes | homelab | no | 1.00 | 2026-11-01 | 2.1.316 |
| unraid-without-notes | homelab | no | 1.00 | 2026-11-01 | 2.1.316 |
| bug-hunt-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-heal-harness | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-heal-publish | loadout | yes | 0.95 | 2026-11-02 | 2.1.316 |
| gear-heal-repo | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-mend-smoke | loadout | yes | 0.92 | 2026-11-03 | 2.1.316 |
| gear-outfit-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| gear-respec-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| lore-scribe-readme | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-default | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-rpg | loadout | no | 1.00 | 2026-11-01 | 2.1.316 |
| lore-scribe-voice-unknown | loadout | no | 0.89 | 2026-11-01 | 2.1.316 |
| map-draw-smoke | loadout | no | 1.00 | 2026-11-02 | 2.1.316 |
| map-follow-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| map-scout-portfolio-live | loadout | yes | 0.89 | 2026-11-02 | 2.1.316 |
| map-scout-portfolio-map | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| map-scout-portfolio-quiet | loadout | yes | 0.77 | 2026-11-02 | 2.1.316 |
| map-scout-portfolio-record | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| map-scout-smoke | loadout | no | 1.00 | 2026-11-03 | 2.1.316 |
| map-scout-twin-offer-only | loadout | no | 0.50 | 2026-11-03 | 2.1.316 |
| map-scout-twin-two-questions | loadout | no | 0.50 | 2026-11-03 | 2.1.316 |
| pr-turn-in-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| readme-s6 | loadout | no | 1.00 | 2026-10-31 | 2.1.316 |
| repo-raid-clean | loadout | yes | 1.00 | 2026-11-03 | 2.1.316 |
| repo-raid-planted | loadout | yes | 1.00 | 2026-11-03 | 2.1.316 |
| review-party-smoke | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
| review-party-trigger | loadout | yes | 1.00 | 2026-11-02 | 2.1.316 |
