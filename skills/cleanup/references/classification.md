# macOS storage classification

Use this reference after running the bundled audit. Classify only from current evidence; do not reuse old sizes, process state, or installed-app inventories.

## Classes

| Class | Required evidence | Default action |
| --- | --- | --- |
| Safe | Confirmed absent owner or standard rebuildable cache; inactive; exact path known | Offer as a numbered cleanup item |
| Conditional | Active, shared, regenerating, offline, model, simulator, or ambiguous vendor data | Explain the trade-off and request a separate decision |
| Protected | User content, credentials, account/profile database, source, active task data, runtime volume, booted simulator, or uncertain ownership | Do not delete |

Never include Conditional or Protected items in the Safe reclaim total.

Classification and recovery persistence are separate labels:

| Recovery | Meaning | Planning rule |
| --- | --- | --- |
| Durable | Installed component, unused local device, model, offline media, or confirmed residue stays absent until an explicit reinstall or download | May count toward a durable free-space target after its safety gate passes |
| Deferred | macOS or a cloud client may evict local data later or APFS may release physical blocks later | Report as potential recovery, never as immediate guaranteed space |
| Temporary | Cache or build artifact returns through ordinary app, package, build, test, or simulator use | Report the recreation trigger and do not use it alone to promise a durable target |

## Protected by default

- `~/.codex/sessions`: Codex task history.
- `~/.codex/memories`: persistent Codex guidance.
- Source repositories and project working directories.
- Xcode Archives: release artifacts and symbol data.
- Direct contents of `/Library/Developer/CoreSimulator/Volumes`: installed simulator runtime volumes; never remove them with `rm`.
- Booted simulator devices and data used by an active build.
- Keychains, Cookies, Local Storage, IndexedDB, WebStorage, app profiles, and account databases.
- Telegram `postbox/db`; remove only `postbox/media` or temporary data when specifically approved.
- MacWhisper models and `Database/ExternalMedia` unless the user explicitly chooses to remove models or recordings.
- User documents, downloads, media, and cloud-storage files unless the user explicitly selects them.

## Xcode and CoreSimulator

| Item | Class | Rule |
| --- | --- | --- |
| DerivedData | Safe or Conditional | Safe only when no matching Xcode or build process is active; it rebuilds and re-indexes |
| XcodeBuildMCP workspaces | Safe or Conditional | Use modification dates and active process evidence; old inactive workspaces rebuild |
| Archives | Protected | Do not call them cache or remove by default |
| DeviceLogs | Conditional | Offer only with an age and diagnostic-value warning |
| Unavailable simulator devices | Safe after verification | List exact unavailable UDIDs, request approval for those identities, re-list, then delete only each still-unavailable approved UDID; any changed or newly unavailable set requires fresh approval |
| Valid shutdown simulator devices | Conditional | Resolve the active-project keep set and run the repeatable smoke gate when available; deletion permanently loses that device's local apps, data, and state, and recreation starts blank |
| Booted simulator devices | Protected | Never delete or erase during cleanup |
| CoreSimulator dyld caches | Conditional | They can be removed after Xcode/Simulator/CoreSimulator stop, but regenerate |
| Installed runtimes | Conditional through supported tools | Remove only an exact unneeded runtime identifier through Xcode component management or supported `simctl` runtime tooling after dependent devices and the keep set are verified |
| Runtime volume files | Protected | Never direct-delete files or directories from `/Library/Developer/CoreSimulator/Volumes` |
| CoreDevice installation binary deltas | Conditional | Temporary transfer/install cache; require inactive device install/build activity and exact-path approval |
| Xcode Developer Documentation in `AssetsV2` | Conditional managed asset | Inspect and remove only through supported Xcode component/settings management; opening the documentation viewer may download more assets, so do not open it just to measure storage |

Treat a cache that will immediately regenerate as temporary recovery and say so explicitly.

## Removed applications

Classify an app residue as Confirmed only when all applicable checks agree:

1. No matching `.app` exists in `/Applications`, `~/Applications`, or another verified install location.
2. No matching process is active.
3. Bundle identifier, product name, launch entry, receipt, or executable maps the path reliably to that app.
4. The path is not a shared vendor directory or shared container used by another installed edition.

Treat these as Conditional:

- Stable/Beta sibling data where either edition remains installed.
- Vendor directories such as `Adobe`, `Google`, or generic Electron/Hermes storage.
- Group containers or helper tools shared by more than one app.
- Missing launch executable when unrelated support directories cannot be mapped reliably.

For system launch entries and helpers, verify both the plist label and resolved executable. Request administrator approval only during the cleanup phase and only for exact paths.

## Installed-app caches

Usually Safe after the owning application is closed:

- `~/Library/Caches/<bundle-or-product>`.
- Chromium/Electron `Cache`, `Code Cache`, `GPUCache`, Dawn caches, and clearly named component download caches.
- Logs and crash reports that are not needed for an active investigation.
- Xcode DerivedData from inactive builds.

Conditional because they may remove offline behavior or require re-download:

- Service Worker `CacheStorage`.
- Spotify persistent cache and offline media.
- Telegram `postbox/media` and app temporary directories.
- Speech, simulator, and application models.
- Package-manager caches when active builds depend on them.

Partition package-manager storage before classification. For example, npm `_cacache` is a regenerating download cache while `_npx` can contain a currently executing tool. Use supported cache commands when available and do not delete a sibling directory merely because it shares a package-manager root.

## Photos and cloud storage

| Item | Class | Rule |
| --- | --- | --- |
| Photos library database, thumbnails, edits, and metadata | Protected | Required local library state; Optimize Mac Storage does not promise to remove it |
| Locally cached Photos originals | Deferred | Verify iCloud Photos sync is complete and Optimize Mac Storage is enabled in the Photos UI; macOS evicts originals under storage pressure on its own schedule, so no immediate size or timing promise |
| Cloud Photos objects | Protected | Never delete photos or videos from the library to reclaim only local disk space; deletion syncs to other devices |
| Downloaded iCloud Drive file | Conditional/Deferred | Use the supported Remove Download action only when sync is complete; preserve the cloud object |
| Cloud file or folder deletion | Protected | Deletion is not local eviction and can propagate to the cloud and other devices |

Report the whole Photos library separately from originals, resources, scopes, database, and thumbnails when visible. These sizes can overlap; do not add them as independent reclaim totals.

Do not treat these as ordinary cache:

- Profiles, Preferences, Cookies, Keychains, Local Storage, IndexedDB, WebStorage, databases, extensions, bookmarks, or account metadata.
- Application Support directories whose internal ownership has not been inspected.

## Approval and verification

Before cleanup, show:

- Numbered item and exact absolute target.
- Current size and confidence.
- Expected effect and whether data regenerates.
- Applications or services that must stop.
- Whether deletion is permanent or recoverable.

Accept approval only when it names items or unambiguously selects numbered rows. Set-wide deletion commands are not valid substitutes for exact approved identities. Recheck existence, size, and active use immediately before deletion.

After cleanup:

- Recheck each exact target.
- Recheck protected data when it was adjacent to a cleaned target.
- Restart only applications the user approved stopping and verify they run.
- Compare free space in consistent units.
- Report permission failures, partial removal, and macOS metadata stubs.
- Explain that Storage categories can lag and caches can regenerate.
