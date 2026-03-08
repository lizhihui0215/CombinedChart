import SwiftUI

extension CombinedChartView {
    struct CombinedChartViewOrchestrationSnapshot {
        let data: [ChartDataPoint]
        let derivedState: ChartDerivedState
        let pagingContext: PagingContext
        let canSelectPreviousPage: Bool
        let canSelectNextPage: Bool

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

        var axisPointInfos: [ChartConfig.Axis.PointInfo] {
            derivedState.axisPointInfos
        }

        var pagerState: PagerState {
            derivedState.viewport.pagerState
        }

        func makePagerContext(
            dispatch: @escaping (ViewAction) -> Void) -> PagerContext? {
            guard hasData else { return nil }
            return .init(
                entries: pagerState.entries,
                highlightedEntry: pagerState.highlightedEntry,
                canSelectPreviousPage: canSelectPreviousPage,
                canSelectNextPage: canSelectNextPage,
                onSelectPreviousPage: { dispatch(.selectPreviousPage) },
                onSelectEntry: { entry in
                    dispatch(.selectMonthWindow(startMonthIndex: entry.startMonthIndex))
                },
                onSelectNextPage: { dispatch(.selectNextPage) })
        }

        func makeSectionContext(
            config: ChartConfig,
            selectedTab: ChartTab,
            showDebugOverlay: Bool,
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)?,
            yAxisLabel: @escaping (Double) -> String) -> SectionContext {
            .init(
                config: config,
                selectedTab: selectedTab,
                data: data,
                yAxisTickValues: yAxisTickValues,
                yAxisDisplayDomain: yAxisDisplayDomain,
                showDebugOverlay: showDebugOverlay,
                selectionOverlay: selectionOverlay,
                pagingContext: pagingContext,
                yAxisLabel: yAxisLabel)
        }

        func makeInteractionState(
            visibleSelection: VisibleSelection?,
            viewportState: ViewportState,
            unitWidth: CGFloat)
            -> InteractionState {
            .init(
                visibleSelection: visibleSelection,
                visiblePointIDs: data.map(\.id),
                viewport: viewportState,
                unitWidth: unitWidth,
                pagingContext: pagingContext)
        }
    }

    struct CombinedChartViewOrchestrationContext {
        let config: ChartConfig
        let groups: [ChartGroup]
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

        var snapshot: CombinedChartViewOrchestrationSnapshot {
            let derivedState = derivedState
            let pagerState = derivedState.viewport.pagerState
            let pagingContext = PagingContext(
                monthsPerPage: config.monthsPerPage,
                maxStartMonthIndex: max(0, data.count - config.monthsPerPage),
                arrowScrollMode: config.pager.arrowScrollMode,
                currentYearRangeIndex: pagerState.currentYearRangeIndex,
                yearPageRanges: pagerState.yearPageRanges)

            return .init(
                data: data,
                derivedState: derivedState,
                pagingContext: pagingContext,
                canSelectPreviousPage: viewportState.startIndex > 0,
                canSelectNextPage: viewportState.startIndex < pagingContext.maxStartMonthIndex)
        }
    }
}
