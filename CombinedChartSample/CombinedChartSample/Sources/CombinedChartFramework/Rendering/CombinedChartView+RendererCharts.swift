import Charts
import SwiftUI

extension CombinedChartView.Renderer {
    @ViewBuilder
    var chartsBody: some View {
        let chart = Chart {
            barMarks()
            sharedMarks
        }
        .chartXScale(domain: axisRenderContext.monthValues)
        .chartYScale(domain: context.yAxisDisplayDomain)
        .chartYAxis {
            chartYAxis
        }

        if #available(iOS 17, *) {
            chart
                .chartXAxis {
                    chartXAxis(axisContext: axisRenderContext)
                }
                .chartOverlay { proxy in
                    containerOverlay(proxy: proxy)
                }
        } else {
            chart
        }
    }

    @ChartContentBuilder
    func barMarks() -> some ChartContent {
        ForEach(barMarkItems) { item in
            BarMark(
                x: .value("Month", item.xKey),
                yStart: .value("Start", item.start),
                yEnd: .value("End", item.end),
                width: .fixed(marksContext.config.bar.barWidth))
                .foregroundStyle(item.color)
        }
    }

    @ChartContentBuilder
    var sharedMarks: some ChartContent {
        if context.yAxisDisplayDomain.lowerBound <= 0,
           context.yAxisDisplayDomain.upperBound >= 0 {
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(marksContext.config.axis.gridLineColor.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: marksContext.config.axis.zeroLineWidth))
        }

        if let selection = context.visibleSelection,
           context.visibleData.indices.contains(selection.index),
           context.selectedTab.mode.showsSelectedPoint {
            let point = context.visibleData[selection.index]
            let value = point.trendLineValue(using: marksContext.config)
            PointMark(
                x: .value("Month", point.xKey),
                y: .value("Value", value))
                .foregroundStyle(overlaySelectionLineColor(for: value))
                .symbolSize(pow(marksContext.config.line.selection.pointSize, 2))
        }
    }
}
