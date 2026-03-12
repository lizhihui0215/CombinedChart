import SwiftUI

extension CombinedChartView {
    struct PreparedData {
        let sortedGroups: [ChartDataGroup]
        let data: [ChartDataPoint]
        let dataPointIDs: [ChartPointID]
        let axisPointInfos: [ChartConfig.Axis.PointInfo]

        static func make(from groups: [ChartGroup]) -> Self {
            let sortedGroups = groups
                .map { ChartDataGroup(source: $0) }
                .sorted { $0.groupOrder < $1.groupOrder }
            let data = sortedGroups.flatMap(\.points)
            let axisPointInfos = data.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            return .init(
                sortedGroups: sortedGroups,
                data: data,
                dataPointIDs: data.map(\.id),
                axisPointInfos: axisPointInfos)
        }
    }

    struct Snapshot {
        let data: [ChartDataPoint]
        let dataPointIDs: [ChartPointID]
        let derivedState: DerivedState
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

    struct InteractionContext {
        let config: ChartConfig
        let preparedData: PreparedData
        let viewportState: ViewportState
        let layoutState: LayoutState

        var sortedGroups: [ChartDataGroup] {
            preparedData.sortedGroups
        }

        var data: [ChartDataPoint] {
            preparedData.data
        }

        var derivedState: DerivedState {
            .init(
                config: config,
                sortedGroups: sortedGroups,
                data: data,
                axisPointInfos: preparedData.axisPointInfos,
                startIndex: viewportState.startIndex,
                contentOffsetX: viewportState.contentOffsetX,
                unitWidth: layoutState.unitWidth)
        }

        var snapshot: Snapshot {
            let derivedState = derivedState
            let pagerState = derivedState.viewport.pagerState
            let pagingContext = PagingContext(
                visibleValueCount: config.visibleValueCount,
                maxStartIndex: max(0, data.count - config.visibleValueCount),
                arrowScrollMode: config.pager.arrowScrollMode,
                currentPageRangeIndex: pagerState.currentPageRangeIndex,
                pageRanges: pagerState.pageRanges)

            return .init(
                data: data,
                dataPointIDs: preparedData.dataPointIDs,
                derivedState: derivedState,
                pagingContext: pagingContext,
                canSelectPreviousPage: viewportState.startIndex > 0,
                canSelectNextPage: viewportState.startIndex < pagingContext.maxStartIndex)
        }
    }
}
