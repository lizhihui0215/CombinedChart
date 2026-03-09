import OSLog
import SwiftUI

extension CombinedChartView {
    struct Section: View {
        private let logger = ChartLog.logger(.section)
        let context: ChartSectionContext
        let visibleSelection: VisibleSelection?
        @Binding var viewportState: ViewportState
        @Binding var layoutState: LayoutState
        @Binding var plotSyncState: PlotSyncState
        let onDebugStateChange: ((DebugState) -> Void)?
        let onDispatchAction: (ViewAction) -> Void
        @GestureState private var dragTranslationX: CGFloat = 0
        @State private var settlingOffsetX: CGFloat = 0
        @State private var isDraggingScroll = false
        @State private var isDeceleratingScroll = false

        var body: some View {
            GeometryReader { geometry in
                let scrollState = makeScrollState(for: geometry)
                let isDragging = dragTranslationX != 0 || isDraggingScroll
                let debugState = makeDebugState(
                    scrollState: scrollState,
                    isDragging: isDragging)

                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        YAxisLabels(
                            context: context.makeYAxisLabelsContext(
                                plotSyncState: plotSyncState))

                        if let plotAreaMinY = plotSyncState.plotAreaMinY, plotSyncState.plotAreaHeight > 0 {
                            Rectangle()
                                .fill(context.config.axis.dividerColor)
                                .frame(width: 1, height: plotSyncState.plotAreaHeight)
                                .offset(y: plotAreaMinY)
                        }
                    }

                    chartContainer(scrollState: scrollState, isDragging: isDragging)
                }
                .onAppear {
                    syncViewport(scrollState: scrollState)
                    onDebugStateChange?(debugState)
                }
                .onChange(of: geometry.size) { _ in
                    syncViewport(scrollState: scrollState)
                }
                .onChange(of: debugState) { onDebugStateChange?($0) }
            }
        }
    }
}

private extension CombinedChartView.Section {
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

    func makeDebugState(
        scrollState: CombinedChartView.ChartScrollState,
        isDragging: Bool) -> CombinedChartView.DebugState {
        let effectiveContentOffsetX = max(-scrollState.layoutMetrics.currentContentOffsetX, 0)
        let targetSettleContext = scrollState.makeDragSettleContext(from: dragTranslationX)
        let visibleStartIndex = CombinedChartView.PagerState.makeVisibleStartIndex(
            dataCount: context.data.count,
            contentOffsetX: effectiveContentOffsetX,
            unitWidth: scrollState.layoutMetrics.unitWidth,
            progressThreshold: context.config.pager.visibleStartThreshold)
        let visibleStartLabel = visibleStartIndex.flatMap {
            context.data.indices.contains($0) ? context.data[$0].xLabel : nil
        }
        let selectedPointIndex = visibleSelection?.index
        let selectedPoint = selectedPointIndex.flatMap {
            context.data.indices.contains($0) ? context.data[$0].source : nil
        }
        let selectedPointValue = selectedPointIndex.flatMap {
            context.data.indices.contains($0) ? context.data[$0].trendLineValue(using: context.config) : nil
        }

        return .init(
            selectedTabTitle: context.selectedTab.title,
            scrollImplementationTitle: scrollImplementationTitle,
            dragScrollModeTitle: dragScrollModeTitle,
            isDragging: isDragging,
            isDecelerating: isDeceleratingScroll,
            startIndex: viewportState.startIndex,
            visibleStartIndex: visibleStartIndex,
            visibleStartLabel: visibleStartLabel,
            visibleStartThreshold: context.config.pager.visibleStartThreshold,
            contentOffsetX: effectiveContentOffsetX,
            dragTranslationX: dragTranslationX,
            targetContentOffsetX: targetSettleContext.targetContentOffsetX,
            targetMonthIndex: targetSettleContext.targetMonthIndex,
            viewportWidth: scrollState.layoutMetrics.viewportWidth,
            unitWidth: scrollState.layoutMetrics.unitWidth,
            chartWidth: scrollState.layoutMetrics.chartWidth,
            selectedPointIndex: selectedPointIndex,
            selectedPointGroupID: selectedPoint?.id.groupID,
            selectedPointXKey: selectedPoint?.xKey,
            selectedPointXLabel: selectedPoint?.xLabel,
            selectedPointValue: selectedPointValue)
    }

