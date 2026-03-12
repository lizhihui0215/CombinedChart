//
//  CombinedChartSampleUITests.swift
//  ScrollChatTestUITests
//
//  Created by Bernard on 2026/2/13.
//
import SnapshotTesting
import UIKit
import XCTest

private enum SnapshotScenario {
    case totalTrendDefault
    case breakdownByPage
    case totalTrendCharts
    case totalTrendChartsAxisAlignment
    case totalTrendChartsDebugRootPhonePortrait
    case totalTrendChartsScrolledPhonePortrait
    case totalTrendChartsScrolledSelectedPhonePortrait
    case breakdownChartsSelectedPhonePortrait
    case totalTrendCanvasSwiftUI
    case totalTrendCanvasSwiftUIScrolledSelectedPhonePortrait
    case totalTrendCanvasUIKit

    var snapshotName: String {
        switch self {
        case .totalTrendDefault:
            "combined-chart.total-trend.default"
        case .breakdownByPage:
            "combined-chart.breakdown.by-page"
        case .totalTrendCharts:
            "combined-chart.total-trend.charts"
        case .totalTrendChartsAxisAlignment:
            "combined-chart.total-trend.charts-axis-alignment"
        case .totalTrendChartsDebugRootPhonePortrait:
            "combined-chart.total-trend.charts.debug-root.iphone-portrait"
        case .totalTrendChartsScrolledPhonePortrait:
            "combined-chart.total-trend.charts.scrolled.iphone-portrait"
        case .totalTrendChartsScrolledSelectedPhonePortrait:
            "combined-chart.total-trend.charts.scrolled-selected.iphone-portrait"
        case .breakdownChartsSelectedPhonePortrait:
            "combined-chart.breakdown.charts.selected.iphone-portrait"
        case .totalTrendCanvasSwiftUI:
            "combined-chart.total-trend.canvas.swiftui"
        case .totalTrendCanvasSwiftUIScrolledSelectedPhonePortrait:
            "combined-chart.total-trend.canvas.swiftui.scrolled-selected.iphone-portrait"
        case .totalTrendCanvasUIKit:
            "combined-chart.total-trend.canvas.uikit"
        }
    }

    var launchArguments: [String] {
        switch self {
        case .totalTrendDefault:
            []
        case .breakdownByPage:
            [
                "-snapshot-selected-tab", "breakdown",
                "-snapshot-scroll-target-behavior", "byPage"
            ]
        case .totalTrendCharts:
            [
                "-snapshot-rendering-engine", "charts"
            ]
        case .totalTrendChartsAxisAlignment:
            [
                "-snapshot-rendering-engine", "charts",
                "-snapshot-show-debug-overlay"
            ]
        case .totalTrendChartsDebugRootPhonePortrait:
            [
                "-snapshot-rendering-engine", "charts",
                "-snapshot-show-debug-overlay"
            ]
        case .totalTrendChartsScrolledPhonePortrait:
            [
                "-snapshot-rendering-engine", "charts",
                "-snapshot-show-debug-overlay",
                "-snapshot-scroll-target-behavior", "free",
                "-snapshot-visible-start-threshold", "0"
            ]
        case .totalTrendChartsScrolledSelectedPhonePortrait:
            [
                "-snapshot-rendering-engine", "charts",
                "-snapshot-show-debug-overlay",
                "-snapshot-scroll-target-behavior", "free",
                "-snapshot-visible-start-threshold", "0"
            ]
        case .breakdownChartsSelectedPhonePortrait:
            [
                "-snapshot-rendering-engine", "charts",
                "-snapshot-selected-tab", "breakdown",
                "-snapshot-show-debug-overlay"
            ]
        case .totalTrendCanvasSwiftUI:
            [
                "-snapshot-rendering-engine", "canvas",
                "-snapshot-scroll-engine", "swiftUI"
            ]
        case .totalTrendCanvasSwiftUIScrolledSelectedPhonePortrait:
            [
                "-snapshot-rendering-engine", "canvas",
                "-snapshot-scroll-engine", "swiftUI",
                "-snapshot-show-debug-overlay",
                "-snapshot-scroll-target-behavior", "free",
                "-snapshot-visible-start-threshold", "0"
            ]
        case .totalTrendCanvasUIKit:
            [
                "-snapshot-rendering-engine", "canvas",
                "-snapshot-scroll-engine", "uiKit"
            ]
        }
    }

