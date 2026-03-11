import SwiftUI

extension CombinedChartView {
    struct YAxisLabelsContext {
        let yAxisTickValues: [Double]
        let tickPositions: [Double: CGFloat]
        let plotAreaMinY: CGFloat?
        let plotAreaHeight: CGFloat
        let labelWidth: CGFloat
        let labelText: (Double) -> String
        let labelFont: Font
        let labelColor: Color
    }

    struct YAxisLabels: View {
        let context: YAxisLabelsContext

        var body: some View {
            let tickRange = context.tickPositions.values.min().flatMap { minY in
                context.tickPositions.values.max().map { maxY in (minY, maxY) }
            }
            let topPadding = context.plotAreaMinY ?? tickRange?.0 ?? 0
            let fallbackPlotAreaHeight = tickRange.map { max($0.1 - $0.0, 0) } ?? 320
            let plotAreaHeight = context.plotAreaHeight > 0 ? context.plotAreaHeight : fallbackPlotAreaHeight
            let totalHeight = max(topPadding + plotAreaHeight, topPadding)

            ZStack(alignment: .topLeading) {
                ForEach(context.yAxisTickValues, id: \.self) { value in
                    if let yPos = context.tickPositions[value] {
                        Text(context.labelText(value))
                            .font(context.labelFont)
                            .foregroundStyle(context.labelColor)
                            .multilineTextAlignment(.trailing)
                            .frame(width: context.labelWidth, alignment: .trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .position(x: context.labelWidth / 2, y: yPos)
                    }
                }
            }
            .frame(width: context.labelWidth, height: totalHeight, alignment: .topLeading)
        }
    }
}
