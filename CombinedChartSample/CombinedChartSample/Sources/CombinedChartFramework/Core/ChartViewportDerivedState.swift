import SwiftUI

extension CombinedChartView {
    struct PagerState {
        let entries: [PagerEntry]
        let yearPageRanges: [YearPageRange]
        let currentYearRange: YearPageRange?
        let currentYearRangeIndex: Int?
        let highlightedEntry: PagerEntry?
        let visibleStartIndex: Int?
        let visibleMonthRange: ClosedRange<Int>?

        init(
            sortedGroups: [ChartDataGroup],
            dataCount: Int,
            monthsPerPage: Int,
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat) {
            let yearPageRanges = Self.makeYearPageRanges(
                from: sortedGroups,
                monthsPerPage: monthsPerPage)
            let entries = yearPageRanges.map {
                PagerEntry(
                    id: $0.id,
                    displayTitle: $0.displayTitle,
                    startMonthIndex: $0.startMonthIndex)
            }
            let visibleStartIndex = Self.makeVisibleStartIndex(
                dataCount: dataCount,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                progressThreshold: visibleStartThreshold)
            let currentYearRange = yearPageRanges.first {
                $0.startMonthIndex <= (visibleStartIndex ?? startIndex) &&
                    $0.endMonthIndex >= (visibleStartIndex ?? startIndex)
            } ?? yearPageRanges.first
            let currentYearRangeIndex = currentYearRange.flatMap { currentYearRange in
                yearPageRanges.firstIndex { $0.id == currentYearRange.id }
            }
            let visibleMonthRange = Self.makeVisibleMonthRange(
                dataCount: dataCount,
                monthsPerPage: monthsPerPage,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                visibleStartThreshold: visibleStartThreshold)
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
            self.visibleStartIndex = visibleStartIndex
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

        private static func makeVisibleMonthRange(
            dataCount: Int,
            monthsPerPage: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat) -> ClosedRange<Int>? {
            guard let start = makeVisibleStartIndex(
                dataCount: dataCount,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                progressThreshold: visibleStartThreshold)
            else {
                return nil
            }
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

    struct ChartViewportDerivedState {
        let visibleStartIndex: Int?
        let visibleStartLabel: String?
        let pagerState: PagerState
    }
}