    var elementIdentifier: String {
        switch self {
        case .totalTrendDefault, .breakdownByPage:
            "combined-chart-root"
        case .totalTrendCharts,
             .totalTrendChartsAxisAlignment,
             .totalTrendChartsDebugRootPhonePortrait,
             .totalTrendChartsScrolledPhonePortrait,
             .totalTrendChartsScrolledSelectedPhonePortrait,
             .breakdownChartsSelectedPhonePortrait,
             .totalTrendCanvasSwiftUI,
             .totalTrendCanvasSwiftUIScrolledSelectedPhonePortrait,
             .totalTrendCanvasUIKit:
            "combined-chart-snapshot-card"
        }
    }
}

class CombinedChartUITestCase: XCTestCase {
    static let recordFlagPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent(".record-snapshots")
        .path
    static let snapshotDeviceName = "iPhone 15"
    static let snapshotRuntimeVersionPrefix = "17.0"

    var isRecordingSnapshots: Bool {
        ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" ||
            FileManager.default.fileExists(atPath: Self.recordFlagPath)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
}

final class CombinedChartSnapshotUITests: CombinedChartUITestCase {
    override func invokeTest() {
        if isRecordingSnapshots {
            withSnapshotTesting(record: .all) {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }

    @MainActor
    func testCombinedChartDefaultSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendDefault)
    }

    @MainActor
    func testCombinedChartBreakdownByPageSnapshot() throws {
        try assertScenarioSnapshot(for: .breakdownByPage)
    }

    @MainActor
    func testCombinedChartChartsSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendCharts)
    }

    @MainActor
    func testCombinedChartChartsAxisAlignmentSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendChartsAxisAlignment)
    }

    @MainActor
    func testCombinedChartChartsDebugRootPhonePortraitSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendChartsDebugRootPhonePortrait)
    }

    @MainActor
    func testCombinedChartChartsScrolledPhonePortraitSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendChartsScrolledPhonePortrait) { app in
            try self.prepareScrolledSnapshot(app)
        }
    }

    @MainActor
    func testCombinedChartChartsScrolledSelectedPhonePortraitSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendChartsScrolledSelectedPhonePortrait) { app in
            try self.prepareScrolledAndSelectedSnapshot(app)
        }
    }

    @MainActor
    func testCombinedChartBreakdownChartsSelectedPhonePortraitSnapshot() throws {
        try assertScenarioSnapshot(for: .breakdownChartsSelectedPhonePortrait) { app in
            try self.prepareBreakdownSelectionSnapshot(app)
        }
    }

    @MainActor
    func testCombinedChartCanvasSwiftUISnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendCanvasSwiftUI)
    }

    @MainActor
    func testCombinedChartCanvasSwiftUIScrolledSelectedPhonePortraitSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendCanvasSwiftUIScrolledSelectedPhonePortrait) { app in
            try self.prepareScrolledAndSelectedSnapshot(app)
        }
    }

    @MainActor
    func testCombinedChartCanvasUIKitSnapshot() throws {
        try assertScenarioSnapshot(for: .totalTrendCanvasUIKit)
    }
}

final class CombinedChartInteractionUITests: CombinedChartUITestCase {

    @MainActor
    func testChartsCanScrollHorizontally() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free",
            "-snapshot-visible-start-threshold", "0"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        surface.swipeLeft()
        surface.swipeLeft()

