import OSLog
import SwiftUI

extension CombinedChartView {
    private static let interactionLogger = ChartLog.logger(.interaction)

    // MARK: - Derived State

    var interactionSnapshot: Snapshot {
        interactionContext.snapshot
    }

    @ViewBuilder
    func pagerView(context: PagerContext) -> some View {
        if let pager = slots.pager {
            pager(context)
        } else {
            Pager(context: context)
        }
    }

    private var interactionContext: InteractionContext {
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
        snapshot: Snapshot,
        axisPointInfos: [ChartConfig.Axis.PointInfo]) -> SectionContext {
        .init(
            config: config,
            selectedTab: selectedTab,
            data: snapshot.data,
            yAxisTickValues: snapshot.yAxisTickValues,
            yAxisDisplayDomain: snapshot.yAxisDisplayDomain,
            showDebugOverlay: showDebugOverlay,
            selectionOverlay: slots.selectionOverlay,
            pagingContext: snapshot.pagingContext,
            yAxisLabel: { amount in
                yAxisLabel(for: amount, axisPointInfos: axisPointInfos)
            })
    }

    func makePagerContext(snapshot: Snapshot) -> PagerContext? {
        guard snapshot.hasData else { return nil }
        return .init(
            config: config,
            entries: snapshot.pagerState.entries,
            highlightedEntry: snapshot.pagerState.highlightedEntry,
            canSelectPreviousPage: snapshot.canSelectPreviousPage,
            canSelectNextPage: snapshot.canSelectNextPage,
            onSelectPreviousPage: { dispatch(.selectPreviousPage) },
            onSelectEntry: { entry in
                dispatch(.selectWindow(startIndex: entry.startIndex))
            },
            onSelectNextPage: { dispatch(.selectNextPage) })
    }

    func makeInteractionState(snapshot: Snapshot) -> InteractionState {
        .init(
            visibleSelection: visibleSelection,
            visiblePointIDs: snapshot.dataPointIDs,
            viewport: viewportState,
            unitWidth: layoutState.unitWidth,
            pagingContext: snapshot.pagingContext)
    }

    // MARK: - Dispatch

    func dispatch(_ action: ViewAction) {
        let snapshot = interactionSnapshot
        let interactionState = makeInteractionState(snapshot: snapshot)
        if config.debug.isLoggingEnabled {
            Self.interactionLogger.debug("Dispatching action: \(String(describing: action), privacy: .public)")
        }
        let result = InteractionReducer.reduce(action: action, state: interactionState)
        for mutation in result.mutations {
            apply(mutation, dataPointIDs: snapshot.dataPointIDs)
        }
        for command in result.commands {
            perform(command, data: snapshot.data, dataPointIDs: snapshot.dataPointIDs)
        }
    }

    // MARK: - Apply

    private func apply(
        _ mutation: InteractionMutation,
        dataPointIDs: [ChartPointID]) {
        switch mutation {
        case .selection(let visibleSelection, let emitsPointTap):
            if config.debug.isLoggingEnabled, let visibleSelection {
                Self.interactionLogger.debug(
                    "Applying selection mutation. index=\(visibleSelection.index) pointID=\(String(describing: visibleSelection.pointID), privacy: .public)")
            }
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
        data: [ChartDataPoint],
        dataPointIDs: [ChartPointID]) {
        switch command {
        case .emitPointTap(let visibleSelection):
            emitPointTap(
                for: visibleSelection,
                data: data,
                dataPointIDs: dataPointIDs)
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
        data: [ChartDataPoint],
        dataPointIDs: [ChartPointID]) {
        guard let resolvedIndex = CombinedChartView.SelectionResolver.resolvedVisibleIndex(
            for: visibleSelection,
            dataPointIDs: dataPointIDs)
        else { return }

        if config.debug.isLoggingEnabled {
            Self.interactionLogger.debug(
                """
                Emitting point tap. \
                resolvedIndex=\(resolvedIndex) \
                groupID=\(data[resolvedIndex].source.id.groupID, privacy: .public) \
                xKey=\(data[resolvedIndex].source.xKey, privacy: .public)
                """)
        }
        onPointTap?(
            .init(
                point: data[resolvedIndex].source,
                index: resolvedIndex))
    }
}
