import SwiftUI

extension CombinedChartView {
    struct DragState {
        let contentOffsetX: CGFloat
        let startIndex: Int
        let monthsPerPage: Int
        let maxStartMonthIndex: Int
        let dragScrollMode: ChartConfig.Pager.DragScrollMode

        private func displayTranslationX(from dragTranslationX: CGFloat) -> CGFloat {
            switch dragScrollMode {
            case .byPage:
                0
            case .freeSnapping, .free:
                dragTranslationX
            }
        }

        private func clampedDragTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            let maxRightDragOffset = contentOffsetX
            let maxLeftDragOffset = max(maxContentOffsetX - contentOffsetX, 0)

            return min(
                max(dragTranslationX, -maxLeftDragOffset),
                maxRightDragOffset)
        }

        func clampedDisplayTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            clampedDragTranslationX(
                from: displayTranslationX(from: dragTranslationX),
                maxContentOffsetX: maxContentOffsetX)
        }

        func currentContentOffsetX(
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            -contentOffsetX + settlingOffsetX + clampedDisplayTranslationX(
                from: dragTranslationX,
                maxContentOffsetX: maxContentOffsetX)
        }

        func targetOffsetX(
            for rawTranslationX: CGFloat,
            computedUnitWidth: CGFloat,
            computedViewportWidth: CGFloat) -> CGFloat {
            let maxContentOffsetX = CGFloat(maxStartMonthIndex) * computedUnitWidth
            let clampedTranslationX = clampedDragTranslationX(
                from: rawTranslationX,
                maxContentOffsetX: maxContentOffsetX)
            let proposedContentOffsetX = min(
                max(contentOffsetX - clampedTranslationX, 0),
                maxContentOffsetX)

            switch dragScrollMode {
            case .byPage:
                let threshold = computedViewportWidth * 0.2
                let pageDelta: Int = if clampedTranslationX <= -threshold {
                    monthsPerPage
                } else if clampedTranslationX >= threshold {
                    -monthsPerPage
                } else {
                    0
                }
                let targetMonthIndex = min(
                    max(startIndex + pageDelta, 0),
                    maxStartMonthIndex)
                return CGFloat(targetMonthIndex) * computedUnitWidth
            case .freeSnapping:
                let snappedMonthIndex = min(
                    max(Int(round(proposedContentOffsetX / computedUnitWidth)), 0),
                    maxStartMonthIndex)
                return CGFloat(snappedMonthIndex) * computedUnitWidth
            case .free:
                return proposedContentOffsetX
            }
        }

        func targetMonthIndex(
            for targetContentOffsetX: CGFloat,
            computedUnitWidth: CGFloat) -> Int {
            min(
                max(Int(floor(targetContentOffsetX / computedUnitWidth)), 0),
                maxStartMonthIndex)
        }
    }
}
