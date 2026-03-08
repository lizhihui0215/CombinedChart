import Charts
import SwiftUI

extension CombinedChartView.ChartContainer {
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
                        .font(.caption2)
                }
            }
        }
    }

    @AxisContentBuilder
    var chartYAxis: some AxisContent {
        AxisMarks(position: .leading, values: context.yAxisTickValues) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.gray)
        }
    }

    func xAxisLabelContext(
        for key: String,
        axisPointByKey: [String: ChartConfig.ChartAxisConfig.AxisPointInfo],
        axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo]) -> ChartConfig.ChartAxisConfig.XAxisLabelContext {
        .init(
            point: axisPointByKey[key] ?? fallbackAxisPointInfo(for: key),
            visiblePoints: axisPointInfos)
    }

    func fallbackAxisPointInfo(for key: String) -> ChartConfig.ChartAxisConfig.AxisPointInfo {
        .init(
            id: key,
            index: 0,
            xKey: key,
            xLabel: key,
            values: [:])
    }
}
