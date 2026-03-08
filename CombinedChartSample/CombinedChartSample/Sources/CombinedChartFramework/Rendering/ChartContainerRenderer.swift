import Charts
import SwiftUI

extension CombinedChartView {
    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    struct ChartContainer: View {
        let context: ChartRenderContext
        let onSelectIndex: (Int) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void

        var body: some View {
            let axisContext = axisRenderContext

            Chart {
                barMarks(useTrendBarColor: usesTrendBarColor)
                sharedMarks
            }
            .chartXScale(domain: axisContext.monthValues)
            .chartXAxis { chartXAxis(axisContext: axisContext) }
            .chartYAxis { chartYAxis }
            .chartYScale(domain: context.yAxisDisplayDomain)
            .chartPlotStyle { plot in
                plot
            }
            .chartOverlay { proxy in
                containerOverlay(proxy: proxy)
            }
        }

        var axisRenderContext: AxisRenderContext {
            let pointInfos = context.visibleData.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            return .init(
                monthValues: context.visibleData.map(\.xKey),
                pointInfos: pointInfos,
                pointInfoByKey: Dictionary(uniqueKeysWithValues: pointInfos.map { ($0.xKey, $0) }))
        }

        var marksContext: MarksRenderContext {
            .init(
                selectedTab: context.selectedTab,
                visibleData: context.visibleData,
                yAxisDisplayDomain: context.yAxisDisplayDomain,
                plotAreaHeight: context.plotAreaHeight,
                config: context.config,
                showDebugOverlay: context.showDebugOverlay,
                visibleSelection: context.visibleSelection)
        }

        var overlayContext: OverlayRenderContext {
            .init(
                selectedTab: context.selectedTab,
                visibleData: context.visibleData,
                yAxisTickValues: context.yAxisTickValues,
                config: context.config,
                selectionOverlay: context.selectionOverlay,
                visibleSelection: context.visibleSelection)
        }
    }
}

private extension CombinedChartView.ChartContainer {
    func lineColor(for value: Double) -> Color {
        value >= 0 ? marksContext.config.line.positiveLineColor : marksContext.config.line.negativeLineColor
    }

    var usesTrendBarColor: Bool {
        guard marksContext.selectedTab.mode.barColorStyle == .unifiedTrendColor else {
            return false
        }

        if case .unified = marksContext.config.bar.trendBarColorStyle {
            return true
        }

        return false
    }

    func gapValue() -> Double {
        CombinedChartView.BarSegmentResolver.gapValue(
            plotAreaHeight: marksContext.plotAreaHeight,
            yAxisDisplayDomain: marksContext.yAxisDisplayDomain,
            segmentGap: marksContext.config.bar.segmentGap)
    }

    func segments(
        for point: CombinedChartView.ChartDataPoint,
        useTrendBarColor: Bool) -> [CombinedChartView.BarSegment] {
        CombinedChartView.BarSegmentResolver.makeSegments(
            for: point,
            series: marksContext.config.bar.series,
            useTrendBarColor: useTrendBarColor,
            trendBarColorStyle: marksContext.config.bar.trendBarColorStyle)
    }

    @ChartContentBuilder
    func barMarks(useTrendBarColor: Bool) -> some ChartContent {
        ForEach(Array(marksContext.visibleData.enumerated()), id: \.element.id) { index, item in
            ForEach(segments(for: item, useTrendBarColor: useTrendBarColor)) { segment in
                segmentBar(
                    index: index,
                    segment: segment,
                    gap: gapValue())
            }
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

        if marksContext.showDebugOverlay {
            ForEach(marksContext.visibleData, id: \.id) { item in
                RuleMark(x: .value("Debug X", item.xKey))
                    .foregroundStyle(Color.red.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [2, 3]))
            }
        }
    }

    @ChartContentBuilder
    func segmentBar(
        index: Int,
        segment: CombinedChartView.BarSegment,
        gap: Double) -> some ChartContent {
        let bounds = CombinedChartView.BarSegmentResolver.adjustedSegmentBounds(
            start: segment.start,
            value: segment.value)
        BarMark(
            x: .value("Month", marksContext.visibleData[index].xKey),
            yStart: .value("Value", bounds.low),
            yEnd: .value("Value", bounds.high),
            width: .fixed(marksContext.config.bar.barWidth))
            .cornerRadius(0)
            .foregroundStyle(segment.color)
        if gap > 0.0001, abs(segment.start) > 0.0001 {
            BarMark(
                x: .value("Month", marksContext.visibleData[index].xKey),
                yStart: .value("Gap", segment.start - gap / 2.0),
                yEnd: .value("Gap", segment.start + gap / 2.0),
                width: .fixed(marksContext.config.bar.barWidth))
                .foregroundStyle(marksContext.config.bar.segmentGapColor)
        }
    }
}
