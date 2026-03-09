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
    enum SampleAppearance {
        enum Colors {
            static let surface = Color(uiColor: .secondarySystemBackground)
            static let secondaryText = Color.secondary
            static let checklistBullet = Color.blue.opacity(0.8)
        }

        enum Typography {
            static let screenTitle = Font.headline
            static let cardTitle = Font.subheadline.weight(.semibold)
            static let bodyCaption = Font.caption
            static let valueCaption = Font.caption.monospacedDigit()
            static let statValue = Font.headline.monospaced()
            static let sectionTitle = Font.subheadline.weight(.semibold)
        }
    }

    enum Palette {
        static let liabilities = Color(red: 0.82, green: 0.35, blue: 0.42)
        static let saving = Color(red: 0.20, green: 0.52, blue: 0.68)
        static let investment = Color(red: 0.86, green: 0.43, blue: 0.16)
        static let otherLiquid = Color(red: 0.30, green: 0.67, blue: 0.14)
        static let otherNonLiquid = Color(red: 0.08, green: 0.28, blue: 0.34)
        static let trendBar = Color.gray.opacity(0.45)
        static let positiveLine = Color.red
        static let negativeLine = Color.yellow
        static let selectionLine = Color.gray
        static let selectionFill = Color.gray.opacity(0.12)
        static let zeroLine = Color.black
        static let segmentGap = Color(uiColor: .systemBackground)
    }

    enum LineTypeOption: String, CaseIterable, Identifiable {
        case linear = "Linear"
        case smoothed = "Smoothed"

        var id: Self {
            self
        }

        func makeStyle(tension: CGFloat) -> CombinedChartView.Config.Line.LineType {
            switch self {
            case .linear:
                .linear
            case .smoothed:
                .smoothed(tension: tension)
            }
        }
    }

    enum DatasetOption: String, CaseIterable, Identifiable {
        case current = "Current"
        case positiveYAxisDominant = "Positive Y Dominant"

        var id: Self {
            self
        }

        var resourceName: String {
            switch self {
            case .current:
                "SampleChartData.current"
            case .positiveYAxisDominant:
                "SampleChartData.positiveYAxisDominant"
            }
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

    static func makeGroups(
        dataset: DatasetOption = .current,
        variance: Double = 0.5) -> [CombinedChartView.DataGroup] {
        guard let decoded = ChartSampleDataLoader.loadResponse(resourceName: dataset.resourceName)
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
                        values: randomizedValues)
                })
        }
    }

    static func makeConfig(
        monthsPerPage: Int = 4,
        arrowScrollMode: CombinedChartView.Config.Pager.ArrowScrollMode = .byPage,
        dragScrollMode: CombinedChartView.Config.Pager.DragScrollMode = .freeSnapping,
        scrollImplementation: CombinedChartView.Config.Pager.ScrollImplementation = .automatic,
        chartHeight: CGFloat = 420,
        visibleStartThreshold: CGFloat = 2.0 / 3.0,
        barWidth: CGFloat = 40,
        segmentGap: CGFloat = 2,
        lineWidth: CGFloat = 1,
        lineType: CombinedChartView.Config.Line.LineType = .linear,
        selectionPointSize: CGFloat = 20,
        minimumSelectionWidth: CGFloat = 24,
        yAxisWidth: CGFloat = 40,
        zeroLineWidth: CGFloat = 1,
        gridLineWidth: CGFloat = 0.5,
        isPagerVisible: Bool = true,
        trendBarColorStyle: CombinedChartView.Config.Bar.TrendBarColorStyle = .unified(Palette.trendBar),
        selectionLineColorStyle: CombinedChartView.Config.Line
            .LineColorStrategy = .fixedLine(Palette.selectionLine),
        debugLoggingEnabled: Bool = false) -> CombinedChartView.Config {
        CombinedChartView.Config(
            monthsPerPage: monthsPerPage,
            chartHeight: chartHeight,
            bar: makeBarConfig(
                barWidth: barWidth,
                segmentGap: segmentGap,
                trendBarColorStyle: trendBarColorStyle),
            line: CombinedChartView.Config.Line(
                positiveLineColor: Palette.positiveLine,
                negativeLineColor: Palette.negativeLine,
                lineWidth: lineWidth,
                lineType: lineType,
                selection: .init(
                    pointSize: selectionPointSize,
                    selectionLineColorStrategy: selectionLineColorStyle,
                    fillColor: Palette.selectionFill,
                    minimumSelectionWidth: minimumSelectionWidth)),
            axis: CombinedChartView.Config.Axis(
                xAxisLabel: { context in
                    context.point.xLabel
                },
                yAxisLabel: { context in
                    let value = context.value
                    return value == 0 ? "0" : "\(Int(value / 1000))K"
                },
                gridLineWidth: gridLineWidth,
                zeroLineColor: Palette.zeroLine,
                zeroLineWidth: zeroLineWidth,
                yAxisWidth: yAxisWidth),
            pager: .init(
                isVisible: isPagerVisible,
                arrowScrollMode: arrowScrollMode,
                dragScrollMode: dragScrollMode,
                scrollImplementation: scrollImplementation,
                visibleStartThreshold: visibleStartThreshold),
            debug: .init(isLoggingEnabled: debugLoggingEnabled))
    }

    private static func makeBarConfig(
        barWidth: CGFloat,
        segmentGap: CGFloat,
        trendBarColorStyle: CombinedChartView.Config.Bar.TrendBarColorStyle) -> CombinedChartView.Config.Bar {
        CombinedChartView.Config.Bar(
            series: makeBarSeries(),
            trendBarColorStyle: trendBarColorStyle,
            segmentGap: segmentGap,
            segmentGapColor: Palette.segmentGap,
            barWidth: barWidth)
    }

    private static func makeBarSeries() -> [CombinedChartView.Config.Bar.SeriesStyle] {
        [
            makeSeriesStyle(
                id: ChartSeriesKey.liabilities,
                label: "Liabilities",
                color: Palette.liabilities,
                valuePolarity: .forcedSign(.negative)),
            makeSeriesStyle(
                id: ChartSeriesKey.saving,
                label: "Saving",
                color: Palette.saving),
            makeSeriesStyle(
                id: ChartSeriesKey.investment,
                label: "Investment",
                color: Palette.investment),
            makeSeriesStyle(
                id: ChartSeriesKey.otherLiquid,
                label: "Other Liquid",
                color: Palette.otherLiquid),
            makeSeriesStyle(
                id: ChartSeriesKey.otherNonLiquid,
                label: "Other Non-Liquid",
                color: Palette.otherNonLiquid)
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
}
