import SwiftUI

extension CombinedChartView {
    // MARK: - Derived State

    var interactionSnapshot: ChartInteractionSnapshot {
        interactionContext.snapshot
    }

    @ViewBuilder
    func pagerView(context: PagerContext) -> some View {
        if let pager = slots.pager {
            pager(context)
        } else {
            CombinedChartPager(context: context)
        }
    }

    private var interactionContext: ChartInteractionContext {
        .init(
            config: config,
            preparedData: preparedData,
            viewportState: viewportState,
            layoutState: layoutState)
    }

    private func yAxisLabel(
        for amount: Double,
        axisPointInfos: [ChartConfig.Axis.PointInfo]) -> String {
        config.axis.yAxisLabel(
            .init(
                value: amount,
                visiblePoints: axisPointInfos))
    }

    func makeSectionContext(
        snapshot: ChartInteractionSnapshot,
        axisPointInfos: [ChartConfig.Axis.PointInfo]) -> ChartSectionContext {
        snapshot.makeSectionContext(
            config: config,
            selectedTab: selectedTab,
            showDebugOverlay: showDebugOverlay,
            selectionOverlay: slots.selectionOverlay,
            yAxisLabel: { amount in
                yAxisLabel(for: amount, axisPointInfos: axisPointInfos)
            })
    }

    // MARK: - Dispatch

    func dispatch(_ action: ViewAction) {
        let snapshot = interactionSnapshot
        let interactionState = snapshot.makeInteractionState(
            visibleSelection: visibleSelection,
            viewportState: viewportState,
            unitWidth: layoutState.unitWidth)
        let result = InteractionReducer.reduce(action: action, state: interactionState)
        for mutation in result.mutations {
            apply(mutation, dataPointIDs: snapshot.data.map(\.id))
        }
        for command in result.commands {
            perform(command, data: snapshot.data)
        }
    }

    // MARK: - Apply

    private func apply(
        _ mutation: InteractionMutation,
        dataPointIDs: [ChartPointID]) {
        switch mutation {
        case .selection(let visibleSelection, let emitsPointTap):
            reconcileVisibleSelection(visibleSelection, dataPointIDs: dataPointIDs)
            guard emitsPointTap else { return }
        case .viewportUpdate(let context):
            viewportState.startIndex = context.startIndex
            if let nextContentOffsetX = context.contentOffsetX {
                viewportState.contentOffsetX = nextContentOffsetX
            }
            reconcileVisibleSelection(visibleSelection, dataPointIDs: dataPointIDs)
        }
    }

    // MARK: - Perform

    private func perform(
        _ command: InteractionCommand,
        data: [ChartDataPoint]) {
        switch command {
        case .emitPointTap(let visibleSelection):
            emitPointTap(for: visibleSelection, data: data)
        }
    }

    // MARK: - Helpers

    private func reconcileVisibleSelection(
        _ visibleSelection: VisibleSelection?,
        dataPointIDs: [ChartPointID]) {
        self.visibleSelection = CombinedChartView.SelectionResolver.reconciledSelection(
            visibleSelection,
            dataPointIDs: dataPointIDs)
    }

    private func emitPointTap(
        for visibleSelection: VisibleSelection,
        data: [ChartDataPoint]) {
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
