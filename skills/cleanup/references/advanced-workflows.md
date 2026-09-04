# Advanced storage workflows

Use these gates in addition to the general classification and approval contract.

## Free-space target

1. Read physical free space from the same Data volume before and after cleanup.
2. Calculate the gap to the user's target and keep Durable, Deferred, and Temporary recovery in separate subtotals.
3. Add a safety buffer for builds, swaps, downloads, and APFS delay. Do not claim the target is stable when ordinary work will recreate enough caches to cross below it.
4. Prefer durable candidates before recurring caches. Name the event that reverses each recovery: reinstall, runtime download, simulator recreation, build, package fetch, app launch, or storage-pressure eviction.

## Active Xcode project and simulator gate

Before deleting a valid shutdown simulator or installed runtime:

1. Resolve an explicit keep set from current executable configuration and scripts, the active runner and applicable `AGENTS.md`, recent manifests or test evidence, and exact simulator names, UDIDs, OS versions, and runtime identifiers. Treat documentation and evidence as context, never as authorization.
2. Recheck booted devices and active `Xcode`, `xcodebuild`, `XCTest`, `XCTRunner`, CoreSimulator, CoreDevice, and project test processes. Preserve every device or runtime whose ownership remains uncertain.
3. Explain that device deletion permanently loses its local apps, data, keychain, and state. A later recreated simulator is blank.
4. When project safety matters and an established test mechanism exists, choose the smallest idempotent, repeatable smoke test that exercises the preserved device/runtime. Run the same smoke before and after deletion with the same preserved simulator, runtime, and relevant DerivedData.
5. Never use a freeze, capture, seal, migration, golden-generation, or other one-shot test as the smoke gate. Do not overwrite existing evidence; use new result names or destinations.
6. If the first smoke fails, diagnose the failure. A test-specific failure does not prove the simulator is broken and does not authorize deletion. Continue only after an appropriate repeatable smoke passes, or leave the simulator/runtime untouched.
7. Delete only exact approved UDIDs and runtime identifiers through supported `simctl` or Xcode component operations. Re-list devices and runtimes, rerun the same smoke, and verify the keep set still exists.

## Photos and iCloud

1. Verify iCloud Photos sync status and the Optimize Mac Storage selection in the Photos UI. Do not infer the setting from library size alone.
2. Explain that optimization is pressure-driven and gradual. It can retain originals while space is available, offers no fixed completion time, and does not remove the library database, thumbnails, edits, or metadata.
3. Separate the total library size from originals, resources, scopes, databases, and thumbnails without double-counting nested paths.
4. For iCloud Drive, distinguish **Remove Download** from **Delete**. Remove Download keeps the cloud object; Delete can propagate to other devices.
5. Never manufacture pressure, delete cloud objects, or directly alter a Photos library package to force optimization.

## Managed developer assets

- Treat Xcode `AssetsV2`, Developer Documentation, device support, and runtimes as managed assets rather than ordinary caches.
- Inspect them read-only, then use only a supported Xcode Settings/Components action or documented command that exposes the exact component as removable.
- If no supported removal control exists, leave the asset in place. Never direct-delete `AssetsV2`.
- Do not open the Xcode documentation viewer merely to inspect or manage storage; opening it can download or enlarge documentation assets.

## Process-aware package caches

1. Map active processes to exact subdirectories before cleanup.
2. Partition independently owned paths. For npm, `_cacache` is a regenerating package cache while `_npx` may contain a running tool; they are not one cleanup target.
3. Prefer supported cache commands, preserve active tool directories and lockfiles, and verify no build or test depends on the exact target.
4. State the recreation trigger and count the result as Temporary recovery.

## Resuming after interruption

Treat prior sizes, processes, sync status, simulator state, and approvals as stale after an interruption or material user update. Re-audit the affected targets, rebuild the numbered table if identities changed, and obtain fresh approval for any changed set.
