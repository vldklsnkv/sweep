# Sweep

Sweep is a local Codex plugin for auditing and safely cleaning macOS storage.
It packages the existing `macos-storage-cleanup` workflow as
`$sweep:cleanup`.

## Safety contract

1. Audit is read-only.
2. Findings are classified as Safe, Conditional, or Protected.
3. Sweep stops and asks for approval of numbered exact targets.
4. Cleanup starts only after that separate approval and rechecks every target.
5. Protected data such as Codex history, projects, credentials, Xcode Archives,
   booted simulators, and runtime volumes is preserved by default.

Logical `du` size and physical `df` recovery are reported separately because
APFS clones and shared blocks can make them differ.

## Verification

```sh
python3 -m unittest discover -s tests -v
```
