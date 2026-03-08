import SwiftUI

extension CombinedChartView {
    enum ViewAction {
        case selectPoint(index: Int?, emitsPointTap: Bool = true)
        case selectMonthWindow(startMonthIndex: Int)
        case settleDrag(DragSettleContext)
        case selectPreviousPage
        case selectNextPage
    }

    struct DragSettleContext: Equatable {
        let targetMonthIndex: Int
        let targetContentOffsetX: CGFloat
    }

    struct ViewportUpdateContext: Equatable {
        let startIndex: Int
        let contentOffsetX: CGFloat?
    }

    struct ViewportState: Equatable {
        var startIndex: Int
        var contentOffsetX: CGFloat

        var visibleStartMonthIndex: Int {
            get { startIndex }
            set { startIndex = newValue }
        }
    }

    struct PagingContext {
        let monthsPerPage: Int
        let maxStartMonthIndex: Int
        let arrowScrollMode: ChartConfig.Pager.ArrowScrollMode
        let currentYearRangeIndex: Int?
        let yearPageRanges: [YearPageRange]
    }

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

        private static func makeSelection(
            for index: Int?,
            state: InteractionState) -> VisibleSelection? {
            guard let index, state.visiblePointIDs.indices.contains(index) else {
                return nil
            }
            return .init(
                index: index,
                pointID: state.visiblePointIDs[index])
        }

        private static func selectionCommands(
            for selection: VisibleSelection?,
            emitsPointTap: Bool) -> [InteractionCommand] {
            guard emitsPointTap, let selection else { return [] }
            return [.emitPointTap(selection)]
        }

        private static func selectionResult(
            for index: Int?,
            emitsPointTap: Bool,
            state: InteractionState) -> InteractionResult {
            let selection = makeSelection(for: index, state: state)
            return .init(
                mutations: [.selection(selection, emitsPointTap: emitsPointTap)],
                commands: selectionCommands(
                    for: selection,
                    emitsPointTap: emitsPointTap))
        }

        // MARK: - Navigation

        private static func navigationResult(
            for direction: Int,
            state: InteractionState) -> InteractionResult {
            guard let startIndex = targetStartIndex(
                for: direction,
                state: state)
            else {
                return .init(mutations: [], commands: [])
            }

            return viewportUpdateResult(
                startIndex: startIndex,
                state: state)
        }

        private static func targetStartIndex(
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
                mutations: [viewportUpdateMutation(
                    startIndex: context.targetMonthIndex,
                    contentOffsetX: context.targetContentOffsetX,
                    state: state)],
                commands: [])
        }

        private static func viewportUpdateMutation(
            startIndex: Int,
            contentOffsetX: CGFloat? = nil,
            state: InteractionState) -> InteractionMutation {
            .viewportUpdate(
                makeViewportUpdateContext(
                    startIndex: startIndex,
                    contentOffsetX: contentOffsetX,
                    state: state))
        }

        private static func makeViewportUpdateContext(
            startIndex: Int,
            contentOffsetX: CGFloat?,
            state: InteractionState) -> ViewportUpdateContext {
            let clampedStartIndex = clampedStartIndex(
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

        private static func clampedStartIndex(
            _ startIndex: Int,
            state: InteractionState) -> Int {
            min(max(startIndex, 0), state.pagingContext.maxStartMonthIndex)
        }

        private static func clampedContentOffsetX(
            _ contentOffsetX: CGFloat,
            state: InteractionState) -> CGFloat {
            let maximumContentOffsetX = CGFloat(state.pagingContext.maxStartMonthIndex) * state.unitWidth
            return min(max(contentOffsetX, 0), maximumContentOffsetX)
        }
    }
}
