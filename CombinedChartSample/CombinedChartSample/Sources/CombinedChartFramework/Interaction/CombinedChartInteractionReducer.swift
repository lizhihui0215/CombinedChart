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
                selectionResult(
                    for: index,
                    emitsPointTap: emitsPointTap,
                    state: state)
            case .selectMonthWindow(let startMonthIndex):
                .init(
                    mutations: [monthWindowMutation(startMonthIndex: startMonthIndex, state: state)],
                    commands: [])
            case .settleDrag(let context):
                .init(
                    mutations: [settledDragMutation(context: context, state: state)],
                    commands: [])
            case .selectPreviousPage:
                .init(
                    mutations: monthWindowMutations(for: -1, state: state),
                    commands: [])
            case .selectNextPage:
                .init(
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

        private static func selectionResult(
            for visibleIndex: Int?,
            emitsPointTap: Bool,
            state: InteractionState) -> InteractionResult {
            let selection = selection(for: visibleIndex, state: state)
            return .init(
                mutations: [.selection(selection, emitsPointTap: emitsPointTap)],
                commands: emitsPointTap ? selection.map { [.emitPointTap($0)] } ?? [] : [])
        }

        private static func monthWindowMutations(
            for direction: Int,
            state: InteractionState) -> [InteractionMutation] {
            guard let startMonthIndex = targetStartMonthIndex(
                for: direction,
                state: state)
            else { return [] }

            return [monthWindowMutation(
                startMonthIndex: startMonthIndex,
                state: state)]
        }

        private static func monthWindowMutation(
            startMonthIndex: Int,
            state: InteractionState) -> InteractionMutation {
            .monthWindow(
                makeMonthWindowContext(
                    startMonthIndex: startMonthIndex,
                    contentOffsetX: nil,
                    state: state))
        }

        private static func settledDragMutation(
            context: DragSettleContext,
            state: InteractionState) -> InteractionMutation {
            .monthWindow(
                makeMonthWindowContext(
                    startMonthIndex: context.targetMonthIndex,
                    contentOffsetX: context.targetContentOffsetX,
                    state: state))
        }

        private static func makeMonthWindowContext(
            startMonthIndex: Int,
            contentOffsetX: CGFloat?,
            state: InteractionState) -> MonthWindowContext {
            let clampedStartMonthIndex = clampedStartMonthIndex(
                startMonthIndex,
                state: state)

            let resolvedContentOffsetX: CGFloat? = if let contentOffsetX {
                clampedContentOffsetX(contentOffsetX, state: state)
            } else if state.unitWidth > 0 {
                CGFloat(clampedStartMonthIndex) * state.unitWidth
            } else {
                nil
            }

            return .init(
                startMonthIndex: clampedStartMonthIndex,
                contentOffsetX: resolvedContentOffsetX)
        }

        private static func targetStartMonthIndex(
            for direction: Int,
            state: InteractionState) -> Int? {
            switch state.pagingContext.arrowScrollMode {
            case .byPage:
                return state.viewport.visibleStartMonthIndex + (direction * state.pagingContext.monthsPerPage)
            case .byEntry:
                guard let currentYearRangeIndex = state.pagingContext.currentYearRangeIndex else {
                    return nil
                }
                let targetIndex = min(
                    max(currentYearRangeIndex + direction, 0),
                    max(state.pagingContext.yearPageRanges.count - 1, 0))
                guard state.pagingContext.yearPageRanges.indices.contains(targetIndex) else {
                    return nil
                }
                return state.pagingContext.yearPageRanges[targetIndex].startMonthIndex
            }
        }

        private static func clampedStartMonthIndex(
            _ startMonthIndex: Int,
            state: InteractionState) -> Int {
            min(max(startMonthIndex, 0), state.pagingContext.maxStartMonthIndex)
        }

        private static func clampedContentOffsetX(
            _ contentOffsetX: CGFloat,
            state: InteractionState) -> CGFloat {
            let maximumContentOffsetX = CGFloat(state.pagingContext.maxStartMonthIndex) * state.unitWidth
            return min(max(contentOffsetX, 0), maximumContentOffsetX)
        }
    }
}
