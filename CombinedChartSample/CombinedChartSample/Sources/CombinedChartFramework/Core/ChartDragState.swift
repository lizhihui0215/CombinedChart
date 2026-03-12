import SwiftUI

extension CombinedChartView {
    struct DragState {
        let contentOffsetX: CGFloat
        let startIndex: Int
        let visibleValueCount: Int
        let maxStartIndex: Int
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
            let maxContentOffsetX = CGFloat(maxStartIndex) * computedUnitWidth
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
                    visibleValueCount
                } else if clampedTranslationX >= threshold {
                    -visibleValueCount
                } else {
                    0
                }
                let targetIndex = min(
                    max(startIndex + pageDelta, 0),
                    maxStartIndex)
                return CGFloat(targetIndex) * computedUnitWidth
            case .freeSnapping:
                let snappedIndex = min(
                    max(Int(round(proposedContentOffsetX / computedUnitWidth)), 0),
                    maxStartIndex)
                return CGFloat(snappedIndex) * computedUnitWidth
            case .free:
                return proposedContentOffsetX
            }
        }

        func targetIndex(
            for targetContentOffsetX: CGFloat,
            computedUnitWidth: CGFloat) -> Int {
            min(
                max(Int(floor(targetContentOffsetX / computedUnitWidth)), 0),
                maxStartIndex)
        }
    }
}
