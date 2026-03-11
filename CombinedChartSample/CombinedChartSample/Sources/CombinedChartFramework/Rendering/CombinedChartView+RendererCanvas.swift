import OSLog
import SwiftUI

extension CombinedChartView.Renderer {
    private var logger: Logger {
        ChartLog.logger(.rendering)
    }

    var canvasBody: some View {
        GeometryReader { geometry in
            let plotAreaFrameHeight = max(0, geometry.size.height - xAxisHeight)
            let plotRect = canvasPlotRect(
                in: CGSize(width: geometry.size.width, height: plotAreaFrameHeight),
                xAxisHeight: 0)
            let tickPositions = canvasTickPositions(in: plotRect)
            let tickPositionMap = canvasTickPositionMap(in: plotRect)
            let lineSegments = canvasLineSegments(in: plotRect)

            VStack(spacing: 0) {
                Canvas { graphicsContext, _ in
                    drawCanvasGrid(in: &graphicsContext, plotRect: plotRect, tickPositions: tickPositions)
                    drawCanvasZeroLine(in: &graphicsContext, plotRect: plotRect)
                    drawCanvasBars(in: &graphicsContext, plotRect: plotRect)
                    if context.selectedTab.mode.showsTrendLine {
                        drawCanvasTrendLine(in: &graphicsContext, lineSegments: lineSegments)
                    }
                    drawCanvasSelection(in: &graphicsContext, plotRect: plotRect)
                }
                .frame(height: plotAreaFrameHeight)
                .background(Color.clear)
                .contentShape(Rectangle())
                .onAppear {
                    logCanvasYAxisDebug(
                        phase: "appear",
                        size: CGSize(width: geometry.size.width, height: plotAreaFrameHeight),
                        xAxisHeight: xAxisHeight,
                        plotRect: plotRect,
                        tickPositionMap: tickPositionMap)
                    onPlotAreaChange(plotRect)
                    onYAxisTickPositions(tickPositionMap)
                }
                .onChange(of: plotRect.size) { _ in
                    logCanvasYAxisDebug(
                        phase: "plotRect.size changed",
                        size: CGSize(width: geometry.size.width, height: plotAreaFrameHeight),
                        xAxisHeight: xAxisHeight,
                        plotRect: plotRect,
                        tickPositionMap: tickPositionMap)
                    onPlotAreaChange(plotRect)
                    onYAxisTickPositions(tickPositionMap)
                }
                .gesture(canvasTapGesture(in: plotRect))

                canvasXAxisLabels(in: plotRect)
                    .frame(height: xAxisHeight)
            }
        }
    }

