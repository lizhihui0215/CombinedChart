@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartInteractionReducerTests: XCTestCase {
    func testReducerBuildsByPagePreviousMutation() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectPreviousPage,
            state: makeState(
                startIndex: 8,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 12,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startMonthIndex, 4)
        XCTAssertEqual(context.contentOffsetX, 400)
    }

    func testReducerBuildsByEntryNextMutation() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectNextPage,
            state: makeState(
                startIndex: 0,
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

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startMonthIndex, 6)
        XCTAssertEqual(context.contentOffsetX, 600)
    }

    func testReducerClampsSelectMonthWindowMutation() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectMonthWindow(startMonthIndex: 99),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startMonthIndex, 8)
        XCTAssertEqual(context.contentOffsetX, 800)
    }

    func testReducerPreservesFreeDragSettledOffset() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .settleDrag(.init(targetMonthIndex: 3, targetContentOffsetX: 365)),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startMonthIndex, 3)
        XCTAssertEqual(context.contentOffsetX, 365)
    }

    func testReducerClampsSettledDragOffsetToMaximumRange() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .settleDrag(.init(targetMonthIndex: 99, targetContentOffsetX: 9999)),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startMonthIndex, 8)
        XCTAssertEqual(context.contentOffsetX, 800)
    }

    func testReducerSelectionMutationCarriesStablePointIdentity() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectPoint(index: 1),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage,
                visiblePointIDs: [
                    .init(groupID: "2024", xKey: "2024-01"),
                    .init(groupID: "2024", xKey: "2024-02")
                ]))

        XCTAssertEqual(result.mutations.count, 1)
        guard case .selection(let visibleSelection, let emitsPointTap) = result.mutations[0] else {
            return XCTFail("Expected selection mutation")
        }
        XCTAssertEqual(visibleSelection?.index, 1)
        XCTAssertEqual(visibleSelection?.pointID, .init(groupID: "2024", xKey: "2024-02"))
        XCTAssertTrue(emitsPointTap)
        XCTAssertEqual(result.commands, [.emitPointTap(.init(
            index: 1,
            pointID: .init(groupID: "2024", xKey: "2024-02")))])
    }

    func testReducerSelectionWithoutEmitTapProducesNoCommand() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectPoint(index: 1, emitsPointTap: false),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                monthsPerPage: 4,
                maxStartMonthIndex: 8,
                arrowScrollMode: .byPage,
                visiblePointIDs: [
                    .init(groupID: "2024", xKey: "2024-01"),
                    .init(groupID: "2024", xKey: "2024-02")
                ]))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
    }

    private func makeState(
        startIndex: Int,
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
            viewport: .init(
                startIndex: startIndex,
                contentOffsetX: CGFloat(startIndex) * unitWidth),
            unitWidth: unitWidth,
            pagingContext: .init(
                monthsPerPage: monthsPerPage,
                maxStartMonthIndex: maxStartMonthIndex,
                arrowScrollMode: arrowScrollMode,
                currentYearRangeIndex: currentYearRangeIndex,
                yearPageRanges: yearPageRanges))
    }
}
