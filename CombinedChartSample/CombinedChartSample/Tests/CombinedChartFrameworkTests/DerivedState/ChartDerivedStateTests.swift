@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartDerivedStateTests: XCTestCase {
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

    func testPublicContextsExposeStableInitializers() {
        let point = CombinedChartView.Point(
            id: .init(groupID: "2024", xKey: "2024-01"),
            xKey: "2024-01",
            xLabel: "Jan",
            values: [.saving: 12])

        let selection = CombinedChartView.Selection(point: point, index: 0)
        let overlay = CombinedChartView.SelectionOverlay(
            point: point,
            value: 12,
            plotFrame: CGRect(x: 0, y: 0, width: 120, height: 240),
            indicatorFrame: CGRect(x: 20, y: 10, width: 24, height: 200),
            indicatorStyle: .line)
        let entry = CombinedChartView.PagerItem(
            id: "2024",
            displayTitle: "2024",
            startMonthIndex: 0)
        let pager = CombinedChartView.PagerContext(
            entries: [entry],
            highlightedEntry: entry,
            canSelectPreviousPage: false,
            canSelectNextPage: true,
            onSelectPreviousPage: {},
            onSelectEntry: { _ in },
            onSelectNextPage: {})

        XCTAssertEqual(selection.point.id, point.id)
        XCTAssertEqual(selection.index, 0)
        XCTAssertEqual(overlay.point.id, point.id)
        XCTAssertEqual(overlay.indicatorStyle, .line)
        XCTAssertEqual(pager.entries, [entry])
        XCTAssertEqual(pager.highlightedEntry, entry)
        XCTAssertFalse(pager.canSelectPreviousPage)
        XCTAssertTrue(pager.canSelectNextPage)
    }

    func testSlotsInitializerSupportsEmptyStateOnlyCustomization() {
        let slots = CombinedChartView.Slots {
            Text("No chart data")
        }

        XCTAssertNil(slots.selectionOverlay)
        XCTAssertNil(slots.pager)

        let groups = [
            CombinedChartView.DataGroup(
                id: "2024",
                displayTitle: "2024",
                groupOrder: 0,
                points: [
                    .init(
                        id: .init(groupID: "2024", xKey: "2024-01"),
                        xKey: "2024-01",
                        xLabel: "Jan",
                        values: [.saving: 1])
                ])
        ]
        let view = CombinedChartView(groups: groups, slots: slots)

        XCTAssertNotNil(view)
    }
}
