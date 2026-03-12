import SwiftUI

extension CombinedChartView {
    struct LayoutMetrics {
        let viewportWidth: CGFloat
        let unitWidth: CGFloat
        let chartWidth: CGFloat
        let maxContentOffsetX: CGFloat
        let currentContentOffsetX: CGFloat

        init(
            availableWidth: CGFloat,
            axisWidth: CGFloat,
            visibleValueCount: Int,
            dataCount: Int,
            dragState: DragState,
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxStartIndex: Int) {
            let visibleCount = CGFloat(visibleValueCount)
            viewportWidth = max(availableWidth - axisWidth, 1)
            unitWidth = viewportWidth / visibleCount
            chartWidth = max(viewportWidth, unitWidth * CGFloat(dataCount))
            maxContentOffsetX = CGFloat(maxStartIndex) * unitWidth
            currentContentOffsetX = dragState.currentContentOffsetX(
                dragTranslationX: dragTranslationX,
                settlingOffsetX: settlingOffsetX,
                maxContentOffsetX: maxContentOffsetX)
        }
    }
}
