import SwiftUI

extension CombinedChartView {
    struct ChartLayoutMetrics {
        let viewportWidth: CGFloat
        let unitWidth: CGFloat
        let chartWidth: CGFloat
        let maxContentOffsetX: CGFloat
        let currentContentOffsetX: CGFloat

        init(
            availableWidth: CGFloat,
            axisWidth: CGFloat,
            monthsPerPage: Int,
            dataCount: Int,
            dragPagingState: DragViewportState,
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxStartMonthIndex: Int) {
            let visibleCount = CGFloat(monthsPerPage)
            viewportWidth = max(availableWidth - axisWidth, 1)
            unitWidth = viewportWidth / visibleCount
            chartWidth = max(viewportWidth, unitWidth * CGFloat(dataCount))
            maxContentOffsetX = CGFloat(maxStartMonthIndex) * unitWidth
            currentContentOffsetX = dragPagingState.currentContentOffsetX(
                dragTranslationX: dragTranslationX,
                settlingOffsetX: settlingOffsetX,
                maxContentOffsetX: maxContentOffsetX)
        }
    }
}
