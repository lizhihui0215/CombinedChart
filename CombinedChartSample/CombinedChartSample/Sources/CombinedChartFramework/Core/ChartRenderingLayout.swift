import SwiftUI

extension CombinedChartView {
    struct RenderingLayout {
        let topInset: CGFloat
        let xAxisHeight: CGFloat

        init(rendering: ChartConfig.Rendering) {
            topInset = rendering.topInset
            xAxisHeight = rendering.xAxisHeight
        }

        func contentHeight(for totalHeight: CGFloat) -> CGFloat {
            max(totalHeight - topInset, 0)
        }

        func plotAreaHeight(for totalHeight: CGFloat) -> CGFloat {
            max(contentHeight(for: totalHeight) - xAxisHeight, 0)
        }

        func canvasTickPositions(
            yAxisTickValues: [Double],
            yAxisDisplayDomain: ClosedRange<Double>,
            plotAreaHeight: CGFloat) -> [Double: CGFloat] {
            let range = yAxisDisplayDomain.upperBound - yAxisDisplayDomain.lowerBound
            guard plotAreaHeight > 0, range > 0 else { return [:] }

            return Dictionary(uniqueKeysWithValues: yAxisTickValues.map { value in
                let normalized = (value - yAxisDisplayDomain.lowerBound) / range
                let position = plotAreaHeight - (CGFloat(normalized) * plotAreaHeight)
                return (value, position)
            })
        }
    }
}
