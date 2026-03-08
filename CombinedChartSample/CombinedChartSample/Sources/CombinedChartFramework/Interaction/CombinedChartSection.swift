import SwiftUI

extension CombinedChartView {
    struct CombinedChartSection: View {
        let context: SectionContext
        let visibleSelection: VisibleSelection?
        @Binding var viewportState: ViewportState
        @Binding var layoutState: LayoutState
        @Binding var plotSyncState: PlotSyncState
        let onDispatchAction: (ViewAction) -> Void
        @GestureState private var dragTranslationX: CGFloat = 0
        @State private var settlingOffsetX: CGFloat = 0

        var body: some View {
            GeometryReader { geometry in
                let runtimeContext = makeRuntimeContext(for: geometry)
                let isDragging = dragTranslationX != 0

                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        ChartYAxisLabels(
                            context: context.makeYAxisLabelsContext(
                                plotSyncState: plotSyncState))

                        if let plotAreaInfo = plotSyncState.plotAreaInfo {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 1, height: plotAreaInfo.height)
                                .offset(y: plotAreaInfo.minY)
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        ChartContainer(
                            context: runtimeContext.renderContext,
                            onSelectIndex: { onDispatchAction(.selectPoint(index: $0)) },
                            onPlotAreaChange: { plotRect in
                                syncPlotArea(plotRect, isDragging: isDragging)
                            },
                            onYAxisTickPositions: { positions in
                                syncYAxisTickPositions(positions, isDragging: isDragging)
                            })
                            .frame(width: runtimeContext.layoutMetrics.chartWidth)
                            .frame(maxHeight: .infinity)
                    }
                    .compositingGroup()
                    .offset(x: runtimeContext.layoutMetrics.currentContentOffsetX)
                    .frame(width: runtimeContext.layoutMetrics.viewportWidth, alignment: .leading)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(dragGesture(runtimeContext: runtimeContext))
                }
                .onAppear {
                    syncViewport(metrics: runtimeContext.layoutMetrics)
                }
                .onChange(of: geometry.size) { _ in
                    syncViewport(metrics: runtimeContext.layoutMetrics)
                }
            }
        }
    }
}

private extension CombinedChartView.CombinedChartSection {
    func makeRuntimeContext(for geometry: GeometryProxy) -> CombinedChartView.SectionRuntimeContext {
        let pagingContext = CombinedChartView.PagingContext(
            monthsPerPage: context.renderContext.config.monthsPerPage,
            maxStartMonthIndex: max(
                0,
                context.renderContext.data.count - context.renderContext.config.monthsPerPage),
            arrowScrollMode: context.renderContext.config.pager.arrowScrollMode,
            currentYearRangeIndex: nil,
            yearPageRanges: [])
        let dragPagingState = CombinedChartView.DragPagingState(
            contentOffsetX: viewportState.contentOffsetX,
            visibleStartMonthIndex: viewportState.visibleStartMonthIndex,
            monthsPerPage: pagingContext.monthsPerPage,
            maxStartMonthIndex: pagingContext.maxStartMonthIndex,
            dragScrollMode: context.renderContext.config.pager.dragScrollMode)
        let layoutMetrics = CombinedChartView.ChartLayoutMetrics(
            availableWidth: geometry.size.width,
            axisWidth: context.renderContext.config.axis.yAxisWidth,
            monthsPerPage: pagingContext.monthsPerPage,
            dataCount: context.renderContext.data.count,
            dragPagingState: dragPagingState,
            dragTranslationX: dragTranslationX,
            settlingOffsetX: settlingOffsetX,
            maxStartMonthIndex: pagingContext.maxStartMonthIndex)

        return .init(
            pagingContext: pagingContext,
            maxStartMonthIndex: pagingContext.maxStartMonthIndex,
            dragPagingState: dragPagingState,
            layoutMetrics: layoutMetrics,
            renderContext: context.makeRenderContext(
                plotAreaHeight: plotSyncState.plotAreaInfo?.height ?? 0,
                visibleSelection: visibleSelection))
    }

    func syncPlotArea(_ plotRect: CGRect, isDragging: Bool) {
        guard !isDragging else { return }
        let info = CombinedChartView.PlotAreaInfo(minY: plotRect.minY, height: plotRect.height)
        if plotSyncState.plotAreaInfo != info {
            plotSyncState.plotAreaInfo = info
        }
    }

    func syncYAxisTickPositions(_ positions: [Double: CGFloat], isDragging: Bool) {
        guard !isDragging else { return }
        if plotSyncState.yTickPositions != positions {
            plotSyncState.yTickPositions = positions
        }
    }

    func syncViewport(metrics: CombinedChartView.ChartLayoutMetrics) {
        layoutState = .init(
            viewportWidth: metrics.viewportWidth,
            unitWidth: metrics.unitWidth)
        viewportState.contentOffsetX = CGFloat(viewportState.visibleStartMonthIndex) * metrics.unitWidth
    }

    func dragGesture(runtimeContext: CombinedChartView.SectionRuntimeContext) -> some Gesture {
        DragGesture()
            .updating($dragTranslationX) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let clampedTranslationX = runtimeContext.dragPagingState.clampedDisplayTranslationX(
                    from: value.translation.width,
                    maxContentOffsetX: runtimeContext.layoutMetrics.maxContentOffsetX)
                let targetOffsetX = runtimeContext.dragPagingState.targetOffsetX(
                    for: value.translation.width,
                    computedUnitWidth: runtimeContext.layoutMetrics.unitWidth,
                    computedViewportWidth: runtimeContext.layoutMetrics.viewportWidth)
                let targetMonthIndex = runtimeContext.dragPagingState.targetMonthIndex(
                    for: targetOffsetX,
                    computedUnitWidth: runtimeContext.layoutMetrics.unitWidth)
                settlingOffsetX = clampedTranslationX
                onDispatchAction(
                    .settleDrag(
                        targetMonthIndex: targetMonthIndex,
                        targetContentOffsetX: targetOffsetX))
                settlingOffsetX = 0
            }
    }
}
