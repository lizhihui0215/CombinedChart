@testable import CombinedChartFramework
import SwiftUI
import Testing

struct ChartDerivedStateTests {
    @Test func pagerStateUsesFullyVisibleRangeForHighlight() {
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

        #expect(pagerState.visibleMonthRange == 4...7)
        #expect(pagerState.highlightedEntry?.id == "2025")
        #expect(pagerState.currentYearRange?.id == "2025")
    }

    @Test func pagerStateFallsBackToCurrentRangeWhenWindowSpansYears() {
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

        #expect(pagerState.visibleMonthRange == 4...7)
        #expect(pagerState.currentYearRange?.id == "2024")
        #expect(pagerState.highlightedEntry?.id == "2024")
    }

    @Test func chartDerivedStateBuildsExpectedAxisDomainAndLabel() {
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
            visibleStartMonthIndex: 1,
            contentOffsetX: 100,
            unitWidth: 100)

        #expect(derivedState.hasData)
        #expect(derivedState.visibleStartMonthLabel == "Feb")
        #expect(derivedState.axisPointInfos.count == 2)
        #expect(derivedState.yDomain.lowerBound == -13.5)
        #expect(derivedState.yDomain.upperBound == 28.5)
        #expect(derivedState.yAxisTickValues == [-30, -24, -18, -12, -6, 0, 6, 12, 18, 24, 30])
        #expect(derivedState.yAxisDisplayDomain == -30.0...30.0)
    }

    @Test func pagerStateRangeReturnsNilWhenIndexIsOutOfBounds() {
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

        #expect(pagerState.range(at: 0)?.id == "2024")
        #expect(pagerState.range(at: 1)?.id == "2025")
        #expect(pagerState.range(at: -1) == nil)
        #expect(pagerState.range(at: 2) == nil)
    }
}
