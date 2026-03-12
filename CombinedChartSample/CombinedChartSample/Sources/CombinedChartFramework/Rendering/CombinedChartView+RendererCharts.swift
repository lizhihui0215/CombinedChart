import Charts
import SwiftUI

@available(iOS 16, *)
extension CombinedChartView.Renderer {
    var chartsBarWidth: CGFloat {
        marksPresentationContext.fallbackBarWidth
    }

    @ViewBuilder
    var chartsBody: some View {
        let chart = Chart {
            barMarks()
            sharedMarks
        }
        .chartXScale(domain: axisPresentationContext.xDomain)
        .chartYScale(domain: context.yAxisDisplayDomain)
        .chartYAxis {
            chartYAxis
        }

        if #available(iOS 17, *) {
            configureChartsBody(chart)
                .chartXAxis {
                    chartXAxis(axisContext: axisPresentationContext)
                }
                .chartOverlay { proxy in
                    containerOverlay(proxy: proxy)
                }
        } else {
            chart
        }
    }

    @ChartContentBuilder
    func barMarks() -> some ChartContent {
        ForEach(marksPresentationContext.barMarks) { item in
            BarMark(
                x: .value("X Index", item.xValue),
                yStart: .value("Start", item.start),
                yEnd: .value("End", item.end),
                width: .fixed(item.width))
                .foregroundStyle(item.color)
        }
    }

    @ChartContentBuilder
    var sharedMarks: some ChartContent {
        ForEach(marksPresentationContext.ruleMarks) { ruleMark in
            RuleMark(y: .value("Rule", ruleMark.value))
                .foregroundStyle(ruleMark.color)
                .lineStyle(StrokeStyle(lineWidth: ruleMark.lineWidth))
        }

        ForEach(marksPresentationContext.pointMarks) { pointMark in
            PointMark(
                x: .value("X Index", pointMark.xValue),
                y: .value("Value", pointMark.value))
                .foregroundStyle(pointMark.color)
                .symbolSize(pointMark.symbolSize)
        }
    }

    @available(iOS 17, *)
    @ViewBuilder
    private func configureChartsBody(_ chart: some View) -> some View {
        let visibleDomainLength = Double(max(context.config.visibleValueCount, 1))

        if let chartsScrollPosition,
           axisPresentationContext.dataCount > max(context.config.visibleValueCount, 1) {
            let scrollableChart = chart
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleDomainLength)
                .chartScrollPosition(x: chartsScrollPosition)
                .chartGesture { proxy in
                    chartsTapGesture(proxy: proxy)
                }

            switch context.config.pager.scrollTargetBehavior {
            case .byPage:
                scrollableChart.chartScrollTargetBehavior(
                    .valueAligned(unit: 1.0, majorAlignment: .page))
            case .freeSnapping:
                scrollableChart.chartScrollTargetBehavior(
                    .valueAligned(unit: 1.0))
            case .free:
                scrollableChart
            }
        } else {
            chart
                .chartGesture { proxy in
                    chartsTapGesture(proxy: proxy)
                }
        }
    }

    @available(iOS 17, *)
    private func chartsTapGesture(proxy: ChartProxy) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                if let domainXValue = proxy.value(atX: value.location.x, as: Double.self),
                   let resolvedIndex = CombinedChartView.SelectionResolver.resolvedIndex(
                       forDomainXValue: domainXValue,
                       dataCount: context.visibleData.count) {
                    onSelectIndex(resolvedIndex)
                    return
                }

                let xPositions = CombinedChartView.XPositionResolver.descriptors(.init(
                    dataCount: context.visibleData.count,
                    xPosition: { index in
                        proxy.position(forX: Double(index))
                    }))
                let fallbackIndex = CombinedChartView.SelectionHitResolver.resolveIndex(
                    at: value.location,
                    request: .init(
                        dataCount: context.visibleData.count,
                        minimumHitWidth: context.config.line.selection.minimumSelectionWidth,
                        fallbackWidth: chartsBarWidth,
                        xPositions: xPositions))
                onSelectIndex(fallbackIndex)
            }
    }
}
