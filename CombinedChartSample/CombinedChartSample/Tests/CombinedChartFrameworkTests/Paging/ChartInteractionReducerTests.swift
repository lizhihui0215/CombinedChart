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
                visibleValueCount: 4,
                maxStartIndex: 12,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 4)
        XCTAssertEqual(context.contentOffsetX, 400)
    }

    func testReducerBuildsByEntryNextMutation() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectNextPage,
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 12,
                arrowScrollMode: .byEntry,
                currentPageRangeIndex: 0,
                pageRanges: [
                    .init(
                        displayTitle: "2024",
                        groupOrder: 0,
                        startIndex: 0,
                        endIndex: 5,
                        startPage: 0,
                        endPage: 1),
                    .init(
                        displayTitle: "2025",
                        groupOrder: 1,
                        startIndex: 6,
                        endIndex: 11,
                        startPage: 1,
                        endPage: 2)
                ]))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 6)
        XCTAssertEqual(context.contentOffsetX, 600)
    }

    func testReducerBuildsByPageNextMutationFromPartialPageStart() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectNextPage,
            state: makeState(
                startIndex: 2,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 12,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 4)
        XCTAssertEqual(context.contentOffsetX, 400)
    }

    func testReducerBuildsByPagePreviousMutationFromPartialPageStart() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectPreviousPage,
            state: makeState(
                startIndex: 6,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 12,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 0)
        XCTAssertEqual(context.contentOffsetX, 0)
    }

    func testReducerClampsSelectWindowMutation() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectWindow(startIndex: 99),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 8)
        XCTAssertEqual(context.contentOffsetX, 800)
    }

    func testReducerPreservesFreeDragSettledOffset() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .settleDrag(.init(targetIndex: 3, targetContentOffsetX: 365)),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 3)
        XCTAssertEqual(context.contentOffsetX, 365)
    }

    func testReducerClampsSettledDragOffsetToMaximumRange() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .settleDrag(.init(targetIndex: 99, targetContentOffsetX: 9999)),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 8,
                arrowScrollMode: .byPage))

        XCTAssertEqual(result.mutations.count, 1)
        XCTAssertTrue(result.commands.isEmpty)
        guard case .viewportUpdate(let context) = result.mutations[0] else {
            return XCTFail("Expected viewportUpdate mutation")
        }
        XCTAssertEqual(context.startIndex, 8)
        XCTAssertEqual(context.contentOffsetX, 800)
    }

    func testReducerSelectionMutationCarriesStablePointIdentity() {
        let result = CombinedChartView.InteractionReducer.reduce(
            action: .selectPoint(index: 1),
            state: makeState(
                startIndex: 0,
                unitWidth: 100,
                visibleValueCount: 4,
                maxStartIndex: 8,
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
                visibleValueCount: 4,
                maxStartIndex: 8,
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
        visibleValueCount: Int,
        maxStartIndex: Int,
        arrowScrollMode: ChartConfig.Pager.ArrowScrollMode,
        visiblePointIDs: [CombinedChartView.ChartPointID] = [],
        currentPageRangeIndex: Int? = nil,
        pageRanges: [CombinedChartView.PageRange] = []) -> CombinedChartView.InteractionState {
        .init(
            visibleSelection: nil,
            visiblePointIDs: visiblePointIDs,
            viewport: .init(
                startIndex: startIndex,
                contentOffsetX: CGFloat(startIndex) * unitWidth),
            unitWidth: unitWidth,
            pagingContext: .init(
                visibleValueCount: visibleValueCount,
                maxStartIndex: maxStartIndex,
                arrowScrollMode: arrowScrollMode,
                currentPageRangeIndex: currentPageRangeIndex,
                pageRanges: pageRanges))
    }
}
