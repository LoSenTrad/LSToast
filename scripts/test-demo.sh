#!/bin/bash
set -euo pipefail

# UIKit tests require the iOS demo host; plain macOS `swift test` is insufficient.
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ -z "${OUTPUT_DIR:-}" ]]; then
  run_output_dir="$(mktemp -d "${TMPDIR:-/tmp}/LSToast-tests.XXXXXX")"
else
  run_output_dir="$OUTPUT_DIR"
  mkdir -p "$run_output_dir"
  run_output_dir="$(cd "$run_output_dir" && pwd)"
fi

if [[ -e "$run_output_dir/Tests.xcresult" ]]; then
  echo "Refusing to reuse an existing result bundle: $run_output_dir/Tests.xcresult" >&2
  exit 2
fi

simulator_inventory="$run_output_dir/simulators.json"
xcrun simctl list devices available --json > "$simulator_inventory"
# The library/demo run on iOS 15; hosted Swift Testing / ContinuousClock tests need iOS 16.
simulator_id="$(python3 - "$simulator_inventory" "${SIMULATOR_UDID:-}" <<'PY'
import json
import re
import sys
with open(sys.argv[1], encoding="utf-8") as stream:
    inventory = json.load(stream)
candidates = []
for runtime, devices in inventory.get("devices", {}).items():
    version = re.search(r"\.iOS-(\d+)(?:-|$)", runtime)
    if not version or int(version.group(1)) < 16:
        continue
    candidates.extend(device for device in devices
                      if device.get("isAvailable") and device.get("name", "").startswith("iPhone"))
requested = sys.argv[2]
if requested:
    selected = next((device for device in candidates if device["udid"] == requested), None)
    if not selected:
        sys.exit("SIMULATOR_UDID must identify an available iOS 16+ iPhone simulator.")
    print(selected["udid"])
else:
    candidates.sort(key=lambda item: (item.get("state") != "Booted", item["name"], item["udid"]))
    if not candidates:
        sys.exit("No available iOS 16+ iPhone simulator. Install a compatible iOS runtime in Xcode.")
    print(candidates[0]["udid"])
PY
)"

printf 'Output: %s\nSimulator: %s\n' "$run_output_dir" "$simulator_id"
xcodebuild -version
xcrun swift --version
xcodebuild \
  -project Examples/LSToastDemo/LSToastDemo.xcodeproj \
  -scheme LSToastDemo \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$run_output_dir/DerivedData" \
  -resultBundlePath "$run_output_dir/Tests.xcresult" \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | tee "$run_output_dir/xcodebuild.log"
