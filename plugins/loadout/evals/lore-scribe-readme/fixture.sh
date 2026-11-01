#!/usr/bin/env bash
# Plants a small CLI repo whose README opens with history and counts, and buries
# what the tool does. A guide already exists for the depth to move to.
set -euo pipefail
mkdir -p docs src
cat >README.md <<'MD'
# tidemark

Tidemark began in March 2024 as a weekend script. Version 2 was rewritten in Go in
early 2025 after the Python version hit its limits. As of October 2026 it has 47
commands, 212 tests, 18 contributors and 1,340 GitHub stars, and it took 8.3 seconds
to process our 40 GB sample on an M3 laptop.

## Architecture

The scanner walks the tree in parallel with a pool of 16 workers. Each worker hashes
files with BLAKE3 and writes rows into a SQLite index under `.tidemark/`. The planner
reads the index, groups rows into 256 buckets and compares them to the last snapshot.

## Every command

| Command | What it does |
| --- | --- |
| `tidemark scan` | Hash the tree and update the index |
| `tidemark diff` | Show what changed since the last snapshot |
| `tidemark snap` | Save a snapshot |
| `tidemark restore` | Restore a file from a snapshot |
| `tidemark prune` | Delete old snapshots |

## Install

`go install example.com/tidemark@latest`

## About

Tidemark tracks what changed in a large directory of files, without git, so people
with media libraries or datasets can see and undo changes.
MD
cat >docs/guide.md <<'MD'
# Tidemark guide

Longer notes for people using Tidemark every day.
MD
echo 'package main' >src/main.go
