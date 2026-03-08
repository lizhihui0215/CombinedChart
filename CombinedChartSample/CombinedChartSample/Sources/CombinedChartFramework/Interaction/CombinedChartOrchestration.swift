import SwiftUI

extension CombinedChartView {
    // MARK: - Derived State

    private var snapshot: CombinedChartViewOrchestrationSnapshot {
        orchestrationContext.snapshot
    }

    @ViewBuilder
    var pagerView: some View {
        if let pagerContext {
            if let pager = slots.pager {
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
            viewportState: viewportState,
            layoutState: layoutState)
    }

    var hasData: Bool {
        snapshot.hasData
    }

    var visibleStartLabel: String? {
        snapshot.visibleStartLabel
    }

    var yAxisTickValues: [Double] {
        snapshot.yAxisTickValues
    }

    var yAxisDisplayDomain: ClosedRange<Double> {
        snapshot.yAxisDisplayDomain
    }

    private var axisPointInfos: [ChartConfig.Axis.PointInfo] {
        snapshot.axisPointInfos
    }

    private var pagerContext: PagerContext? {
        snapshot.makePagerContext(dispatch: dispatch)
    }

    private func yAxisLabel(for amount: Double) -> String {
        config.axis.yAxisLabel(
            .init(
                value: amount,
                visiblePoints: axisPointInfos))
    }

    var sectionContext: SectionContext {
        snapshot.makeSectionContext(
            config: config,
            selectedTab: selectedTab,
            showDebugOverlay: showDebugOverlay,
            selectionOverlay: slots.selectionOverlay,
            yAxisLabel: yAxisLabel(for:))
    }

    private var interactionState: InteractionState {
        snapshot.makeInteractionState(
            visibleSelection: visibleSelection,
            viewportState: viewportState,
            unitWidth: layoutState.unitWidth)
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
            dataPointIDs: snapshot.data.map(\.id))
    }

    private func emitPointTap(for visibleSelection: VisibleSelection) {
        guard let resolvedIndex = CombinedChartView.SelectionResolver.resolvedVisibleIndex(
            for: visibleSelection,
            dataPointIDs: snapshot.data.map(\.id))
        else { return }

        onPointTap?(
            .init(
                point: snapshot.data[resolvedIndex].source,
                index: resolvedIndex))
    }
}
