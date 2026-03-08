@testable import CombinedChartFramework
import SwiftUI
import Testing

struct ChartInteractionReducerTests {
    @Test func reducerBuildsByPagePreviousMutation() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectPreviousPage,
            state: makeState(
                visibleStartMonthIndex: 8,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 12,
                arrowScrollMode: .byPage))

        #expect(mutations.count == 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            Issue.record("Expected monthWindow mutation")
            return
        }
        #expect(startMonthIndex == 4)
        #expect(contentOffsetX == 400)
    }

    @Test func reducerBuildsByEntryNextMutation() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectNextPage,
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 12,
                arrowScrollMode: .byEntry,
                currentYearRangeIndex: 0,
                yearPageRanges: [
                    .init(
                        displayTitle: "2024",
                        groupOrder: 0,
                        startMonthIndex: 0,
                        endMonthIndex: 5,
                        startPage: 0,
                        endPage: 1),
                    .init(
                        displayTitle: "2025",
                        groupOrder: 1,
                        startMonthIndex: 6,
                        endMonthIndex: 11,
                        startPage: 1,
                        endPage: 2)
                ]))

        #expect(mutations.count == 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            Issue.record("Expected monthWindow mutation")
            return
        }
        #expect(startMonthIndex == 6)
        #expect(contentOffsetX == 600)
    }

    @Test func reducerClampsSelectMonthWindowMutation() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectMonthWindow(startMonthIndex: 99),
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        #expect(mutations.count == 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            Issue.record("Expected monthWindow mutation")
            return
        }
        #expect(startMonthIndex == 8)
        #expect(contentOffsetX == 800)
    }

    private func makeState(
        visibleStartMonthIndex: Int,
        unitWidth: CGFloat,
        monthsPerPage: Int,
        maxStartMonthIndex: Int,
        arrowScrollMode: ChartConfig.ChartPagerConfig.ArrowScrollMode,
        currentYearRangeIndex: Int? = nil,
        yearPageRanges: [CombinedChartView.YearPageRange] = []) -> CombinedChartView.InteractionState {
        .init(
            selectedIndex: nil,
            visibleStartMonthIndex: visibleStartMonthIndex,
            contentOffsetX: CGFloat(visibleStartMonthIndex) * unitWidth,
            unitWidth: unitWidth,
            monthsPerPage: monthsPerPage,
            maxStartMonthIndex: maxStartMonthIndex,
            arrowScrollMode: arrowScrollMode,
            currentYearRangeIndex: currentYearRangeIndex,
            yearPageRanges: yearPageRanges)
    }
}
