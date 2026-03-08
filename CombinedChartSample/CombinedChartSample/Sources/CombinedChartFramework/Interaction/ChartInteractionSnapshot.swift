import SwiftUI

extension CombinedChartView {
    struct ChartPreparedData {
        let sortedGroups: [ChartDataGroup]
        let data: [ChartDataPoint]
        let dataPointIDs: [ChartPointID]

        static func make(from groups: [ChartGroup]) -> Self {
            let sortedGroups = groups
                .map { ChartDataGroup(source: $0) }
                .sorted { $0.groupOrder < $1.groupOrder }
            let data = sortedGroups.flatMap(\.points)

            return .init(
                sortedGroups: sortedGroups,
                data: data,
                dataPointIDs: data.map(\.id))
        }
    }

    struct ChartInteractionSnapshot {
        let data: [ChartDataPoint]
        let dataPointIDs: [ChartPointID]
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

        var visibleStartIndex: Int? {
            derivedState.viewport.visibleStartIndex
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
    }

    struct ChartInteractionContext {
        let config: ChartConfig
        let preparedData: ChartPreparedData
        let viewportState: ViewportState
        let layoutState: LayoutState

        var sortedGroups: [ChartDataGroup] {
            preparedData.sortedGroups
        }

        var data: [ChartDataPoint] {
            preparedData.data
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

        var snapshot: ChartInteractionSnapshot {
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
                dataPointIDs: preparedData.dataPointIDs,
                derivedState: derivedState,
                pagingContext: pagingContext,
                canSelectPreviousPage: viewportState.startIndex > 0,
                canSelectNextPage: viewportState.startIndex < pagingContext.maxStartMonthIndex)
        }
    }
}
