import Charts
import SwiftUI

@available(iOS 16, *)
extension CombinedChartView.Renderer {
    @AxisContentBuilder
    func chartXAxis(axisContext: CombinedChartView.AxisPresentationDescriptor) -> some AxisContent {
        AxisMarks(values: axisContext.xValues) { value in
            AxisValueLabel {
                if let xValue = value.as(Double.self),
                   let labelDescriptor = axisContext.xLabel(forXValue: xValue) {
                    Text(labelDescriptor.text)
                        .font(context.config.axis.xAxisLabelFont)
                        .foregroundStyle(context.config.axis.xAxisLabelColor)
                        .accessibilityIdentifier("combined-chart-x-axis-label-\(labelDescriptor.index)")
                }
            }
        }
    }

    @AxisContentBuilder
    var chartYAxis: some AxisContent {
        AxisMarks(position: .leading, values: axisPresentationContext.yGridValues) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: context.config.axis.gridLineWidth))
                .foregroundStyle(context.config.axis.gridLineColor)
        }
    }
}
