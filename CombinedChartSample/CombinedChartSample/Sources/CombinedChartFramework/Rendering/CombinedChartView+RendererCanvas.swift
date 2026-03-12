import OSLog
import SwiftUI

extension CombinedChartView.Renderer {
    private var logger: Logger {
        ChartLog.logger(.rendering)
    }

    var canvasBody: some View {
        GeometryReader { geometry in
            let plotFrame = canvasPlotFrameDescriptor(
                in: CGSize(width: geometry.size.width, height: max(0, geometry.size.height - xAxisHeight)),
                xAxisHeight: 0)
            let plotRect = plotFrame.plotRect
            let xPositions = canvasXPositions(in: plotRect)
            let tickPositions = axisPresentationContext.yGridPositions(in: plotFrame)
            let overlayPresentation = makeOverlayPresentationDescriptor(
                plotRect: plotRect,
                xPositions: xPositions,
                yPosition: { value in
                    canvasYPosition(for: value, in: plotRect)
                })

            let canvasContent = VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Canvas { graphicsContext, _ in
                        drawCanvasGrid(in: &graphicsContext, plotRect: plotRect, tickPositions: tickPositions)
                        drawCanvasZeroLine(in: &graphicsContext, plotRect: plotRect)
                        drawCanvasBars(in: &graphicsContext, plotRect: plotRect)
                        drawCanvasSelectedPointMark(in: &graphicsContext, plotRect: plotRect)
                        drawCanvasTrendLine(
                            in: &graphicsContext,
                            overlayPresentation: overlayPresentation)
                        drawCanvasSelection(
                            in: &graphicsContext,
                            plotRect: plotRect,
                            overlayPresentation: overlayPresentation)
                    }
                    canvasSelectionOverlayView(
                        overlayPresentation: overlayPresentation,
                        plotFrame: plotFrame)
                    canvasDebugOverlayView(
                        plotFrame: plotFrame,
                        overlayPresentation: overlayPresentation)
                }
                .frame(height: plotFrame.plotRect.height)
                .background(Color.clear)
                .contentShape(Rectangle())
                .onAppear {
                    logCanvasYAxisDebug(
                        phase: "appear",
                        size: CGSize(width: geometry.size.width, height: plotFrame.plotRect.height),
                        xAxisHeight: xAxisHeight,
                        plotRect: plotRect,
                        tickPositionMap: plotFrame.yAxisTickPositions)
                    onPlotAreaChange(plotFrame.plotRect)
                    onYAxisTickPositions(plotFrame.yAxisTickPositions)
                }
                .chartOnChange(of: plotRect.size) {
                    logCanvasYAxisDebug(
                        phase: "plotRect.size changed",
                        size: CGSize(width: geometry.size.width, height: plotFrame.plotRect.height),
                        xAxisHeight: xAxisHeight,
                        plotRect: plotRect,
                        tickPositionMap: plotFrame.yAxisTickPositions)
                    onPlotAreaChange(plotFrame.plotRect)
                    onYAxisTickPositions(plotFrame.yAxisTickPositions)
                }

                canvasXAxisLabels(in: plotRect)
                    .frame(height: xAxisHeight)
            }

