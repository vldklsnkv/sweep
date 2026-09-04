#!/bin/zsh
set -u
setopt null_glob

compact=0
if [[ "${1:-}" == "--compact" ]]; then
  compact=1
elif [[ -n "${1:-}" ]]; then
  print -r -u2 -- "Usage: ${0:t} [--compact]"
  exit 2
fi

user_home="${HOME}"
user_library="${user_home}/Library"
item_limit=25
(( compact )) && item_limit=12

heading() {
  print -r -- "\n## $1"
}

warn() {
  print -r -- "- WARN: $1"
}

safe_field() {
  local value="$1"
  printf '%q' "$value"
}

size_of() {
  local target="$1"
  local result

  if [[ ! -e "$target" ]]; then
    print -r -- "0B"
    return
  fi

  result="$(du -sh "$target" 2>/dev/null | awk '{print $1}')"
  if [[ -n "$result" ]]; then
    print -r -- "$result"
  else
    print -r -- "permission-denied"
  fi
}

report_path() {
  local label="$1"
  local target="$2"
  print -r -- "- ${label}: $(size_of "$target") — $(safe_field "$target")"
}

list_largest_children() {
  local root="$1"
  local limit="$2"
  local entry size_kib human_size escaped_path
  local -a entries rows

  if [[ ! -d "$root" ]]; then
    print -r -- "- unavailable — $(safe_field "$root")"
    return
  fi

  entries=("$root"/*(N))
  if (( ${#entries[@]} == 0 )); then
    print -r -- "- empty — $(safe_field "$root")"
    return
  fi

  rows=()
  for entry in "${entries[@]}"; do
    size_kib="$(du -sk "$entry" 2>/dev/null | awk '{print $1}')"
    human_size="$(du -sh "$entry" 2>/dev/null | awk '{print $1}')"
    [[ -n "$size_kib" ]] || size_kib=0
    [[ -n "$human_size" ]] || human_size="permission-denied"
    escaped_path="$(safe_field "$entry")"
    rows+=("${size_kib}"$'\t'"${human_size}"$'\t'"${escaped_path}")
  done

  printf '%s\n' "${rows[@]}" | sort -n -k1,1 | tail -n "$limit" |
    while IFS=$'\t' read -r _size human escaped; do
      print -r -- "- ${human} — ${escaped}"
    done
}

plist_value() {
  local plist="$1"
  local key="$2"
  plutil -extract "$key" raw "$plist" 2>/dev/null
}

heading "Disk"
df -h / /System/Volumes/Data 2>/dev/null || warn "Unable to read filesystem usage."

heading "Largest user storage"
report_path "User caches" "${user_library}/Caches"
report_path "Application Support" "${user_library}/Application Support"
report_path "App containers" "${user_library}/Containers"
report_path "Group containers" "${user_library}/Group Containers"
report_path "Developer data" "${user_library}/Developer"
report_path "User model and package caches" "${user_home}/.cache"
report_path "npm storage" "${user_home}/.npm"
report_path "Codex data" "${user_home}/.codex"
report_path "Codex task history (protected)" "${user_home}/.codex/sessions"
report_path "macOS temporary data" "/private/var/folders"

heading "Xcode and simulators"
report_path "DerivedData" "${user_library}/Developer/Xcode/DerivedData"
report_path "Archives (protected by default)" "${user_library}/Developer/Xcode/Archives"
report_path "XcodeBuildMCP workspaces" "${user_library}/Developer/XcodeBuildMCP/workspaces"
report_path "Simulator devices" "${user_library}/Developer/CoreSimulator/Devices"
report_path "CoreSimulator caches" "/Library/Developer/CoreSimulator/Caches"
report_path "Installed simulator runtime volumes (never direct-delete)" "/Library/Developer/CoreSimulator/Volumes"
report_path "CoreDevice installation binary deltas" "${user_library}/Developer/CoreDevice/Caches/AppInstallationBinaryDeltas"
report_path "Xcode managed Developer Documentation" "${user_library}/Developer/Xcode/DocumentationCache"
print -r -- "\n### Active developer processes"
process_output="$(pgrep -ifl 'Xcode|Simulator|CoreSimulator|CoreDevice|xcodebuild|XcodeBuildMCP|xctest|testmanagerd|XCTRunner' 2>&1)"
process_status=$?
if (( process_status == 0 )); then
  while IFS= read -r process_line; do
    print -r -- "- process: $(safe_field "$process_line")"
  done <<< "$process_output"
elif (( process_status == 1 )); then
  print -r -- "- no matching processes visible"
else
  warn "Developer process state is unavailable (pgrep status ${process_status})."
fi
if command -v xcrun >/dev/null 2>&1; then
  print -r -- "\n### Simulator device status"
  xcrun simctl list devices 2>/dev/null || warn "simctl device status is unavailable."
  print -r -- "\n### Installed simulator runtime status"
  xcrun simctl runtime list 2>/dev/null || warn "simctl runtime status is unavailable."
else
  warn "xcrun is unavailable; simulator state was not inspected."
fi

heading "Installed applications"
apps=(/Applications/*.app(N) "${user_home}"/Applications/*.app(N))
if (( ${#apps[@]} == 0 )); then
  print -r -- "- no applications found in standard locations"
else
  for app in "${apps[@]}"; do
    bundle_id="$(plist_value "${app}/Contents/Info.plist" CFBundleIdentifier)"
    [[ -n "$bundle_id" ]] || bundle_id="unreadable-bundle-id"
    print -r -- "- $(safe_field "${app:t:r}") | $(safe_field "$bundle_id") | $(safe_field "$app")"
  done
fi

heading "Application residue signals"
print -r -- "\n### Largest Application Support entries"
list_largest_children "${user_library}/Application Support" "$item_limit"
print -r -- "\n### Largest app containers"
list_largest_children "${user_library}/Containers" "$item_limit"
print -r -- "\n### Largest group containers"
list_largest_children "${user_library}/Group Containers" "$item_limit"
print -r -- "\n### Launch entries with missing executables"
launch_plists=(
  "${user_library}"/LaunchAgents/*.plist(N)
  /Library/LaunchAgents/*.plist(N)
  /Library/LaunchDaemons/*.plist(N)
)
missing_launch_count=0
for plist in "${launch_plists[@]}"; do
  program="$(plist_value "$plist" Program)"
  [[ -n "$program" ]] || program="$(plist_value "$plist" ProgramArguments.0)"
  if [[ "$program" == /* && ! -e "$program" ]]; then
    print -r -- "- $(safe_field "$plist") -> $(safe_field "$program")"
    (( missing_launch_count += 1 ))
  fi
done
(( missing_launch_count > 0 )) || print -r -- "- none found or none readable"

heading "Application caches"
print -r -- "\n### Largest user cache entries"
list_largest_children "${user_library}/Caches" "$item_limit"
print -r -- "\n### Known rebuildable locations"
report_path "Codex UI cache" "${user_library}/Caches/Codex"
report_path "Codex browser cache" "${user_library}/Application Support/Codex/Partitions/codex-browser-app/Cache"
report_path "Codex browser code cache" "${user_library}/Application Support/Codex/Partitions/codex-browser-app/Code Cache"
report_path "Codex temporary task data (conditional)" "${user_home}/.codex/.tmp"
report_path "Xcode DerivedData" "${user_library}/Developer/Xcode/DerivedData"
report_path "CoreSimulator dyld cache" "/Library/Developer/CoreSimulator/Caches"
report_path "npm package cache" "${user_home}/.npm/_cacache"
report_path "npm transient executors (may be active)" "${user_home}/.npm/_npx"
report_path "uv package cache" "${user_home}/.cache/uv"
report_path "Hugging Face model cache" "${user_home}/.cache/huggingface"
report_path "AdGuard logs" "${user_library}/Group Containers/TC3Q7MAJXF.com.adguard.mac/Library/Logs"

heading "Photos and cloud storage"
photos_library="${user_home}/Pictures/Photos Library.photoslibrary"
report_path "Photos library total (protected package)" "$photos_library"
report_path "Photos originals (nested; do not add to total)" "${photos_library}/originals"
report_path "Photos resources (nested; do not add to total)" "${photos_library}/resources"
report_path "Photos scopes (nested; do not add to total)" "${photos_library}/scopes"
report_path "iCloud Drive local data (protected until exact files are reviewed)" "${user_library}/Mobile Documents/com~apple~CloudDocs"
print -r -- "- Verify iCloud sync and Optimize Mac Storage in the Photos UI; optimization is gradual and pressure-driven."
print -r -- "- Use Remove Download for a synced iCloud Drive item; Delete can remove the cloud object."

print -r -- "\n### Related active processes"
cloud_process_output="$(pgrep -ifl 'photolibraryd|photoanalysisd|cloudphotosd|bird|cloudd|npm|uv|MacWhisper|Telegram|Aside|Spotify' 2>&1)"
cloud_process_status=$?
if (( cloud_process_status == 0 )); then
  while IFS= read -r process_line; do
    print -r -- "- process: $(safe_field "$process_line")"
  done <<< "$cloud_process_output"
elif (( cloud_process_status == 1 )); then
  print -r -- "- no matching processes visible"
else
  warn "Photos, cloud, or package process state is unavailable (pgrep status ${cloud_process_status})."
fi

heading "Snapshots"
if command -v tmutil >/dev/null 2>&1; then
  tmutil listlocalsnapshots / 2>/dev/null || warn "Local snapshots are unavailable or permission was denied."
else
  warn "tmutil is unavailable."
fi

heading "Warnings"
print -r -- "- Audit only: no files or processes were changed."
print -r -- "- Protected: ~/.codex/sessions is task history, not cache."
print -r -- "- Protected: /Library/Developer/CoreSimulator/Volumes contains installed runtimes."
print -r -- "- Managed: Xcode AssetsV2 must not be direct-deleted."
print -r -- "- Photos optimization is pressure-driven and does not remove the local library database or thumbnails."
print -r -- "- Cache sizes can regenerate after applications or simulators restart."
print -r -- "- Permission errors are partial results, not proof that a path is absent."