        let predicate = NSPredicate(format: "label != %@", initialOffset)
        expectation(for: predicate, evaluatedWith: offsetValue)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testCanvasCanScrollHorizontally() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "canvas",
            "-snapshot-scroll-engine", "swiftUI",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free",
            "-snapshot-visible-start-threshold", "0"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.25)
        waitForLabelChange(of: offsetValue, from: initialOffset, timeout: 5)
    }

    @MainActor
    func testChartsTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-selected-tab", "totalTrend"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)
        let initialSelection = selectedIndexValue.label

        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45),
                (0.62, 0.32),
                (0.62, 0.58)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }

    @MainActor
    func testChartsBreakdownTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-selected-tab", "breakdown"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)
        let initialSelection = selectedIndexValue.label

        tap(on: surface, xRatio: 0.62, yRatio: 0.45)

        let predicate = NSPredicate(format: "label != %@", initialSelection)
        expectation(for: predicate, evaluatedWith: selectedIndexValue)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testChartsXAxisLabelAlignsWithSelectedIndicator() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-selected-tab", "totalTrend"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)
        let initialSelection = selectedIndexValue.label

        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.24, 0.44),
                (0.28, 0.44),
                (0.20, 0.44),
                (0.24, 0.34),
                (0.24, 0.56)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)

        let label = element(in: app, identifier: "combined-chart-x-axis-label-0")
        let indicator = element(in: app, identifier: "combined-chart-selection-indicator")
        XCTAssertTrue(label.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(indicator.waitForExistence(timeout: 5), app.debugDescription)

        let alignmentDelta = abs(label.frame.midX - indicator.frame.midX)
        XCTAssertLessThanOrEqual(
            alignmentDelta,
            12,
            "Expected first x-axis label to align with the selected indicator, delta=\(alignmentDelta)")
    }

    @MainActor
    func testChartsScrollThenTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-selected-tab", "totalTrend",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.25)
        waitForLabelChange(of: offsetValue, from: initialOffset, timeout: 5)

        let initialSelection = selectedIndexValue.label
        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }

    @MainActor
    func testCanvasScrollThenTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "canvas",
            "-snapshot-scroll-engine", "swiftUI",
            "-snapshot-selected-tab", "totalTrend",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.25)
        waitForLabelChange(of: offsetValue, from: initialOffset, timeout: 5)

        let initialSelection = selectedIndexValue.label
        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }

    @MainActor
    func testChartsBreakdownScrollThenTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-selected-tab", "breakdown",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.25)
        waitForLabelChange(of: offsetValue, from: initialOffset, timeout: 5)

        let initialSelection = selectedIndexValue.label
        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }

    @MainActor
    func testCanvasBreakdownScrollThenTapSelectsPoint() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "canvas",
            "-snapshot-scroll-engine", "swiftUI",
            "-snapshot-selected-tab", "breakdown",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)

        let offsetValue = element(in: app, identifier: "combined-chart-debug-offset-x")
        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        XCTAssertTrue(offsetValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)

        let initialOffset = offsetValue.label
        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.25)
        waitForLabelChange(of: offsetValue, from: initialOffset, timeout: 5)

        let initialSelection = selectedIndexValue.label
        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }

    @MainActor
    func testChartsPagerAdvancesFromCurrentPageBoundaryAfterPartialScroll() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "charts",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        let visibleStartValue = element(in: app, identifier: "combined-chart-debug-visible-start")
        let nextButton = element(in: app, identifier: "combined-chart-pager-next")
        let previousButton = element(in: app, identifier: "combined-chart-pager-previous")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(visibleStartValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(previousButton.waitForExistence(timeout: 10), app.debugDescription)

        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.40)
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "2", timeout: 5)

        nextButton.tap()
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "4", timeout: 5)

        previousButton.tap()
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "0", timeout: 5)
    }

    @MainActor
    func testCanvasPagerAdvancesFromCurrentPageBoundaryAfterPartialScroll() throws {
        let app = launchApp(arguments: [
            "-snapshot-rendering-engine", "canvas",
            "-snapshot-scroll-engine", "swiftUI",
            "-snapshot-show-debug-overlay",
            "-snapshot-scroll-target-behavior", "free"
        ])

        let surface = element(in: app, identifier: "combined-chart-surface")
        let visibleStartValue = element(in: app, identifier: "combined-chart-debug-visible-start")
        let nextButton = element(in: app, identifier: "combined-chart-pager-next")
        let previousButton = element(in: app, identifier: "combined-chart-pager-previous")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(visibleStartValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(previousButton.waitForExistence(timeout: 10), app.debugDescription)

        dragHorizontally(on: surface, fromStartRatio: 0.82, toEndRatio: 0.40)
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "2", timeout: 5)

        nextButton.tap()
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "4", timeout: 5)

        previousButton.tap()
        waitForExpectedLabel(of: visibleStartValue, expectedValue: "0", timeout: 5)
    }
}

