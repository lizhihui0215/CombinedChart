import SwiftUI

extension CombinedChartView {
    struct ChartDataPoint: Identifiable {
        let source: ChartPoint

        var id: ChartPointID {
            source.id
        }

        var xKey: String {
            source.xKey
        }

        var xLabel: String {
            source.xLabel
        }

        var values: [ChartSeriesKey: Double] {
            source.values
        }

        func signedValue(for series: ChartConfig.Bar.SeriesStyle) -> Double {
            let rawValue = values[series.id] ?? 0
            return series.signedValue(for: rawValue)
        }

        func trendLineValue(using config: ChartConfig) -> Double {
            config.bar.trendLineSeries.reduce(0) { partial, series in
                partial + signedValue(for: series)
            }
        }

        func stackedExtents(using config: ChartConfig) -> (min: Double, max: Double) {
            var positiveTotal: Double = 0
            var negativeTotal: Double = 0

            for series in config.bar.series {
                let value = signedValue(for: series)
                if value >= 0 {
                    positiveTotal += value
                } else {
                    negativeTotal += value
                }
            }

            return (negativeTotal, positiveTotal)
        }

        func axisPointInfo(index: Int) -> ChartConfig.Axis.PointInfo {
            .init(
                id: axisPointID,
                index: index,
                xKey: xKey,
                xLabel: xLabel,
                values: values)
        }

        var axisPointID: String {
            "\(id.groupID):\(id.xKey)"
        }
    }

    struct ChartDataGroup: Identifiable {
        let source: ChartGroup
        let points: [ChartDataPoint]

        var id: String {
            source.id
        }

        var displayTitle: String {
            source.displayTitle
        }

        var groupOrder: Int {
            source.groupOrder
        }

        init(source: ChartGroup) {
            self.source = source
            points = source.points.map { .init(source: $0) }
        }
    }

    struct PageRange: Identifiable {
        var id: String {
            displayTitle
        }

        let displayTitle: String
        let groupOrder: Int
        let startIndex: Int
        let endIndex: Int
        let startPage: Int
        let endPage: Int

        func contains(page: Int) -> Bool {
            page >= startPage && page <= endPage
        }
    }
}
