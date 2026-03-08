import Charts
import SwiftUI

extension CombinedChartView.ChartRenderer {
    @AxisContentBuilder
    func chartXAxis(axisContext: CombinedChartView.AxisRenderContext) -> some AxisContent {
        AxisMarks(values: axisContext.monthValues) { value in
            AxisValueLabel(centered: true) {
                if let key = value.as(String.self) {
                    Text(context.config.axis.xAxisLabel(
                        xAxisLabelContext(
                            for: key,
                            axisPointByKey: axisContext.pointInfoByKey,
                            axisPointInfos: axisContext.pointInfos)))
                        .font(context.config.axis.xAxisLabelFont)
                        .foregroundStyle(context.config.axis.xAxisLabelColor)
                }
            }
        }
    }

    @AxisContentBuilder
    var chartYAxis: some AxisContent {
        AxisMarks(position: .leading, values: context.yAxisTickValues) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: context.config.axis.gridLineWidth))
                .foregroundStyle(context.config.axis.gridLineColor)
        }
    }

    func xAxisLabelContext(
        for key: String,
        axisPointByKey: [String: ChartConfig.Axis.PointInfo],
        axisPointInfos: [ChartConfig.Axis.PointInfo]) -> ChartConfig.Axis.XLabelContext {
        .init(
            point: axisPointByKey[key] ?? fallbackAxisPointInfo(for: key),
            visiblePoints: axisPointInfos)
    }

    func fallbackAxisPointInfo(for key: String) -> ChartConfig.Axis.PointInfo {
        .init(
            id: key,
            index: 0,
            xKey: key,
            xLabel: key,
            values: [:])
    }
}