fileprivate extension CombinedChartUITestCase {
    var snapshotStrategy: Snapshotting<UIImage, UIImage> {
        .image(precision: 0.995, perceptualPrecision: 0.98)
    }

    @MainActor
    func launchApp(arguments: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += [
            "-snapshot-disable-animations",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ] + arguments
        app.launch()
        let rootElement = element(in: app, identifier: "combined-chart-root")
        XCTAssertTrue(rootElement.waitForExistence(timeout: 10), app.debugDescription)
        sleep(1)
        return app
    }

    @MainActor
    func assertScenarioSnapshot(
        for scenario: SnapshotScenario,
        prepare: ((XCUIApplication) throws -> Void)? = nil) throws {
        let app = launchApp(arguments: scenario.launchArguments)
        try prepare?(app)
        let image = try snapshotImage(for: app, elementIdentifier: scenario.elementIdentifier)
        try assertRecordedSnapshot(image, named: scenario.snapshotName)
    }

    @MainActor
    func snapshotImage(for app: XCUIApplication, elementIdentifier: String) throws -> UIImage {
        let element = snapshotElement(in: app, identifier: elementIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10), app.debugDescription)
        let screenshot = stableScreenshot(for: app)
        let image = try XCTUnwrap(UIImage(data: screenshot.pngRepresentation))
        return try cropSnapshotImage(image, to: element.frame, in: app.frame)
    }

    @MainActor
    func snapshotElement(in app: XCUIApplication, identifier: String) -> XCUIElement {
        switch identifier {
        case "combined-chart-root":
            app.scrollViews[identifier].firstMatch
        case "combined-chart-snapshot-card", "combined-chart-surface":
            app.otherElements[identifier].firstMatch
        default:
            element(in: app, identifier: identifier)
        }
    }

    @MainActor
    func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    func stableScreenshot(
        for element: XCUIElement,
        maxAttempts: Int = 6,
        interval: TimeInterval = 0.35) -> XCUIScreenshot {
        var previous = element.screenshot()

        for _ in 0..<maxAttempts {
            Thread.sleep(forTimeInterval: interval)
            let current = element.screenshot()
            if current.pngRepresentation == previous.pngRepresentation {
                return current
            }
            previous = current
        }

        return previous
    }

    func cropSnapshotImage(_ image: UIImage, to frame: CGRect, in referenceFrame: CGRect) throws -> UIImage {
        let cgImage = try XCTUnwrap(image.cgImage)
        let scaleX = CGFloat(cgImage.width) / referenceFrame.width
        let scaleY = CGFloat(cgImage.height) / referenceFrame.height
        let imageBounds = CGRect(origin: .zero, size: CGSize(
            width: cgImage.width,
            height: cgImage.height))

        let cropRect = CGRect(
            x: frame.minX * scaleX,
            y: frame.minY * scaleY,
            width: frame.width * scaleX,
            height: frame.height * scaleY)
            .integral
            .intersection(imageBounds)

        XCTAssertFalse(cropRect.isNull, "Crop rect is outside of the screenshot bounds.")
        XCTAssertGreaterThan(cropRect.width, 0, "Crop rect width must be positive.")
        XCTAssertGreaterThan(cropRect.height, 0, "Crop rect height must be positive.")

        let croppedCGImage = try XCTUnwrap(
            cgImage.cropping(to: cropRect),
            "Unable to crop screenshot image to element frame.")

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: .up)
    }

    @MainActor
    func dragHorizontally(
        on element: XCUIElement,
        fromStartRatio startRatio: CGFloat,
        toEndRatio endRatio: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: startRatio, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: endRatio, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor
    func tap(on element: XCUIElement, xRatio: CGFloat, yRatio: CGFloat) {
        element.coordinate(withNormalizedOffset: CGVector(dx: xRatio, dy: yRatio)).tap()
    }

    @MainActor
    func tapUntilSelectionChanges(
        on element: XCUIElement,
        selectedIndexValue: XCUIElement,
        initialSelection: String,
        candidates: [(CGFloat, CGFloat)],
        waitTimeout: TimeInterval = 1.0) -> Bool {
        for (xRatio, yRatio) in candidates {
            tap(on: element, xRatio: xRatio, yRatio: yRatio)

            let predicate = NSPredicate(format: "label != %@", initialSelection)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: selectedIndexValue)
            if XCTWaiter().wait(for: [expectation], timeout: waitTimeout) == .completed {
                return true
            }
        }

        return false
    }

    func waitForLabelChange(
        of element: XCUIElement,
        from initialValue: String,
        timeout: TimeInterval) {
        let predicate = NSPredicate(format: "label != %@", initialValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed)
    }

    func waitForExpectedLabel(
        of element: XCUIElement,
        expectedValue: String,
        timeout: TimeInterval) {
        let predicate = NSPredicate(format: "label == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed)
    }

    func assertRecordedSnapshot(_ image: UIImage, named name: String) throws {
        SnapshotTesting.assertSnapshot(of: image, as: snapshotStrategy, named: name)
    }

    @MainActor
    func prepareScrolledSnapshot(_ app: XCUIApplication) throws {
        try advanceToNextPage(app)
    }

    @MainActor
    func prepareScrolledAndSelectedSnapshot(_ app: XCUIApplication) throws {
        try prepareScrolledSnapshot(app)
        try ensureSelectionExists(in: app)
    }

    @MainActor
    func prepareBreakdownSelectionSnapshot(_ app: XCUIApplication) throws {
        try ensureSelectionExists(in: app)
    }

    @MainActor
    func advanceToNextPage(_ app: XCUIApplication) throws {
        let visibleStartValue = element(in: app, identifier: "combined-chart-debug-visible-start")
        let nextButton = element(in: app, identifier: "combined-chart-pager-next")
        XCTAssertTrue(visibleStartValue.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), app.debugDescription)

        let initialVisibleStart = visibleStartValue.label
        nextButton.tap()
        waitForLabelChange(of: visibleStartValue, from: initialVisibleStart, timeout: 5)
    }

    @MainActor
    func ensureSelectionExists(in app: XCUIApplication) throws {
        let surface = element(in: app, identifier: "combined-chart-surface")
        let selectedIndexValue = element(in: app, identifier: "combined-chart-debug-selected-index")
        let indicator = element(in: app, identifier: "combined-chart-selection-indicator")
        XCTAssertTrue(surface.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(selectedIndexValue.waitForExistence(timeout: 10), app.debugDescription)

        if indicator.exists || selectedIndexValue.label != "-" {
            return
        }

        let initialSelection = selectedIndexValue.label
        let didSelect = tapUntilSelectionChanges(
            on: surface,
            selectedIndexValue: selectedIndexValue,
            initialSelection: initialSelection,
            candidates: [
                (0.62, 0.45),
                (0.55, 0.45),
                (0.68, 0.45),
                (0.62, 0.32),
                (0.62, 0.58)
            ])

        XCTAssertTrue(didSelect, app.debugDescription)
    }
}
