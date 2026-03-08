import SwiftUI

public enum ChartSeriesKey: String, CaseIterable, Hashable, Identifiable {
    case liabilities
    case saving
    case investment
    case otherLiquid
    case otherNonLiquid

    public var id: Self {
        self
    }
}

public struct ChartConfig {
    public let monthsPerPage: Int
    public let chartHeight: CGFloat
    public let bar: ChartBarConfig
    public let line: ChartLineConfig
    public let axis: ChartAxisConfig
    public let pager: ChartPagerConfig

    public static let `default` = ChartConfig(
        monthsPerPage: 4,
        chartHeight: 420,
        bar: ChartBarConfig(
            series: [
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: .liabilities,
                    label: "Liabilities",
                    color: Color(red: 0.82, green: 0.35, blue: 0.42),
                    valuePolarity: .forcedSign(.negative),
                    trendLineInclusion: .included),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: .saving,
                    label: "Saving",
                    color: Color(red: 0.20, green: 0.52, blue: 0.68),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: .investment,
                    label: "Investment",
                    color: Color(red: 0.86, green: 0.43, blue: 0.16),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: .otherLiquid,
                    label: "Other Liquid",
                    color: Color(red: 0.30, green: 0.67, blue: 0.14),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: .otherNonLiquid,
                    label: "Other Non-Liquid",
                    color: Color(red: 0.08, green: 0.28, blue: 0.34),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included)
            ],
            trendBarColorStyle: .seriesColor,
            segmentGap: 4,
            segmentGapColor: Color(uiColor: .systemBackground),
            barWidth: 40),
        line: ChartLineConfig(
            positiveLineColor: Color(red: 0.16, green: 0.30, blue: 0.38),
            negativeLineColor: Color(red: 0.74, green: 0.24, blue: 0.28),
            lineWidth: 2,
            selection: .init(
                pointSize: 60,
                selectionLineColorStrategy: .fixedLine(Color.gray),
                fillColor: Color.gray.opacity(0.12),
                minimumSelectionWidth: 24)),
        axis: ChartAxisConfig(
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
        pager: ChartPagerConfig())

    public init(
        monthsPerPage: Int,
        chartHeight: CGFloat,
        bar: ChartBarConfig,
        line: ChartLineConfig,
        axis: ChartAxisConfig,
        pager: ChartPagerConfig) {
        self.monthsPerPage = monthsPerPage
        self.chartHeight = chartHeight
        self.bar = bar
        self.line = line
        self.axis = axis
        self.pager = pager
    }
}

public extension ChartConfig {
    struct ChartBarConfig {
        public enum TrendBarColorStyle {
            case seriesColor
            case unified(Color)
        }

        public let series: [ChartSeriesStyle]
        public let trendBarColorStyle: TrendBarColorStyle
        public let segmentGap: CGFloat
        public let segmentGapColor: Color
        public let barWidth: CGFloat

        public init(
            series: [ChartSeriesStyle],
            trendBarColorStyle: TrendBarColorStyle,
            segmentGap: CGFloat,
            segmentGapColor: Color,
            barWidth: CGFloat) {
            self.series = series
            self.trendBarColorStyle = trendBarColorStyle
            self.segmentGap = segmentGap
            self.segmentGapColor = segmentGapColor
            self.barWidth = barWidth
        }
    }

    struct ChartLineConfig {
        public let positiveLineColor: Color
        public let negativeLineColor: Color
        public let lineWidth: CGFloat
        public let selection: SelectionConfig

        public init(
            positiveLineColor: Color,
            negativeLineColor: Color,
            lineWidth: CGFloat,
            selection: SelectionConfig) {
            self.positiveLineColor = positiveLineColor
            self.negativeLineColor = negativeLineColor
            self.lineWidth = lineWidth
            self.selection = selection
        }
    }

    struct ChartAxisConfig {
        public let xAxisLabel: (XAxisLabelContext) -> String
        public let yAxisLabel: (YAxisLabelContext) -> String
        public let zeroLineColor: Color
        public let zeroLineWidth: CGFloat
        public let yAxisWidth: CGFloat

        public init(
            xAxisLabel: @escaping (XAxisLabelContext) -> String,
            yAxisLabel: @escaping (YAxisLabelContext) -> String,
            zeroLineColor: Color,
            zeroLineWidth: CGFloat,
            yAxisWidth: CGFloat) {
            self.xAxisLabel = xAxisLabel
            self.yAxisLabel = yAxisLabel
            self.zeroLineColor = zeroLineColor
            self.zeroLineWidth = zeroLineWidth
            self.yAxisWidth = yAxisWidth
        }
    }

    struct ChartPagerConfig {
        public enum ArrowScrollMode {
            case byPage
            case byEntry
        }

