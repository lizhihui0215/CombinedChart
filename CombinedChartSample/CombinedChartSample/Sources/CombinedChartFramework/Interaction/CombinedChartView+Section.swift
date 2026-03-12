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
                let yAxisDescriptor = context.makeYAxisDescriptor(plotSyncState: effectivePlotSyncState)
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
                            ZStack(alignment: .topLeading) {
                                YAxisLabels(
                                    context: context.makeYAxisLabelsContext(
                                        plotSyncState: effectivePlotSyncState,
                                        yAxisDescriptor: yAxisDescriptor))

                                if yAxisDescriptor.plotAreaHeight > 0 {
                                    Rectangle()
                                        .fill(context.config.axis.dividerColor)
                                        .frame(
                                            width: yAxisDescriptor.dividerFrame.width,
                                            height: yAxisDescriptor.dividerFrame.height)
                                        .offset(
                                            x: yAxisDescriptor.dividerFrame.minX,
                                            y: yAxisDescriptor.dividerFrame.minY)
                                }
                            }
                            .frame(
                                width: yAxisDescriptor.containerWidth,
                                height: yAxisDescriptor.totalHeight,
                                alignment: .topLeading)
                        }

                        chartContainer(scrollState: scrollState, isDragging: isDragging)
                    }
                    .frame(height: contentHeight, alignment: .top)
                }
                .onAppear {
                    logSectionYAxisDebug(
                        phase: "appear",
                        geometrySize: geometry.size,
                        yAxisDescriptor: yAxisDescriptor)
                    syncViewport(scrollState: scrollState)
                    onDebugStateChange?(debugState)
                }
                .chartOnChange(of: geometry.size) {
                    logSectionYAxisDebug(
                        phase: "geometry.size changed",
                        geometrySize: geometry.size,
                        yAxisDescriptor: yAxisDescriptor)
                    syncViewport(scrollState: scrollState)
                }
                .chartOnChange(of: debugState) {
                    onDebugStateChange?(debugState)
                }
            }
        }
    }
}

private extension CombinedChartView.Section {
    var implementation: CombinedChartView.Implementation {
        .resolve(config: context.config)
    }

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
        guard !implementation.usesImmediatePlotSync else { return }
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
        guard !implementation.usesImmediatePlotSync else { return }
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
        if implementation == .charts {
            layoutState.update(
                viewportWidth: scrollState.viewport.viewportWidth,
                unitWidth: scrollState.viewport.unitWidth)
            viewportState.contentOffsetX = scrollState.viewport.contentOffsetX
            viewportState.startIndex = scrollState.viewport.startIndex
            return
        }

