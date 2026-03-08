@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class DragViewportStateTests: XCTestCase {
    func testByPageDragUsesRealTranslationForPaging() {
        let state = CombinedChartView.DragViewportState(
            contentOffsetX: 0,
            startIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -80,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 400)
    }

    func testByPageDragBelowThresholdDoesNotPage() {
        let state = CombinedChartView.DragViewportState(
            contentOffsetX: 0,
            startIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -79,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 0)
    }

    func testFreeSnappingRoundsToNearestMonth() {
        let state = CombinedChartView.DragViewportState(
            contentOffsetX: 130,
            startIndex: 1,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .freeSnapping)

        let targetOffsetX = state.targetOffsetX(
            for: -30,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        XCTAssertEqual(targetOffsetX, 200)
    }

    func testTargetMonthIndexClampsToValidRange() {
        let state = CombinedChartView.DragViewportState(
            contentOffsetX: 0,
            startIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .free)

        let negativeIndex = state.targetMonthIndex(
            for: -120,
            computedUnitWidth: 100)
        let oversizedIndex = state.targetMonthIndex(
            for: 9999,
            computedUnitWidth: 100)

        XCTAssertEqual(negativeIndex, 0)
        XCTAssertEqual(oversizedIndex, 8)
    }
}
