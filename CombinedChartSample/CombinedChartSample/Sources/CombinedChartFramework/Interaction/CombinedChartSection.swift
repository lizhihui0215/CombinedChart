import SwiftUI

extension CombinedChartView {
    struct CombinedChartSection: View {
        let context: SectionContext
        let visibleSelection: VisibleSelection?
        @Binding var viewportState: ViewportState
        @Binding var layoutState: LayoutState
        @Binding var plotAreaInfo: PlotAreaInfo?
        @Binding var yTickPositions: [Double: CGFloat]
        let onDispatchAction: (ViewAction) -> Void
        @GestureState private var dragTranslationX: CGFloat = 0
        @State private var settlingOffsetX: CGFloat = 0

        var body: some View {
            GeometryReader { geometry in
                let metrics = layoutMetrics(for: geometry)
                let isDragging = dragTranslationX != 0

                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        ChartYAxisLabels(
                            yAxisTickValues: context.yAxisTickValues,
                            tickPositions: yTickPositions,
                            plotArea: plotAreaInfo,
                            labelText: context.yAxisLabel)

                        if let plotAreaInfo {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 1, height: plotAreaInfo.height)
                                .offset(y: plotAreaInfo.minY)
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        ChartContainer(
                            context: renderContext,
                            onSelectIndex: { onDispatchAction(.selectPoint(index: $0)) },
                            onPlotAreaChange: { plotRect in
                                syncPlotArea(plotRect, isDragging: isDragging)
                            },
                            onYAxisTickPositions: { positions in
                                syncYAxisTickPositions(positions, isDragging: isDragging)
                            })
                            .frame(width: metrics.chartWidth)
                            .frame(maxHeight: .infinity)
                    }
                    .compositingGroup()
                    .offset(x: metrics.currentContentOffsetX)
                    .frame(width: metrics.viewportWidth, alignment: .leading)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(dragGesture(metrics: metrics))
                }
                .onAppear {
                    syncViewport(metrics: metrics)
                }
                .onChange(of: geometry.size) { _ in
                    syncViewport(metrics: metrics)
                }
            }
        }
    }
}

private extension CombinedChartView.CombinedChartSection {
    var maxStartMonthIndex: Int {
        max(0, context.data.count - context.config.monthsPerPage)
    }

    var dragPagingState: CombinedChartView.DragPagingState {
        .init(
            contentOffsetX: viewportState.contentOffsetX,
            visibleStartMonthIndex: viewportState.visibleStartMonthIndex,
            monthsPerPage: context.config.monthsPerPage,
            maxStartMonthIndex: maxStartMonthIndex,
            dragScrollMode: context.config.pager.dragScrollMode)
    }

    func layoutMetrics(for geometry: GeometryProxy) -> CombinedChartView.ChartLayoutMetrics {
        .init(
            availableWidth: geometry.size.width,
            axisWidth: context.config.axis.yAxisWidth,
            monthsPerPage: context.config.monthsPerPage,
            dataCount: context.data.count,
            dragPagingState: dragPagingState,
            dragTranslationX: dragTranslationX,
            settlingOffsetX: settlingOffsetX,
            maxStartMonthIndex: maxStartMonthIndex)
    }

    func syncPlotArea(_ plotRect: CGRect, isDragging: Bool) {
        guard !isDragging else { return }
        let info = CombinedChartView.PlotAreaInfo(minY: plotRect.minY, height: plotRect.height)
        if plotAreaInfo != info {
            plotAreaInfo = info
        }
    }

    func syncYAxisTickPositions(_ positions: [Double: CGFloat], isDragging: Bool) {
        guard !isDragging else { return }
        if yTickPositions != positions {
            yTickPositions = positions
        }
    }

    func syncViewport(metrics: CombinedChartView.ChartLayoutMetrics) {
        layoutState = .init(
            viewportWidth: metrics.viewportWidth,
            unitWidth: metrics.unitWidth)
        viewportState.contentOffsetX = CGFloat(viewportState.visibleStartMonthIndex) * metrics.unitWidth
    }

    var renderContext: CombinedChartView.ChartRenderContext {
        .init(
            selectedTab: context.selectedTab,
            visibleData: context.data,
            yAxisTickValues: context.yAxisTickValues,
            yAxisDisplayDomain: context.yAxisDisplayDomain,
            plotAreaHeight: plotAreaInfo?.height ?? 0,
            config: context.config,
            showDebugOverlay: context.showDebugOverlay,
            selectionOverlay: context.selectionOverlay,
            visibleSelection: visibleSelection)
    }

    func dragGesture(metrics: CombinedChartView.ChartLayoutMetrics) -> some Gesture {
        DragGesture()
            .updating($dragTranslationX) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let clampedTranslationX = dragPagingState.clampedDisplayTranslationX(
                    from: value.translation.width,
                    maxContentOffsetX: metrics.maxContentOffsetX)
                let targetOffsetX = dragPagingState.targetOffsetX(
                    for: value.translation.width,
                    computedUnitWidth: metrics.unitWidth,
                    computedViewportWidth: metrics.viewportWidth)
                let targetMonthIndex = dragPagingState.targetMonthIndex(
                    for: targetOffsetX,
                    computedUnitWidth: metrics.unitWidth)
                settlingOffsetX = clampedTranslationX
                onDispatchAction(
                    .settleDrag(
                        targetMonthIndex: targetMonthIndex,
                        targetContentOffsetX: targetOffsetX))
                settlingOffsetX = 0
            }
    }
}
