import Charts
import SwiftUI

extension CombinedChartView {
    struct CombinedChartViewOrchestrationContext {
        let config: ChartConfig
        let groups: [ChartGroup]
        let selectedTab: ChartTab
        let showDebugOverlay: Bool
        let viewSlots: ViewSlots
        let visibleStartMonthIndex: Int
        let contentOffsetX: CGFloat
        let unitWidth: CGFloat

        var sortedGroups: [ChartDataGroup] {
            groups
                .map { ChartDataGroup(source: $0) }
                .sorted { $0.groupOrder < $1.groupOrder }
        }

        var data: [ChartDataPoint] {
            sortedGroups.flatMap(\.points)
        }

        var derivedState: ChartDerivedState {
            .init(
                config: config,
                sortedGroups: sortedGroups,
                data: data,
                visibleStartMonthIndex: visibleStartMonthIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth)
        }
    }

    struct PlotAreaInfo: Equatable {
        let minY: CGFloat
        let height: CGFloat
    }

    struct ChartLayoutMetrics {
        let viewportWidth: CGFloat
        let unitWidth: CGFloat
        let chartWidth: CGFloat
        let maxContentOffsetX: CGFloat
        let currentContentOffsetX: CGFloat

        init(
            availableWidth: CGFloat,
            axisWidth: CGFloat,
            monthsPerPage: Int,
            dataCount: Int,
            dragPagingState: DragPagingState,
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxStartMonthIndex: Int) {
            let visibleCount = CGFloat(monthsPerPage)
            viewportWidth = max(availableWidth - axisWidth, 1)
            unitWidth = viewportWidth / visibleCount
            chartWidth = max(viewportWidth, unitWidth * CGFloat(dataCount))
            maxContentOffsetX = CGFloat(maxStartMonthIndex) * unitWidth
            currentContentOffsetX = dragPagingState.currentContentOffsetX(
                dragTranslationX: dragTranslationX,
                settlingOffsetX: settlingOffsetX,
                maxContentOffsetX: maxContentOffsetX)
        }
    }

    struct DragPagingState {
        let contentOffsetX: CGFloat
        let visibleStartMonthIndex: Int
        let monthsPerPage: Int
        let maxStartMonthIndex: Int
        let dragScrollMode: ChartConfig.ChartPagerConfig.DragScrollMode

        private func displayTranslationX(from dragTranslationX: CGFloat) -> CGFloat {
            switch dragScrollMode {
            case .byPage:
                0
            case .freeSnapping, .free:
                dragTranslationX
            }
        }

        private func clampedDragTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            let maxRightDragOffset = contentOffsetX
            let maxLeftDragOffset = max(maxContentOffsetX - contentOffsetX, 0)

            return min(
                max(dragTranslationX, -maxLeftDragOffset),
                maxRightDragOffset)
        }

