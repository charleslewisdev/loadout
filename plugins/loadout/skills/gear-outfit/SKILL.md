---
name: gear-outfit
description: "Recommends settings, plugins and permissions from a few broad questions and your real denials, shows every change, and leaves applying it to you. Typed only."
disable-model-invocation: true
allowed-tools: Edit(~/.config/loadout/outfit-plan.json), Bash(${CLAUDE_SKILL_DIR}/outfit friction), Bash(${CLAUDE_SKILL_DIR}/outfit friction --since *), Bash(${CLAUDE_SKILL_DIR}/outfit keys), Bash(${CLAUDE_SKILL_DIR}/outfit remember *), Bash(${CLAUDE_SKILL_DIR}/outfit recommendations), Bash(${CLAUDE_SKILL_DIR}/outfit show), Bash(${CLAUDE_SKILL_DIR}/outfit review *), Bash(claude auto-mode defaults *), Bash(claude auto-mode config), Bash(claude auto-mode critique)
---

# Outfit the character

Recommend a whole setup, show every change, and stop. **You never apply a plan, and never work around a refusal from `outfit apply`.** The owner runs it, reads the lines it prints, and types the word. If something blocks you, say so and leave it to the owner. Never edit `settings.json` or a machine profile, and never read `settings.json`, because it can hold secrets. `outfit show` gives you what you need.

The script is `${CLAUDE_SKILL_DIR}/outfit`, and running it needs that full path.

This skill's tool grants last only for the turn that invoked it, and clear at the owner's next message. So do all the reading first, and ask everything in one message. Tell the owner the later commands will prompt, and that each is the exact command shown here, so a one-time yes is enough.

## 1. Read the current state

Run `outfit show`, `outfit friction` and `outfit keys`. If `keys` exits 3, tell the owner the reference couldn't be read, and don't say there's nothing new.

## 2. Ask about the setup

Run `outfit recommendations`. Ask in plain language, in one message with the friction and key questions below, and skip a question the current settings already answer or the owner has answered. There are six: autonomy, git and PR freedom, cost versus quality, stack, solo or team, and public or private work. Fill every `<placeholder>` from the owner's answers, because a plan holding one is refused.

## 3. Walk through the friction

Take each label from `outfit friction`, most frequent first. Run `claude auto-mode defaults --label "<label>"` to read that rule, explain in one sentence what it stops, and ask whether the owner wants that decided for them or still wants to be asked. Some rules are worth their prompts, so say so when you think one is, and why.

Two rows aren't rules, so don't look them up. `You rejected a prompt` counts prompts the owner said no to. `No rule named` counts denials that gave no label. The report hides commands, so give the count and ask whether anything comes to mind.

For each one they want loosened, ask what exactly is safe: which organization, host or command. Then propose the narrowest fix that works, in this order:

1. A fact in `autoMode.environment`, such as an organization that also counts as source control, or a host on their network.
2. A `permissions.allow` rule for one exact command shape, never a broad wildcard.
3. An `autoMode.allow` entry, only for an exception the first two can't cover.

Use `add` for these. It keeps `"$defaults"` when it creates a list, and leaves an existing list as it is. They belong to user scope, not a project's settings.

## 4. Ask about new keys

For each key from `outfit keys`, read its entry in the [settings reference](https://code.claude.com/docs/en/settings-reference.md), explain it in plain language, and ask. Record every answer, including "not interested", with `outfit remember <key> "<answer>"`.

`outfit` only writes a fixed list of safe keys. If the owner wants any other key, tell them to edit it by hand. That covers `env`, hooks, helpers, sandbox settings and marketplaces.

## 5. Write and review the plan

Write the plan to `~/.config/loadout/outfit-plan.json`, in the format at the top of the script. Mark a line `"accepted": true` only once the owner has said yes to that line. Give each a `means` that says what can now happen without asking. Run `outfit review <plan>`, adding `--profile <file>` if the owner keeps a private machine profile, and show the output as it is.

Let the owner reject any line, set it to `"accepted": false`, and review again.

## 6. Hand over

Give the owner the command `outfit review` printed, and say to run it in their own terminal. For a line that enables a plugin, also give `claude plugin install <id>`, and name any binary it needs. If `autoMode` changes, say to run `claude auto-mode critique` afterward, because it reads saved rules. A `remove` of a line the installer's profile also carries comes back on the next install, so say so. End there.
