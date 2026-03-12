import SwiftUI

extension CombinedChartView {
    struct ViewportInfo: Equatable {
        static let chartsScrollLeadingInset = 0.5

        let startIndex: Int
        let contentOffsetX: CGFloat
        let scrollPosition: Double
        let visibleStartIndex: Int?
        let visibleValueRange: ClosedRange<Int>?
        let maxStartIndex: Int

        init(
            dataCount: Int,
            visibleValueCount: Int,
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat) {
            let maxStartIndex = Self.maxStartIndex(
                dataCount: dataCount,
                visibleValueCount: visibleValueCount)
            let clampedStartIndex = min(max(startIndex, 0), maxStartIndex)
            let resolvedContentOffsetX = Self.clampedContentOffsetX(
                contentOffsetX,
                unitWidth: unitWidth,
                maxStartIndex: maxStartIndex)
            let visibleStartIndex = Self.makeVisibleStartIndex(
                dataCount: dataCount,
                contentOffsetX: resolvedContentOffsetX,
                unitWidth: unitWidth,
                progressThreshold: visibleStartThreshold)

            self.startIndex = visibleStartIndex ?? clampedStartIndex
            self.contentOffsetX = resolvedContentOffsetX
            scrollPosition = Self.makeScrollPosition(
                contentOffsetX: resolvedContentOffsetX,
                unitWidth: unitWidth,
                fallbackStartIndex: self.startIndex)
            self.visibleStartIndex = visibleStartIndex
            visibleValueRange = Self.makeVisibleValueRange(
                dataCount: dataCount,
                visibleValueCount: visibleValueCount,
                visibleStartIndex: visibleStartIndex)
            self.maxStartIndex = maxStartIndex
        }

        var chartsScrollPosition: Double {
            scrollPosition - Self.chartsScrollLeadingInset
        }

        func visibleStartLabel(in data: [ChartDataPoint]) -> String? {
            visibleStartIndex.flatMap { index in
                data.indices.contains(index) ? data[index].xLabel : nil
            }
        }

        static func maxStartIndex(
            dataCount: Int,
            visibleValueCount: Int) -> Int {
            max(0, dataCount - max(visibleValueCount, 1))
        }

        static func contentOffsetX(
            for startIndex: Int,
            unitWidth: CGFloat) -> CGFloat {
            CGFloat(max(startIndex, 0)) * max(unitWidth, 0)
        }

        static func contentOffsetX(
            for scrollPosition: Double,
            unitWidth: CGFloat,
            maxStartIndex: Int) -> CGFloat {
            guard unitWidth > 0 else { return 0 }
            let clampedPosition = min(max(scrollPosition, 0), Double(maxStartIndex))
            return CGFloat(clampedPosition) * unitWidth
        }

        static func contentOffsetX(
            forChartsScrollPosition scrollPosition: Double,
            unitWidth: CGFloat,
            maxStartIndex: Int) -> CGFloat {
            contentOffsetX(
                for: scrollPosition + chartsScrollLeadingInset,
                unitWidth: unitWidth,
                maxStartIndex: maxStartIndex)
        }

        static func makeVisibleStartIndex(
            dataCount: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            progressThreshold: CGFloat = 2.0 / 3.0) -> Int? {
            guard dataCount > 0, unitWidth > 0 else { return nil }

            let normalizedOffset = max(contentOffsetX / unitWidth, 0)
            let baseIndex = min(
                max(Int(floor(normalizedOffset)), 0),
                max(0, dataCount - 1))
            let progressIntoCurrentUnit = normalizedOffset - CGFloat(baseIndex)
            let effectiveIndex = if progressIntoCurrentUnit < progressThreshold || baseIndex >= dataCount - 1 {
                baseIndex
            } else {
                baseIndex + 1
            }

            return min(max(effectiveIndex, 0), dataCount - 1)
        }

        private static func clampedContentOffsetX(
            _ contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            maxStartIndex: Int) -> CGFloat {
            guard unitWidth > 0 else { return 0 }
            let maxContentOffsetX = CGFloat(maxStartIndex) * unitWidth
            return min(max(contentOffsetX, 0), maxContentOffsetX)
        }

        private static func makeScrollPosition(
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            fallbackStartIndex: Int) -> Double {
            guard unitWidth > 0 else { return Double(fallbackStartIndex) }
            return Double(max(contentOffsetX, 0) / unitWidth)
        }

        private static func makeVisibleValueRange(
            dataCount: Int,
            visibleValueCount: Int,
            visibleStartIndex: Int?) -> ClosedRange<Int>? {
            guard let start = visibleStartIndex else { return nil }
            let visibleCount = max(1, visibleValueCount)
            let end = min(dataCount - 1, start + visibleCount - 1)
            return start...end
        }
    }

    struct ViewportDescriptor: Equatable {
        let info: ViewportInfo
        let viewportWidth: CGFloat
        let unitWidth: CGFloat
        let chartWidth: CGFloat
        let maxContentOffsetX: CGFloat
        let displayOffsetX: CGFloat

