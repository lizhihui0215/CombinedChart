@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartViewportDerivedStateTests: XCTestCase {
    func testViewportDescriptorCombinesViewportInfoAndLayoutMetrics() {
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 200,
            startIndex: 2,
            visibleValueCount: 4,
            maxStartIndex: 4,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 440,
            axisWidth: 40,
            visibleValueCount: 4,
            dataCount: 8,
            dragState: dragState,
            dragTranslationX: -20,
            settlingOffsetX: 0,
            maxStartIndex: 4)
        let descriptor = CombinedChartView.ViewportDescriptor(
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 2,
            contentOffsetX: 200,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)

        XCTAssertEqual(descriptor.startIndex, 2)
        XCTAssertEqual(descriptor.contentOffsetX, 200)
        XCTAssertEqual(descriptor.visibleStartIndex, 2)
        XCTAssertEqual(descriptor.visibleValueRange, 2...5)
        XCTAssertEqual(descriptor.viewportWidth, 400)
        XCTAssertEqual(descriptor.unitWidth, 100)
        XCTAssertEqual(descriptor.chartWidth, 800)
        XCTAssertEqual(descriptor.maxContentOffsetX, 400)
        XCTAssertEqual(descriptor.displayOffsetX, -220)
    }

    func testViewportDescriptorExposesChartsScrollPosition() {
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 200,
            startIndex: 2,
            visibleValueCount: 4,
            maxStartIndex: 4,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 440,
            axisWidth: 40,
            visibleValueCount: 4,
            dataCount: 8,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 4)
        let descriptor = CombinedChartView.ViewportDescriptor(
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 2,
            contentOffsetX: 200,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)

        XCTAssertEqual(descriptor.scrollPosition, 2)
        XCTAssertEqual(descriptor.chartsScrollPosition, 1.5)
    }

    func testPlotFrameDescriptorPreservesHorizontalContentOffsetWhileNormalizingYAxis() {
        let descriptor = CombinedChartView.PlotFrameDescriptor.normalized(
            plotRect: CGRect(x: -12, y: -8, width: 180, height: 240),
            yAxisTickPositions: [0: 120])

        XCTAssertEqual(descriptor.plotRect, CGRect(x: -12, y: 0, width: 180, height: 240))
        XCTAssertEqual(descriptor.maskFrame, CGRect(x: -12, y: 0, width: 180, height: 240))
        XCTAssertEqual(descriptor.plotAreaMinY, 0)
        XCTAssertEqual(descriptor.plotAreaHeight, 240)
    }

    func testPlotSyncStateUpdatesFromPlotFrameDescriptor() {
        var plotSyncState = CombinedChartView.PlotSyncState.empty
        let descriptor = CombinedChartView.PlotFrameDescriptor(
            plotRect: CGRect(x: 0, y: 12, width: 180, height: 240),
            yAxisTickPositions: [-10: 220, 0: 120, 10: 20])

        plotSyncState.update(with: descriptor)

        XCTAssertEqual(plotSyncState.plotAreaMinY, 12)
        XCTAssertEqual(plotSyncState.plotAreaHeight, 240)
        XCTAssertEqual(plotSyncState.yTickPositions, [-10: 220, 0: 120, 10: 20])
    }

    func testYAxisDescriptorUsesPlotSyncMetricsForLayout() {
        let plotSyncState = CombinedChartView.PlotSyncState(
            plotAreaMinY: 12,
            plotAreaHeight: 240,
            yTickPositions: [-10: 220, 0: 120, 10: 20])

        let descriptor = plotSyncState.makeYAxisDescriptor(labelWidth: 40)

        XCTAssertEqual(descriptor.plotAreaTop, 12)
        XCTAssertEqual(descriptor.plotAreaHeight, 240)
        XCTAssertEqual(descriptor.totalHeight, 252)
        XCTAssertEqual(descriptor.labelWidth, 40)
        XCTAssertEqual(descriptor.dividerX, 48)
        XCTAssertEqual(descriptor.dividerWidth, 1)
        XCTAssertEqual(descriptor.containerWidth, 49)
        XCTAssertEqual(descriptor.dividerFrame, CGRect(x: 48, y: 12, width: 1, height: 240))
    }

    func testYAxisDescriptorFallsBackToTickRangeWhenPlotHeightIsMissing() {
        let plotSyncState = CombinedChartView.PlotSyncState(
            plotAreaMinY: -16,
            plotAreaHeight: 0,
            yTickPositions: [-10: 210, 0: 120, 10: 30])

        let descriptor = plotSyncState.makeYAxisDescriptor(labelWidth: 40)

        XCTAssertEqual(descriptor.plotAreaTop, 0)
        XCTAssertEqual(descriptor.plotAreaHeight, 180)
        XCTAssertEqual(descriptor.totalHeight, 180)
    }

    func testViewportInfoUsesThresholdAlignedVisibleStartAsResolvedStart() {
        let viewportInfo = CombinedChartView.ViewportInfo(
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 67,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(viewportInfo.startIndex, 1)
        XCTAssertEqual(viewportInfo.visibleStartIndex, 1)
        XCTAssertEqual(viewportInfo.visibleValueRange, 1...4)
    }

    func testViewportInfoBuildsScrollPositionAndClampsContentOffset() {
        let viewportInfo = CombinedChartView.ViewportInfo(
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 999,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(viewportInfo.maxStartIndex, 4)
        XCTAssertEqual(viewportInfo.contentOffsetX, 400)
        XCTAssertEqual(viewportInfo.scrollPosition, 4)
        XCTAssertEqual(
            CombinedChartView.ViewportInfo.contentOffsetX(
                for: 2,
                unitWidth: 100),
            200)
        XCTAssertEqual(
            CombinedChartView.ViewportInfo.contentOffsetX(
                for: 3.5,
                unitWidth: 100,
                maxStartIndex: 4),
            350)
    }

    func testPagerStateUsesFullyVisibleRangeForHighlight() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 4,
            contentOffsetX: 400,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleValueRange, 4...7)
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2025")
        XCTAssertEqual(pagerState.currentPageRange?.id, "2025")
    }

    func testPagerStateFallsBackToCurrentRangeWhenWindowSpansYears() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 6),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 6)
            ],
            dataCount: 12,
            visibleValueCount: 4,
            startIndex: 4,
            contentOffsetX: 400,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleValueRange, 4...7)
        XCTAssertEqual(pagerState.currentPageRange?.id, "2024")
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
    }

    func testPagerStateKeepsCurrentStartBeforeUnitProgressReachesThreshold() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 66,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleStartIndex, 0)
        XCTAssertEqual(pagerState.visibleValueRange, 0...3)
        XCTAssertEqual(pagerState.highlightedEntry?.id, "2024")
    }

    func testPagerStateAdvancesWhenUnitProgressReachesThreshold() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 67,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(pagerState.visibleStartIndex, 1)
        XCTAssertEqual(pagerState.visibleValueRange, 1...4)
    }

    func testPagerStateRangeReturnsNilWhenIndexIsOutOfBounds() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
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
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 40,
            unitWidth: 100,
            visibleStartThreshold: 0.5)

        XCTAssertEqual(pagerState.visibleStartIndex, 0)
        XCTAssertEqual(pagerState.visibleValueRange, 0...3)
    }

    func testPagerStateUsesConfigurableVisibleStartThresholdToAdvanceLater() {
        let pagerState = CombinedChartView.PagerState(
            sortedGroups: [
                ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, pointCount: 4),
                ChartTestBuilders.makeGroup(id: "2025", title: "2025", order: 1, pointCount: 4)
            ],
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 55,
            unitWidth: 100,
            visibleStartThreshold: 0.5)

        XCTAssertEqual(pagerState.visibleStartIndex, 1)
        XCTAssertEqual(pagerState.visibleValueRange, 1...4)
    }

    func testViewportInfoBuildsChartsScrollPositionWithLeadingInset() {
        let viewportInfo = CombinedChartView.ViewportInfo(
            dataCount: 8,
            visibleValueCount: 4,
            startIndex: 0,
            contentOffsetX: 200,
            unitWidth: 100,
            visibleStartThreshold: 2.0 / 3.0)

        XCTAssertEqual(viewportInfo.scrollPosition, 2)
        XCTAssertEqual(viewportInfo.chartsScrollPosition, 1.5)
    }

    func testViewportInfoRestoresContentOffsetFromChartsScrollPosition() {
        XCTAssertEqual(
            CombinedChartView.ViewportInfo.contentOffsetX(
                forChartsScrollPosition: -0.5,
                unitWidth: 100,
                maxStartIndex: 4),
            0)
        XCTAssertEqual(
            CombinedChartView.ViewportInfo.contentOffsetX(
                forChartsScrollPosition: 1.5,
                unitWidth: 100,
                maxStartIndex: 4),
            200)
    }
}
