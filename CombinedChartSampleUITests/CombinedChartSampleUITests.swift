//
//  CombinedChartSampleUITests.swift
//  ScrollChatTestUITests
//
//  Created by Bernard on 2026/2/13.
//
import SnapshotTesting
import UIKit
import XCTest

final class CombinedChartSampleUITests: XCTestCase {
    var shouldRecordSnapshots: Bool = false

    private enum SnapshotScenario {
        case totalTrendDefault
        case breakdownByPage

        var snapshotName: String {
            switch self {
            case .totalTrendDefault:
                "combined-chart.total-trend.default"
            case .breakdownByPage:
                "combined-chart.breakdown.by-page"
            }
        }

        var launchArguments: [String] {
            switch self {
            case .totalTrendDefault:
                []
            case .breakdownByPage:
                [
                    "-snapshot-selected-tab", "breakdown",
                    "-snapshot-drag-mode", "byPage"
                ]
            }
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCombinedChartDefaultSnapshot() throws {
        try assertSnapshot(for: .totalTrendDefault)
    }

    @MainActor
    func testCombinedChartBreakdownByPageSnapshot() throws {
        try assertSnapshot(for: .breakdownByPage)
    }
}

private extension CombinedChartSampleUITests {
    @MainActor
    func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-snapshot-disable-animations",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ] + arguments
        app.launch()
        XCTAssertTrue(app.otherElements["combined-chart-root"].waitForExistence(timeout: 5))
        sleep(1)
        return app
    }

    @MainActor
    private func assertSnapshot(for scenario: SnapshotScenario) throws {
        let app = launchApp(arguments: scenario.launchArguments)
        let image = try snapshotImage(for: app)
        try assertRecordedSnapshot(image, named: scenario.snapshotName)
    }

    @MainActor
    func snapshotImage(for app: XCUIApplication) throws -> UIImage {
        let screenshot = app.otherElements["combined-chart-root"].screenshot()
        return try XCTUnwrap(UIImage(data: screenshot.pngRepresentation))
    }

    func assertRecordedSnapshot(_ image: UIImage, named name: String) throws {
        if shouldRecordSnapshots {
            withSnapshotTesting(record: .all) {
                SnapshotTesting.assertSnapshot(of: image, as: .image, named: name)
            }
        } else {
            SnapshotTesting.assertSnapshot(of: image, as: .image, named: name)
        }
    }
}
