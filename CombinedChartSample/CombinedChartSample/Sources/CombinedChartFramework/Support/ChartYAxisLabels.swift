import SwiftUI

extension CombinedChartView {
    struct YAxisLabelsContext {
        let yAxisTickValues: [Double]
        let tickPositions: [Double: CGFloat]
        let plotAreaMinY: CGFloat?
        let plotAreaHeight: CGFloat
        let labelText: (Double) -> String
    }

    struct ChartYAxisLabels: View {
        let context: YAxisLabelsContext

        var body: some View {
            let topPadding = context.plotAreaMinY ?? 12
            let plotHeight = context.plotAreaHeight > 0 ? context.plotAreaHeight : 320

            GeometryReader { _ in
                let maxLabelWidth: CGFloat = 44
                ZStack(alignment: .topLeading) {
                    ForEach(context.yAxisTickValues, id: \.self) { value in
                        if let yPos = context.tickPositions[value] {
                            Text(context.labelText(value))
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                                .frame(width: maxLabelWidth, alignment: .trailing)
                                .fixedSize(horizontal: false, vertical: true)
                                .position(x: 0, y: yPos)
                        }
                    }
                }
            }
            .frame(height: plotHeight)
            .padding(.top, topPadding)
        }
    }
}