    @ViewBuilder
    func chartContainer(
        scrollState: CombinedChartView.ChartScrollState,
        isDragging: Bool) -> some View {
        switch resolvedScrollImplementation {
        case .uiKitScrollView:
            uiKitChartContainer(scrollState: scrollState, isDragging: isDragging)
        default:
            swiftUIGestureChartContainer(scrollState: scrollState, isDragging: isDragging)
        }
    }

    func chartContent(isDragging: Bool, scrollState: CombinedChartView.ChartScrollState) -> some View {
        CombinedChartView.Renderer(
            context: scrollState.renderContext,
            onSelectIndex: { onDispatchAction(.selectPoint(index: $0)) },
            onPlotAreaChange: { plotRect in
                syncPlotArea(plotRect, isDragging: isDragging)
            },
            onYAxisTickPositions: { positions in
                syncYAxisTickPositions(positions, isDragging: isDragging)
            })
    }

    func swiftUIGestureChartContainer(
        scrollState: CombinedChartView.ChartScrollState,
        isDragging: Bool) -> some View {
        chartContent(isDragging: isDragging, scrollState: scrollState)
            .frame(width: scrollState.layoutMetrics.chartWidth)
            .frame(maxHeight: .infinity)
            .offset(x: scrollState.layoutMetrics.currentContentOffsetX)
            .frame(width: scrollState.layoutMetrics.viewportWidth, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture(scrollState: scrollState))
    }

    var resolvedScrollImplementation: ChartConfig.Pager.ScrollImplementation {
        switch context.config.pager.scrollImplementation {
        case .automatic:
            if #available(iOS 17, *) {
                .uiKitScrollView
            } else {
                .swiftUIGesture
            }
        case .swiftUIGesture:
            .swiftUIGesture
        case .uiKitScrollView:
            .uiKitScrollView
        }
    }

    var scrollImplementationTitle: String {
        switch resolvedScrollImplementation {
        case .automatic:
            "Automatic"
        case .swiftUIGesture:
            "SwiftUI Gesture"
        case .uiKitScrollView:
            "UIKit ScrollView"
        }
    }

    var dragScrollModeTitle: String {
        switch context.config.pager.dragScrollMode {
        case .byPage:
            "By Page"
        case .freeSnapping:
            "Free Snapping"
        case .free:
            "Free"
        }
    }

    // MARK: - Gesture

    func dragGesture(scrollState: CombinedChartView.ChartScrollState) -> some Gesture {
        DragGesture()
            .updating($dragTranslationX) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                if context.config.debug.isLoggingEnabled {
                    logger.debug(
                        "SwiftUI drag ended. translationX=\(value.translation.width, format: .fixed(precision: 2)) startIndex=\(viewportState.startIndex)")
                }
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

private extension CombinedChartView.Section {
    func uiKitChartContainer(
        scrollState: CombinedChartView.ChartScrollState,
        isDragging: Bool) -> some View {
        ChartUIKitScrollContainer(
            viewportWidth: scrollState.layoutMetrics.viewportWidth,
            chartWidth: scrollState.layoutMetrics.chartWidth,
            contentOffsetX: viewportState.contentOffsetX,
            onContentOffsetChange: { viewportState.contentOffsetX = $0 },
            onDraggingChange: { isDraggingScroll = $0 },
            onDeceleratingChange: { isDeceleratingScroll = $0 },
            onWillEndDragging: { proposedOffsetX in
                let settleContext = scrollState.makeDragSettleContext(for: proposedOffsetX)
                if context.config.debug.isLoggingEnabled {
                    logger.debug(
                        """
                        UIKit settle requested. \
                        proposedOffsetX=\(proposedOffsetX, format: .fixed(precision: 2)) \
                        targetOffsetX=\(settleContext.targetContentOffsetX, format: .fixed(precision: 2)) \
                        targetIndex=\(settleContext.targetMonthIndex)
                        """)
                }
                onDispatchAction(.settleDrag(settleContext))
                return settleContext.targetContentOffsetX
            },
            isLoggingEnabled: context.config.debug.isLoggingEnabled,
            content: chartContent(isDragging: isDragging, scrollState: scrollState))
            .frame(width: scrollState.layoutMetrics.viewportWidth)
            .frame(maxHeight: .infinity)
            .clipped()
    }
}
