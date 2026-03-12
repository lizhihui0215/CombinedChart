import SwiftUI

extension CombinedChartView {
    struct DerivedState {
        let hasData: Bool
        let axisPointInfos: [ChartConfig.Axis.PointInfo]
        let yDomain: ClosedRange<Double>
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let viewport: ViewportDerivedState

        init(
            config: ChartConfig,
            sortedGroups: [ChartDataGroup],
            data: [ChartDataPoint],
            axisPointInfos: [ChartConfig.Axis.PointInfo],
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) {
            hasData = !data.isEmpty
            self.axisPointInfos = axisPointInfos

            var minValue = Double.infinity
            var maxValue = -Double.infinity
            for point in data {
                let extents = point.stackedExtents(using: config)
                minValue = min(minValue, extents.min)
                maxValue = max(maxValue, extents.max)
            }
            if !minValue.isFinite || !maxValue.isFinite {
                minValue = -20
                maxValue = 20
            }
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
                visibleValueCount: config.visibleValueCount,
                startIndex: startIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                visibleStartThreshold: config.pager.visibleStartThreshold)
            let viewportInfo = CombinedChartView.ViewportInfo(
                dataCount: data.count,
                visibleValueCount: config.visibleValueCount,
                startIndex: startIndex,
                contentOffsetX: contentOffsetX,
                unitWidth: unitWidth,
                visibleStartThreshold: config.pager.visibleStartThreshold)

            viewport = .init(
                visibleStartIndex: viewportInfo.visibleStartIndex,
                visibleStartLabel: viewportInfo.visibleStartLabel(in: data),
                pagerState: pagerState)
        }
    }
}
