# Lens: public readiness

Hold the repo to `standard.md` in the facts directory, item by item. That file is the checklist, and it was written for one owner's repos, so its paths mean the same thing here.

- Tree items: read the snapshot. Each workflow's `permissions:`, every `uses:` pinned to a full commit SHA, the Dependabot config, `LICENSE`, `REUSE.toml`, the community files and templates.
- Settings items: read `settings.txt`.
- Publishing items: read `guard.txt`, which scans every ref it could reach, and says if remote refs couldn't be fetched.
- With `visibility` not public, this lens is asking whether the repo could go public, so say that.

Report each unmet item once, naming the item. List items you can't judge, such as an `unavailable` setting, under what you couldn't check.
