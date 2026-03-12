import SwiftUI

extension CombinedChartView {
    enum ViewAction {
        case selectPoint(index: Int?, emitsPointTap: Bool = true)
        case selectWindow(startIndex: Int)
        case settleDrag(DragSettleContext)
        case selectPreviousPage
        case selectNextPage
    }

    struct DragSettleContext: Equatable {
        let targetIndex: Int
        let targetContentOffsetX: CGFloat
    }

    struct ViewportUpdateContext: Equatable {
        let startIndex: Int
        let contentOffsetX: CGFloat?
    }

    struct ViewportState: Equatable {
        var startIndex: Int
        var contentOffsetX: CGFloat
    }

    struct PagingContext {
        let visibleValueCount: Int
        let maxStartIndex: Int
        let arrowScrollMode: ChartConfig.Pager.ArrowScrollMode
        let currentPageRangeIndex: Int?
        let pageRanges: [PageRange]
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
            case .selectWindow(let startIndex):
                viewportUpdateResult(
                    startIndex: startIndex,
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
                let currentPageStartIndex = pageAlignedStartIndex(
                    state.viewport.startIndex,
                    visibleValueCount: state.pagingContext.visibleValueCount)
                return currentPageStartIndex + (direction * state.pagingContext.visibleValueCount)
            case .byEntry:
                guard let currentPageRangeIndex = state.pagingContext.currentPageRangeIndex else {
                    return nil
                }
                let targetIndex = min(
                    max(currentPageRangeIndex + direction, 0),
                    max(state.pagingContext.pageRanges.count - 1, 0))
                guard state.pagingContext.pageRanges.indices.contains(targetIndex) else {
                    return nil
                }
                return state.pagingContext.pageRanges[targetIndex].startIndex
            }
        }

        private static func pageAlignedStartIndex(
            _ startIndex: Int,
            visibleValueCount: Int) -> Int {
            let pageSize = max(visibleValueCount, 1)
            return (max(startIndex, 0) / pageSize) * pageSize
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
                    startIndex: context.targetIndex,
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
            min(max(startIndex, 0), state.pagingContext.maxStartIndex)
        }

        private static func clampedContentOffsetX(
            _ contentOffsetX: CGFloat,
            state: InteractionState) -> CGFloat {
            let maximumContentOffsetX = CGFloat(state.pagingContext.maxStartIndex) * state.unitWidth
            return min(max(contentOffsetX, 0), maximumContentOffsetX)
        }
    }
}
