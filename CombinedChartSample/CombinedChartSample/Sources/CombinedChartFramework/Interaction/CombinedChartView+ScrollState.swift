import SwiftUI

extension CombinedChartView {
    struct ScrollState {
        let pagingContext: PagingContext
        let dragState: DragState
        let layoutMetrics: LayoutMetrics
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
                monthsPerPage: context.pagingContext.monthsPerPage,
                maxStartMonthIndex: context.pagingContext.maxStartMonthIndex,
                dragScrollMode: context.config.pager.dragScrollMode)
            let layoutMetrics = LayoutMetrics(
                availableWidth: availableWidth,
                axisWidth: context.config.axis.yAxisWidth,
                monthsPerPage: context.pagingContext.monthsPerPage,
                dataCount: context.data.count,
                dragState: dragState,
                dragTranslationX: dragTranslationX,
                settlingOffsetX: settlingOffsetX,
                maxStartMonthIndex: context.pagingContext.maxStartMonthIndex)

            pagingContext = context.pagingContext
            self.dragState = dragState
            self.layoutMetrics = layoutMetrics
            renderContext = context.makeRenderContext(
                plotAreaHeight: plotAreaHeight,
                unitWidth: layoutMetrics.unitWidth,
                visibleSelection: visibleSelection)
        }

        func makeDragSettleContext(
            from dragTranslationX: CGFloat) -> DragSettleContext {
            let targetOffsetX = dragState.targetOffsetX(
                for: dragTranslationX,
                computedUnitWidth: layoutMetrics.unitWidth,
                computedViewportWidth: layoutMetrics.viewportWidth)
            let targetMonthIndex = dragState.targetMonthIndex(
                for: targetOffsetX,
                computedUnitWidth: layoutMetrics.unitWidth)

            return .init(
                targetMonthIndex: targetMonthIndex,
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
                    pagingContext.monthsPerPage
                } else if delta <= -threshold {
                    -pagingContext.monthsPerPage
                } else {
                    0
                }
                let targetMonthIndex = min(
                    max(dragState.startIndex + pageDelta, 0),
                    pagingContext.maxStartMonthIndex)
                targetOffsetX = CGFloat(targetMonthIndex) * layoutMetrics.unitWidth
            case .freeSnapping:
                let snappedMonthIndex = min(
                    max(Int(round(clampedProposedOffsetX / layoutMetrics.unitWidth)), 0),
                    pagingContext.maxStartMonthIndex)
                targetOffsetX = CGFloat(snappedMonthIndex) * layoutMetrics.unitWidth
            case .free:
                targetOffsetX = clampedProposedOffsetX
            }

            return .init(
                targetMonthIndex: dragState.targetMonthIndex(
                    for: targetOffsetX,
                    computedUnitWidth: layoutMetrics.unitWidth),
                targetContentOffsetX: targetOffsetX)
        }

        func syncViewport(
            layoutState: inout LayoutState,
            viewportState: inout ViewportState) {
            layoutState.update(
                viewportWidth: layoutMetrics.viewportWidth,
                unitWidth: layoutMetrics.unitWidth)
            viewportState.contentOffsetX = CGFloat(viewportState.startIndex) * layoutMetrics.unitWidth
        }
    }
}
