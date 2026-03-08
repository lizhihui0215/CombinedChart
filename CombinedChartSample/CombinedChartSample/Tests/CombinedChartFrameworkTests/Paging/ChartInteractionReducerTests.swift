@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartInteractionReducerTests: XCTestCase {
    func testReducerBuildsByPagePreviousMutation() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectPreviousPage,
            state: makeState(
                visibleStartMonthIndex: 8,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 12,
                arrowScrollMode: .byPage))

        XCTAssertEqual(mutations.count, 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            return XCTFail("Expected monthWindow mutation")
        }
        XCTAssertEqual(startMonthIndex, 4)
        XCTAssertEqual(contentOffsetX, 400)
    }

    func testReducerBuildsByEntryNextMutation() {
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

        XCTAssertEqual(mutations.count, 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            return XCTFail("Expected monthWindow mutation")
        }
        XCTAssertEqual(startMonthIndex, 6)
        XCTAssertEqual(contentOffsetX, 600)
    }

    func testReducerClampsSelectMonthWindowMutation() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectMonthWindow(startMonthIndex: 99),
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(mutations.count, 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            return XCTFail("Expected monthWindow mutation")
        }
        XCTAssertEqual(startMonthIndex, 8)
        XCTAssertEqual(contentOffsetX, 800)
    }

    func testReducerPreservesFreeDragSettledOffset() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .settleDrag(targetMonthIndex: 3, targetContentOffsetX: 365),
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(mutations.count, 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            return XCTFail("Expected monthWindow mutation")
        }
        XCTAssertEqual(startMonthIndex, 3)
        XCTAssertEqual(contentOffsetX, 365)
    }

    func testReducerClampsSettledDragOffsetToMaximumRange() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .settleDrag(targetMonthIndex: 99, targetContentOffsetX: 9999),
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(mutations.count, 1)
        guard case .monthWindow(let startMonthIndex, let contentOffsetX) = mutations[0] else {
            return XCTFail("Expected monthWindow mutation")
        }
        XCTAssertEqual(startMonthIndex, 8)
        XCTAssertEqual(contentOffsetX, 800)
    }

    func testReducerSelectionMutationCarriesStablePointIdentity() {
        let mutations = CombinedChartView.InteractionReducer.mutations(
            for: .selectPoint(index: 1),
            state: makeState(
                visibleStartMonthIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage,
                visiblePointIDs: [
                    .init(groupID: "2024", xKey: "2024-01"),
                    .init(groupID: "2024", xKey: "2024-02")
                ]))

        XCTAssertEqual(mutations.count, 1)
        guard case .selection(let visibleSelection, let emitsPointTap) = mutations[0] else {
            return XCTFail("Expected selection mutation")
        }
        XCTAssertEqual(visibleSelection?.visibleIndex, 1)
        XCTAssertEqual(visibleSelection?.pointID, .init(groupID: "2024", xKey: "2024-02"))
        XCTAssertTrue(emitsPointTap)
    }

    private func makeState(
        visibleStartMonthIndex: Int,
        unitWidth: CGFloat,
        monthsPerPage: Int,
        maxStartMonthIndex: Int,
        arrowScrollMode: ChartConfig.ChartPagerConfig.ArrowScrollMode,
        visiblePointIDs: [CombinedChartView.ChartPointID] = [],
        currentYearRangeIndex: Int? = nil,
        yearPageRanges: [CombinedChartView.YearPageRange] = []) -> CombinedChartView.InteractionState {
        .init(
            visibleSelection: nil,
            visiblePointIDs: visiblePointIDs,
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
