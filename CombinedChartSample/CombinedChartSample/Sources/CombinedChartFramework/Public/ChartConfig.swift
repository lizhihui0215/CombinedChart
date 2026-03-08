import SwiftUI

/// Stable identifiers for series rendered by the chart.
///
/// Use these keys to provide values for each ``ChartConfig/Bar/SeriesStyle`` and to map
/// incoming business data into ``CombinedChartView/Point`` values.
public enum ChartSeriesKey: String, CaseIterable, Hashable, Identifiable {
    case liabilities
    case saving
    case investment
    case otherLiquid
    case otherNonLiquid

    /// The stable identity of the series key.
    public var id: Self {
        self
    }
}

/// Configuration for rendering and interacting with ``CombinedChartView``.
///
/// ``ChartConfig`` groups the major configuration domains of the chart:
///
/// - bar styling
/// - line styling
/// - axis formatting
/// - pager behavior
///
/// The configuration is value-based, so you can construct variants for previews,
/// tests, and runtime feature flags without relying on mutable shared state.
///
/// Example:
/// ```swift
/// let config = CombinedChartView.Config(
///     monthsPerPage: 4,
///     chartHeight: 420,
///     bar: .init(...),
///     line: .init(...),
///     axis: .init(...),
///     pager: .init()
/// )
/// ```
public struct ChartConfig {
    public let monthsPerPage: Int
    public let chartHeight: CGFloat
    public let bar: Bar
    public let line: Line
    public let axis: Axis
    public let pager: Pager

