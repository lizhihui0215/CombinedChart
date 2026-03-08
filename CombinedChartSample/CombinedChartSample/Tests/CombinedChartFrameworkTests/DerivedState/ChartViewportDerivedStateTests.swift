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
            unitWidth: 100)

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
            unitWidth: 100)

        XCTAssertEqual(pagerState.visibleMonthRange, 4...7)
        XCTAssertEqual(pagerState.currentYearRange?.id, "2024")
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
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
            unitWidth: 100)

        XCTAssertEqual(pagerState.range(at: 0)?.id, "2024")
        XCTAssertEqual(pagerState.range(at: 1)?.id, "2025")
        XCTAssertNil(pagerState.range(at: -1))
        XCTAssertNil(pagerState.range(at: 2))
    }
}
