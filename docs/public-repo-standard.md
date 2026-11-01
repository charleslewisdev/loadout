# Public repo standard

Every public repo I own meets this list, so nothing needs scrubbing later and licensing stays clear. Apply it top to bottom, and tick each item against the repo. `scripts/check` enforces the items marked **checked**, and the rest need a look at GitHub.

## Publishing

- [ ] A new repo starts private, and goes public only when it's ready.
- [ ] Before it goes public, a full guard scan covers every ref, PR refs included:

  ```
  git fetch origin '+refs/pull/*/head:refs/pr/*'
  GUARD_REQUIRE_DENYLIST=1 ~/code/loadout/guard/scan --all
  ```

## GitHub settings

Check these on the repo's Settings page, or with `gh api`:

| Setting | Endpoint under `repos/<owner>/<repo>` |
| --- | --- |
| Secret scanning and push protection | The repo itself, under `security_and_analysis` |
| Dependabot alerts | `vulnerability-alerts`, where 204 means on |
| Private vulnerability reporting | `private-vulnerability-reporting` |
| Branch protection | `branches/main/protection` |

- [ ] Secret scanning is on.
- [ ] Push protection is on.
- [ ] Dependabot alerts are on.
- [ ] Private vulnerability reporting is on, so the link in `SECURITY.md` works.
- [ ] `main` requires the CI check, and blocks force-pushes.

## CI

- [ ] **Checked:** every workflow sets `permissions:`, and none asks for `write-all`.
- [ ] Those permissions are the least that works.
- [ ] **Checked:** a repo with CI has a workflow, and every action is pinned to a full commit SHA, with the version in a comment.
- [ ] **Checked:** Dependabot keeps those pins current.
- [ ] A binary CI downloads is a pinned version, verified by checksum. A package install pins at least its own version.

## Licensing

- [ ] **Checked:** a `LICENSE`, and `THIRD_PARTY_NOTICES.md` for anything borrowed.
- [ ] **Checked:** `REUSE.toml` says which license covers which paths, and `LICENSES/` holds license texts.
- [ ] CI runs `reuse lint`, which proves each text is there.

## Community files

- [ ] **Checked:** `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` and `SECURITY.md`.
- [ ] **Checked:** issue templates, and a pull request template.
- [ ] GitHub's community profile shows no missing files.
