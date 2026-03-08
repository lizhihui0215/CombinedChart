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

    enum InteractionReducer {
        static func mutations(for action: ViewAction, state: InteractionState) -> [InteractionMutation] {
            switch action {
            case .selectPoint(let index, let emitsPointTap):
                [.selection(selection(for: index, state: state), emitsPointTap: emitsPointTap)]
            case .selectMonthWindow(let startMonthIndex):
                [monthWindowMutation(startMonthIndex: startMonthIndex, state: state)]
            case .settleDrag(let targetMonthIndex, let targetContentOffsetX):
                [settledDragMutation(
                    targetMonthIndex: targetMonthIndex,
                    targetContentOffsetX: targetContentOffsetX,
                    state: state)]
            case .selectPreviousPage:
                monthWindowMutations(for: -1, state: state)
            case .selectNextPage:
                monthWindowMutations(for: 1, state: state)
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
