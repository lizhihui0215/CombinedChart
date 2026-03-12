#!/bin/sh

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION_DEVICE_NAME="iPhone 15"
DESTINATION_OS_VERSION="17.0"
DESTINATION="platform=iOS Simulator,OS=$DESTINATION_OS_VERSION,name=$DESTINATION_DEVICE_NAME"
SCHEME="CombinedChartSampleUITests"
RECORD_FLAG_FILE="$ROOT_DIR/CombinedChartSampleUITests/.record-snapshots"
DEFAULT_ONLY_TESTING="-only-testing:CombinedChartSampleUITests/CombinedChartSnapshotUITests"
RESULT_BUNDLE_PATH="/tmp/combinedchart-snapshot-tests.$$.xcresult"
rm -rf "$RESULT_BUNDLE_PATH"

record_mode=0

if [ "${1:-}" = "--record" ]; then
    record_mode=1
    shift
fi

cleanup() {
    if [ "$record_mode" -eq 1 ]; then
        rm -f "$RECORD_FLAG_FILE"
    fi
}

trap cleanup EXIT INT TERM

if [ "$record_mode" -eq 1 ]; then
    touch "$RECORD_FLAG_FILE"
    echo "Recording snapshots on $DESTINATION_DEVICE_NAME / iOS $DESTINATION_OS_VERSION"
else
    echo "Running snapshot tests on $DESTINATION_DEVICE_NAME / iOS $DESTINATION_OS_VERSION"
fi

cd "$ROOT_DIR"

if [ "$#" -eq 0 ]; then
    set -- "$DEFAULT_ONLY_TESTING"
fi

if ! xcrun simctl list devices available | grep -Fq "$DESTINATION_DEVICE_NAME ("; then
    echo "Snapshot destination $DESTINATION_DEVICE_NAME / iOS $DESTINATION_OS_VERSION is not available on this machine." >&2
    echo "Available simulators:" >&2
    xcrun simctl list devices available | sed 's/^/  /' >&2
    exit 1
fi

set +e
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    "$@"
xcodebuild_status=$?
set -e

python3 - <<'PY' "$RESULT_BUNDLE_PATH" "$record_mode" "$xcodebuild_status"
import json
import subprocess
import sys

result_bundle_path = sys.argv[1]
record_mode = sys.argv[2] == "1"
xcodebuild_status = int(sys.argv[3])
summary = subprocess.check_output(
    [
        "xcrun",
        "xcresulttool",
        "get",
        "test-results",
        "summary",
        "--path",
        result_bundle_path,
        "--compact",
    ],
    text=True,
)
data = json.loads(summary)
count = data.get("totalTestCount", 0)
if count <= 0:
    print(f"No snapshot tests executed. Inspect result bundle: {result_bundle_path}", file=sys.stderr)
    sys.exit(1)

failures = data.get("testFailures", [])
if record_mode:
    real_failures = []
    for failure in failures:
        text = failure.get("failureText", "")
        if "Record mode is on. Automatically recorded snapshot" in text:
            continue
        real_failures.append(
            f"{failure.get('testIdentifierString', failure.get('testName', 'unknown'))}: {text}"
        )

    if real_failures:
        print("Snapshot recording finished with real failures:", file=sys.stderr)
        for failure in real_failures:
            print(f" - {failure}", file=sys.stderr)
        print(f"Inspect result bundle: {result_bundle_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Recorded {count} snapshot tests. Result bundle: {result_bundle_path}")
    sys.exit(0)

if xcodebuild_status != 0:
    print(f"Snapshot verification failed. Inspect result bundle: {result_bundle_path}", file=sys.stderr)
    sys.exit(xcodebuild_status)

print(f"Executed {count} snapshot tests. Result bundle: {result_bundle_path}")
PY
