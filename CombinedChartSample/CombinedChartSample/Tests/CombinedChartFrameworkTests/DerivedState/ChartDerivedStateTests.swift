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
}
