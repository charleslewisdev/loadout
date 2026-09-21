---
name: plan-brainstorm
description: "Turns an open feature or design idea into a decision: one question at a time, two or three approaches compared, the choice recorded. Use when requirements are still open."
---

# Brainstorm a design

Take an open idea to a recorded decision through a short conversation. The person decides; you ask, compare and write it down.

## 1. Look before asking

Read what already exists: the relevant code, docs and recent commits. Never ask what the repository can answer.

## 2. One question per message

- Ask exactly one question, then stop and wait for the answer. Several open points take several turns.
- Ask first what changes the design most: purpose and users, then constraints, then what success looks like.
- When the answer space is small, offer two to four labeled options, mark the one you would pick, and give a one-line reason.
- Skip any question whose answer would not change what gets built.

## 3. Compare two or three approaches

Once purpose, constraints and success are clear, lay out two or three approaches. For each: how it works in two sentences, what it costs, what it rules out. Lead with the one you recommend and say why. Leave out features nobody asked for.

## 4. Confirm the design in sections

Present the chosen design in short sections (the parts, the data flow, failure handling, how it is tested) and ask after each whether it holds before writing the next. Go back when an answer changes an earlier choice.

## 5. Record the decision

Write the result to `docs/plans/<yyyy-mm-dd>-<topic>-design.md`, unless the project keeps decisions elsewhere:

- the decision in one sentence
- the approaches considered, and why the others lost
- the design, section by section
- what is out of scope
- questions still open, if any

Commit it once the person agrees. For multi-step work, the next step is `/loadout:plan-write`.
