import SwiftUI

extension CombinedChartView {
    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    struct Renderer: View {
        let context: RenderContext
        let chartsScrollPosition: Binding<Double>?
        let onSelectIndex: (Int?) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void
        let chartPresentationContext: CombinedChartView.ChartPresentationDescriptor
        let marksContext: CombinedChartView.MarksContext
        let overlayContext: CombinedChartView.OverlayContext

        init(
            context: RenderContext,
            chartsScrollPosition: Binding<Double>? = nil,
            onSelectIndex: @escaping (Int?) -> Void,
            onPlotAreaChange: @escaping (CGRect) -> Void,
            onYAxisTickPositions: @escaping ([Double: CGFloat]) -> Void) {
            self.context = context
            self.chartsScrollPosition = chartsScrollPosition
            self.onSelectIndex = onSelectIndex
            self.onPlotAreaChange = onPlotAreaChange
            self.onYAxisTickPositions = onYAxisTickPositions

            let marksContext = Self.makeMarksRenderContext(context: context)
            let overlayContext = Self.makeOverlayRenderContext(context: context)
            let useTrendBarColor = Self.resolveUsesTrendBarColor(for: marksContext)
            let barMarkItems = Self.makeBarMarkItems(
                visibleData: marksContext.visibleData,
                marksContext: marksContext,
                useTrendBarColor: useTrendBarColor)
            let marksPresentationContext = Self.makeMarksPresentationContext(
                context: context,
                marksContext: marksContext,
                barMarkItems: barMarkItems)
            let chartPresentationContext = Self.makeChartPresentationContext(
                context: context,
                marksContext: marksContext,
                marksPresentationContext: marksPresentationContext)

            self.chartPresentationContext = chartPresentationContext
            self.marksContext = marksContext
            self.overlayContext = overlayContext
        }

        var body: some View {
            rendererBody
        }
    }
}

extension CombinedChartView.Renderer {
    var axisPresentationContext: CombinedChartView.AxisPresentationDescriptor {
        chartPresentationContext.axis
    }

    var marksPresentationContext: CombinedChartView.MarksPresentationDescriptor {
        chartPresentationContext.marks
    }

    struct BarMarkItem: Identifiable {
        enum Kind {
            case segment
            case gap
        }

        let id: String
        let xIndex: Int
        let xValue: Double
        let start: Double
        let end: Double
        let color: Color
        let kind: Kind
    }

    func lineColor(for value: Double) -> Color {
        value >= 0 ? marksContext.config.line.positiveLineColor : marksContext.config.line.negativeLineColor
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

    func debugGuides(
        plotRect: CGRect,
        guideMarks: [CombinedChartView.GuideMarkPresentationDescriptor]) -> some View {
        ZStack {
            ForEach(guideMarks) { guideMark in
                Path { path in
                    for xPosition in guideMark.xPositions {
                        path.move(to: CGPoint(x: xPosition, y: plotRect.minY))
                        path.addLine(to: CGPoint(x: xPosition, y: plotRect.maxY))
                    }
                }
                .stroke(
                    guideMark.color,
                    style: StrokeStyle(lineWidth: guideMark.lineWidth, dash: guideMark.dash))
            }
        }
    }

    func pointGuideXPositions(
        xPositions: [CombinedChartView.XPositionDescriptor]) -> [CGFloat] {
        CombinedChartView.DebugGuideResolver.pointGuideXPositions(xPositions: xPositions)
    }

    func thresholdGuideXPositions(
        xPositions: [CombinedChartView.XPositionDescriptor]) -> [CGFloat] {
        CombinedChartView.DebugGuideResolver.thresholdGuideXPositions(
            unitWidth: overlayContext.viewport.unitWidth,
            visibleStartThreshold: overlayContext.config.pager.visibleStartThreshold,
            xPositions: xPositions)
    }

    func plotMask(for plotFrame: CombinedChartView.PlotFrameDescriptor) -> some View {
        Rectangle()
            .frame(width: plotFrame.maskFrame.width, height: plotFrame.maskFrame.height)
            .position(x: plotFrame.maskFrame.midX, y: plotFrame.maskFrame.midY)
    }

    @ViewBuilder
    func selectionOverlayView(selection: CombinedChartView.SelectionPresentationDescriptor) -> some View {
        if let context = selection.context {
            switch selection.mode {
            case .none:
                EmptyView()
            case .defaultOverlay:
                defaultSelectionOverlay(context: context)
            case .customOverlay:
                if let overlay = overlayContext.selectionOverlay {
                    overlay(context)
                }
            }
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
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.minY))
                path.addLine(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.maxY))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .foregroundStyle(overlaySelectionLineColor(for: context.value))

