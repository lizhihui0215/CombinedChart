import SwiftUI

extension CombinedChartView {
    struct CombinedChartSection: View {
        let context: ChartSectionContext
        let visibleSelection: VisibleSelection?
        @Binding var viewportState: ViewportState
        @Binding var layoutState: LayoutState
        @Binding var plotSyncState: PlotSyncState
        let onDispatchAction: (ViewAction) -> Void
        @GestureState private var dragTranslationX: CGFloat = 0
        @State private var settlingOffsetX: CGFloat = 0

        var body: some View {
            GeometryReader { geometry in
                let scrollState = makeScrollState(for: geometry)
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

                    ChartRenderer(
                        context: scrollState.renderContext,
                        onSelectIndex: { onDispatchAction(.selectPoint(index: $0)) },
                        onPlotAreaChange: { plotRect in
                            syncPlotArea(plotRect, isDragging: isDragging)
                        },
                        onYAxisTickPositions: { positions in
                            syncYAxisTickPositions(positions, isDragging: isDragging)
                        })
                        .frame(width: scrollState.layoutMetrics.chartWidth)
                        .frame(maxHeight: .infinity)
                        .offset(x: scrollState.layoutMetrics.currentContentOffsetX)
                        .frame(width: scrollState.layoutMetrics.viewportWidth, alignment: .leading)
                        .clipped()
                        .contentShape(Rectangle())
                        .gesture(dragGesture(scrollState: scrollState))
                }
                .onAppear {
                    syncViewport(scrollState: scrollState)
                }
                .onChange(of: geometry.size) { _ in
                    syncViewport(scrollState: scrollState)
                }
            }
        }
    }
}

private extension CombinedChartView.CombinedChartSection {
    // MARK: - Scroll State

    func makeScrollState(for geometry: GeometryProxy) -> CombinedChartView.ChartScrollState {
        .init(
            context: context,
            viewportState: viewportState,
            plotAreaHeight: plotSyncState.plotAreaHeight,
            visibleSelection: visibleSelection,
            availableWidth: geometry.size.width,
            dragTranslationX: dragTranslationX,
            settlingOffsetX: settlingOffsetX)
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

    func syncViewport(scrollState: CombinedChartView.ChartScrollState) {
        scrollState.syncViewport(
            layoutState: &_layoutState.wrappedValue,
            viewportState: &viewportState)
    }

    // MARK: - Gesture

    func dragGesture(scrollState: CombinedChartView.ChartScrollState) -> some Gesture {
        DragGesture()
            .updating($dragTranslationX) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                settlingOffsetX = scrollState.makeSettlingOffsetX(
                    from: value.translation.width)
                onDispatchAction(
                    .settleDrag(
                        scrollState.makeDragSettleContext(
                            from: value.translation.width)))
                settlingOffsetX = 0
            }
    }
}
