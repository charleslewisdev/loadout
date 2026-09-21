---
name: harness-status
description: Report the harness's measured state (turn-0 cost, hook timings, memory index sizes, style, last retro). --measure re-runs the measurements.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/status:*)
shell: bash
---

!`${CLAUDE_SKILL_DIR}/status $ARGUMENTS`

Reply with the report above copied exactly, inside one code block, and nothing else. Its last section already says what to do.
