@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartResolversTests: XCTestCase {
    private func makeXPositions(_ values: [CGFloat?]) -> [CombinedChartView.XPositionDescriptor] {
        CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: values.count,
            xPosition: { index in
                values[index]
            }))
    }

    func testSelectionResolverPicksNearestCandidate() {
        let candidates = [
            (index: 0, xPosition: CGFloat(20)),
            (index: 1, xPosition: CGFloat(80)),
            (index: 2, xPosition: CGFloat(140))
        ]

        let nearestIndex = CombinedChartView.SelectionResolver.nearestIndex(
            to: CGPoint(x: 95, y: 0),
            candidates: candidates)

        XCTAssertEqual(nearestIndex, 1)
    }

    func testSelectionResolverRoundsAndClampsDomainXValues() {
        XCTAssertEqual(
            CombinedChartView.SelectionResolver.resolvedIndex(
                forDomainXValue: -0.6,
                dataCount: 6),
            0)
        XCTAssertEqual(
            CombinedChartView.SelectionResolver.resolvedIndex(
                forDomainXValue: 2.49,
                dataCount: 6),
            2)
        XCTAssertEqual(
            CombinedChartView.SelectionResolver.resolvedIndex(
                forDomainXValue: 2.5,
                dataCount: 6),
            3)
        XCTAssertEqual(
            CombinedChartView.SelectionResolver.resolvedIndex(
                forDomainXValue: 8.2,
                dataCount: 6),
            5)
        XCTAssertNil(
            CombinedChartView.SelectionResolver.resolvedIndex(
                forDomainXValue: .nan,
                dataCount: 6))
    }

    func testDebugGuideResolverBuildsPointGuidesFromAvailablePositions() {
        let positions = CombinedChartView.DebugGuideResolver.pointGuideXPositions(
            xPositions: makeXPositions([0, 40, nil, 120]))

        XCTAssertEqual(positions, [0, 40, 120])
    }

    func testDebugGuideResolverOffsetsThresholdGuidesFromPointCenters() {
        let positions = CombinedChartView.DebugGuideResolver.thresholdGuideXPositions(
            unitWidth: 20,
            visibleStartThreshold: 0.75,
            xPositions: makeXPositions([20, 60, 100]))

        XCTAssertEqual(positions, [25, 65, 105])
    }

    func testSelectionLayoutResolverBuildsCandidatesFromAvailablePositions() {
        let candidates = CombinedChartView.SelectionLayoutResolver.candidates(
            dataCount: 3,
            xPosition: { index in
                index == 1 ? nil : CGFloat(index * 40)
            })

        XCTAssertEqual(candidates.map(\.index), [0, 2])
        XCTAssertEqual(candidates.map(\.xPosition), [0, 80])
    }

    func testSelectionHitResolverBuildsDescriptorsFromAvailablePositions() {
        let descriptors = CombinedChartView.SelectionHitResolver.descriptors(.init(
            dataCount: 3,
            minimumHitWidth: 24,
            fallbackWidth: 20,
            xPositions: makeXPositions([0, nil, 80])))

        XCTAssertEqual(descriptors.map(\.index), [0, 2])
        XCTAssertEqual(descriptors.map(\.xPosition), [0, 80])
        XCTAssertEqual(descriptors.map(\.hitWidth), [24, 24])
    }

    func testSelectionHitResolverPrefersContainingHitRange() {
        let resolvedIndex = CombinedChartView.SelectionHitResolver.resolveIndex(
            at: CGPoint(x: 110, y: 0),
            request: .init(
                dataCount: 3,
                minimumHitWidth: 0,
                fallbackWidth: 0,
                xPositions: makeXPositions([20, 100, 180])))

        XCTAssertEqual(resolvedIndex, 1)
    }

    func testSelectionHitResolverFallsBackToNearestWhenTapIsOutsideHitRanges() {
        let resolvedIndex = CombinedChartView.SelectionHitResolver.resolveIndex(
            at: CGPoint(x: 58, y: 0),
            request: .init(
                dataCount: 3,
                minimumHitWidth: 0,
                fallbackWidth: 0,
                xPositions: makeXPositions([20, 100, 180])))

        XCTAssertEqual(resolvedIndex, 0)
    }

    @MainActor
    func testSelectionLayoutResolverResolvesSelectionState() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 12])
        ]

        let selectionState = CombinedChartView.SelectionLayoutResolver.selectionState(
            for: .init(index: 1, pointID: data[1].id),
            data: data,
            config: config,
            xPositions: makeXPositions([20, 60]))

        XCTAssertEqual(selectionState?.index, 1)
        XCTAssertEqual(selectionState?.xPosition, 60)
        XCTAssertEqual(selectionState?.value, 12)
    }

    @MainActor
    func testSelectionLayoutResolverReconcilesStaleVisibleIndex() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 12])
        ]

        let selectionState = CombinedChartView.SelectionLayoutResolver.selectionState(
            for: .init(index: 0, pointID: data[1].id),
            data: data,
            config: config,
            xPositions: makeXPositions([20, 60]))

        XCTAssertEqual(selectionState?.index, 1)
        XCTAssertEqual(selectionState?.point.id, data[1].id)
        XCTAssertEqual(selectionState?.xPosition, 60)
    }

    func testSelectionLayoutResolverUsesMinimumWidthForSinglePointBand() {
        let point = ChartTestBuilders.makeDataPoint(
            groupID: "2024",
            xKey: "2024-01",
            xLabel: "Jan",
            values: [.saving: 10])
        let selectionState = CombinedChartView.SelectionState(
            point: point,
            index: 0,
            value: 10,
            xPosition: 40)

        let layout = CombinedChartView.SelectionLayoutResolver.layout(
            for: selectionState,
            dataCount: 1,
            indicatorStyle: .band,
            plotRect: CGRect(x: 0, y: 0, width: 120, height: 240),
            minimumSelectionWidth: 30,
            fallbackWidth: 20,
            xPositions: [])

        XCTAssertEqual(layout.highlightWidth, 30)
        XCTAssertEqual(layout.indicatorFrame.width, 30)
        XCTAssertEqual(layout.indicatorFrame.minX, 25)
    }

    @MainActor
    func testSelectionOverlayResolverBuildsOverlayContextAndPointCenter() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 12])
        ]

        let overlayState = CombinedChartView.SelectionOverlayResolver.resolve(.init(
            visibleSelection: .init(index: 1, pointID: data[1].id),
            data: data,
            config: config,
            indicatorStyle: .band,
            plotRect: CGRect(x: 0, y: 0, width: 120, height: 240),
            minimumSelectionWidth: 24,
            fallbackWidth: 20,
            xPositions: makeXPositions([20, 60]),
            yPosition: { value in
                value == 12 ? 80 : nil
            }))

        XCTAssertEqual(overlayState?.context.point.id, data[1].id)
        XCTAssertEqual(overlayState?.context.value, 12)
        XCTAssertEqual(overlayState?.context.plotFrame, CGRect(x: 0, y: 0, width: 120, height: 240))
        XCTAssertEqual(overlayState?.context.indicatorFrame, CGRect(x: 42, y: 0, width: 36, height: 240))
        XCTAssertEqual(overlayState?.context.indicatorStyle, .band)
        XCTAssertEqual(overlayState?.pointCenter, CGPoint(x: 60, y: 80))
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

    func testLineSegmentResolverProducesStableSegmentIDs() {
        let points = [
            (position: CGPoint(x: 0, y: 0), value: 3.0),
            (position: CGPoint(x: 10, y: 10), value: -2.0),
            (position: CGPoint(x: 20, y: 5), value: -1.0)
        ]

        let firstIDs = CombinedChartView.LineSegmentResolver.makeSegments(
            points: points,
            style: .linear,
            color: { _ in .red })
            .map(\.id)
        let secondIDs = CombinedChartView.LineSegmentResolver.makeSegments(
            points: points,
            style: .linear,
            color: { _ in .red })
            .map(\.id)

        XCTAssertEqual(firstIDs, ["0-segment", "1-segment"])
        XCTAssertEqual(secondIDs, firstIDs)
    }

    @MainActor
    func testTrendLineResolverBuildsPointDescriptorsFromAvailableCoordinates() {
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 3]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: -2]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-03",
                xLabel: "Mar",
                values: [.saving: 5])
        ]

        let descriptors = CombinedChartView.TrendLineResolver.pointDescriptors(.init(
            data: data,
            config: .default,
            xPositions: makeXPositions([10, 40, nil]),
            yPosition: { value in
                value == 5 ? nil : CGFloat(50 - value)
            }))

        XCTAssertEqual(descriptors.map(\.index), [0, 1])
        XCTAssertEqual(descriptors.map(\.value), [3, 2])
        XCTAssertEqual(descriptors.map(\.position), [
            CGPoint(x: 10, y: 47),
            CGPoint(x: 40, y: 48)
        ])
    }

    @MainActor
    func testTrendLineResolverProducesStableSegmentIDs() {
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 3]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: -2]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-03",
                xLabel: "Mar",
                values: [.saving: -1])
        ]

        let segmentIDs = CombinedChartView.TrendLineResolver.segments(.init(
            data: data,
            config: .default,
            xPositions: makeXPositions([0, 10, 20]),
            yPosition: { value in
                CGFloat(20 - value)
            }),
            color: { _ in .red })
            .map(\.id)

        XCTAssertEqual(segmentIDs, ["0-segment"])
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
                index: 1,
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
                index: 0,
                pointID: .init(groupID: "2024", xKey: "2024-03")),
            dataPointIDs: [
                .init(groupID: "2024", xKey: "2024-01"),
                .init(groupID: "2024", xKey: "2024-02"),
                .init(groupID: "2024", xKey: "2024-03")
            ])

        XCTAssertEqual(resolvedIndex, 2)
    }

    func testSelectionResolverReconcilesSelectionToUpdatedVisibleIndex() {
        let reconciledSelection = CombinedChartView.SelectionResolver.reconciledSelection(
            .init(
                index: 0,
                pointID: .init(groupID: "2024", xKey: "2024-03")),
            dataPointIDs: [
                .init(groupID: "2024", xKey: "2024-01"),
                .init(groupID: "2024", xKey: "2024-02"),
                .init(groupID: "2024", xKey: "2024-03")
            ])

        XCTAssertEqual(
            reconciledSelection,
            .init(
                index: 2,
                pointID: .init(groupID: "2024", xKey: "2024-03")))
    }

    func testSelectionResolverDropsSelectionWhenPointIsMissing() {
        let reconciledSelection = CombinedChartView.SelectionResolver.reconciledSelection(
            .init(
                index: 1,
                pointID: .init(groupID: "2024", xKey: "2024-99")),
            dataPointIDs: [
                .init(groupID: "2024", xKey: "2024-01"),
                .init(groupID: "2024", xKey: "2024-02")
            ])

        XCTAssertNil(reconciledSelection)
    }
}
