#!/bin/sh

set -eu

if [ "$(uname -m)" = "arm64" ]; then
    PATH="/opt/homebrew/bin:$PATH"
    export PATH
fi

run_checks="${COMBINED_CHART_RUN_CODE_QUALITY:-}"
apply_fixes="${COMBINED_CHART_APPLY_CODE_STYLE:-}"
ci_mode="${CI:-}"

if [ "$run_checks" != "1" ] && [ -z "$ci_mode" ]; then
    echo "Skipping SwiftFormat/SwiftLint. Set COMBINED_CHART_RUN_CODE_QUALITY=1 to enable."
    echo "Set COMBINED_CHART_APPLY_CODE_STYLE=1 to allow source mutations."
    exit 0
fi

if command -v swiftformat >/dev/null 2>&1; then
    if [ "$apply_fixes" = "1" ]; then
        echo "Running SwiftFormat..."
        swiftformat "$SRCROOT" --verbose
    else
        echo "Skipping SwiftFormat writes. Set COMBINED_CHART_APPLY_CODE_STYLE=1 to enable."
    fi
else
    echo "warning: SwiftFormat not installed"
fi

if command -v swiftlint >/dev/null 2>&1; then
    if [ "$apply_fixes" = "1" ]; then
        echo "Running SwiftLint autocorrect..."
        swiftlint --fix --config "$SRCROOT/.swiftlint.yml"
    fi

    echo "Running SwiftLint..."
    swiftlint --config "$SRCROOT/.swiftlint.yml"
else
    echo "warning: SwiftLint not installed"
fi
