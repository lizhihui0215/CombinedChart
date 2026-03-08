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
        case viewportUpdate(ViewportUpdateContext)
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
                viewportUpdateResult(
                    startIndex: startMonthIndex,
                    state: state)
            case .settleDrag(let context):
                settledDragResult(
                    context: context,
                    state: state)
            case .selectPreviousPage:
                navigationResult(
                    for: -1,
                    state: state)
            case .selectNextPage:
                navigationResult(
                    for: 1,
                    state: state)
            }
        }

        // MARK: - Selection

        private static func selection(for index: Int?, state: InteractionState) -> VisibleSelection? {
            guard let index, state.visiblePointIDs.indices.contains(index) else {
                return nil
            }
            return .init(
                index: index,
                pointID: state.visiblePointIDs[index])
        }

        private static func selectionResult(
            for index: Int?,
            emitsPointTap: Bool,
            state: InteractionState) -> InteractionResult {
            let selection = selection(for: index, state: state)
            return .init(
                mutations: [.selection(selection, emitsPointTap: emitsPointTap)],
                commands: emitsPointTap ? selection.map { [.emitPointTap($0)] } ?? [] : [])
        }

        // MARK: - Navigation

        private static func navigationResult(
            for direction: Int,
            state: InteractionState) -> InteractionResult {
            .init(
                mutations: viewportUpdateMutations(for: direction, state: state),
                commands: [])
        }

        private static func viewportUpdateMutations(
            for direction: Int,
            state: InteractionState) -> [InteractionMutation] {
            guard let startIndex = targetStartMonthIndex(
                for: direction,
                state: state)
            else { return [] }

            return [viewportUpdateMutation(
                startIndex: startIndex,
                state: state)]
        }

        private static func targetStartMonthIndex(
            for direction: Int,
            state: InteractionState) -> Int? {
            switch state.pagingContext.arrowScrollMode {
            case .byPage:
                return state.viewport.startIndex + (direction * state.pagingContext.monthsPerPage)
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

        // MARK: - Viewport

        private static func viewportUpdateResult(
            startIndex: Int,
            state: InteractionState) -> InteractionResult {
            .init(
                mutations: [viewportUpdateMutation(startIndex: startIndex, state: state)],
                commands: [])
        }

        private static func settledDragResult(
            context: DragSettleContext,
            state: InteractionState) -> InteractionResult {
            .init(
                mutations: [settledDragMutation(context: context, state: state)],
                commands: [])
        }

        private static func viewportUpdateMutation(
            startIndex: Int,
            state: InteractionState) -> InteractionMutation {
            .viewportUpdate(
                makeViewportUpdateContext(
                    startIndex: startIndex,
                    contentOffsetX: nil,
                    state: state))
        }

        private static func settledDragMutation(
            context: DragSettleContext,
            state: InteractionState) -> InteractionMutation {
            .viewportUpdate(
                makeViewportUpdateContext(
                    startIndex: context.targetMonthIndex,
                    contentOffsetX: context.targetContentOffsetX,
                    state: state))
        }

        private static func makeViewportUpdateContext(
            startIndex: Int,
            contentOffsetX: CGFloat?,
            state: InteractionState) -> ViewportUpdateContext {
            let clampedStartIndex = clampedStartMonthIndex(
                startIndex,
                state: state)

            let resolvedContentOffsetX: CGFloat? = if let contentOffsetX {
                clampedContentOffsetX(contentOffsetX, state: state)
            } else if state.unitWidth > 0 {
                CGFloat(clampedStartIndex) * state.unitWidth
            } else {
                nil
            }

            return .init(
                startIndex: clampedStartIndex,
                contentOffsetX: resolvedContentOffsetX)
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
