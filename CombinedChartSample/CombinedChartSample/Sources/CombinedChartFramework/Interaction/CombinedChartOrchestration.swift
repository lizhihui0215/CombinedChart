import SwiftUI

extension CombinedChartView {
    // MARK: - Derived State

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

    private var orchestrationContext: CombinedChartViewOrchestrationContext {
        .init(
            config: config,
            groups: groups,
            selectedTab: selectedTab,
            showDebugOverlay: showDebugOverlay,
            viewSlots: viewSlots,
            viewportState: viewportState,
            layoutState: layoutState)
    }

    private var sortedGroups: [ChartDataGroup] {
        orchestrationContext.sortedGroups
    }

    private var data: [ChartDataPoint] {
        orchestrationContext.data
    }

    private var derivedState: ChartDerivedState {
        orchestrationContext.derivedState
    }

    private var pagerState: PagerState {
        derivedState.viewport.pagerState
    }

    private var yearPageRanges: [YearPageRange] {
        pagerState.yearPageRanges
    }

    private var currentYearRangeIndex: Int? {
        pagerState.currentYearRangeIndex
    }

    private var highlightedPagerEntry: PagerEntry? {
        pagerState.highlightedEntry
    }

    private var pagerEntries: [PagerEntry] {
        pagerState.entries
    }

    private var visibleMonthRange: ClosedRange<Int>? {
        pagerState.visibleMonthRange
    }

    private var currentYearRange: YearPageRange? {
        pagerState.currentYearRange
    }

    private var maxStartMonthIndex: Int {
        max(0, data.count - config.monthsPerPage)
    }

    var hasData: Bool {
        derivedState.hasData
    }

    var visibleStartLabel: String? {
        derivedState.viewport.visibleStartLabel
    }

    var yAxisTickValues: [Double] {
        derivedState.yAxisTickValues
    }

    var yAxisDisplayDomain: ClosedRange<Double> {
        derivedState.yAxisDisplayDomain
    }

    private var axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo] {
        derivedState.axisPointInfos
    }

    private var pagerContext: PagerContext? {
        guard hasData else { return nil }
        return .init(
            entries: pagerEntries,
            highlightedEntry: highlightedPagerEntry,
            canSelectPreviousPage: viewportState.startIndex > 0,
            canSelectNextPage: viewportState.startIndex < maxStartMonthIndex,
            onSelectPreviousPage: { dispatch(.selectPreviousPage) },
            onSelectEntry: { entry in
                dispatch(.selectMonthWindow(startMonthIndex: entry.startMonthIndex))
            },
            onSelectNextPage: { dispatch(.selectNextPage) })
    }

    private func yAxisLabel(for amount: Double) -> String {
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
            pagingContext: pagingContext,
            yAxisLabel: yAxisLabel(for:))
    }

    private var interactionState: InteractionState {
        .init(
            visibleSelection: visibleSelection,
            visiblePointIDs: data.map(\.id),
            viewport: viewportState,
            unitWidth: layoutState.unitWidth,
            pagingContext: pagingContext)
    }

    private var pagingContext: PagingContext {
        .init(
            monthsPerPage: config.monthsPerPage,
            maxStartMonthIndex: maxStartMonthIndex,
            arrowScrollMode: config.pager.arrowScrollMode,
            currentYearRangeIndex: currentYearRangeIndex,
            yearPageRanges: yearPageRanges)
    }

    // MARK: - Dispatch

    func dispatch(_ action: ViewAction) {
        let result = InteractionReducer.reduce(action: action, state: interactionState)
        for mutation in result.mutations {
            apply(mutation)
        }
        for command in result.commands {
            perform(command)
        }
    }

    // MARK: - Apply

    private func apply(_ mutation: InteractionMutation) {
        switch mutation {
        case .selection(let visibleSelection, let emitsPointTap):
            reconcileVisibleSelection(visibleSelection)
            guard emitsPointTap else { return }
        case .viewportUpdate(let context):
            viewportState.startIndex = context.startIndex
            if let nextContentOffsetX = context.contentOffsetX {
                viewportState.contentOffsetX = nextContentOffsetX
            }
            reconcileVisibleSelection(visibleSelection)
        }
    }

    // MARK: - Perform

    private func perform(_ command: InteractionCommand) {
        switch command {
        case .emitPointTap(let visibleSelection):
            emitPointTap(for: visibleSelection)
        }
    }

    // MARK: - Helpers

    private func reconcileVisibleSelection(_ visibleSelection: VisibleSelection?) {
        self.visibleSelection = CombinedChartView.SelectionResolver.reconciledSelection(
            visibleSelection,
            dataPointIDs: data.map(\.id))
    }

    private func emitPointTap(for visibleSelection: VisibleSelection) {
        guard let resolvedIndex = CombinedChartView.SelectionResolver.resolvedVisibleIndex(
            for: visibleSelection,
            dataPointIDs: data.map(\.id))
        else { return }

        onPointTap?(
            .init(
                point: data[resolvedIndex].source,
                index: resolvedIndex))
    }
}

private extension CombinedChartView {
    struct CombinedChartViewOrchestrationContext {
        let config: ChartConfig
        let groups: [ChartGroup]
        let selectedTab: ChartTab
        let showDebugOverlay: Bool
        let viewSlots: ViewSlots
        let viewportState: ViewportState
        let layoutState: LayoutState

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
                startIndex: viewportState.startIndex,
                contentOffsetX: viewportState.contentOffsetX,
                unitWidth: layoutState.unitWidth)
        }
    }
}