            Color.clear
                .frame(width: max(context.indicatorFrame.width, 2), height: context.plotFrame.height)
                .position(x: context.indicatorFrame.midX, y: context.plotFrame.midY)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("combined-chart-selection-indicator")
        }
    }

    func selectionIndicatorBand(context: CombinedChartView.SelectionOverlayContext) -> some View {
        Rectangle()
            .fill(overlayContext.config.line.selection.fillColor)
            .frame(width: context.indicatorFrame.width, height: context.indicatorFrame.height)
            .position(x: context.indicatorFrame.midX, y: context.indicatorFrame.midY)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("combined-chart-selection-indicator")
    }

    func makeSelectionPresentationDescriptor(
        plotRect: CGRect,
        xPositions: [CombinedChartView.XPositionDescriptor],
        yPosition: @escaping (Double) -> CGFloat?) -> CombinedChartView.SelectionPresentationDescriptor {
        let selectionOverlayState = CombinedChartView.SelectionOverlayResolver.resolve(.init(
            visibleSelection: overlayContext.visibleSelection,
            data: overlayContext.visibleData,
            config: overlayContext.config,
            indicatorStyle: overlayContext.selectedTab.mode.selectionIndicatorStyle,
            plotRect: plotRect,
            minimumSelectionWidth: overlayContext.config.line.selection.minimumSelectionWidth,
            fallbackWidth: marksPresentationContext.fallbackBarWidth,
            xPositions: xPositions,
            yPosition: yPosition))

        guard let selectionOverlayState else {
            return .init(
                mode: .none,
                overlayState: nil,
                indicatorLineColor: nil,
                indicatorFillColor: nil)
        }

        let mode: CombinedChartView.SelectionPresentationDescriptor.Mode =
            overlayContext.selectionOverlay == nil ? .defaultOverlay : .customOverlay

        let indicatorLineColor: Color?
        let indicatorFillColor: Color?
        if mode == .defaultOverlay {
            indicatorLineColor = selectionOverlayState.context.indicatorStyle == .line
                ? overlaySelectionLineColor(for: selectionOverlayState.selectionState.value)
                : nil
            indicatorFillColor = selectionOverlayState.context.indicatorStyle == .band
                ? overlayContext.config.line.selection.fillColor
                : nil
        } else {
            indicatorLineColor = nil
            indicatorFillColor = nil
        }

        return .init(
            mode: mode,
            overlayState: selectionOverlayState,
            indicatorLineColor: indicatorLineColor,
            indicatorFillColor: indicatorFillColor)
    }

    func makeOverlayPresentationDescriptor(
        plotRect: CGRect,
        xPositions: [CombinedChartView.XPositionDescriptor],
        yPosition: @escaping (Double) -> CGFloat?) -> CombinedChartView.OverlayPresentationDescriptor {
        let lineMarks: [CombinedChartView.LineMarkPresentationDescriptor]
        if let trendLineStyle = marksPresentationContext.trendLineStyle {
            let segments = CombinedChartView.TrendLineResolver.segments(.init(
                data: overlayContext.visibleData,
                config: overlayContext.config,
                xPositions: xPositions,
                yPosition: yPosition),
                color: overlayLineColor(for:))
            lineMarks = [
                .init(
                    id: "trend-line",
                    segments: segments,
                    lineWidth: trendLineStyle.width)
            ]
        } else {
            lineMarks = []
        }

        let selection = makeSelectionPresentationDescriptor(
            plotRect: plotRect,
            xPositions: xPositions,
            yPosition: yPosition)

        let guideMarks: [CombinedChartView.GuideMarkPresentationDescriptor]
        if marksContext.showDebugOverlay {
            guideMarks = [
                .init(
                    id: "point-guides",
                    kind: .point,
                    xPositions: pointGuideXPositions(xPositions: xPositions),
                    color: overlayContext.config.debug.pointGuideColor,
                    lineWidth: 1.0,
                    dash: [2, 3]),
                .init(
                    id: "threshold-guides",
                    kind: .threshold,
                    xPositions: thresholdGuideXPositions(xPositions: xPositions),
                    color: overlayContext.config.debug.thresholdGuideColor,
                    lineWidth: 1.0,
                    dash: [6, 4])
            ]
        } else {
            guideMarks = []
        }

        return .init(
            lineMarks: lineMarks,
            selection: selection,
            guideMarks: guideMarks)
    }

    var xAxisHeight: CGFloat {
        context.config.rendering.xAxisHeight
    }

    @ViewBuilder
    var rendererBody: some View {
        switch implementation {
        case .charts:
            if #available(iOS 16, *) {
                chartsBody
            } else {
                canvasBody
            }
        case .canvas, .uiKit:
            canvasBody
        }
    }

    var implementation: CombinedChartView.Implementation {
        .resolve(config: context.config)
    }

    static func makeAxisPresentationContext(
        context: CombinedChartView.RenderContext) -> CombinedChartView.AxisPresentationDescriptor {
        let pointInfos = context.visibleData.enumerated().map { index, point in
            point.axisPointInfo(index: index)
        }

        return .init(
            xLabels: makeXAxisLabelDescriptors(
                pointInfos: pointInfos,
                config: context.config),
            xDomain: -0.5...Double(max(pointInfos.count, 1)) - 0.5,
            yGridValues: context.yAxisTickValues)
    }

    static func makeXAxisLabelDescriptors(
        pointInfos: [ChartConfig.Axis.PointInfo],
        config: ChartConfig) -> [CombinedChartView.XAxisLabelDescriptor] {
        pointInfos.map { pointInfo in
            let text = config.axis.xAxisLabel(.init(point: pointInfo, visiblePoints: pointInfos))
            return .init(
                id: pointInfo.id,
                index: pointInfo.index,
                xValue: Double(pointInfo.index),
                text: text)
        }
    }

    static func makeMarksRenderContext(
        context: CombinedChartView.RenderContext) -> CombinedChartView.MarksContext {
        .init(
            selectedTab: context.selectedTab,
            visibleData: context.visibleData,
            yAxisDisplayDomain: context.yAxisDisplayDomain,
            plotAreaHeight: context.plotAreaHeight,
            config: context.config,
            showDebugOverlay: context.showDebugOverlay,
            visibleSelection: context.visibleSelection)
    }

    static func makeChartPresentationContext(
        context: CombinedChartView.RenderContext,
        marksContext _: CombinedChartView.MarksContext,
        marksPresentationContext: CombinedChartView.MarksPresentationDescriptor) -> CombinedChartView.ChartPresentationDescriptor {
        .init(
            axis: makeAxisPresentationContext(context: context),
            marks: marksPresentationContext)
    }

    static func makeMarksPresentationContext(
        context: CombinedChartView.RenderContext,
        marksContext: CombinedChartView.MarksContext,
        barMarkItems: [BarMarkItem]) -> CombinedChartView.MarksPresentationDescriptor {
        let fallbackBarWidth = resolveBarWidth(
            preferredBarWidth: context.config.bar.barWidth,
            unitWidth: context.viewport.unitWidth)
        return CombinedChartView.MarksPresentationDescriptor(
            barMarks: makeBarMarkPresentationDescriptors(
                items: barMarkItems,
                width: fallbackBarWidth),
            ruleMarks: makeRuleMarkPresentationDescriptors(
                zeroLine: makeZeroLineMarkDescriptor(
                    yAxisDisplayDomain: context.yAxisDisplayDomain,
                    config: context.config)),
            pointMarks: makePointMarkPresentationDescriptors(
                selectedPoint: makeSelectedPointMarkDescriptor(
                    marksContext: marksContext)),
            fallbackBarWidth: fallbackBarWidth,
            trendLineStyle: marksContext.selectedTab.mode.showsTrendLine
                ? CombinedChartView.TrendLineStylePresentationDescriptor(width: marksContext.config.line.lineWidth)
                : nil)
    }

    static func makeBarMarkPresentationDescriptors(
        items: [BarMarkItem],
        width: CGFloat) -> [CombinedChartView.BarMarkPresentationDescriptor] {
        items.map { item in
            .init(
                id: item.id,
                xIndex: item.xIndex,
                xValue: item.xValue,
                start: item.start,
                end: item.end,
                color: item.color,
                width: width,
                kind: item.kind)
        }
    }

    static func makeRuleMarkPresentationDescriptors(
        zeroLine: CombinedChartView.RuleMarkPresentationDescriptor?) -> [CombinedChartView.RuleMarkPresentationDescriptor] {
        guard let zeroLine else { return [] }
        return [zeroLine]
    }

    static func makePointMarkPresentationDescriptors(
        selectedPoint: CombinedChartView.PointMarkPresentationDescriptor?) -> [CombinedChartView.PointMarkPresentationDescriptor] {
        guard let selectedPoint else { return [] }
        return [selectedPoint]
    }

    static func resolveBarWidth(
        preferredBarWidth: CGFloat,
        unitWidth: CGFloat) -> CGFloat {
        guard unitWidth > 0 else { return preferredBarWidth }
        return min(preferredBarWidth, unitWidth)
    }

    static func makeZeroLineMarkDescriptor(
        yAxisDisplayDomain: ClosedRange<Double>,
        config: ChartConfig) -> CombinedChartView.RuleMarkPresentationDescriptor? {
        guard yAxisDisplayDomain.lowerBound <= 0,
              yAxisDisplayDomain.upperBound >= 0 else {
            return nil
        }

        return .init(
            id: "zero-line",
            value: 0,
            color: config.axis.gridLineColor.opacity(0.8),
            lineWidth: config.axis.zeroLineWidth)
    }

    static func makeSelectedPointMarkDescriptor(
        marksContext: CombinedChartView.MarksContext) -> CombinedChartView.PointMarkPresentationDescriptor? {
        guard let selection = marksContext.visibleSelection,
              marksContext.visibleData.indices.contains(selection.index),
              marksContext.selectedTab.mode.showsSelectedPoint else {
            return nil
        }

        let point = marksContext.visibleData[selection.index]
        let value = point.trendLineValue(using: marksContext.config)

        return .init(
            id: point.id.groupID + "|" + point.id.xKey + "|selected-point",
            index: selection.index,
            xValue: Double(selection.index),
            value: value,
            color: selectionMarkColor(
                value: value,
                selection: marksContext.config.line.selection),
            pointSize: marksContext.config.line.selection.pointSize)
    }

    static func selectionMarkColor(
        value: Double,
        selection: ChartConfig.Line.Selection) -> Color {
        switch selection.selectionLineColorStrategy {
        case .fixedLine(let color):
            color
        case .color(let positive, let negative):
            value >= 0 ? positive : negative
        }
    }

    static func makeOverlayRenderContext(
        context: CombinedChartView.RenderContext) -> CombinedChartView.OverlayContext {
        .init(
            selectedTab: context.selectedTab,
            visibleData: context.visibleData,
            yAxisTickValues: context.yAxisTickValues,
            viewport: context.viewport,
            config: context.config,
            selectionOverlay: context.selectionOverlay,
            visibleSelection: context.visibleSelection)
    }

    static func resolveUsesTrendBarColor(
        for marksContext: CombinedChartView.MarksContext) -> Bool {
        guard marksContext.selectedTab.mode.barColorStyle == .unifiedTrendColor else {
            return false
        }

        if case .unified = marksContext.config.bar.trendBarColorStyle {
            return true
        }

        return false
    }

    static func makeBarMarkItems(
        visibleData: [CombinedChartView.ChartDataPoint],
        marksContext: CombinedChartView.MarksContext,
        useTrendBarColor: Bool) -> [BarMarkItem] {
        let gap = CombinedChartView.BarSegmentResolver.gapValue(
            plotAreaHeight: marksContext.plotAreaHeight,
            yAxisDisplayDomain: marksContext.yAxisDisplayDomain,
            segmentGap: marksContext.config.bar.segmentGap)

        return visibleData.enumerated().flatMap { index, item in
            CombinedChartView.BarSegmentResolver.makeSegments(
                for: item,
                series: marksContext.config.bar.series,
                useTrendBarColor: useTrendBarColor,
                trendBarColorStyle: marksContext.config.bar.trendBarColorStyle)
                .flatMap { segment -> [BarMarkItem] in
                    let bounds = CombinedChartView.BarSegmentResolver.adjustedSegmentBounds(
                        start: segment.start,
                        value: segment.value)
                    var items = [
                        BarMarkItem(
                            id: "\(item.id.groupID)|\(item.id.xKey)|\(segment.start)|\(segment.value)|segment",
                            xIndex: index,
                            xValue: Double(index),
                            start: bounds.low,
                            end: bounds.high,
                            color: segment.color,
                            kind: .segment)
                    ]

                    if gap > 0.0001, abs(segment.start) > 0.0001 {
                        items.append(
                            BarMarkItem(
                                id: "\(item.id.groupID)|\(item.id.xKey)|\(segment.start)|gap",
                                xIndex: index,
                                xValue: Double(index),
                                start: segment.start - gap / 2.0,
                                end: segment.start + gap / 2.0,
                                color: marksContext.config.bar.segmentGapColor,
                                kind: .gap))
                    }

                    return items
                }
        }
    }
}
