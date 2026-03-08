@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartViewportDerivedStateTests: XCTestCase {
    func testPagerStateUsesFullyVisibleRangeForHighlight() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 4,
            contentOffsetX: 400,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleMonthRange, 4...7)
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2025")
        XCTAssertEqual(pagerState.currentYearRange?.id, "2025")
    }

    func testPagerStateFallsBackToCurrentRangeWhenWindowSpansYears() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 6),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 6)
            ],
            dataCount: 12,
            monthsPerPage: 4,
            startIndex: 4,
            contentOffsetX: 400,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleMonthRange, 4...7)
        XCTAssertEqual(pagerState.currentYearRange?.id, "2024")
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
    }

    func testPagerStateKeepsCurrentStartBeforeUnitProgressReachesThreshold() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 0,
            contentOffsetX: 66,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleStartIndex, 0)
        XCTAssertEqual(pagerState.visibleMonthRange, 0...3)
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
    }

    func testPagerStateAdvancesWhenUnitProgressReachesThreshold() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 0,
            contentOffsetX: 67,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleStartIndex, 1)
        XCTAssertEqual(pagerState.visibleMonthRange, 1...4)
    }

    func testPagerStateRangeReturnsNilWhenIndexIsOutOfBounds() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 0,
            contentOffsetX: 0,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.range(at: 0)?.id, "2024")
        XCTAssertEqual(pagerState.range(at: 1)?.id, "2025")
        XCTAssertNil(pagerState.range(at: -1))
        XCTAssertNil(pagerState.range(at: 2))
    }

    func testPagerStateUsesConfigurableVisibleStartThreshold() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 0,
            contentOffsetX: 40,
            unitWidth: 100,
            visibleStartThreshold: 0.5)

        XCTAssertEqual(pagerState.visibleStartIndex, 0)
        XCTAssertEqual(pagerState.visibleMonthRange, 0...3)
    }

    func testPagerStateUsesConfigurableVisibleStartThresholdToAdvanceLater() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            startIndex: 0,
            contentOffsetX: 55,
            unitWidth: 100,
            visibleStartThreshold: 0.5)

        XCTAssertEqual(pagerState.visibleStartIndex, 1)
        XCTAssertEqual(pagerState.visibleMonthRange, 1...4)
    }
}
