@testable import CombinedChartFramework
import SwiftUI
import Testing

struct DragPagingStateTests {
    @Test func byPageDragUsesRealTranslationForPaging() {
        let state = CombinedChartView.DragPagingState(
            contentOffsetX: 0,
            visibleStartMonthIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -80,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        #expect(targetOffsetX == 400)
    }

    @Test func byPageDragBelowThresholdDoesNotPage() {
        let state = CombinedChartView.DragPagingState(
            contentOffsetX: 0,
            visibleStartMonthIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .byPage)

        let targetOffsetX = state.targetOffsetX(
            for: -79,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        #expect(targetOffsetX == 0)
    }

    @Test func freeSnappingRoundsToNearestMonth() {
        let state = CombinedChartView.DragPagingState(
            contentOffsetX: 130,
            visibleStartMonthIndex: 1,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .freeSnapping)

        let targetOffsetX = state.targetOffsetX(
            for: -30,
            computedUnitWidth: 100,
            computedViewportWidth: 400)

        #expect(targetOffsetX == 200)
    }

    @Test func targetMonthIndexClampsToValidRange() {
        let state = CombinedChartView.DragPagingState(
            contentOffsetX: 0,
            visibleStartMonthIndex: 0,
            monthsPerPage: 4,
            maxStartMonthIndex: 8,
            dragScrollMode: .free)

        let negativeIndex = state.targetMonthIndex(
            for: -120,
            computedUnitWidth: 100)
        let oversizedIndex = state.targetMonthIndex(
            for: 9999,
            computedUnitWidth: 100)

        #expect(negativeIndex == 0)
        #expect(oversizedIndex == 8)
    }
}
