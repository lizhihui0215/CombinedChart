import SwiftUI

extension CombinedChartView {
    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    struct Renderer: View {
        let context: RenderContext
        let onSelectIndex: (Int) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void
        let axisRenderContext: CombinedChartView.AxisContext
        let marksContext: CombinedChartView.MarksContext
        let overlayContext: CombinedChartView.OverlayContext
        let usesTrendBarColor: Bool
        let barMarkItems: [BarMarkItem]

        init(
            context: RenderContext,
            onSelectIndex: @escaping (Int) -> Void,
            onPlotAreaChange: @escaping (CGRect) -> Void,
            onYAxisTickPositions: @escaping ([Double: CGFloat]) -> Void) {
            self.context = context
            self.onSelectIndex = onSelectIndex
            self.onPlotAreaChange = onPlotAreaChange
            self.onYAxisTickPositions = onYAxisTickPositions

            let axisRenderContext = Self.makeAxisRenderContext(context: context)
            let marksContext = Self.makeMarksRenderContext(context: context)
            let overlayContext = Self.makeOverlayRenderContext(context: context)
            let usesTrendBarColor = Self.resolveUsesTrendBarColor(for: marksContext)

            self.axisRenderContext = axisRenderContext
            self.marksContext = marksContext
            self.overlayContext = overlayContext
            self.usesTrendBarColor = usesTrendBarColor
            barMarkItems = Self.makeBarMarkItems(
                visibleData: marksContext.visibleData,
                marksContext: marksContext,
                useTrendBarColor: usesTrendBarColor)
        }

        var body: some View {
            rendererBody
        }
    }
}

extension CombinedChartView.Renderer {
    enum RenderingEngine {
        case charts
        case canvas
    }

    struct BarMarkItem: Identifiable {
        enum Kind {
            case segment
            case gap
        }

        let id: String
        let xKey: String
        let start: Double
        let end: Double
        let color: Color
        let kind: Kind
    }

    func lineColor(for value: Double) -> Color {
        value >= 0 ? marksContext.config.line.positiveLineColor : marksContext.config.line.negativeLineColor
    }

    var xAxisHeight: CGFloat {
        context.config.rendering.xAxisHeight
    }

    @ViewBuilder
    var rendererBody: some View {
        switch resolvedRenderingEngine {
        case .charts:
            chartsBody
        case .canvas:
            canvasBody
        }
    }

    var resolvedRenderingEngine: RenderingEngine {
        switch context.config.rendering.engine {
        case .automatic:
            if #available(iOS 17, *) {
                .charts
            } else {
                .canvas
            }
        case .charts:
            .charts
        case .canvas:
            .canvas
        }
    }

    static func makeAxisRenderContext(
        context: CombinedChartView.RenderContext) -> CombinedChartView.AxisContext {
        let pointInfos = context.visibleData.enumerated().map { index, point in
            point.axisPointInfo(index: index)
        }

        return .init(
            monthValues: context.visibleData.map(\.xKey),
            pointInfos: pointInfos,
            pointInfoByKey: Dictionary(uniqueKeysWithValues: pointInfos.map { ($0.xKey, $0) }))
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

    static func makeOverlayRenderContext(
        context: CombinedChartView.RenderContext) -> CombinedChartView.OverlayContext {
        .init(
            selectedTab: context.selectedTab,
            visibleData: context.visibleData,
            yAxisTickValues: context.yAxisTickValues,
            unitWidth: context.unitWidth,
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

        return visibleData.flatMap { item in
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
                            xKey: item.xKey,
                            start: bounds.low,
                            end: bounds.high,
                            color: segment.color,
                            kind: .segment)
                    ]

                    if gap > 0.0001, abs(segment.start) > 0.0001 {
                        items.append(
                            BarMarkItem(
                                id: "\(item.id.groupID)|\(item.id.xKey)|\(segment.start)|gap",
                                xKey: item.xKey,
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
