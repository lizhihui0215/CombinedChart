import Charts
import SwiftUI

extension CombinedChartView {
    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    struct ChartRenderer: View {
        let context: ChartRenderContext
        let onSelectIndex: (Int) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void
        let axisRenderContext: CombinedChartView.AxisRenderContext
        let marksContext: CombinedChartView.MarksRenderContext
        let overlayContext: CombinedChartView.OverlayRenderContext
        let usesTrendBarColor: Bool
        private let barMarkItems: [BarMarkItem]

        init(
            context: ChartRenderContext,
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
            Chart {
                barMarks()
                sharedMarks
            }
            .chartXScale(domain: axisRenderContext.monthValues)
            .chartXAxis { chartXAxis(axisContext: axisRenderContext) }
            .chartYAxis { chartYAxis }
            .chartYScale(domain: context.yAxisDisplayDomain)
            .chartOverlay { proxy in
                containerOverlay(proxy: proxy)
            }
        }
    }
}

private extension CombinedChartView.ChartRenderer {
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

    static func makeAxisRenderContext(
        context: CombinedChartView.ChartRenderContext) -> CombinedChartView.AxisRenderContext {
        let pointInfos = context.visibleData.enumerated().map { index, point in
            point.axisPointInfo(index: index)
        }

        return .init(
            monthValues: context.visibleData.map(\.xKey),
            pointInfos: pointInfos,
            pointInfoByKey: Dictionary(uniqueKeysWithValues: pointInfos.map { ($0.xKey, $0) }))
    }

    static func makeMarksRenderContext(
        context: CombinedChartView.ChartRenderContext) -> CombinedChartView.MarksRenderContext {
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
        context: CombinedChartView.ChartRenderContext) -> CombinedChartView.OverlayRenderContext {
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
        for marksContext: CombinedChartView.MarksRenderContext) -> Bool {
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
        marksContext: CombinedChartView.MarksRenderContext,
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

    @ChartContentBuilder
    func barMarks() -> some ChartContent {
        ForEach(barMarkItems) { item in
            BarMark(
                x: .value("Month", item.xKey),
                yStart: .value(item.kind == .gap ? "Gap" : "Value", item.start),
                yEnd: .value(item.kind == .gap ? "Gap" : "Value", item.end),
                width: .fixed(marksContext.config.bar.barWidth))
                .cornerRadius(0)
                .foregroundStyle(item.color)
        }
    }

    @ChartContentBuilder
    var sharedMarks: some ChartContent {
        RuleMark(y: .value("Zero", 0))
            .foregroundStyle(marksContext.config.axis.zeroLineColor)
            .lineStyle(StrokeStyle(lineWidth: marksContext.config.axis.zeroLineWidth))

        if marksContext.selectedTab.mode.showsSelectedPoint,
           let visibleSelection = marksContext.visibleSelection,
           marksContext.visibleData.indices.contains(visibleSelection.index) {
            let value = marksContext.visibleData[visibleSelection.index]
                .trendLineValue(using: marksContext.config)
            PointMark(
                x: .value("Selected Month", marksContext.visibleData[visibleSelection.index].xKey),
                y: .value("Selected Value", value))
                .foregroundStyle(lineColor(for: value))
                .symbolSize(marksContext.config.line.selection.pointSize)
        }
    }
}
