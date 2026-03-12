import SwiftUI

extension CombinedChartView {
    struct YAxisLabelsContext {
        let yAxisTickValues: [Double]
        let descriptor: YAxisDescriptor
        let labelText: (Double) -> String
        let labelFont: Font
        let labelColor: Color
    }

    struct YAxisLabels: View {
        let context: YAxisLabelsContext

        var body: some View {
            ZStack(alignment: .topLeading) {
                ForEach(context.yAxisTickValues, id: \.self) { value in
                    if let yPos = context.descriptor.tickPositions[value] {
                        Text(context.labelText(value))
                            .font(context.labelFont)
                            .foregroundStyle(context.labelColor)
                            .multilineTextAlignment(.trailing)
                            .frame(width: context.descriptor.labelWidth, alignment: .trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .position(x: context.descriptor.labelWidth / 2, y: yPos)
                    }
                }
            }
            .frame(
                width: context.descriptor.labelWidth,
                height: context.descriptor.totalHeight,
                alignment: .topLeading)
        }
    }
}
