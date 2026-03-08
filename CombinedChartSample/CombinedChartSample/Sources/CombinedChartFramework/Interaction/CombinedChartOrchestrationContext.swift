import SwiftUI

extension CombinedChartView {
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