        func clampedDisplayTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            clampedDragTranslationX(
                from: displayTranslationX(from: dragTranslationX),
                maxContentOffsetX: maxContentOffsetX)
        }

        func currentContentOffsetX(
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            -contentOffsetX + settlingOffsetX + clampedDisplayTranslationX(
                from: dragTranslationX,
                maxContentOffsetX: maxContentOffsetX)
        }

        func targetOffsetX(
            for rawTranslationX: CGFloat,
            computedUnitWidth: CGFloat,
            computedViewportWidth: CGFloat) -> CGFloat {
            let maxContentOffsetX = CGFloat(maxStartMonthIndex) * computedUnitWidth
            let clampedTranslationX = clampedDragTranslationX(
                from: rawTranslationX,
                maxContentOffsetX: maxContentOffsetX)
            let proposedContentOffsetX = min(
                max(contentOffsetX - clampedTranslationX, 0),
                maxContentOffsetX)

            switch dragScrollMode {
            case .byPage:
                let threshold = computedViewportWidth * 0.2
                let pageDelta: Int = if clampedTranslationX <= -threshold {
                    monthsPerPage
                } else if clampedTranslationX >= threshold {
                    -monthsPerPage
                } else {
                    0
                }
                let targetMonthIndex = min(
                    max(visibleStartMonthIndex + pageDelta, 0),
                    maxStartMonthIndex)
                return CGFloat(targetMonthIndex) * computedUnitWidth
            case .freeSnapping:
                let snappedMonthIndex = min(
                    max(Int(round(proposedContentOffsetX / computedUnitWidth)), 0),
                    maxStartMonthIndex)
                return CGFloat(snappedMonthIndex) * computedUnitWidth
            case .free:
                return proposedContentOffsetX
            }
        }

        func targetMonthIndex(
            for targetContentOffsetX: CGFloat,
            computedUnitWidth: CGFloat) -> Int {
            min(
                max(Int(floor(targetContentOffsetX / computedUnitWidth)), 0),
                maxStartMonthIndex)
        }
    }

    struct PagerState {
        let entries: [PagerEntry]
        let yearPageRanges: [YearPageRange]
        let currentYearRange: YearPageRange?
        let currentYearRangeIndex: Int?
        let highlightedEntry: PagerEntry?
        let visibleMonthRange: ClosedRange<Int>?

        init(
            sortedGroups: [ChartDataGroup],
            dataCount: Int,
            monthsPerPage: Int,
            visibleStartMonthIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) {
            let yearPageRanges = Self.makeYearPageRanges(
                from: sortedGroups,
                monthsPerPage: monthsPerPage)
            let entries = yearPageRanges.map {
                PagerEntry(
                    id: $0.id,
                    displayTitle: $0.displayTitle,
                    startMonthIndex: $0.startMonthIndex)
            }
            let currentYearRange = yearPageRanges.first {
                $0.startMonthIndex <= visibleStartMonthIndex &&
                    $0.endMonthIndex >= visibleStartMonthIndex
            } ?? yearPageRanges.first
            let currentYearRangeIndex = currentYearRange.flatMap { currentYearRange in
                yearPageRanges.firstIndex { $0.id == currentYearRange.id }
            }
            let visibleMonthRange = Self.makeVisibleMonthRange(
                dataCount: dataCount,
                monthsPerPage: monthsPerPage,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth)
            let highlightedRange = Self.fullyVisibleYearRange(
                in: yearPageRanges,
                visibleMonthRange: visibleMonthRange) ?? currentYearRange
            let highlightedEntry = highlightedRange.flatMap { range in
                entries.first { $0.id == range.id }
            }

            self.entries = entries
            self.yearPageRanges = yearPageRanges
            self.currentYearRange = currentYearRange
            self.currentYearRangeIndex = currentYearRangeIndex
            self.highlightedEntry = highlightedEntry
            self.visibleMonthRange = visibleMonthRange
        }

        func range(at index: Int) -> YearPageRange? {
            guard yearPageRanges.indices.contains(index) else { return nil }
            return yearPageRanges[index]
        }

        private static func makeYearPageRanges(
            from groups: [ChartDataGroup],
            monthsPerPage: Int) -> [YearPageRange] {
            var ranges: [YearPageRange] = []
            var cumulativeMonths = 0

            for group in groups {
                let endMonthIndex = cumulativeMonths + max(group.points.count - 1, 0)
                let startPage = cumulativeMonths / monthsPerPage
                let endPage = endMonthIndex / monthsPerPage
                ranges.append(
                    .init(
                        displayTitle: group.displayTitle,
                        groupOrder: group.groupOrder,
                        startMonthIndex: cumulativeMonths,
                        endMonthIndex: endMonthIndex,
                        startPage: startPage,
                        endPage: endPage))
                cumulativeMonths += group.points.count
            }

            return ranges
        }

        private static func makeVisibleMonthRange(
            dataCount: Int,
            monthsPerPage: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) -> ClosedRange<Int>? {
            guard dataCount > 0, unitWidth > 0 else { return nil }
            let start = min(
                max(Int(floor(contentOffsetX / unitWidth)), 0),
                max(0, dataCount - 1))
            let visibleCount = max(1, monthsPerPage)
            let end = min(dataCount - 1, start + visibleCount - 1)
            return start...end
        }

        private static func fullyVisibleYearRange(
            in ranges: [YearPageRange],
            visibleMonthRange: ClosedRange<Int>?) -> YearPageRange? {
            guard let visibleMonthRange else { return nil }
            return ranges.first { range in
                range.startMonthIndex <= visibleMonthRange.lowerBound &&
                    range.endMonthIndex >= visibleMonthRange.upperBound
            }
        }
    }

    struct ChartDerivedState {
        let hasData: Bool
        let visibleStartMonthLabel: String?
        let axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo]
        let yDomain: ClosedRange<Double>
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let pagerState: PagerState

        init(
            config: ChartConfig,
            sortedGroups: [ChartDataGroup],
            data: [ChartDataPoint],
            visibleStartMonthIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) {
            hasData = !data.isEmpty
            visibleStartMonthLabel = data.indices.contains(visibleStartMonthIndex)
                ? data[visibleStartMonthIndex].xLabel
                : nil
            axisPointInfos = data.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            let minValue = data
                .map { $0.stackedExtents(using: config).min }
                .min() ?? -20
            let maxValue = data
                .map { $0.stackedExtents(using: config).max }
                .max() ?? 20
            let padding = max((maxValue - minValue) * 0.1, 2)
            yDomain = (minValue - padding)...(maxValue + padding)

            let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
            let step = max(ceil(halfRange / 5.0), 1.0)
            yAxisTickValues = (-5...5).map { Double($0) * step }

            if let first = yAxisTickValues.first, let last = yAxisTickValues.last {
                yAxisDisplayDomain = first...last
            } else {
                yAxisDisplayDomain = yDomain
            }

            pagerState = .init(
                sortedGroups: sortedGroups,
                dataCount: data.count,
                monthsPerPage: config.monthsPerPage,
                visibleStartMonthIndex: visibleStartMonthIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth)
        }
    }

    enum ViewAction {
        case selectPoint(index: Int?, emitsPointTap: Bool = true)
        case selectMonthWindow(startMonthIndex: Int)
        case selectPreviousPage
        case selectNextPage
    }

    struct SectionContext {
        let config: ChartConfig
        let selectedTab: ChartTab
        let data: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let yAxisLabel: (Double) -> String
    }

    struct ChartRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
    }

    struct ChartSelectionState {
        let point: ChartDataPoint
        let index: Int
        let value: Double
        let xPosition: CGFloat
    }

    struct SelectionLayout {
        let highlightWidth: CGFloat
        let indicatorFrame: CGRect
    }

    struct BarSegment: Identifiable {
        let id = UUID()
        let start: Double
        let value: Double
        let color: Color
    }

    struct LineSegmentPath: Identifiable {
        let id = UUID()
        let path: Path
        let color: Color
    }

    struct AxisRenderContext {
        let monthValues: [String]
        let pointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo]
        let pointInfoByKey: [String: ChartConfig.ChartAxisConfig.AxisPointInfo]
    }

    struct MarksRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let selectedIndex: Int?
    }

    struct OverlayRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let config: ChartConfig
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let selectedIndex: Int?
    }
}
