@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class DragViewportStateTests: XCTestCase {
    func testByPageDragUsesRealTranslationForPaging() {
        let state = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 4,
            maxStartIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -80,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 400)
    }

    func testByPageDragBelowThresholdDoesNotPage() {
        let state = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 4,
            maxStartIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -79,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 0)
    }

    func testFreeSnappingRoundsToNearestValue() {
        let state = CombinedChartView.DragState(
            contentOffsetX: 130,
            startIndex: 1,
            visibleValueCount: 4,
            maxStartIndex: 8,
            dragScrollMode: .freeSnapping)

        let targetOffsetX = state.targetOffsetX(
            for: -30,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 200)
    }

    func testTargetIndexClampsToValidRange() {
        let state = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 4,
            maxStartIndex: 8,
            dragScrollMode: .free)

        let negativeIndex = state.targetIndex(
            for: -120,
            computedUnitWidth: 100)
        let oversizedIndex = state.targetIndex(
            for: 9999,
            computedUnitWidth: 100)

        XCTAssertEqual(negativeIndex, 0)
        XCTAssertEqual(oversizedIndex, 8)
    }
}
