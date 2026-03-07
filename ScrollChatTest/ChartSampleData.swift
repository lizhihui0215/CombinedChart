//
//  ChartSampleData.swift
//  ScrollChatTest
//
//  Shared sample data/config for ContentView and Preview.
//

import SwiftUI
import UIKit

// swiftlint:disable line_length

enum ChartSampleData {
    struct Response: Decodable {
        let groups: [Group]
    }

    struct Group: Decodable {
        let id: String
        let title: String
        let sortKey: Int
        let points: [Point]
    }

    struct Point: Decodable {
        let xKey: String
        let xLabel: String
        let values: [String: Double]
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

    static func makeGroups(variance: Double = 0.5) -> [CombinedChartView<String>.ChartGroup] {
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8),
              let decoded = try? decoder.decode(Response.self, from: data)
        else {
            return []
        }

        let clampedVariance = max(0, min(variance, 0.9))

        return decoded.groups.map { group in
            CombinedChartView<String>.ChartGroup(
                id: group.id,
                title: group.title,
                sortKey: group.sortKey,
                points: group.points.map { point in
                    let randomizedValues = point.values.mapValues { value in
                        let factor = Double.random(in: (1.0 - clampedVariance)...(1.0 + clampedVariance))
                        return max(0, value * factor)
                    }
                    return CombinedChartView<String>.ChartPoint(
                        xKey: point.xKey,
                        xLabel: point.xLabel,
                        values: randomizedValues,
                        payload: point.xKey)
                })
        }
    }

    static func makeConfig() -> ChartConfig {
        ChartConfig(
            bar: makeBarConfig(),
            line: ChartConfig.ChartLineConfig(
                positiveLineColor: .red,
                negativeLineColor: .yellow,
                lineWidth: 1,
                selection: .init(
                    pointSize: 20,
                    lineColorStrategy: .fixedLine(Color.gray),
                    fillColor: Color.gray.opacity(0.12))),
            axis: ChartConfig.ChartAxisConfig(
                xAxisLabel: { context in
                    context.point.xLabel
                },
                yAxisLabel: { context in
                    let value = context.value
                    return value == 0 ? "0" : "\(Int(value / 1000))K"
                },
                zeroLineColor: .black,
                zeroLineWidth: 1))
    }

    private static func makeBarConfig() -> ChartConfig.ChartBarConfig {
        ChartConfig.ChartBarConfig(
            series: makeBarSeries(),
            totalTrendColor: Color.gray.opacity(0.45),
            useTotalTrendSingleColor: true,
            segmentGap: 2,
            segmentGapColor: Color(uiColor: .systemBackground))
    }

    private static func makeBarSeries() -> [ChartConfig.ChartBarConfig.ChartSeriesStyle] {
        [
            makeSeriesStyle(
                id: "liabilities",
                label: "Liabilities",
                color: Color(red: 0.82, green: 0.35, blue: 0.42),
                isNegative: true),
            makeSeriesStyle(
                id: "saving",
                label: "Saving",
                color: Color(red: 0.20, green: 0.52, blue: 0.68)),
            makeSeriesStyle(
                id: "investment",
                label: "Investment",
                color: Color(red: 0.86, green: 0.43, blue: 0.16)),
            makeSeriesStyle(
                id: "otherLiquid",
                label: "Other Liquid",
                color: Color(red: 0.30, green: 0.67, blue: 0.14)),
            makeSeriesStyle(
                id: "otherNonLiquid",
                label: "Other Non-Liquid",
                color: Color(red: 0.08, green: 0.28, blue: 0.34))
        ]
    }

    private static func makeSeriesStyle(
        id: String,
        label: String,
        color: Color,
        isNegative: Bool = false) -> ChartConfig.ChartBarConfig.ChartSeriesStyle {
        ChartConfig.ChartBarConfig.ChartSeriesStyle(
            id: id,
            label: label,
            color: color,
            isNegative: isNegative,
            includeInLine: true)
    }
}
