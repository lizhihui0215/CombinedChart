@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartDerivedStateTests: XCTestCase {
    func testPagerStateUsesFullyVisibleRangeForHighlight() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            visibleStartMonthIndex: 4,
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
            visibleStartMonthIndex: 4,
            contentOffsetX: 400,
            unitWidth: 100)

        XCTAssertEqual(pagerState.visibleMonthRange, 4...7)
        XCTAssertEqual(pagerState.currentYearRange?.id, "2024")
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
    }

    func testChartDerivedStateBuildsExpectedAxisDomainAndLabel() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [
                    .liabilities: 10,
                    .saving: 20,
                    .investment: 5
                ]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [
                    .liabilities: 4,
                    .saving: 12
                ])
        ]

        let derivedState = CombinedChartView.ChartDerivedState(
            config: config,
            sortedGroups: [ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, points: data)],
            data: data,
            startIndex: 1,
            contentOffsetX: 100,
            unitWidth: 100)

        XCTAssertTrue(derivedState.hasData)
        XCTAssertEqual(derivedState.viewport.visibleStartLabel, "Feb")
        XCTAssertEqual(derivedState.axisPointInfos.count, 2)
        XCTAssertEqual(derivedState.yDomain.lowerBound, -13.5)
        XCTAssertEqual(derivedState.yDomain.upperBound, 28.5)
        XCTAssertEqual(derivedState.yAxisTickValues, [-30, -24, -18, -12, -6, 0, 6, 12, 18, 24, 30])
        XCTAssertEqual(derivedState.yAxisDisplayDomain, -30.06...30.06)
    }

    func testPagerStateRangeReturnsNilWhenIndexIsOutOfBounds() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, monthCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, monthCount: 4)
            ],
            dataCount: 8,
            monthsPerPage: 4,
            visibleStartMonthIndex: 0,
            contentOffsetX: 0,
            unitWidth: 100)

        XCTAssertEqual(pagerState.range(at: 0)?.id, "2024")
        XCTAssertEqual(pagerState.range(at: 1)?.id, "2025")
        XCTAssertNil(pagerState.range(at: -1))
        XCTAssertNil(pagerState.range(at: 2))
    }
}
