import SwiftUI

extension CombinedChartView {
    struct InteractionState {
        let visibleSelection: VisibleSelection?
        let visiblePointIDs: [ChartPointID]
        let visibleStartMonthIndex: Int
        let contentOffsetX: CGFloat
        let unitWidth: CGFloat
        let monthsPerPage: Int
        let maxStartMonthIndex: Int
        let arrowScrollMode: ChartConfig.ChartPagerConfig.ArrowScrollMode
        let currentYearRangeIndex: Int?
        let yearPageRanges: [YearPageRange]
    }

    enum InteractionMutation {
        case selection(VisibleSelection?, emitsPointTap: Bool)
        case monthWindow(startMonthIndex: Int, contentOffsetX: CGFloat?)
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
            case .settleDrag(let targetMonthIndex, let targetContentOffsetX):
                return .init(
                    mutations: [settledDragMutation(
                        targetMonthIndex: targetMonthIndex,
                        targetContentOffsetX: targetContentOffsetX,
                        state: state)],
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
            switch state.arrowScrollMode {
            case .byPage:
                return [monthWindowMutation(
                    startMonthIndex: state.visibleStartMonthIndex + (direction * state.monthsPerPage),
                    state: state)]
            case .byEntry:
                guard let currentYearRangeIndex = state.currentYearRangeIndex else { return [] }
                let targetIndex = min(
                    max(currentYearRangeIndex + direction, 0),
                    max(state.yearPageRanges.count - 1, 0))
                guard state.yearPageRanges.indices.contains(targetIndex) else { return [] }
                return [monthWindowMutation(
                    startMonthIndex: state.yearPageRanges[targetIndex].startMonthIndex,
                    state: state)]
            }
        }

        private static func monthWindowMutation(
            startMonthIndex: Int,
            state: InteractionState) -> InteractionMutation {
            let clampedStartMonthIndex = min(max(startMonthIndex, 0), state.maxStartMonthIndex)
            let nextContentOffsetX = state.unitWidth > 0
                ? CGFloat(clampedStartMonthIndex) * state.unitWidth
                : nil

            return .monthWindow(
                startMonthIndex: clampedStartMonthIndex,
                contentOffsetX: nextContentOffsetX)
        }

        private static func settledDragMutation(
            targetMonthIndex: Int,
            targetContentOffsetX: CGFloat,
            state: InteractionState) -> InteractionMutation {
            let clampedStartMonthIndex = min(max(targetMonthIndex, 0), state.maxStartMonthIndex)
            let maximumContentOffsetX = CGFloat(state.maxStartMonthIndex) * state.unitWidth
            let clampedContentOffsetX = min(max(targetContentOffsetX, 0), maximumContentOffsetX)

            return .monthWindow(
                startMonthIndex: clampedStartMonthIndex,
                contentOffsetX: clampedContentOffsetX)
        }
    }
}
