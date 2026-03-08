@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartResolversTests: XCTestCase {
    func testSelectionResolverPicksNearestCandidate() {
        let candidates = [
            CombinedChartView.SelectionCandidate(index: 0, xPosition: 20),
            CombinedChartView.SelectionCandidate(index: 1, xPosition: 80),
            CombinedChartView.SelectionCandidate(index: 2, xPosition: 140)
        ]

        let nearestIndex = CombinedChartView.SelectionResolver.nearestIndex(
            to: CGPoint(x: 95, y: 0),
            candidates: candidates)

        XCTAssertEqual(nearestIndex, 1)
    }

    func testLineSegmentResolverComputesZeroIntersection() {
        let intersection = CombinedChartView.LineSegmentResolver.zeroIntersection(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 10, y: 10),
            startValue: 5,
            endValue: -5)

        XCTAssertEqual(intersection?.x, 5)
        XCTAssertEqual(intersection?.y, 5)
    }

    func testLineSegmentResolverTreatsZeroAsSameSide() {
        XCTAssertTrue(CombinedChartView.LineSegmentResolver.isSameSideOrZero(0, -5))
        XCTAssertTrue(CombinedChartView.LineSegmentResolver.isSameSideOrZero(7, 0))
        XCTAssertFalse(CombinedChartView.LineSegmentResolver.isSameSideOrZero(3, -2))
    }

    func testBarSegmentResolverAdjustsSegmentBounds() {
        let bounds = CombinedChartView.BarSegmentResolver.adjustedSegmentBounds(
            start: 10,
            value: -4)

        XCTAssertEqual(bounds.low, 6)
        XCTAssertEqual(bounds.high, 10)
    }

    func testBarSegmentResolverReturnsZeroGapForZeroHeightPlotArea() {
        let gapValue = CombinedChartView.BarSegmentResolver.gapValue(
            plotAreaHeight: 0,
            yAxisDisplayDomain: -10...10,
            segmentGap: 8)

        XCTAssertEqual(gapValue, 0)
    }

    func testSelectionResolverPrefersMatchingVisibleIndexWhenPointIDMatches() {
        let resolvedIndex = CombinedChartView.SelectionResolver.resolvedVisibleIndex(
            for: .init(
                visibleIndex: 1,
                pointID: .init(groupID: "2024", xKey: "2024-02")),
            dataPointIDs: [
                .init(groupID: "2024", xKey: "2024-01"),
                .init(groupID: "2024", xKey: "2024-02"),
                .init(groupID: "2024", xKey: "2024-03")
            ])

        XCTAssertEqual(resolvedIndex, 1)
    }

    func testSelectionResolverFallsBackToPointIDLookupWhenVisibleIndexIsStale() {
        let resolvedIndex = CombinedChartView.SelectionResolver.resolvedVisibleIndex(
            for: .init(
                visibleIndex: 0,
                pointID: .init(groupID: "2024", xKey: "2024-03")),
            dataPointIDs: [
                .init(groupID: "2024", xKey: "2024-01"),
                .init(groupID: "2024", xKey: "2024-02"),
                .init(groupID: "2024", xKey: "2024-03")
            ])

        XCTAssertEqual(resolvedIndex, 2)
    }
}
