import OSLog
import SwiftUI

extension CombinedChartView {
    struct Section: View {
        private let logger = ChartLog.logger(.section)
        let context: SectionContext
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
                let effectivePlotSyncState = effectivePlotSyncState(for: geometry.size)
                let topInset = context.config.rendering.topInset
                let contentHeight = max(geometry.size.height - topInset, 0)
                let scrollState = makeScrollState(
                    for: geometry,
                    plotAreaHeight: effectivePlotSyncState.plotAreaHeight)
                let isDragging = dragTranslationX != 0 || isDraggingScroll
                let debugState = makeDebugState(
                    scrollState: scrollState,
                    isDragging: isDragging)

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topInset)

                    HStack(alignment: .top, spacing: 0) {
                        HStack(alignment: .top, spacing: 8) {
                            let tickRange = effectivePlotSyncState.yTickPositions.values.min().flatMap { minY in
                                effectivePlotSyncState.yTickPositions.values.max().map { maxY in (minY, maxY) }
                            }
                            let plotAreaTop = effectivePlotSyncState.plotAreaMinY ?? tickRange?.0 ?? 0
                            let fallbackPlotAreaHeight = tickRange.map { max($0.1 - $0.0, 0) } ?? 320
                            let plotAreaHeight = effectivePlotSyncState.plotAreaHeight > 0
                                ? effectivePlotSyncState.plotAreaHeight
                                : fallbackPlotAreaHeight
                            let plotAreaBottom = plotAreaTop + plotAreaHeight
                            let totalPlotHeight = max(plotAreaBottom, plotAreaTop)
                            let yAxisWidth = context.config.axis.yAxisWidth
                            let dividerX = yAxisWidth + 8
                            let yAxisContainerWidth = dividerX + 1

                            ZStack(alignment: .topLeading) {
                                YAxisLabels(
                                    context: context.makeYAxisLabelsContext(
                                        plotSyncState: effectivePlotSyncState))

                                if plotAreaHeight > 0 {
                                    Rectangle()
                                        .fill(context.config.axis.dividerColor)
                                        .frame(width: 1, height: plotAreaHeight)
                                        .offset(x: dividerX, y: plotAreaTop)
                                }
                            }
                            .frame(width: yAxisContainerWidth, height: totalPlotHeight, alignment: .topLeading)
                        }

                        chartContainer(scrollState: scrollState, isDragging: isDragging)
                    }
                    .frame(height: contentHeight, alignment: .top)
                }
                .onAppear {
                    logSectionYAxisDebug(
                        phase: "appear",
                        geometrySize: geometry.size,
                        plotAreaTop: effectivePlotSyncState.plotAreaMinY ?? 0,
                        plotAreaHeight: effectivePlotSyncState.plotAreaHeight > 0 ? effectivePlotSyncState
                            .plotAreaHeight : 320)
                    syncViewport(scrollState: scrollState)
                    onDebugStateChange?(debugState)
                }
                .onChange(of: geometry.size) { _ in
                    logSectionYAxisDebug(
                        phase: "geometry.size changed",
                        geometrySize: geometry.size,
                        plotAreaTop: effectivePlotSyncState.plotAreaMinY ?? 0,
                        plotAreaHeight: effectivePlotSyncState.plotAreaHeight > 0 ? effectivePlotSyncState
                            .plotAreaHeight : 320)
                    syncViewport(scrollState: scrollState)
                }
                .onChange(of: debugState) { onDebugStateChange?($0) }
            }
        }
    }
}

private extension CombinedChartView.Section {
    // MARK: - Scroll State

    func makeScrollState(
        for geometry: GeometryProxy,
        plotAreaHeight: CGFloat) -> CombinedChartView.ScrollState {
        .init(
            context: context,
            viewportState: viewportState,
            plotAreaHeight: plotAreaHeight,
            visibleSelection: visibleSelection,
            availableWidth: geometry.size.width,
            dragTranslationX: dragTranslationX,
            settlingOffsetX: settlingOffsetX)
    }

    // MARK: - Sync

    func syncPlotArea(_ plotRect: CGRect, isDragging: Bool) {
        guard !usesImmediateCanvasLayout else { return }
        guard !isDragging else { return }
        if context.config.debug.isLoggingEnabled {
            logger.debug(
                """
                [Section YAxis] syncPlotArea \
                incomingMinY=\(plotRect.minY, format: .fixed(precision: 2)) \
                incomingHeight=\(plotRect.height, format: .fixed(precision: 2)) \
                currentMinY=\(plotSyncState.plotAreaMinY ?? .zero, format: .fixed(precision: 2)) \
                currentHeight=\(plotSyncState.plotAreaHeight, format: .fixed(precision: 2))
                """)
        }
        plotSyncState.updatePlotArea(with: plotRect)
    }