        public enum DragScrollMode {
            case byPage
            case freeSnapping
            case free
        }

        public let isVisible: Bool
        public let arrowScrollMode: ArrowScrollMode
        public let dragScrollMode: DragScrollMode

        public init(
            isVisible: Bool = true,
            arrowScrollMode: ArrowScrollMode = .byPage,
            dragScrollMode: DragScrollMode = .freeSnapping) {
            self.isVisible = isVisible
            self.arrowScrollMode = arrowScrollMode
            self.dragScrollMode = dragScrollMode
        }
    }
}

public extension ChartConfig.ChartBarConfig {
    var trendLineSeries: [ChartSeriesStyle] {
        series.filter(\.contributesToTrendLine)
    }

    struct ChartSeriesStyle: Identifiable {
        public struct Appearance {
            public let label: String
            public let color: Color

            public init(label: String, color: Color) {
                self.label = label
                self.color = color
            }
        }

        public struct ValueBehavior {
            public enum TrendLineInclusion {
                case included
                case excluded
            }

            public enum Sign {
                case positive
                case negative
            }

            public enum ValuePolarity {
                case preserveSign
                case forcedSign(Sign)
            }

            public let valuePolarity: ValuePolarity
            public let trendLineInclusion: TrendLineInclusion

            public init(
                valuePolarity: ValuePolarity,
                trendLineInclusion: TrendLineInclusion) {
                self.valuePolarity = valuePolarity
                self.trendLineInclusion = trendLineInclusion
            }

            public func signedValue(for rawValue: Double) -> Double {
                switch valuePolarity {
                case .preserveSign:
                    rawValue
                case .forcedSign(.positive):
                    abs(rawValue)
                case .forcedSign(.negative):
                    -abs(rawValue)
                }
            }

            public var contributesToTrendLine: Bool {
                trendLineInclusion == .included
            }
        }

        public let id: ChartSeriesKey
        public let appearance: Appearance
        public let valueBehavior: ValueBehavior

        public init(
            id: ChartSeriesKey,
            label: String,
            color: Color,
            valuePolarity: ValueBehavior.ValuePolarity,
            trendLineInclusion: ValueBehavior.TrendLineInclusion) {
            self.id = id
            appearance = .init(label: label, color: color)
            valueBehavior = .init(
                valuePolarity: valuePolarity,
                trendLineInclusion: trendLineInclusion)
        }

        public var label: String {
            appearance.label
        }

        public var color: Color {
            appearance.color
        }

        public var valuePolarity: ValueBehavior.ValuePolarity {
            valueBehavior.valuePolarity
        }

        public var trendLineInclusion: ValueBehavior.TrendLineInclusion {
            valueBehavior.trendLineInclusion
        }

        public func signedValue(for rawValue: Double) -> Double {
            valueBehavior.signedValue(for: rawValue)
        }

        public var contributesToTrendLine: Bool {
            valueBehavior.contributesToTrendLine
        }
    }
}

public extension ChartConfig.ChartLineConfig {
    struct SelectionConfig {
        public let pointSize: CGFloat
        public let selectionLineColorStrategy: LineColorStrategy
        public let fillColor: Color
        public let minimumSelectionWidth: CGFloat

        public init(
            pointSize: CGFloat,
            selectionLineColorStrategy: LineColorStrategy,
            fillColor: Color,
            minimumSelectionWidth: CGFloat) {
            self.pointSize = pointSize
            self.selectionLineColorStrategy = selectionLineColorStrategy
            self.fillColor = fillColor
            self.minimumSelectionWidth = minimumSelectionWidth
        }
    }

    enum LineColorStrategy {
        case fixedLine(Color)
        case color(positive: Color, negative: Color)
    }
}

public extension ChartConfig.ChartAxisConfig {
    struct AxisPointInfo: Identifiable {
        public let id: String
        public let index: Int
        public let xKey: String
        public let xLabel: String
        public let values: [ChartSeriesKey: Double]

        public init(
            id: String,
            index: Int,
            xKey: String,
            xLabel: String,
            values: [ChartSeriesKey: Double]) {
            self.id = id
            self.index = index
            self.xKey = xKey
            self.xLabel = xLabel
            self.values = values
        }
    }

    struct XAxisLabelContext {
        public let point: AxisPointInfo
        public let visiblePoints: [AxisPointInfo]

        public init(point: AxisPointInfo, visiblePoints: [AxisPointInfo]) {
            self.point = point
            self.visiblePoints = visiblePoints
        }
    }

    struct YAxisLabelContext {
        public let value: Double
        public let visiblePoints: [AxisPointInfo]

        public init(value: Double, visiblePoints: [AxisPointInfo]) {
            self.value = value
            self.visiblePoints = visiblePoints
        }
    }
}
