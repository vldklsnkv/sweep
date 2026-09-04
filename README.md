# Sweep

Sweep is a local Codex plugin for understanding and safely reducing macOS storage usage. It is designed for situations where “System Data,” Xcode, simulators, Photos, package caches, managed developer assets, or abandoned files consume significant space but broad cleanup commands would be too risky.

Sweep always separates investigation from deletion. An audit is read-only; cleanup begins only after the user approves exact numbered targets in a separate message.

## What Sweep audits

- Large directories and rebuildable caches.
- Xcode Derived Data, device support, archives, and related developer storage.
- CoreSimulator devices, caches, logs, and runtime-related storage.
- Residue from applications that may no longer be installed.
- Local application caches and temporary data.
- Differences between logical file size and physically recoverable disk space.
- Durable recovery versus temporary cache relief and deferred cloud/APFS recovery.
- Photos/iCloud local-storage behavior and managed Xcode assets.

Sweep investigates ambiguous ownership before classifying an item. A large path is not automatically considered safe to remove.

## Safety classifications

Every finding is assigned one of three classes:

- **Safe** — rebuildable or disposable data with a clear owner and predictable consequence.
- **Conditional** — removable only after a stated condition is checked, such as an inactive process, an unneeded simulator, or confirmed application ownership.
- **Protected** — projects, credentials, account data, Codex history, Xcode Archives, active simulator data, runtime volumes, or other data preserved by default.

The audit presents exact paths, current sizes, consequences, regeneration behavior, and separate totals for Safe and Conditional findings. Protected data is never counted as easy reclaimable space.

Sweep also labels recovery as **Durable**, **Deferred**, or **Temporary**. It does not promise a stable free-space target from caches that ordinary builds, package fetches, simulator launches, or applications will recreate.

## Two-phase workflow

### 1. Read-only audit

Invoke Sweep in a Codex task:

```text
Use $sweep:cleanup to audit my Mac storage safely before proposing any cleanup.
```

Sweep runs its compact audit, investigates uncertain entries, and returns a numbered table. It does not move files, stop applications, request administrator access, or delete anything during this phase.

### 2. Approved cleanup

The user selects exact item numbers in a new message. Sweep then resolves every target again, rechecks its size and ownership, verifies active processes and simulator state, and explains what will be removed and regenerated.

If an application or service must stop, Sweep requests separate approval before terminating it. If ownership changes or remains ambiguous, that target is skipped.

Valid simulator devices and installed runtimes receive an additional active-project gate. Sweep resolves a keep set and, when an established test mechanism exists, uses the same idempotent smoke test before and after exact supported removal. One-shot freeze or evidence-generation tests are never used as the gate.

For Photos and iCloud, Sweep distinguishes local eviction from cloud deletion. Optimize Mac Storage is treated as gradual and pressure-driven, while iCloud Drive's Remove Download action is kept distinct from Delete. Xcode `AssetsV2` and Developer Documentation are managed assets and are never direct-deleted.

## Protected by default

Sweep does not remove source repositories, `~/.codex/sessions`, `~/.codex/memories`, keychains, account databases, Xcode Archives, booted simulator data, or Xcode runtime volumes as ordinary cleanup targets. It avoids broad globs, unresolved environment variables, and set-wide recursive deletion commands.

After cleanup, Sweep verifies each approved target, checks relevant neighboring protected data, and compares free disk space before and after. Logical `du` totals and physical `df` recovery are reported separately because APFS clones, snapshots, and shared blocks can make them differ.

## Limitations

- macOS Storage categories may update slowly after files are removed.
- Rebuildable caches can return when applications or simulators run again.
- Permission errors are reported as missing evidence, not interpreted as proof that a path is absent.
- Application residue is classified only when reliable evidence shows that the owning application is no longer present.

## Development and verification

```sh
python3 -m unittest discover -s tests -v
/bin/zsh -n skills/cleanup/scripts/audit_macos_storage.sh
```

Sweep is released under the MIT License. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
