//
//  ChartSampleData.swift
//  ScrollChatTest
//
//  Shared sample data/config for ContentView and Preview.
//

import CombinedChartFramework
import SwiftUI
import UIKit

// swiftlint:disable line_length

enum ChartSampleData {
    enum DatasetOption: String, CaseIterable, Identifiable {
        case current = "Current"
        case positiveDominant = "Positive Dominant"

        var id: Self {
            self
        }
    }

    struct Response: Decodable {
        let groups: [Group]
    }

    struct Group: Decodable {
        let id: String
        let displayTitle: String
        let groupOrder: Int
        let points: [Point]

        enum CodingKeys: String, CodingKey {
            case id
            case displayTitle = "title"
            case groupOrder = "sortKey"
            case points
        }
    }

    struct Point: Decodable {
        let xKey: String
        let xLabel: String
        let values: [ChartSeriesKey: Double]

        enum CodingKeys: String, CodingKey {
            case xKey
            case xLabel
            case values
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            xKey = try container.decode(String.self, forKey: .xKey)
            xLabel = try container.decode(String.self, forKey: .xLabel)

            let rawValues = try container.decode([String: Double].self, forKey: .values)
            values = rawValues.reduce(into: [:]) { partial, entry in
                guard let key = ChartSeriesKey(rawValue: entry.key) else { return }
                partial[key] = entry.value
            }
        }
    }

    static let json: String = """
    {
        "groups": [
            {
                "id": "2020",
                "title": "2020",
                "sortKey": 2020,
                "points": [
                    {"xKey": "2020-01", "xLabel": "2020-01", "values": {"saving": 5000, "investment": 10000, "otherLiquid": 2000, "otherNonLiquid": 3000, "liabilities": 15000}},
                    {"xKey": "2020-02", "xLabel": "2020-02", "values": {"saving": 5200, "investment": 9800, "otherLiquid": 2100, "otherNonLiquid": 3100, "liabilities": 14800}},
                    {"xKey": "2020-03", "xLabel": "2020-03", "values": {"saving": 5100, "investment": 10300, "otherLiquid": 2050, "otherNonLiquid": 3200, "liabilities": 14950}},
                    {"xKey": "2020-04", "xLabel": "2020-04", "values": {"saving": 5300, "investment": 10100, "otherLiquid": 2150, "otherNonLiquid": 3300, "liabilities": 15100}},
                    {"xKey": "2020-05", "xLabel": "2020-05", "values": {"saving": 5400, "investment": 10400, "otherLiquid": 2200, "otherNonLiquid": 3350, "liabilities": 15200}},
                    {"xKey": "2020-06", "xLabel": "2020-06", "values": {"saving": 5500, "investment": 10600, "otherLiquid": 2250, "otherNonLiquid": 3400, "liabilities": 15300}},
                    {"xKey": "2020-07", "xLabel": "2020-07", "values": {"saving": 5600, "investment": 10700, "otherLiquid": 2300, "otherNonLiquid": 3450, "liabilities": 15400}},
                    {"xKey": "2020-08", "xLabel": "2020-08", "values": {"saving": 5700, "investment": 10800, "otherLiquid": 2350, "otherNonLiquid": 3500, "liabilities": 15500}},
                    {"xKey": "2020-09", "xLabel": "2020-09", "values": {"saving": 5800, "investment": 11000, "otherLiquid": 2400, "otherNonLiquid": 3550, "liabilities": 15600}},
                    {"xKey": "2020-10", "xLabel": "2020-10", "values": {"saving": 5900, "investment": 11100, "otherLiquid": 2450, "otherNonLiquid": 3600, "liabilities": 15700}},
                    {"xKey": "2020-11", "xLabel": "2020-11", "values": {"saving": 6000, "investment": 11200, "otherLiquid": 2500, "otherNonLiquid": 3650, "liabilities": 15800}},
                    {"xKey": "2020-12", "xLabel": "2020-12", "values": {"saving": 6100, "investment": 11300, "otherLiquid": 2550, "otherNonLiquid": 3700, "liabilities": 15900}}
                ]
            },
            {
                "id": "2021",
                "title": "2021",
                "sortKey": 2021,
                "points": [
                    {"xKey": "2021-01", "xLabel": "2021-01", "values": {"saving": 6200, "investment": 11400, "otherLiquid": 2600, "otherNonLiquid": 3750, "liabilities": 16000}},
                    {"xKey": "2021-02", "xLabel": "2021-02", "values": {"saving": 6300, "investment": 11500, "otherLiquid": 2650, "otherNonLiquid": 3800, "liabilities": 16100}},
                    {"xKey": "2021-03", "xLabel": "2021-03", "values": {"saving": 6400, "investment": 11600, "otherLiquid": 2700, "otherNonLiquid": 3850, "liabilities": 16200}},
                    {"xKey": "2021-04", "xLabel": "2021-04", "values": {"saving": 6500, "investment": 11700, "otherLiquid": 2750, "otherNonLiquid": 3900, "liabilities": 16300}},
                    {"xKey": "2021-05", "xLabel": "2021-05", "values": {"saving": 6600, "investment": 11800, "otherLiquid": 2800, "otherNonLiquid": 3950, "liabilities": 16400}},
                    {"xKey": "2021-06", "xLabel": "2021-06", "values": {"saving": 6700, "investment": 11900, "otherLiquid": 2850, "otherNonLiquid": 4000, "liabilities": 16500}},
                    {"xKey": "2021-07", "xLabel": "2021-07", "values": {"saving": 6800, "investment": 12000, "otherLiquid": 2900, "otherNonLiquid": 4050, "liabilities": 16600}},
                    {"xKey": "2021-08", "xLabel": "2021-08", "values": {"saving": 6900, "investment": 12100, "otherLiquid": 2950, "otherNonLiquid": 4100, "liabilities": 16700}},
                    {"xKey": "2021-09", "xLabel": "2021-09", "values": {"saving": 7000, "investment": 12200, "otherLiquid": 3000, "otherNonLiquid": 4150, "liabilities": 16800}},
                    {"xKey": "2021-10", "xLabel": "2021-10", "values": {"saving": 7100, "investment": 12300, "otherLiquid": 3050, "otherNonLiquid": 4200, "liabilities": 16900}},
                    {"xKey": "2021-11", "xLabel": "2021-11", "values": {"saving": 7200, "investment": 12400, "otherLiquid": 3100, "otherNonLiquid": 4250, "liabilities": 17000}},
                    {"xKey": "2021-12", "xLabel": "2021-12", "values": {"saving": 7300, "investment": 12500, "otherLiquid": 3150, "otherNonLiquid": 4300, "liabilities": 17100}}
                ]
            }
        ]
    }
    """