    func canvasPlotRect(in size: CGSize, xAxisHeight: CGFloat) -> CGRect {
        CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: max(0, size.height - xAxisHeight))
    }

    func canvasXPosition(for key: String, in plotRect: CGRect) -> CGFloat? {
        guard let index = axisRenderContext.monthValues.firstIndex(of: key),
              !axisRenderContext.monthValues.isEmpty
        else {
            return nil
        }

        let step = plotRect.width / CGFloat(axisRenderContext.monthValues.count)
        return plotRect.minX + step * (CGFloat(index) + 0.5)
    }

    func canvasYPosition(for value: Double, in plotRect: CGRect) -> CGFloat? {
        let domain = context.yAxisDisplayDomain
        let range = domain.upperBound - domain.lowerBound
        guard range > 0 else { return nil }

        let normalized = (value - domain.lowerBound) / range
        return plotRect.maxY - CGFloat(normalized) * plotRect.height
    }

    func canvasTickPositions(in plotRect: CGRect) -> [CGFloat] {
        context.yAxisTickValues.compactMap { value in
            canvasYPosition(for: value, in: plotRect)
        }
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

    func canvasLineSegments(in plotRect: CGRect) -> [CombinedChartView.LineSegmentPath] {
        let points = context.visibleData.compactMap { point -> (CGPoint, Double)? in
            let value = point.trendLineValue(using: overlayContext.config)
            guard
                let x = canvasXPosition(for: point.xKey, in: plotRect),
                let y = canvasYPosition(for: value, in: plotRect)
            else {
                return nil
            }

            return (CGPoint(x: x, y: y), value)
        }

        return CombinedChartView.LineSegmentResolver.makeSegments(
            points: points,
            style: overlayContext.config.line.lineType,
            color: overlayLineColor)
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
        guard
            context.yAxisDisplayDomain.lowerBound <= 0,
            context.yAxisDisplayDomain.upperBound >= 0,
            let y = canvasYPosition(for: 0, in: plotRect)
        else {
            return
        }

        var path = Path()
        path.move(to: CGPoint(x: plotRect.minX, y: y))
        path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        graphicsContext.stroke(
            path,
            with: .color(context.config.axis.gridLineColor.opacity(0.8)),
            lineWidth: context.config.axis.zeroLineWidth)
    }

    func drawCanvasBars(in graphicsContext: inout GraphicsContext, plotRect: CGRect) {
        guard !barMarkItems.isEmpty else { return }

        let step = plotRect.width / CGFloat(max(axisRenderContext.monthValues.count, 1))
        let barWidth = min(context.config.bar.barWidth, step)

        for item in barMarkItems {
            guard
                let x = canvasXPosition(for: item.xKey, in: plotRect),
                let yStart = canvasYPosition(for: item.start, in: plotRect),
                let yEnd = canvasYPosition(for: item.end, in: plotRect)
            else {
                continue
            }

            let rect = CGRect(
                x: x - barWidth / 2,
                y: min(yStart, yEnd),
                width: barWidth,
                height: Swift.abs(yEnd - yStart))

            graphicsContext.fill(Path(rect), with: .color(item.color))
        }
    }

    func drawCanvasTrendLine(
        in graphicsContext: inout GraphicsContext,
        lineSegments: [CombinedChartView.LineSegmentPath]) {
        for segment in lineSegments {
            graphicsContext.stroke(
                segment.path,
                with: .color(segment.color),
                style: StrokeStyle(lineWidth: overlayContext.config.line.lineWidth))
        }
    }

    func drawCanvasSelection(in graphicsContext: inout GraphicsContext, plotRect: CGRect) {
        guard
            let selection = context.visibleSelection,
            context.visibleData.indices.contains(selection.index)
        else {
            return
        }

        let point = context.visibleData[selection.index]
        let value = point.trendLineValue(using: overlayContext.config)
        guard
            let x = canvasXPosition(for: point.xKey, in: plotRect),
            let y = canvasYPosition(for: value, in: plotRect)
        else {
            return
        }

        let unitWidth = plotRect.width / CGFloat(max(axisRenderContext.monthValues.count, 1))
        let lineColor = overlaySelectionLineColor(for: value)

        switch context.selectedTab.mode.selectionIndicatorStyle {
        case .band:
            let width = max(unitWidth * 0.9, overlayContext.config.line.selection.minimumSelectionWidth)
            let rect = CGRect(x: x - width / 2, y: plotRect.minY, width: width, height: plotRect.height)
            graphicsContext.fill(Path(rect), with: .color(lineColor.opacity(0.08)))
        case .line:
            var path = Path()
            path.move(to: CGPoint(x: x, y: plotRect.minY))
            path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
            graphicsContext.stroke(path, with: .color(lineColor), lineWidth: 1)
        }

        if context.selectedTab.mode.showsSelectedPoint {
            let pointSize = overlayContext.config.line.selection.pointSize
            let rect = CGRect(x: x - pointSize / 2, y: y - pointSize / 2, width: pointSize, height: pointSize)
            graphicsContext.fill(Path(ellipseIn: rect), with: .color(lineColor))
        }
    }

    func canvasXAxisLabels(in plotRect: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(axisRenderContext.pointInfos, id: \.xKey) { pointInfo in
                if let x = canvasXPosition(for: pointInfo.xKey, in: plotRect) {
                    Text(context.config.axis.xAxisLabel(xAxisLabelContext(
                        for: pointInfo.xKey,
                        axisPointByKey: axisRenderContext.pointInfoByKey,
                        axisPointInfos: axisRenderContext.pointInfos)))
                        .font(context.config.axis.xAxisLabelFont)
                        .foregroundStyle(context.config.axis.xAxisLabelColor)
                        .position(x: x, y: 10)
                }
            }
        }
    }

    func canvasTapGesture(in plotRect: CGRect) -> some Gesture {
        SpatialTapGesture()
            .onEnded { gesture in
                let candidates = context.visibleData.enumerated().compactMap { index, point -> (
                    index: Int,
                    xPosition: CGFloat)? in
                    guard let x = canvasXPosition(for: point.xKey, in: plotRect) else { return nil }
                    return (index: index, xPosition: x)
                }

                if let index = CombinedChartView.SelectionResolver.nearestIndex(
                    to: gesture.location,
                    candidates: candidates) {
                    onSelectIndex(index)
                }
            }
    }
}
