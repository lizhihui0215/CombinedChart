import SwiftUI

extension CombinedChartView {
    @ViewBuilder
    var pagerView: some View {
        if let pagerContext {
            if let pager = viewSlots.pager {
                pager(pagerContext)
            } else {
                CombinedChartPager(context: pagerContext)
            }
        }
    }

    var orchestrationContext: CombinedChartViewOrchestrationContext {
        .init(
            config: config,
            groups: groups,
            selectedTab: selectedTab,
            showDebugOverlay: showDebugOverlay,
            viewSlots: viewSlots,
            visibleStartMonthIndex: visibleStartMonthIndex,
            contentOffsetX: contentOffsetX,
            unitWidth: unitWidth)
    }

    var sortedGroups: [ChartDataGroup] {
        orchestrationContext.sortedGroups
    }

    var data: [ChartDataPoint] {
        orchestrationContext.data
    }

    var derivedState: ChartDerivedState {
        orchestrationContext.derivedState
    }

    var pagerState: PagerState {
        derivedState.pagerState
    }

    var yearPageRanges: [YearPageRange] {
        pagerState.yearPageRanges
    }

    var currentYearRangeIndex: Int? {
        pagerState.currentYearRangeIndex
    }

    var highlightedPagerEntry: PagerEntry? {
        pagerState.highlightedEntry
    }

    var pagerEntries: [PagerEntry] {
        pagerState.entries
    }

    var visibleMonthRange: ClosedRange<Int>? {
        pagerState.visibleMonthRange
    }

    var currentYearRange: YearPageRange? {
        pagerState.currentYearRange
    }

    var maxStartMonthIndex: Int {
        max(0, data.count - config.monthsPerPage)
    }

    var hasData: Bool {
        derivedState.hasData
    }

    var visibleStartMonthLabel: String? {
        derivedState.visibleStartMonthLabel
    }

    var yAxisTickValues: [Double] {
        derivedState.yAxisTickValues
    }

    var yAxisDisplayDomain: ClosedRange<Double> {
        derivedState.yAxisDisplayDomain
    }

    var axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo] {
        derivedState.axisPointInfos
    }

    var pagerContext: PagerContext? {
        guard hasData else { return nil }
        return .init(
            entries: pagerEntries,
            highlightedEntry: highlightedPagerEntry,
            canSelectPreviousPage: visibleStartMonthIndex > 0,
            canSelectNextPage: visibleStartMonthIndex < maxStartMonthIndex,
            onSelectPreviousPage: { dispatch(.selectPreviousPage) },
            onSelectEntry: { entry in
                dispatch(.selectMonthWindow(startMonthIndex: entry.startMonthIndex))
            },
            onSelectNextPage: { dispatch(.selectNextPage) })
    }

    func yAxisLabel(for amount: Double) -> String {
        config.axis.yAxisLabel(
            .init(
                value: amount,
                visiblePoints: axisPointInfos))
    }

    var sectionContext: SectionContext {
        .init(
            config: config,
            selectedTab: selectedTab,
            data: data,
            yAxisTickValues: yAxisTickValues,
            yAxisDisplayDomain: yAxisDisplayDomain,
            showDebugOverlay: showDebugOverlay,
            selectionOverlay: viewSlots.selectionOverlay,
            yAxisLabel: yAxisLabel(for:))
    }

    func dispatch(_ action: ViewAction) {
        switch action {
        case .selectPoint(let index, let emitsPointTap):
            applySelection(index: index, emitsPointTap: emitsPointTap)
        case .selectMonthWindow(let startMonthIndex):
            applyMonthWindow(startingAt: startMonthIndex)
        case .selectPreviousPage:
            dispatchPreviousPage()
        case .selectNextPage:
            dispatchNextPage()
        }
    }

    func applySelection(index: Int?, emitsPointTap: Bool) {
        selectedIndex = index
        guard emitsPointTap, let index, data.indices.contains(index) else { return }
        let point = data[index].source
        onPointTap?(
            .init(
                point: point,
                index: index))
    }

    func applyMonthWindow(startingAt monthIndex: Int) {
        let clampedMonthIndex = clampedStartMonthIndex(for: monthIndex)
        visibleStartMonthIndex = clampedMonthIndex
        if unitWidth > 0 {
            contentOffsetX = CGFloat(clampedMonthIndex) * unitWidth
        }
    }

    func dispatchPreviousPage() {
        switch config.pager.arrowScrollMode {
        case .byPage:
            dispatch(.selectMonthWindow(startMonthIndex: visibleStartMonthIndex - config.monthsPerPage))
        case .byEntry:
            guard let currentYearRangeIndex else { return }
            let previousIndex = max(0, currentYearRangeIndex - 1)
            guard let range = pagerState.range(at: previousIndex) else { return }
            dispatch(.selectMonthWindow(startMonthIndex: range.startMonthIndex))
        }
    }

    func dispatchNextPage() {
        switch config.pager.arrowScrollMode {
        case .byPage:
            dispatch(.selectMonthWindow(startMonthIndex: visibleStartMonthIndex + config.monthsPerPage))
        case .byEntry:
            guard let currentYearRangeIndex else { return }
            let nextIndex = min(yearPageRanges.count - 1, currentYearRangeIndex + 1)
            guard let range = pagerState.range(at: nextIndex) else { return }
            dispatch(.selectMonthWindow(startMonthIndex: range.startMonthIndex))
        }
    }

    func clampedStartMonthIndex(for monthIndex: Int) -> Int {
        min(max(monthIndex, 0), maxStartMonthIndex)
    }
}