    static func makeGroups(
        dataset: DatasetOption = .current,
        variance: Double = 0.5) -> [CombinedChartView.DataGroup] {
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8),
              let decoded = try? decoder.decode(Response.self, from: data)
        else {
            return []
        }

        let clampedVariance = max(0, min(variance, 0.9))

        return decoded.groups.map { group in
            CombinedChartView.DataGroup(
                id: group.id,
                displayTitle: group.displayTitle,
                groupOrder: group.groupOrder,
                points: group.points.map { point in
                    let randomizedValues = point.values.reduce(into: [ChartSeriesKey: Double]()) { partial, entry in
                        let factor = stableVarianceFactor(
                            groupID: group.id,
                            xKey: point.xKey,
                            seriesKey: entry.key,
                            variance: clampedVariance)
                        partial[entry.key] = max(0, entry.value * factor)
                    }
                    return CombinedChartView.Point(
                        id: .init(groupID: group.id, xKey: point.xKey),
                        xKey: point.xKey,
                        xLabel: point.xLabel,
                        values: adjustedValues(
                            for: dataset,
                            values: randomizedValues))
                })
        }
    }

    static func makeConfig(
        dragScrollMode: CombinedChartView.Config.Pager.DragScrollMode = .freeSnapping,
        chartHeight: CGFloat = 420,
        visibleStartThreshold: CGFloat = 2.0 / 3.0,
        barWidth: CGFloat = 40) -> CombinedChartView.Config {
        CombinedChartView.Config(
            monthsPerPage: 4,
            chartHeight: chartHeight,
            bar: makeBarConfig(barWidth: barWidth),
            line: CombinedChartView.Config.Line(
                positiveLineColor: .red,
                negativeLineColor: .yellow,
                lineWidth: 1,
                selection: .init(
                    pointSize: 20,
                    selectionLineColorStrategy: .fixedLine(Color.gray),
                    fillColor: Color.gray.opacity(0.12),
                    minimumSelectionWidth: 24)),
            axis: CombinedChartView.Config.Axis(
                xAxisLabel: { context in
                    context.point.xLabel
                },
                yAxisLabel: { context in
                    let value = context.value
                    return value == 0 ? "0" : "\(Int(value / 1000))K"
                },
                zeroLineColor: .black,
                zeroLineWidth: 1,
                yAxisWidth: 40),
            pager: .init(
                isVisible: true,
                dragScrollMode: dragScrollMode,
                visibleStartThreshold: visibleStartThreshold))
    }

    private static func makeBarConfig(barWidth: CGFloat) -> CombinedChartView.Config.Bar {
        CombinedChartView.Config.Bar(
            series: makeBarSeries(),
            trendBarColorStyle: .unified(Color.gray.opacity(0.45)),
            segmentGap: 2,
            segmentGapColor: Color(uiColor: .systemBackground),
            barWidth: barWidth)
    }

    private static func makeBarSeries() -> [CombinedChartView.Config.Bar.SeriesStyle] {
        [
            makeSeriesStyle(
                id: ChartSeriesKey.liabilities,
                label: "Liabilities",
                color: Color(red: 0.82, green: 0.35, blue: 0.42),
                valuePolarity: .forcedSign(.negative)),
            makeSeriesStyle(
                id: ChartSeriesKey.saving,
                label: "Saving",
                color: Color(red: 0.20, green: 0.52, blue: 0.68)),
            makeSeriesStyle(
                id: ChartSeriesKey.investment,
                label: "Investment",
                color: Color(red: 0.86, green: 0.43, blue: 0.16)),
            makeSeriesStyle(
                id: ChartSeriesKey.otherLiquid,
                label: "Other Liquid",
                color: Color(red: 0.30, green: 0.67, blue: 0.14)),
            makeSeriesStyle(
                id: ChartSeriesKey.otherNonLiquid,
                label: "Other Non-Liquid",
                color: Color(red: 0.08, green: 0.28, blue: 0.34))
        ]
    }

    private static func makeSeriesStyle(
        id: ChartSeriesKey,
        label: String,
        color: Color,
        valuePolarity: CombinedChartView.Config.Bar.SeriesStyle.ValueBehavior
            .ValuePolarity = .preserveSign) -> CombinedChartView.Config
                .Bar.SeriesStyle {
        CombinedChartView.Config.Bar.SeriesStyle(
            id: id,
            label: label,
            color: color,
            valuePolarity: valuePolarity,
            trendLineInclusion: .included)
    }

    private static func stableVarianceFactor(
        groupID: String,
        xKey: String,
        seriesKey: ChartSeriesKey,
        variance: Double) -> Double {
        guard variance > 0 else { return 1 }

        let identifier = "\(groupID)|\(xKey)|\(seriesKey.rawValue)"
        let hash = identifier.utf8.reduce(UInt64(1_469_598_103_934_665_603)) { partial, byte in
            (partial ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let normalized = Double(hash % 10000) / 9999
        let lowerBound = 1.0 - variance
        let upperBound = 1.0 + variance
        return lowerBound + ((upperBound - lowerBound) * normalized)
    }

    private static func adjustedValues(
        for dataset: DatasetOption,
        values: [ChartSeriesKey: Double]) -> [ChartSeriesKey: Double] {
        switch dataset {
        case .current:
            return values
        case .positiveDominant:
            var adjusted = values
            adjusted[.saving] = (values[.saving] ?? 0) * 1.8
            adjusted[.investment] = (values[.investment] ?? 0) * 2.2
            adjusted[.otherLiquid] = (values[.otherLiquid] ?? 0) * 1.9
            adjusted[.otherNonLiquid] = (values[.otherNonLiquid] ?? 0) * 1.7
            adjusted[.liabilities] = (values[.liabilities] ?? 0) * 0.22
            return adjusted
        }
    }
}
