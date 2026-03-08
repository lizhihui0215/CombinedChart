import SwiftUI

extension CombinedChartView {
    struct SectionScrollState {
        let pagingContext: PagingContext
        let dragState: DragViewportState
        let layoutMetrics: ChartLayoutMetrics
        let renderContext: ChartRenderContext

        init(
            context: SectionContext,
            viewportState: ViewportState,
            plotAreaHeight: CGFloat,
            visibleSelection: VisibleSelection?,
            availableWidth: CGFloat,
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat) {
            let dragState = DragViewportState(
                contentOffsetX: viewportState.contentOffsetX,
                startIndex: viewportState.startIndex,
                monthsPerPage: context.pagingContext.monthsPerPage,
                maxStartMonthIndex: context.pagingContext.maxStartMonthIndex,
                dragScrollMode: context.config.pager.dragScrollMode)
            let layoutMetrics = ChartLayoutMetrics(
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
