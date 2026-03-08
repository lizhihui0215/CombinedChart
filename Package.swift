// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CombinedChart",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
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
            path: "CombinedChartSample/CombinedChartSample/Tests/CombinedChartFrameworkTests")
    ])
