// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CombinedChart",
    // CombinedChartFramework currently supports iOS only; macOS is not supported.
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CombinedChartFramework",
            targets: ["CombinedChartFramework"])
    ],
    targets: [
        .target(
            name: "CombinedChartFramework",
            path: "CombinedChartSample/CombinedChartSample/Sources/CombinedChartFramework"),
        .testTarget(
            name: "CombinedChartFrameworkTests",
            dependencies: ["CombinedChartFramework"],
            path: "CombinedChartSample/CombinedChartFramework/Tests/CombinedChartFrameworkTests")
    ])
