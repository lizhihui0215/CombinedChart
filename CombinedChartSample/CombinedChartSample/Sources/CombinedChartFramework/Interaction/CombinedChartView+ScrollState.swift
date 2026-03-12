import SwiftUI

extension CombinedChartView {
    struct ScrollState {
        let pagingContext: PagingContext
        let dragState: DragState
        let layoutMetrics: LayoutMetrics
        let viewport: ViewportDescriptor
        let renderContext: RenderContext

        init(
            context: SectionContext,
            viewportState: ViewportState,
            plotAreaHeight: CGFloat,
            visibleSelection: VisibleSelection?,
            availableWidth: CGFloat,
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat) {
            let dragState = DragState(
                contentOffsetX: viewportState.contentOffsetX,
                startIndex: viewportState.startIndex,
                visibleValueCount: context.pagingContext.visibleValueCount,
                maxStartIndex: context.pagingContext.maxStartIndex,
                dragScrollMode: context.config.pager.scrollTargetBehavior)
            let layoutMetrics = LayoutMetrics(
                availableWidth: availableWidth,
                axisWidth: context.config.axis.yAxisWidth,
                visibleValueCount: context.pagingContext.visibleValueCount,
                dataCount: context.data.count,
                dragState: dragState,
                dragTranslationX: dragTranslationX,
                settlingOffsetX: settlingOffsetX,
                maxStartIndex: context.pagingContext.maxStartIndex)

            pagingContext = context.pagingContext
            self.dragState = dragState
            self.layoutMetrics = layoutMetrics
            let viewport = ViewportDescriptor(
                dataCount: context.data.count,
                visibleValueCount: context.pagingContext.visibleValueCount,
                startIndex: viewportState.startIndex,
                contentOffsetX: viewportState.contentOffsetX,
                visibleStartThreshold: context.config.pager.visibleStartThreshold,
                layoutMetrics: layoutMetrics)
            self.viewport = viewport
            renderContext = context.makeRenderContext(
                plotAreaHeight: plotAreaHeight,
                viewport: viewport,
                visibleSelection: visibleSelection)
        }

        func makeDragSettleContext(
            from dragTranslationX: CGFloat) -> DragSettleContext {
            let targetOffsetX = dragState.targetOffsetX(
                for: dragTranslationX,
                computedUnitWidth: layoutMetrics.unitWidth,
                computedViewportWidth: layoutMetrics.viewportWidth)
            let targetIndex = dragState.targetIndex(
                for: targetOffsetX,
                computedUnitWidth: layoutMetrics.unitWidth)

            return .init(
                targetIndex: targetIndex,
                targetContentOffsetX: targetOffsetX)
        }

        func makeSettlingOffsetX(
            from dragTranslationX: CGFloat) -> CGFloat {
            dragState.clampedDisplayTranslationX(
                from: dragTranslationX,
                maxContentOffsetX: layoutMetrics.maxContentOffsetX)
        }

        func makeDragSettleContext(
            for proposedContentOffsetX: CGFloat) -> DragSettleContext {
            let clampedProposedOffsetX = min(
                max(proposedContentOffsetX, 0),
                layoutMetrics.maxContentOffsetX)

            let targetOffsetX: CGFloat
            switch dragState.dragScrollMode {
            case .byPage:
                let delta = clampedProposedOffsetX - dragState.contentOffsetX
                let threshold = layoutMetrics.viewportWidth * 0.2
                let pageDelta: Int = if delta >= threshold {
                    pagingContext.visibleValueCount
                } else if delta <= -threshold {
                    -pagingContext.visibleValueCount
                } else {
                    0
                }
                let targetIndex = min(
                    max(dragState.startIndex + pageDelta, 0),
                    pagingContext.maxStartIndex)
                targetOffsetX = CGFloat(targetIndex) * layoutMetrics.unitWidth
            case .freeSnapping:
                let snappedIndex = min(
                    max(Int(round(clampedProposedOffsetX / layoutMetrics.unitWidth)), 0),
                    pagingContext.maxStartIndex)
                targetOffsetX = CGFloat(snappedIndex) * layoutMetrics.unitWidth
            case .free:
                targetOffsetX = clampedProposedOffsetX
            }

            return .init(
                targetIndex: dragState.targetIndex(
                    for: targetOffsetX,
                    computedUnitWidth: layoutMetrics.unitWidth),
                targetContentOffsetX: targetOffsetX)
        }

        func syncViewport(
            layoutState: inout LayoutState,
            viewportState: inout ViewportState) {
            layoutState.update(
                viewportWidth: viewport.viewportWidth,
                unitWidth: viewport.unitWidth)
            viewportState.contentOffsetX = viewport.contentOffsetX
            viewportState.startIndex = viewport.startIndex
        }
    }
}
