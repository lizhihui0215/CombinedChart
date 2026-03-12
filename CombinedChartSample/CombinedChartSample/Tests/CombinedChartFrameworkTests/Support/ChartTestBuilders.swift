@testable import CombinedChartFramework

enum ChartTestBuilders {
    static func makeGroup(
        id: String,
        title: String,
        order: Int,
        pointCount: Int) -> CombinedChartView.ChartDataGroup {
        makeGroup(
            id: id,
            title: title,
            order: order,
            points: (0..<pointCount).map { index in
                makeDataPoint(
                    groupID: id,
                    xKey: "\(id)-\(index)",
                    xLabel: "M\(index)",
                    values: [.saving: Double(index + 1)])
            })
    }

    static func makeGroup(
        id: String,
        title: String,
        order: Int,
        points: [CombinedChartView.ChartDataPoint]) -> CombinedChartView.ChartDataGroup {
        CombinedChartView.ChartDataGroup(
            source: .init(
                id: id,
                displayTitle: title,
                groupOrder: order,
                points: points.map(\.source)))
    }

    static func makeDataPoint(
        groupID: String,
        xKey: String,
        xLabel: String,
        values: [ChartSeriesKey: Double]) -> CombinedChartView.ChartDataPoint {
        CombinedChartView.ChartDataPoint(
            source: .init(
                id: .init(groupID: groupID, xKey: xKey),
                xKey: xKey,
                xLabel: xLabel,
                values: values))
    }
}
