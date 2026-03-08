import SwiftUI

extension CombinedChartView {
    struct InteractionState {
        let visibleSelection: VisibleSelection?
        let visiblePointIDs: [ChartPointID]
        let viewport: ViewportState
        let unitWidth: CGFloat
        let pagingContext: PagingContext
    }

    enum InteractionMutation {
        case selection(VisibleSelection?, emitsPointTap: Bool)
        case monthWindow(MonthWindowContext)
    }

    enum InteractionCommand: Equatable {
        case emitPointTap(VisibleSelection)
    }

    struct InteractionResult {
        let mutations: [InteractionMutation]
        let commands: [InteractionCommand]
    }

    enum InteractionReducer {
        static func reduce(action: ViewAction, state: InteractionState) -> InteractionResult {
            switch action {
            case .selectPoint(let index, let emitsPointTap):
                let selection = selection(for: index, state: state)
                return .init(
                    mutations: [.selection(selection, emitsPointTap: emitsPointTap)],
                    commands: emitsPointTap ? selection.map { [.emitPointTap($0)] } ?? [] : [])
            case .selectMonthWindow(let startMonthIndex):
                return .init(
                    mutations: [monthWindowMutation(startMonthIndex: startMonthIndex, state: state)],
                    commands: [])
            case .settleDrag(let context):
                return .init(
                    mutations: [settledDragMutation(context: context, state: state)],
                    commands: [])
            case .selectPreviousPage:
                return .init(
                    mutations: monthWindowMutations(for: -1, state: state),
                    commands: [])
            case .selectNextPage:
                return .init(
                    mutations: monthWindowMutations(for: 1, state: state),
                    commands: [])
            }
        }

        private static func selection(for visibleIndex: Int?, state: InteractionState) -> VisibleSelection? {
            guard let visibleIndex, state.visiblePointIDs.indices.contains(visibleIndex) else {
                return nil
            }
            return .init(
                visibleIndex: visibleIndex,
                pointID: state.visiblePointIDs[visibleIndex])
        }

        private static func monthWindowMutations(
            for direction: Int,
            state: InteractionState) -> [InteractionMutation] {
            switch state.pagingContext.arrowScrollMode {
            case .byPage:
                return [monthWindowMutation(
                    startMonthIndex: state.viewport
                        .visibleStartMonthIndex + (direction * state.pagingContext.monthsPerPage),
                    state: state)]
            case .byEntry:
                guard let currentYearRangeIndex = state.pagingContext.currentYearRangeIndex else { return [] }
                let targetIndex = min(
                    max(currentYearRangeIndex + direction, 0),
                    max(state.pagingContext.yearPageRanges.count - 1, 0))
                guard state.pagingContext.yearPageRanges.indices.contains(targetIndex) else { return [] }
                return [monthWindowMutation(
                    startMonthIndex: state.pagingContext.yearPageRanges[targetIndex].startMonthIndex,
                    state: state)]
            }
        }

        private static func monthWindowMutation(
            startMonthIndex: Int,
            state: InteractionState) -> InteractionMutation {
            let clampedStartMonthIndex = min(max(startMonthIndex, 0), state.pagingContext.maxStartMonthIndex)
            let nextContentOffsetX = state.unitWidth > 0
                ? CGFloat(clampedStartMonthIndex) * state.unitWidth
                : nil

            return .monthWindow(
                .init(
                    startMonthIndex: clampedStartMonthIndex,
                    contentOffsetX: nextContentOffsetX))
        }

        private static func settledDragMutation(
            context: DragSettleContext,
            state: InteractionState) -> InteractionMutation {
            let clampedStartMonthIndex = min(
                max(context.targetMonthIndex, 0),
                state.pagingContext.maxStartMonthIndex)
            let maximumContentOffsetX = CGFloat(state.pagingContext.maxStartMonthIndex) * state.unitWidth
            let clampedContentOffsetX = min(
                max(context.targetContentOffsetX, 0),
                maximumContentOffsetX)

            return .monthWindow(
                .init(
                    startMonthIndex: clampedStartMonthIndex,
                    contentOffsetX: clampedContentOffsetX))
        }
    }
}