    func syncYAxisTickPositions(_ positions: [Double: CGFloat], isDragging: Bool) {
        guard !usesImmediateCanvasLayout else { return }
        guard !isDragging else { return }
        if context.config.debug.isLoggingEnabled {
            let sortedTicks = positions.sorted { $0.key < $1.key }
            let firstTick = sortedTicks.first
            let lastTick = sortedTicks.last
            let firstTickValue: Double = firstTick?.key ?? 0
            let firstTickPosition: CGFloat = firstTick?.value ?? 0
            let lastTickValue: Double = lastTick?.key ?? 0
            let lastTickPosition: CGFloat = lastTick?.value ?? 0
            logger.debug(
                """
                [Section YAxis] syncTickPositions \
                count=\(sortedTicks.count) \
                firstTick=\(firstTickValue, format: .fixed(precision: 2))@\(
                    firstTickPosition,
                    format: .fixed(precision: 2)) \
                lastTick=\(lastTickValue, format: .fixed(precision: 2))@\(
                    lastTickPosition,
                    format: .fixed(precision: 2))
                """)
        }
        plotSyncState.updateYAxisTickPositions(positions)
    }

    func syncViewport(scrollState: CombinedChartView.ScrollState) {
        scrollState.syncViewport(
            layoutState: &_layoutState.wrappedValue,
            viewportState: &viewportState)
    }

    var usesImmediateCanvasLayout: Bool {
        switch context.config.rendering.engine {
        case .canvas:
            true
        case .charts:
            false
        case .automatic:
            if #available(iOS 17, *) {
                false
            } else {
                true
            }
        }
    }

    func effectivePlotSyncState(for size: CGSize) -> CombinedChartView.PlotSyncState {
        guard usesImmediateCanvasLayout else {
            return plotSyncState
        }

        let layout = CombinedChartView.RenderingLayout(rendering: context.config.rendering)
        let plotAreaHeight = layout.plotAreaHeight(for: size.height)

        return .init(
            plotAreaMinY: 0,
            plotAreaHeight: plotAreaHeight,
            yTickPositions: layout.canvasTickPositions(
                yAxisTickValues: context.yAxisTickValues,
                yAxisDisplayDomain: context.yAxisDisplayDomain,
                plotAreaHeight: plotAreaHeight))
    }

    func makeDebugState(
        scrollState: CombinedChartView.ScrollState,
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
        scrollState: CombinedChartView.ScrollState,
        isDragging: Bool) -> some View {
        switch resolvedScrollImplementation {
        case .uiKitScrollView:
            uiKitChartContainer(scrollState: scrollState, isDragging: isDragging)
        default:
            swiftUIGestureChartContainer(scrollState: scrollState, isDragging: isDragging)
        }
    }

    func chartContent(isDragging: Bool, scrollState: CombinedChartView.ScrollState) -> some View {
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
        scrollState: CombinedChartView.ScrollState,
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

    func logSectionYAxisDebug(
        phase: String,
        geometrySize: CGSize,
        plotAreaTop: CGFloat,
        plotAreaHeight: CGFloat) {
        guard context.config.debug.isLoggingEnabled else { return }

        let sortedTicks = plotSyncState.yTickPositions.sorted { $0.key < $1.key }
        let firstTick = sortedTicks.first
        let lastTick = sortedTicks.last
        let firstTickValue: Double = firstTick?.key ?? 0
        let firstTickPosition: CGFloat = firstTick?.value ?? 0
        let lastTickValue: Double = lastTick?.key ?? 0
        let lastTickPosition: CGFloat = lastTick?.value ?? 0
        let yAxisWidth = context.config.axis.yAxisWidth
        let dividerX = yAxisWidth + 8
        let yAxisContainerWidth = dividerX + 1

        logger.debug(
            """
            [Section YAxis] \(phase, privacy: .public) \
            geometry=(\(geometrySize.width, format: .fixed(precision: 2)), \(
                geometrySize.height,
                format: .fixed(precision: 2))) \
            yAxisWidth=\(yAxisWidth, format: .fixed(precision: 2)) \
            dividerX=\(dividerX, format: .fixed(precision: 2)) \
            containerWidth=\(yAxisContainerWidth, format: .fixed(precision: 2)) \
            plotTop=\(plotAreaTop, format: .fixed(precision: 2)) \
            plotHeight=\(plotAreaHeight, format: .fixed(precision: 2)) \
            syncMinY=\(plotSyncState.plotAreaMinY ?? .zero, format: .fixed(precision: 2)) \
            syncHeight=\(plotSyncState.plotAreaHeight, format: .fixed(precision: 2)) \
            ticks=\(sortedTicks.count) \
            firstTick=\(firstTickValue, format: .fixed(precision: 2))@\(
                firstTickPosition,
                format: .fixed(precision: 2)) \
            lastTick=\(lastTickValue, format: .fixed(precision: 2))@\(lastTickPosition, format: .fixed(precision: 2))
            """)
    }

    // MARK: - Gesture

    func dragGesture(scrollState: CombinedChartView.ScrollState) -> some Gesture {
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
        scrollState: CombinedChartView.ScrollState,
        isDragging: Bool) -> some View {
        CombinedChartView.UIKitScrollContainer(
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