    /// A ready-to-use configuration tuned for the sample combined chart experience.
    public static let `default` = ChartConfig(
        monthsPerPage: 4,
        chartHeight: 420,
        bar: Bar(
            series: [
                ChartConfig.Bar.SeriesStyle(
                    id: .liabilities,
                    label: "Liabilities",
                    color: Color(red: 0.82, green: 0.35, blue: 0.42),
                    valuePolarity: .forcedSign(.negative),
                    trendLineInclusion: .included),
                ChartConfig.Bar.SeriesStyle(
                    id: .saving,
                    label: "Saving",
                    color: Color(red: 0.20, green: 0.52, blue: 0.68),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.Bar.SeriesStyle(
                    id: .investment,
                    label: "Investment",
                    color: Color(red: 0.86, green: 0.43, blue: 0.16),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.Bar.SeriesStyle(
                    id: .otherLiquid,
                    label: "Other Liquid",
                    color: Color(red: 0.30, green: 0.67, blue: 0.14),
                    valuePolarity: .forcedSign(.positive),
                    trendLineInclusion: .included),
                ChartConfig.Bar.SeriesStyle(
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
        line: Line(
            positiveLineColor: Color(red: 0.16, green: 0.30, blue: 0.38),
            negativeLineColor: Color(red: 0.74, green: 0.24, blue: 0.28),
            lineWidth: 2,
            selection: .init(
                pointSize: 60,
                selectionLineColorStrategy: .fixedLine(Color.gray),
                fillColor: Color.gray.opacity(0.12),
                minimumSelectionWidth: 24)),
        axis: Axis(
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
        pager: Pager())

    /// Creates a chart configuration.
    ///
    /// - Parameters:
    ///   - monthsPerPage: The number of x-axis points visible in one page-sized viewport.
    ///   - chartHeight: The overall height of the composed chart view.
    ///   - bar: Configuration for the stacked or grouped bar marks.
    ///   - line: Configuration for the trend line and selection appearance.
    ///   - axis: Configuration for axis formatting and zero-line rendering.
    ///   - pager: Configuration for pager visibility and scrolling behavior.
    public init(
        monthsPerPage: Int,
        chartHeight: CGFloat,
        bar: Bar,
        line: Line,
        axis: Axis,
        pager: Pager) {
        self.monthsPerPage = monthsPerPage
        self.chartHeight = chartHeight
        self.bar = bar
        self.line = line
        self.axis = axis
        self.pager = pager
    }
}

public extension ChartConfig {
    /// Configuration for bar rendering.
    struct Bar {
        /// Strategy used to color bars in modes that expose trend context.
        public enum TrendBarColorStyle {
            case seriesColor
            case unified(Color)
        }

        public let series: [SeriesStyle]
        public let trendBarColorStyle: TrendBarColorStyle
        public let segmentGap: CGFloat
        public let segmentGapColor: Color
        public let barWidth: CGFloat

        /// Creates bar configuration.
        ///
        /// - Parameters:
        ///   - series: Series definitions used to render the bar stacks.
        ///   - trendBarColorStyle: Color strategy for trend-context rendering.
        ///   - segmentGap: Visual spacing between stacked segments.
        ///   - segmentGapColor: Fill color used for the segment gap.
        ///   - barWidth: Width of each bar.
        public init(
            series: [SeriesStyle],
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

    /// Configuration for trend line rendering and line-based selection styling.
    struct Line {
        public let positiveLineColor: Color
        public let negativeLineColor: Color
        public let lineWidth: CGFloat
        public let selection: Selection

        /// Creates line configuration.
        public init(
            positiveLineColor: Color,
            negativeLineColor: Color,
            lineWidth: CGFloat,
            selection: Selection) {
            self.positiveLineColor = positiveLineColor
            self.negativeLineColor = negativeLineColor
            self.lineWidth = lineWidth
            self.selection = selection
        }
    }

    /// Configuration for axis labels and zero-line rendering.
    struct Axis {
        public let xAxisLabel: (XLabelContext) -> String
        public let yAxisLabel: (YLabelContext) -> String
        public let zeroLineColor: Color
        public let zeroLineWidth: CGFloat
        public let yAxisWidth: CGFloat

        /// Creates axis configuration.
        ///
        /// - Parameters:
        ///   - xAxisLabel: Formats labels for visible x-axis points.
        ///   - yAxisLabel: Formats labels for visible y-axis values.
        ///   - zeroLineColor: The color of the zero-value reference line.
        ///   - zeroLineWidth: The width of the zero-value reference line.
        ///   - yAxisWidth: Reserved width for the y-axis label column.
        public init(
            xAxisLabel: @escaping (XLabelContext) -> String,
            yAxisLabel: @escaping (YLabelContext) -> String,
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

    /// Configuration for pager visibility and navigation behavior.
    struct Pager {
        /// Describes how pager arrows advance through the dataset.
        public enum ArrowScrollMode {
            case byPage
            case byEntry
        }

        /// Describes how drag gestures settle the viewport.
        public enum DragScrollMode {
            case byPage
            case freeSnapping
            case free
        }

        public let isVisible: Bool
        public let arrowScrollMode: ArrowScrollMode
        public let dragScrollMode: DragScrollMode
        /// The scroll progress required before the next x-axis unit becomes the visible start.
        ///
        /// Use a value between `0` and `1`:
        ///
        /// - `0`: switch to the next unit as soon as scrolling begins
        /// - `1`: wait until the current unit has been fully scrolled past
        ///
        /// The default value `2 / 3` switches once roughly two thirds of the leading unit has
        /// been scrolled past.
        public let visibleStartThreshold: CGFloat

        /// Creates pager configuration.
        ///
        /// - Parameters:
        ///   - isVisible: A Boolean value that determines whether the pager is shown.
        ///   - arrowScrollMode: The navigation behavior used for pager arrows.
        ///   - dragScrollMode: The settling behavior used for drag gestures.
        ///   - visibleStartThreshold: The proportion of the leading x-axis unit that must be scrolled
        ///     past before the next unit becomes the visible start. Values are clamped to `0...1`.
        public init(
            isVisible: Bool = true,
            arrowScrollMode: ArrowScrollMode = .byPage,
            dragScrollMode: DragScrollMode = .freeSnapping,
            visibleStartThreshold: CGFloat = 2.0 / 3.0) {
            self.isVisible = isVisible
            self.arrowScrollMode = arrowScrollMode
            self.dragScrollMode = dragScrollMode
            self.visibleStartThreshold = min(max(visibleStartThreshold, 0), 1)
        }
    }
}

public extension ChartConfig.Bar {
    /// Series that currently contribute to the derived trend line.
    var trendLineSeries: [SeriesStyle] {
        series.filter(\.contributesToTrendLine)
    }

    /// Styling and semantic behavior for one bar series.
    struct SeriesStyle: Identifiable {
        /// Visual styling for a series.
        public struct Appearance {
            public let label: String
            public let color: Color

            public init(label: String, color: Color) {
                self.label = label
                self.color = color
            }
        }

        /// Value semantics for a series.
        public struct ValueBehavior {
            /// How incoming values should be interpreted before rendering.
            public enum ValuePolarity {
                case preserveSign
                case forcedSign(Sign)
            }

            public let valuePolarity: ValuePolarity
            public let trendLineInclusion: TrendLineInclusion

            /// Creates value behavior for a series.
            public init(
                valuePolarity: ValuePolarity,
                trendLineInclusion: TrendLineInclusion) {
                self.valuePolarity = valuePolarity
                self.trendLineInclusion = trendLineInclusion
            }

            /// Returns the value after sign normalization.
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

            /// Indicates whether this series should be included in the derived trend line.
            public var contributesToTrendLine: Bool {
                trendLineInclusion == .included
            }
        }

        public let id: ChartSeriesKey
        public let appearance: Appearance
        public let valueBehavior: ValueBehavior

        /// Creates a series style.
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

        /// The label shown for the series in legends or custom UI.
        public var label: String {
            appearance.label
        }

        /// The primary color used to render the series.
        public var color: Color {
            appearance.color
        }

        /// The configured value polarity strategy.
        public var valuePolarity: ValueBehavior.ValuePolarity {
            valueBehavior.valuePolarity
        }

        /// Whether this series contributes to the derived trend line.
        public var trendLineInclusion: ValueBehavior.TrendLineInclusion {
            valueBehavior.trendLineInclusion
        }

        /// Returns the series value after applying configured sign behavior.
        public func signedValue(for rawValue: Double) -> Double {
            valueBehavior.signedValue(for: rawValue)
        }

        /// Indicates whether the series participates in trend line derivation.
        public var contributesToTrendLine: Bool {
            valueBehavior.contributesToTrendLine
        }
    }
}

public extension ChartConfig.Bar.SeriesStyle.ValueBehavior {
    /// Whether the series contributes to the derived trend line.
    enum TrendLineInclusion {
        case included
        case excluded
    }

    /// A forced sign used when remapping incoming values.
    enum Sign {
        case positive
        case negative
    }
}

public extension ChartConfig.Line {
    /// Styling for line-based selection affordances.
    struct Selection {
        public let pointSize: CGFloat
        public let selectionLineColorStrategy: LineColorStrategy
        public let fillColor: Color
        public let minimumSelectionWidth: CGFloat

        /// Creates selection styling for the line layer.
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

    /// Strategy used to determine the selection line color.
    enum LineColorStrategy {
        case fixedLine(Color)
        case color(positive: Color, negative: Color)
    }
}

public extension ChartConfig.Axis {
    /// A visible point projected into the axis formatting domain.
    struct PointInfo: Identifiable {
        public let id: String
        public let index: Int
        public let xKey: String
        public let xLabel: String
        public let values: [ChartSeriesKey: Double]

        /// Creates an axis point descriptor.
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

    /// Context passed to the x-axis label formatter.
    struct XLabelContext {
        public let point: PointInfo
        public let visiblePoints: [PointInfo]

        /// Creates x-axis label context.
        public init(point: PointInfo, visiblePoints: [PointInfo]) {
            self.point = point
            self.visiblePoints = visiblePoints
        }
    }

    /// Context passed to the y-axis label formatter.
    struct YLabelContext {
        public let value: Double
        public let visiblePoints: [PointInfo]

        /// Creates y-axis label context.
        public init(value: Double, visiblePoints: [PointInfo]) {
            self.value = value
            self.visiblePoints = visiblePoints
        }
    }
}
