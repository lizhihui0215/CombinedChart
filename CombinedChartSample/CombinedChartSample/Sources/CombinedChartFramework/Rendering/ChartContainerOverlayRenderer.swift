import Charts
import SwiftUI

extension CombinedChartView {
    struct ChartSelectionState {
        let point: ChartDataPoint
        let index: Int
        let value: Double
        let xPosition: CGFloat
    }

    struct SelectionLayout {
        let highlightWidth: CGFloat
        let indicatorFrame: CGRect
    }
}

extension CombinedChartView.ChartContainer {
    func containerOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let plotRect = geometry[proxy.plotAreaFrame]

            syncPlotOverlay(plotRect: plotRect, proxy: proxy)

            ZStack(alignment: .topLeading) {
                trendLineOverlay(plotRect: plotRect, proxy: proxy)
                selectionOverlay(plotRect: plotRect, proxy: proxy)
                tapSelectionOverlay(plotRect: plotRect, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    func syncPlotOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if hasValidPlotFrame(plotRect) {
            let currentRect = plotRect
            let positions = yAxisTickPositions(plotRect: plotRect, proxy: proxy)

            Color.clear
                .onAppear { onPlotAreaChange(currentRect) }
                .onChange(of: currentRect) { onPlotAreaChange($0) }

            Color.clear
                .onAppear { onYAxisTickPositions(positions) }
                .onChange(of: positions) { onYAxisTickPositions($0) }
        }
    }

    func hasValidPlotFrame(_ plotRect: CGRect) -> Bool {
        plotRect.width > 0 && plotRect.height > 0
    }

    @ViewBuilder
    func trendLineOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if overlayContext.selectedTab.mode.showsTrendLine {
            let segments = lineSegmentPaths(proxy: proxy)
            ForEach(segments) { segment in
                segment.path
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: overlayContext.config.line.lineWidth))
            }
            .mask(plotMask(for: plotRect))
        }
    }

    @ViewBuilder
    func selectionOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if let selectionState = selectionState(proxy: proxy) {
            let context = selectionOverlayContext(
                selectionState: selectionState,
                plotRect: plotRect,
                proxy: proxy)

            selectionOverlayView(context: context)
                .mask(plotMask(for: plotRect))
        }
    }

    @ViewBuilder
    func selectionOverlayView(context: CombinedChartView.SelectionOverlayContext) -> some View {
        if let overlay = overlayContext.selectionOverlay {
            overlay(context)
        } else {
            defaultSelectionOverlay(context: context)
        }
    }

    @ViewBuilder
    func defaultSelectionOverlay(context: CombinedChartView.SelectionOverlayContext) -> some View {
        if context.indicatorStyle == .line {
            selectionIndicatorLine(context: context)
        } else {
            selectionIndicatorBand(context: context)
        }
    }

    func selectionIndicatorLine(context: CombinedChartView.SelectionOverlayContext) -> some View {
        Path { path in
            path.move(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.minY))
            path.addLine(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.maxY))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        .foregroundStyle(overlaySelectionLineColor(for: context.value))
    }

    func selectionIndicatorBand(context: CombinedChartView.SelectionOverlayContext) -> some View {
        Rectangle()
            .fill(overlayContext.config.line.selection.fillColor)
            .frame(width: context.indicatorFrame.width, height: context.indicatorFrame.height)
            .position(x: context.indicatorFrame.midX, y: context.indicatorFrame.midY)
    }

    func selectionOverlayContext(
        selectionState: CombinedChartView.ChartSelectionState,
        plotRect: CGRect,
        proxy: ChartProxy) -> CombinedChartView.SelectionOverlayContext {
        let indicatorStyle = overlayContext.selectedTab.mode.selectionIndicatorStyle
        let layout = selectionLayout(
            for: selectionState,
            plotRect: plotRect,
            proxy: proxy,
            indicatorStyle: indicatorStyle)

        return .init(
            point: selectionState.point.source,
            value: selectionState.value,
            plotFrame: plotRect,
            indicatorFrame: layout.indicatorFrame,
            indicatorStyle: indicatorStyle)
    }

    func selectionLayout(
        for selectionState: CombinedChartView.ChartSelectionState,
        plotRect: CGRect,
        proxy: ChartProxy,
        indicatorStyle: CombinedChartView.ChartPresentationMode.SelectionIndicatorStyle) -> CombinedChartView
        .SelectionLayout {
        let highlightWidth = selectionHighlightWidth(
            at: selectionState.index,
            xPosition: selectionState.xPosition,
            proxy: proxy)

        let indicatorFrame = switch indicatorStyle {
        case .line:
            CGRect(
                x: selectionState.xPosition,
                y: plotRect.minY,
                width: 0,
                height: plotRect.height)
        case .band:
            CGRect(
                x: selectionState.xPosition - (highlightWidth / 2),
                y: plotRect.minY,
                width: highlightWidth,
                height: plotRect.height)
        }

        return .init(
            highlightWidth: highlightWidth,
            indicatorFrame: indicatorFrame)
    }

    func tapSelectionOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: plotRect.width, height: plotRect.height)
            .position(x: plotRect.midX, y: plotRect.midY)
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let tapLocation = value.location
                        guard plotRect.contains(tapLocation) else { return }

                        let candidates = overlayContext.visibleData.enumerated()
                            .compactMap { index, point -> (index: Int, xPosition: CGFloat)? in
                                guard let xPosition = proxy.position(forX: point.xKey) else { return nil }
                                return (index: index, xPosition: xPosition)
                            }
                        let nearestIndex = CombinedChartView.SelectionResolver.nearestIndex(
                            to: tapLocation,
                            candidates: candidates)

                        guard let nearestIndex else { return }
                        onSelectIndex(nearestIndex)
                    })
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

    func plotMask(for plotRect: CGRect) -> some View {
        Rectangle()
            .frame(width: plotRect.width, height: plotRect.height)
            .position(x: plotRect.midX, y: plotRect.midY)
    }

    func selectionState(proxy: ChartProxy) -> CombinedChartView.ChartSelectionState? {
        guard let visibleSelection = overlayContext.visibleSelection,
              overlayContext.visibleData.indices.contains(visibleSelection.index)
        else {
            return nil
        }

        let point = overlayContext.visibleData[visibleSelection.index]
        guard let xPos = proxy.position(forX: point.xKey) else {
            return nil
        }

        let value = point.trendLineValue(using: overlayContext.config)
        return CombinedChartView.ChartSelectionState(
            point: point,
            index: visibleSelection.index,
            value: value,
            xPosition: xPos)
    }

    func selectionHighlightWidth(at index: Int, xPosition: CGFloat, proxy: ChartProxy) -> CGFloat {
        let step: CGFloat = {
            if index + 1 < overlayContext.visibleData.count,
               let nextX = proxy.position(forX: overlayContext.visibleData[index + 1].xKey) {
                return nextX - xPosition
            }
            if index - 1 >= 0,
               let previousX = proxy.position(forX: overlayContext.visibleData[index - 1].xKey) {
                return xPosition - previousX
            }
            return overlayContext.config.bar.barWidth
        }()

        return max(step * 0.9, overlayContext.config.line.selection.minimumSelectionWidth)
    }

    func overlayLineColor(for value: Double) -> Color {
        value >= 0 ? marksContext.config.line.positiveLineColor : marksContext.config.line.negativeLineColor
    }

    func overlaySelectionLineColor(for value: Double) -> Color {
        switch marksContext.config.line.selection.selectionLineColorStrategy {
        case .fixedLine(let color):
            color
        case .color(let positive, let negative):
            value >= 0 ? positive : negative
        }
    }

    func lineSegmentPaths(proxy: ChartProxy) -> [CombinedChartView.LineSegmentPath] {
        let resolvedPoints = overlayContext.visibleData.compactMap { point -> (position: CGPoint, value: Double)? in
            let value = point.trendLineValue(using: overlayContext.config)
            guard let position = linePoint(for: point.xKey, value: value, proxy: proxy) else {
                return nil
            }
            return (position: position, value: value)
        }

        return CombinedChartView.LineSegmentResolver.makeSegments(
            points: resolvedPoints,
            color: overlayLineColor(for:))
    }

    func linePoint(for xKey: String, value: Double, proxy: ChartProxy) -> CGPoint? {
        guard let xPos = proxy.position(forX: xKey),
              let yPos = proxy.position(forY: value) else { return nil }
        return CGPoint(x: xPos, y: yPos)
    }
}
