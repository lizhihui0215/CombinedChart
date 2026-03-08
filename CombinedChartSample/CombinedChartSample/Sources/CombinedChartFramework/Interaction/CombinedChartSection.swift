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

                        if let plotAreaMinY = plotSyncState.plotAreaMinY, plotSyncState.plotAreaHeight > 0 {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 1, height: plotSyncState.plotAreaHeight)
                                .offset(y: plotAreaMinY)
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
    // MARK: - Runtime

    func makeRuntimeContext(for geometry: GeometryProxy) -> CombinedChartView.SectionRuntimeContext {
        let dragPagingState = CombinedChartView.DragViewportState(
            contentOffsetX: viewportState.contentOffsetX,
            startIndex: viewportState.startIndex,
            monthsPerPage: context.pagingContext.monthsPerPage,
            maxStartMonthIndex: context.pagingContext.maxStartMonthIndex,
            dragScrollMode: context.config.pager.dragScrollMode)
        let layoutMetrics = CombinedChartView.ChartLayoutMetrics(
            availableWidth: geometry.size.width,
            axisWidth: context.config.axis.yAxisWidth,
            monthsPerPage: context.pagingContext.monthsPerPage,
            dataCount: context.data.count,
            dragPagingState: dragPagingState,
            dragTranslationX: dragTranslationX,
            settlingOffsetX: settlingOffsetX,
            maxStartMonthIndex: context.pagingContext.maxStartMonthIndex)

        return .init(
            pagingContext: context.pagingContext,
            dragPagingState: dragPagingState,
            layoutMetrics: layoutMetrics,
            renderContext: context.makeRenderContext(
                plotAreaHeight: plotSyncState.plotAreaHeight,
                visibleSelection: visibleSelection))
    }

    // MARK: - Sync

    func syncPlotArea(_ plotRect: CGRect, isDragging: Bool) {
        guard !isDragging else { return }
        plotSyncState.updatePlotArea(with: plotRect)
    }

    func syncYAxisTickPositions(_ positions: [Double: CGFloat], isDragging: Bool) {
        guard !isDragging else { return }
        plotSyncState.updateYAxisTickPositions(positions)
    }

    func syncViewport(metrics: CombinedChartView.ChartLayoutMetrics) {
        _layoutState.wrappedValue.update(
            viewportWidth: metrics.viewportWidth,
            unitWidth: metrics.unitWidth)
        viewportState.contentOffsetX = CGFloat(viewportState.startIndex) * metrics.unitWidth
    }

    // MARK: - Gesture

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
                        .init(
                            targetMonthIndex: targetMonthIndex,
                            targetContentOffsetX: targetOffsetX)))
                settlingOffsetX = 0
            }
    }
}
