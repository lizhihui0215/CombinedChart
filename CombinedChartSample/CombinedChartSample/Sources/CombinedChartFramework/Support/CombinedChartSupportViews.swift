import SwiftUI

extension CombinedChartView {
    struct ChartYAxisLabels: View {
        let context: YAxisLabelsContext

        var body: some View {
            let topPadding = context.plotArea?.minY ?? 12
            let plotHeight = context.plotArea?.height ?? 320

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

    struct CombinedChartPager: View {
        let context: PagerContext

        private var highlightedEntryTitle: String? {
            context.highlightedEntry?.displayTitle
        }

        var body: some View {
            HStack(spacing: 12) {
                Button(action: context.onSelectPreviousPage) {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(context.canSelectPreviousPage ? .primary : .secondary)
                .disabled(!context.canSelectPreviousPage)

                Spacer()

                Text(highlightedEntryTitle ?? "")
                    .font(.callout.weight(.semibold))

                Spacer()

                Button(action: context.onSelectNextPage) {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(context.canSelectNextPage ? .primary : .secondary)
                .disabled(!context.canSelectNextPage)
            }
            .padding(.horizontal, 8)
        }
    }
}