        scrollState.syncViewport(
            layoutState: &_layoutState.wrappedValue,
            viewportState: &viewportState)
    }

    func effectivePlotSyncState(for size: CGSize) -> CombinedChartView.PlotSyncState {
        guard implementation.usesImmediatePlotSync else {
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
        let effectiveContentOffsetX = max(-scrollState.viewport.displayOffsetX, 0)
        let viewportInfo = CombinedChartView.ViewportInfo(
            dataCount: context.data.count,
            visibleValueCount: context.pagingContext.visibleValueCount,
            startIndex: scrollState.viewport.startIndex,
            contentOffsetX: effectiveContentOffsetX,
            unitWidth: scrollState.viewport.unitWidth,
            visibleStartThreshold: context.config.pager.visibleStartThreshold)
        let targetSettleContext = scrollState.makeDragSettleContext(from: dragTranslationX)
        let visibleStartIndex = viewportInfo.visibleStartIndex
        let visibleStartLabel = viewportInfo.visibleStartLabel(in: context.data)
        let selectedPointIndex = visibleSelection?.index
        let selectedPoint = selectedPointIndex.flatMap {
            context.data.indices.contains($0) ? context.data[$0].source : nil
        }
        let selectedPointValue = selectedPointIndex.flatMap {
            context.data.indices.contains($0) ? context.data[$0].trendLineValue(using: context.config) : nil
        }

        return .init(
            selectedTabTitle: context.selectedTab.title,
            scrollEngineTitle: scrollImplementationTitle,
            scrollTargetBehaviorTitle: dragScrollModeTitle,
            isDragging: isDragging,
            isDecelerating: isDeceleratingScroll,
            startIndex: viewportState.startIndex,
            visibleStartIndex: visibleStartIndex,
            visibleStartLabel: visibleStartLabel,
            visibleStartThreshold: context.config.pager.visibleStartThreshold,
            contentOffsetX: viewportInfo.contentOffsetX,
            dragTranslationX: dragTranslationX,
            targetContentOffsetX: targetSettleContext.targetContentOffsetX,
            targetIndex: targetSettleContext.targetIndex,
            viewportWidth: scrollState.viewport.viewportWidth,
            unitWidth: scrollState.viewport.unitWidth,
            chartWidth: scrollState.viewport.chartWidth,
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
        switch implementation {
        case .charts:
            chartsChartContainer(scrollState: scrollState, isDragging: isDragging)
        case .uiKit:
            #if canImport(UIKit)
            uiKitChartContainer(scrollState: scrollState, isDragging: isDragging)
            #else
            swiftUIGestureChartContainer(scrollState: scrollState, isDragging: isDragging)
            #endif
        case .canvas:
            swiftUIGestureChartContainer(scrollState: scrollState, isDragging: isDragging)
        }
    }

    func chartContent(isDragging: Bool, scrollState: CombinedChartView.ScrollState) -> some View {
        CombinedChartView.Renderer(
            context: scrollState.renderContext,
            chartsScrollPosition: chartsScrollPositionBinding(scrollState: scrollState),
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
            .frame(width: scrollState.viewport.chartWidth)
            .frame(maxHeight: .infinity)
            .offset(x: scrollState.viewport.displayOffsetX)
            .frame(width: scrollState.viewport.viewportWidth, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture(scrollState: scrollState))
    }

    func chartsScrollPositionBinding(
        scrollState: CombinedChartView.ScrollState) -> Binding<Double>? {
        guard implementation == .charts else { return nil }
        guard #available(iOS 17, *) else { return nil }

        return Binding<Double>(
            get: {
                scrollState.viewport.chartsScrollPosition
            },
            set: { newValue in
                let unitWidth = scrollState.viewport.unitWidth
                let nextContentOffsetX = CombinedChartView.ViewportInfo.contentOffsetX(
                    forChartsScrollPosition: newValue,
                    unitWidth: unitWidth,
                    maxStartIndex: context.pagingContext.maxStartIndex)
                let viewportInfo = CombinedChartView.ViewportInfo(
                    dataCount: context.data.count,
                    visibleValueCount: context.pagingContext.visibleValueCount,
                    startIndex: viewportState.startIndex,
                    contentOffsetX: nextContentOffsetX,
                    unitWidth: unitWidth,
                    visibleStartThreshold: context.config.pager.visibleStartThreshold)

                if context.config.debug.isLoggingEnabled {
                    let previousStartIndex = viewportState.startIndex
                    if viewportInfo.startIndex != previousStartIndex {
                        logger.debug(
                            """
                            [Charts Scroll] incomingPosition=\(newValue, format: .fixed(precision: 2)) \
                            resolvedOffsetX=\(viewportInfo.contentOffsetX, format: .fixed(precision: 2)) \
                            resolvedStartIndex=\(viewportInfo.startIndex)
                            """)
                    }
                }

                viewportState.contentOffsetX = viewportInfo.contentOffsetX
                viewportState.startIndex = viewportInfo.startIndex
            })
    }

    var scrollImplementationTitle: String {
        implementation.scrollImplementationTitle
    }

    var dragScrollModeTitle: String {
        switch context.config.pager.scrollTargetBehavior {
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
        yAxisDescriptor: CombinedChartView.YAxisDescriptor) {
        guard context.config.debug.isLoggingEnabled else { return }

        let sortedTicks = yAxisDescriptor.tickPositions.sorted { $0.key < $1.key }
        let firstTick = sortedTicks.first
        let lastTick = sortedTicks.last
        let firstTickValue: Double = firstTick?.key ?? 0
        let firstTickPosition: CGFloat = firstTick?.value ?? 0
        let lastTickValue: Double = lastTick?.key ?? 0
        let lastTickPosition: CGFloat = lastTick?.value ?? 0

        logger.debug(
            """
            [Section YAxis] \(phase, privacy: .public) \
            geometry=(\(geometrySize.width, format: .fixed(precision: 2)), \(
                geometrySize.height,
                format: .fixed(precision: 2))) \
            yAxisWidth=\(yAxisDescriptor.labelWidth, format: .fixed(precision: 2)) \
            dividerX=\(yAxisDescriptor.dividerX, format: .fixed(precision: 2)) \
            containerWidth=\(yAxisDescriptor.containerWidth, format: .fixed(precision: 2)) \
            plotTop=\(yAxisDescriptor.plotAreaTop, format: .fixed(precision: 2)) \
            plotHeight=\(yAxisDescriptor.plotAreaHeight, format: .fixed(precision: 2)) \
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
    func chartsChartContainer(
        scrollState: CombinedChartView.ScrollState,
        isDragging: Bool) -> some View {
        chartContent(isDragging: isDragging, scrollState: scrollState)
            .frame(width: scrollState.layoutMetrics.viewportWidth)
            .frame(maxHeight: .infinity)
            .clipped()
    }

    #if canImport(UIKit)
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
                        targetIndex=\(settleContext.targetIndex)
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
    #endif
}
