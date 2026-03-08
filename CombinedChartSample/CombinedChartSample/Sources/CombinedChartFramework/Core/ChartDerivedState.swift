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

            let pagerState = PagerState(
                sortedGroups: sortedGroups,
                dataCount: data.count,
                monthsPerPage: config.monthsPerPage,
                startIndex: startIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                visibleStartThreshold: config.pager.visibleStartThreshold)
            let visibleStartIndex = pagerState.visibleStartIndex

            viewport = .init(
                visibleStartIndex: visibleStartIndex,
                visibleStartLabel: visibleStartIndex.flatMap { index in
                    data.indices.contains(index) ? data[index].xLabel : nil
                },
                pagerState: pagerState)
        }
    }
}
