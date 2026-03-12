#!/bin/bash

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION_DEVICE_NAME="iPhone 15"
DESTINATION_OS_VERSION="17.0"
DESTINATION="platform=iOS Simulator,OS=$DESTINATION_OS_VERSION,name=$DESTINATION_DEVICE_NAME"
SCHEME="CombinedChartFrameworkTests"

echo "Running framework tests on $DESTINATION_DEVICE_NAME / iOS $DESTINATION_OS_VERSION"

cd "$ROOT_DIR"

if ! xcrun simctl list devices available | grep -Fq "$DESTINATION_DEVICE_NAME ("; then
    echo "Framework test destination $DESTINATION_DEVICE_NAME / iOS $DESTINATION_OS_VERSION is not available on this machine." >&2
    echo "Available simulators:" >&2
    xcrun simctl list devices available | sed 's/^/  /' >&2
    exit 1
fi

xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    "$@"