        init(
            dataCount: Int,
            visibleValueCount: Int,
            startIndex: Int,
            contentOffsetX: CGFloat,
            visibleStartThreshold: CGFloat,
            layoutMetrics: LayoutMetrics) {
            info = .init(
                dataCount: dataCount,
                visibleValueCount: visibleValueCount,
                startIndex: startIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: layoutMetrics.unitWidth,
                visibleStartThreshold: visibleStartThreshold)
            viewportWidth = layoutMetrics.viewportWidth
            unitWidth = layoutMetrics.unitWidth
            chartWidth = layoutMetrics.chartWidth
            maxContentOffsetX = layoutMetrics.maxContentOffsetX
            displayOffsetX = layoutMetrics.currentContentOffsetX
        }

        var startIndex: Int {
            info.startIndex
        }

        var contentOffsetX: CGFloat {
            info.contentOffsetX
        }

        var scrollPosition: Double {
            info.scrollPosition
        }

        var chartsScrollPosition: Double {
            info.chartsScrollPosition
        }

        var visibleStartIndex: Int? {
            info.visibleStartIndex
        }

        var visibleValueRange: ClosedRange<Int>? {
            info.visibleValueRange
        }

        var maxStartIndex: Int {
            info.maxStartIndex
        }

        func visibleStartLabel(in data: [ChartDataPoint]) -> String? {
            info.visibleStartLabel(in: data)
        }
    }

    struct PagerState {
        let entries: [PagerEntry]
        let pageRanges: [PageRange]
        let currentPageRange: PageRange?
        let currentPageRangeIndex: Int?
        let highlightedEntry: PagerEntry?
        let visibleStartIndex: Int?
        let visibleValueRange: ClosedRange<Int>?

        init(
            sortedGroups: [ChartDataGroup],
            dataCount: Int,
            visibleValueCount: Int,
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat) {
            let pageRanges = Self.makePageRanges(
                from: sortedGroups,
                visibleValueCount: visibleValueCount)
            let entries = pageRanges.map {
                PagerEntry(
                    id: $0.id,
                    displayTitle: $0.displayTitle,
                    startIndex: $0.startIndex)
            }
            let viewport = ViewportInfo(
                dataCount: dataCount,
                visibleValueCount: visibleValueCount,
                startIndex: startIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                visibleStartThreshold: visibleStartThreshold)
            let visibleStartIndex = viewport.visibleStartIndex
            let currentPageRange = pageRanges.first {
                $0.startIndex <= (visibleStartIndex ?? viewport.startIndex) &&
                    $0.endIndex >= (visibleStartIndex ?? viewport.startIndex)
            } ?? pageRanges.first
            let currentPageRangeIndex = currentPageRange.flatMap { currentPageRange in
                pageRanges.firstIndex { $0.id == currentPageRange.id }
            }
            let visibleValueRange = viewport.visibleValueRange
            let highlightedRange = Self.fullyVisiblePageRange(
                in: pageRanges,
                visibleValueRange: visibleValueRange) ?? currentPageRange
            let highlightedEntry = highlightedRange.flatMap { range in
                entries.first { $0.id == range.id }
            }

            self.entries = entries
            self.pageRanges = pageRanges
            self.currentPageRange = currentPageRange
            self.currentPageRangeIndex = currentPageRangeIndex
            self.highlightedEntry = highlightedEntry
            self.visibleStartIndex = visibleStartIndex
            self.visibleValueRange = visibleValueRange
        }

        func range(at index: Int) -> PageRange? {
            guard pageRanges.indices.contains(index) else { return nil }
            return pageRanges[index]
        }

        private static func makePageRanges(
            from groups: [ChartDataGroup],
            visibleValueCount: Int) -> [PageRange] {
            var ranges: [PageRange] = []
            var cumulativeCount = 0

            for group in groups {
                let endIndex = cumulativeCount + max(group.points.count - 1, 0)
                let startPage = cumulativeCount / visibleValueCount
                let endPage = endIndex / visibleValueCount
                ranges.append(
                    .init(
                        displayTitle: group.displayTitle,
                        groupOrder: group.groupOrder,
                        startIndex: cumulativeCount,
                        endIndex: endIndex,
                        startPage: startPage,
                        endPage: endPage))
                cumulativeCount += group.points.count
            }

            return ranges
        }

        static func makeVisibleStartIndex(
            dataCount: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            progressThreshold: CGFloat = 2.0 / 3.0) -> Int? {
            ViewportInfo.makeVisibleStartIndex(
                dataCount: dataCount,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                progressThreshold: progressThreshold)
        }

        private static func makeVisibleValueRange(
            dataCount: Int,
            visibleValueCount: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat) -> ClosedRange<Int>? {
            guard let start = ViewportInfo.makeVisibleStartIndex(
                dataCount: dataCount,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                progressThreshold: visibleStartThreshold)
            else {
                return nil
            }
            let visibleCount = max(1, visibleValueCount)
            let end = min(dataCount - 1, start + visibleCount - 1)
            return start...end
        }

        private static func fullyVisiblePageRange(
            in ranges: [PageRange],
            visibleValueRange: ClosedRange<Int>?) -> PageRange? {
            guard let visibleValueRange else { return nil }
            return ranges.first { range in
                range.startIndex <= visibleValueRange.lowerBound &&
                    range.endIndex >= visibleValueRange.upperBound
            }
        }
    }

    struct ViewportDerivedState {
        let visibleStartIndex: Int?
        let visibleStartLabel: String?
        let pagerState: PagerState
    }
}
