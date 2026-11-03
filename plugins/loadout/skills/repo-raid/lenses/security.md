# Lens: security

Find what would let someone in, or leak something out, in the repo as it stands.

- **Secrets:** `guard.txt` in the facts directory scans every ref it could reach, and says what it couldn't. Then search the tree for credentials, private keys and committed `.env` files. Name the file and line, never the value.
- **Dependencies:** lockfiles missing or ignored, a dependency installed from a mutable URL, and the open alert counts in `settings.txt`.
- **CI:** under `.github/workflows/`: broad or missing `permissions:`, actions not pinned to a commit, `pull_request_target` running code from a fork, and untrusted input expanded into a shell.
- **GitHub settings:** `settings.txt`, against what a repo of this visibility needs. An `unavailable` value is a gap to report under Not checked, never a finding.
- **Code:** injection, unsafe deserialization, path traversal, and missing authorization at a real entry point.

Give each finding a way in: who can reach it, and what they get. A guard email finding is a finding only when the address looks private or unintended.
