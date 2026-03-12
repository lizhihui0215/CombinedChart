import Charts
import OSLog
import SwiftUI

extension CombinedChartView {
    struct SelectionState {
        let point: ChartDataPoint
        let index: Int
        let value: Double
        let xPosition: CGFloat
    }

    struct SelectionLayout {
        let highlightWidth: CGFloat
        let indicatorFrame: CGRect
    }

    struct SelectionOverlayState {
        let selectionState: SelectionState
        let layout: SelectionLayout
        let context: SelectionOverlayContext
        let pointCenter: CGPoint?
    }

}

@available(iOS 16, *)
extension CombinedChartView.Renderer {
    var renderingLogger: Logger {
        ChartLog.logger(.rendering)
    }

    func containerOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let plotFrame = chartsPlotFrameDescriptor(for: proxy, in: geometry) {
                let xPositions = chartsViewportXPositions(plotFrame: plotFrame, proxy: proxy)
                let overlayPresentation = makeOverlayPresentationDescriptor(
                    plotRect: plotFrame.plotRect,
                    xPositions: xPositions,
                    yPosition: { value in
                        proxy.position(forY: value)
                    })

                syncPlotOverlay(plotFrame: plotFrame)

                ZStack(alignment: .topLeading) {
                    trendLineOverlay(plotFrame: plotFrame, overlayPresentation: overlayPresentation)
                    selectionOverlay(plotFrame: plotFrame, overlayPresentation: overlayPresentation)
                    debugOverlay(plotFrame: plotFrame, overlayPresentation: overlayPresentation)
                }
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    func syncPlotOverlay(plotFrame: CombinedChartView.PlotFrameDescriptor) -> some View {
        if hasValidPlotFrame(plotFrame.plotRect) {
            Color.clear
                .onAppear {
                    applyPlotFrameDescriptor(plotFrame)
                }
                .chartOnChange(of: plotFrame) {
                    applyPlotFrameDescriptor(plotFrame)
                }
        }
    }

    func rawPlotRect(for proxy: ChartProxy, in geometry: GeometryProxy) -> CGRect? {
        if #available(iOS 17, *) {
            return proxy.plotFrame.map { geometry[$0] }
        }
        return geometry[proxy.plotAreaFrame]
    }

    func applyPlotFrameDescriptor(_ descriptor: CombinedChartView.PlotFrameDescriptor) {
        onPlotAreaChange(descriptor.plotRect)
        onYAxisTickPositions(descriptor.yAxisTickPositions)
    }

    func hasValidPlotFrame(_ plotRect: CGRect) -> Bool {
        plotRect.width > 0 && plotRect.height > 0
    }

    func chartsPlotFrameDescriptor(
        for proxy: ChartProxy,
        in geometry: GeometryProxy) -> CombinedChartView.PlotFrameDescriptor? {
        guard let plotRect = rawPlotRect(for: proxy, in: geometry) else { return nil }
        let normalizedPlotFrame = CombinedChartView.PlotFrameDescriptor.normalized(
            plotRect: plotRect,
            yAxisTickPositions: yAxisTickPositions(
                plotRect: CGRect(
                    x: plotRect.minX,
                    y: max(plotRect.minY, 0),
                    width: max(plotRect.width, 0),
                    height: max(plotRect.height, 0)),
                proxy: proxy))
        let normalizationDeltaY = abs(normalizedPlotFrame.plotRect.minY - plotRect.minY)
        if context.config.debug.isLoggingEnabled,
           normalizationDeltaY > 8 {
            renderingLogger.debug(
                """
                [Charts Sync] normalized plotRect \
                originalMinX=\(plotRect.minX, format: .fixed(precision: 2)) \
                originalMinY=\(plotRect.minY, format: .fixed(precision: 2)) \
                normalizedMinX=\(normalizedPlotFrame.plotRect.minX, format: .fixed(precision: 2)) \
                normalizedMinY=\(normalizedPlotFrame.plotRect.minY, format: .fixed(precision: 2)) \
                width=\(normalizedPlotFrame.plotRect.width, format: .fixed(precision: 2)) \
                height=\(normalizedPlotFrame.plotRect.height, format: .fixed(precision: 2))
                """)
        }

        return normalizedPlotFrame
    }

    @ViewBuilder
    func trendLineOverlay(
        plotFrame: CombinedChartView.PlotFrameDescriptor,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) -> some View {
        if marksPresentationContext.trendLineStyle != nil && overlayPresentation.showsTrendLine {
            ForEach(overlayPresentation.lineMarks) { lineMark in
                ForEach(lineMark.segments) { segment in
                    segment.path
                        .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: lineMark.lineWidth))
                }
            }
            .mask(plotMask(for: plotFrame))
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func selectionOverlay(
        plotFrame: CombinedChartView.PlotFrameDescriptor,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) -> some View {
        if overlayPresentation.selection.showsOverlay {
            selectionOverlayView(selection: overlayPresentation.selection)
                .mask(plotMask(for: plotFrame))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func debugOverlay(
        plotFrame: CombinedChartView.PlotFrameDescriptor,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) -> some View {
        if overlayPresentation.showsDebugGuides {
            debugGuides(
                plotRect: plotFrame.plotRect,
                guideMarks: overlayPresentation.guideMarks)
                .mask(plotMask(for: plotFrame))
                .allowsHitTesting(false)
        }
    }

    func yAxisTickPositions(plotRect: CGRect, proxy: ChartProxy) -> [Double: CGFloat] {
        Dictionary(
            uniqueKeysWithValues: overlayContext.yAxisTickValues.compactMap { value in
                if let yPos = proxy.position(forY: value) {
                    return (value, yPos - plotRect.minY)
                }
                return nil
            })
    }

    func chartsViewportXPositions(
        plotFrame: CombinedChartView.PlotFrameDescriptor,
        proxy: ChartProxy) -> [CombinedChartView.XPositionDescriptor] {
        CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: overlayContext.visibleData.count,
            xPosition: { index in
                guard let contentX = proxy.position(forX: Double(index)) else { return nil }
                return plotFrame.plotRect.minX + contentX
            }))
    }
}