            if #available(iOS 16, *) {
                canvasContent
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { gesture in
                                handleCanvasTap(at: gesture.location, xPositions: xPositions)
                            })
            } else {
                canvasContent
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { gesture in
                                handleCanvasTap(at: gesture.location, xPositions: xPositions)
                            })
            }
        }
    }

    @ViewBuilder
    func canvasSelectionOverlayView(
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor,
        plotFrame: CombinedChartView.PlotFrameDescriptor) -> some View {
        if overlayPresentation.selection.showsCustomOverlay {
            selectionOverlayView(selection: overlayPresentation.selection)
                .allowsHitTesting(false)
                .mask(plotMask(for: plotFrame))
        }
    }

    @ViewBuilder
    func canvasDebugOverlayView(
        plotFrame: CombinedChartView.PlotFrameDescriptor,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) -> some View {
        if overlayPresentation.showsDebugGuides {
            debugGuides(
                plotRect: plotFrame.plotRect,
                guideMarks: overlayPresentation.guideMarks)
                .allowsHitTesting(false)
                .mask(plotMask(for: plotFrame))
        }
    }

    func canvasPlotRect(in size: CGSize, xAxisHeight: CGFloat) -> CGRect {
        CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: max(0, size.height - xAxisHeight))
    }

    func canvasPlotFrameDescriptor(
        in size: CGSize,
        xAxisHeight: CGFloat) -> CombinedChartView.PlotFrameDescriptor {
        let plotRect = canvasPlotRect(in: size, xAxisHeight: xAxisHeight)
        return .init(
            plotRect: plotRect,
            yAxisTickPositions: canvasTickPositionMap(in: plotRect))
    }

    func canvasXPosition(for index: Int, in plotRect: CGRect) -> CGFloat? {
        guard axisPresentationContext.dataCount > 0 else {
            return nil
        }
        guard (0..<axisPresentationContext.dataCount).contains(index) else {
            return nil
        }

        let step = plotRect.width / CGFloat(axisPresentationContext.dataCount)
        return plotRect.minX + step * (CGFloat(index) + 0.5)
    }

    func canvasXPositions(in plotRect: CGRect) -> [CombinedChartView.XPositionDescriptor] {
        CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: axisPresentationContext.dataCount,
            xPosition: { index in
                canvasXPosition(for: index, in: plotRect)
            }))
    }

    func canvasYPosition(for value: Double, in plotRect: CGRect) -> CGFloat? {
        let domain = context.yAxisDisplayDomain
        let range = domain.upperBound - domain.lowerBound
        guard range > 0 else { return nil }

        let normalized = (value - domain.lowerBound) / range
        return plotRect.maxY - CGFloat(normalized) * plotRect.height
    }

    func canvasTickPositionMap(in plotRect: CGRect) -> [Double: CGFloat] {
        Dictionary(uniqueKeysWithValues: context.yAxisTickValues.compactMap { value in
            guard let position = canvasYPosition(for: value, in: plotRect) else { return nil }
            return (value, position)
        })
    }

    func logCanvasYAxisDebug(
        phase: String,
        size: CGSize,
        xAxisHeight: CGFloat,
        plotRect: CGRect,
        tickPositionMap: [Double: CGFloat]) {
        guard context.config.debug.isLoggingEnabled else { return }

        let sortedTicks = tickPositionMap.sorted { $0.key < $1.key }
        let firstTick = sortedTicks.first
        let lastTick = sortedTicks.last
        let firstTickValue: Double = firstTick?.key ?? 0
        let firstTickPosition: CGFloat = firstTick?.value ?? 0
        let lastTickValue: Double = lastTick?.key ?? 0
        let lastTickPosition: CGFloat = lastTick?.value ?? 0

        logger.debug(
            """
            [Canvas YAxis] \(phase, privacy: .public) \
            size=(\(size.width, format: .fixed(precision: 2)), \(size.height, format: .fixed(precision: 2))) \
            topInset=\(context.config.rendering.topInset, format: .fixed(precision: 2)) \
            xAxisHeight=\(xAxisHeight, format: .fixed(precision: 2)) \
            plotMinY=\(plotRect.minY, format: .fixed(precision: 2)) \
            plotHeight=\(plotRect.height, format: .fixed(precision: 2)) \
            plotMaxY=\(plotRect.maxY, format: .fixed(precision: 2)) \
            yAxisWidth=\(context.config.axis.yAxisWidth, format: .fixed(precision: 2)) \
            ticks=\(sortedTicks.count) \
            firstTick=\(firstTickValue, format: .fixed(precision: 2))@\(
                firstTickPosition,
                format: .fixed(precision: 2)) \
            lastTick=\(lastTickValue, format: .fixed(precision: 2))@\(lastTickPosition, format: .fixed(precision: 2))
            """)
    }

    func drawCanvasGrid(
        in graphicsContext: inout GraphicsContext,
        plotRect: CGRect,
        tickPositions: [CGFloat]) {
        for y in tickPositions {
            var path = Path()
            path.move(to: CGPoint(x: plotRect.minX, y: y))
            path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
            graphicsContext.stroke(
                path,
                with: .color(context.config.axis.gridLineColor),
                lineWidth: context.config.axis.gridLineWidth)
        }
    }

    func drawCanvasZeroLine(in graphicsContext: inout GraphicsContext, plotRect: CGRect) {
        guard let zeroLine = marksPresentationContext.ruleMarks.first,
              let y = canvasYPosition(for: zeroLine.value, in: plotRect)
        else {
            return
        }

        var path = Path()
        path.move(to: CGPoint(x: plotRect.minX, y: y))
        path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        graphicsContext.stroke(
            path,
            with: .color(zeroLine.color),
            lineWidth: zeroLine.lineWidth)
    }

    func drawCanvasBars(in graphicsContext: inout GraphicsContext, plotRect: CGRect) {
        guard marksPresentationContext.showsBarMarks else { return }

        for item in marksPresentationContext.barMarks {
            guard
                let x = canvasXPosition(for: item.xIndex, in: plotRect),
                let yStart = canvasYPosition(for: item.start, in: plotRect),
                let yEnd = canvasYPosition(for: item.end, in: plotRect)
            else {
                continue
            }

            let rect = CGRect(
                x: x - item.width / 2,
                y: min(yStart, yEnd),
                width: item.width,
                height: Swift.abs(yEnd - yStart))

            graphicsContext.fill(Path(rect), with: .color(item.color))
        }
    }

    func drawCanvasSelectedPointMark(in graphicsContext: inout GraphicsContext, plotRect: CGRect) {
        guard let pointMark = marksPresentationContext.pointMarks.first,
              let x = canvasXPosition(for: pointMark.index, in: plotRect),
              let y = canvasYPosition(for: pointMark.value, in: plotRect) else {
            return
        }

        let rect = CGRect(
            x: x - pointMark.pointSize / 2,
            y: y - pointMark.pointSize / 2,
            width: pointMark.pointSize,
            height: pointMark.pointSize)
        graphicsContext.fill(Path(ellipseIn: rect), with: .color(pointMark.color))
    }

    func drawCanvasTrendLine(
        in graphicsContext: inout GraphicsContext,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) {
        for lineMark in overlayPresentation.lineMarks {
            for segment in lineMark.segments {
                graphicsContext.stroke(
                    segment.path,
                    with: .color(segment.color),
                    style: StrokeStyle(lineWidth: lineMark.lineWidth))
            }
        }
    }

    func drawCanvasSelection(
        in graphicsContext: inout GraphicsContext,
        plotRect: CGRect,
        overlayPresentation: CombinedChartView.OverlayPresentationDescriptor) {
        let selection = overlayPresentation.selection
        guard selection.showsDefaultOverlay else { return }

        if let bandFrame = selection.bandIndicatorFrame,
           let fillColor = selection.indicatorFillColor {
            graphicsContext.fill(
                Path(bandFrame),
                with: .color(fillColor))
        } else if let lineX = selection.lineIndicatorX,
                  let lineColor = selection.indicatorLineColor {
            var path = Path()
            path.move(to: CGPoint(x: lineX, y: plotRect.minY))
            path.addLine(to: CGPoint(x: lineX, y: plotRect.maxY))
            graphicsContext.stroke(
                path,
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
    }

    func canvasXAxisLabels(in plotRect: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(axisPresentationContext.xLabels) { labelDescriptor in
                if let x = canvasXPosition(for: labelDescriptor.index, in: plotRect) {
                    Text(labelDescriptor.text)
                        .font(context.config.axis.xAxisLabelFont)
                        .foregroundStyle(context.config.axis.xAxisLabelColor)
                        .position(x: x, y: 10)
                }
            }
        }
    }

    func handleCanvasTap(
        at location: CGPoint,
        xPositions: [CombinedChartView.XPositionDescriptor]) {
        let nearestIndex = CombinedChartView.SelectionHitResolver.resolveIndex(
            at: location,
            request: .init(
                dataCount: context.visibleData.count,
                minimumHitWidth: context.config.line.selection.minimumSelectionWidth,
                fallbackWidth: marksPresentationContext.fallbackBarWidth,
                xPositions: xPositions))

        if let nearestIndex {
            onSelectIndex(nearestIndex)
        }
    }
}
