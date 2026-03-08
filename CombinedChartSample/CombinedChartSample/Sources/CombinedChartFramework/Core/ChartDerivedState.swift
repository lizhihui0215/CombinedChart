import SwiftUI

extension CombinedChartView {
    struct ChartDerivedState {
        let hasData: Bool
        let axisPointInfos: [ChartConfig.Axis.PointInfo]
        let yDomain: ClosedRange<Double>
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let viewport: ChartViewportDerivedState

        init(
            config: ChartConfig,
            sortedGroups: [ChartDataGroup],
            data: [ChartDataPoint],
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) {
            hasData = !data.isEmpty
            axisPointInfos = data.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            let minValue = data
                .map { $0.stackedExtents(using: config).min }
                .min() ?? -20
            let maxValue = data
                .map { $0.stackedExtents(using: config).max }
                .max() ?? 20
            let padding = max((maxValue - minValue) * 0.1, 2)
            yDomain = (minValue - padding)...(maxValue + padding)

            let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
            let step = max(ceil(halfRange / 5.0), 1.0)
            yAxisTickValues = (-5...5).map { Double($0) * step }

            if let first = yAxisTickValues.first, let last = yAxisTickValues.last {
                let gridlineInset = max(step * 0.01, 0.001)
                yAxisDisplayDomain = (first - gridlineInset)...(last + gridlineInset)
            } else {
                yAxisDisplayDomain = yDomain
            }

            viewport = .init(
                visibleStartLabel: data.indices.contains(startIndex)
                    ? data[startIndex].xLabel
                    : nil,
                pagerState: .init(
                    sortedGroups: sortedGroups,
                    dataCount: data.count,
                    monthsPerPage: config.monthsPerPage,
                    startIndex: startIndex,
                    contentOffsetX: contentOffsetX,
                    unitWidth: unitWidth))
        }
    }
}
