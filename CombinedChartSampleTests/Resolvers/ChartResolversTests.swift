@testable import CombinedChartFramework
import SwiftUI
import Testing

struct ChartResolversTests {
    @Test func selectionResolverPicksNearestCandidate() {
        let candidates = [
            CombinedChartView.SelectionCandidate(index: 0, xPosition: 20),
            CombinedChartView.SelectionCandidate(index: 1, xPosition: 80),
            CombinedChartView.SelectionCandidate(index: 2, xPosition: 140)
        ]

        let nearestIndex = CombinedChartView.SelectionResolver.nearestIndex(
            to: CGPoint(x: 95, y: 0),
            candidates: candidates)

        #expect(nearestIndex == 1)
    }

    @Test func lineSegmentResolverComputesZeroIntersection() {
        let intersection = CombinedChartView.LineSegmentResolver.zeroIntersection(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 10, y: 10),
            startValue: 5,
            endValue: -5)

        #expect(intersection?.x == 5)
        #expect(intersection?.y == 5)
    }

    @Test func lineSegmentResolverTreatsZeroAsSameSide() {
        #expect(CombinedChartView.LineSegmentResolver.isSameSideOrZero(0, -5))
        #expect(CombinedChartView.LineSegmentResolver.isSameSideOrZero(7, 0))
        #expect(!CombinedChartView.LineSegmentResolver.isSameSideOrZero(3, -2))
    }

    @Test func barSegmentResolverAdjustsSegmentBounds() {
        let bounds = CombinedChartView.BarSegmentResolver.adjustedSegmentBounds(
            start: 10,
            value: -4)

        #expect(bounds.low == 6)
        #expect(bounds.high == 10)
    }

    @Test func barSegmentResolverReturnsZeroGapForZeroHeightPlotArea() {
        let gapValue = CombinedChartView.BarSegmentResolver.gapValue(
            plotAreaHeight: 0,
            yAxisDisplayDomain: -10...10,
            segmentGap: 8)

        #expect(gapValue == 0)
    }
}
