import SwiftUI

public extension CombinedChartView {
    // Preferred consumer-facing shorthands.
    typealias Config = ChartConfig
    typealias Tab = ChartTab
    typealias DataGroup = ChartGroup
    typealias Point = ChartPoint
    typealias Slots = ViewSlots
    typealias Selection = SelectionContext

    // Specialized shorthands for advanced customization surfaces.
    typealias Mode = ChartPresentationMode
    typealias PointID = ChartPointID
    typealias PagerItem = PagerEntry
    typealias SelectionOverlay = SelectionOverlayContext

    /// A default empty-state view used when no groups are available.
    struct DefaultEmptyStateView: View {
        public init() {}

        /// The default empty-state rendering.
        public var body: some View {
            Text("No data")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// A pager item representing one selectable viewport anchor.
    struct PagerEntry: Identifiable, Hashable {
        public let id: String
        public let displayTitle: String
        public let startMonthIndex: Int

        /// Creates a pager item.
        public init(id: String, displayTitle: String, startMonthIndex: Int) {
            self.id = id
            self.displayTitle = displayTitle
            self.startMonthIndex = startMonthIndex
        }
    }

    /// Custom content slots for ``CombinedChartView``.
    ///
    /// Use slots to replace the default empty state, selection overlay, or pager UI
    /// without reimplementing the chart itself.
    ///
    /// Example:
    /// ```swift
    /// let slots = CombinedChartView.Slots(
    ///     emptyState: { Text("No chart data") },
    ///     pager: { context in Text(context.highlightedEntry?.displayTitle ?? "-") }
    /// )
    /// ```
    struct ViewSlots {
        public let emptyState: AnyView
        public let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        public let pager: ((PagerContext) -> AnyView)?

        /// The default slot configuration.
        public static var `default`: ViewSlots {
            .init()
        }

        /// Creates slots using concrete `AnyView` instances.
        public init(
            emptyState: AnyView = AnyView(DefaultEmptyStateView()),
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.emptyState = emptyState
            self.selectionOverlay = selectionOverlay
            self.pager = pager
        }

        /// Creates slots with only a custom empty state.
        public init(@ViewBuilder emptyState: () -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: nil,
                pager: nil)
        }

        /// Creates slots with custom empty state, selection overlay, and pager content.
        public init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View,
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: { context in AnyView(pager(context)) })
        }
    }

    /// Context passed to a custom selection overlay.
    struct SelectionOverlayContext {
        public let point: ChartPoint
        public let value: Double
        public let plotFrame: CGRect
        public let indicatorFrame: CGRect
        public let indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle

        /// Creates selection overlay context.
        public init(
            point: ChartPoint,
            value: Double,
            plotFrame: CGRect,
            indicatorFrame: CGRect,
            indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle) {
            self.point = point
            self.value = value
            self.plotFrame = plotFrame
            self.indicatorFrame = indicatorFrame
            self.indicatorStyle = indicatorStyle
        }
    }

    /// Context passed to a custom pager.
    struct PagerContext {
        public let entries: [PagerEntry]
        public let highlightedEntry: PagerEntry?
        public let canSelectPreviousPage: Bool
        public let canSelectNextPage: Bool
        public let onSelectPreviousPage: () -> Void
        public let onSelectEntry: (PagerEntry) -> Void
        public let onSelectNextPage: () -> Void

        /// Creates pager context.
        public init(
            entries: [PagerEntry],
            highlightedEntry: PagerEntry?,
            canSelectPreviousPage: Bool,
            canSelectNextPage: Bool,
            onSelectPreviousPage: @escaping () -> Void,
            onSelectEntry: @escaping (PagerEntry) -> Void,
            onSelectNextPage: @escaping () -> Void) {
            self.entries = entries
            self.highlightedEntry = highlightedEntry
            self.canSelectPreviousPage = canSelectPreviousPage
            self.canSelectNextPage = canSelectNextPage
            self.onSelectPreviousPage = onSelectPreviousPage
            self.onSelectEntry = onSelectEntry
            self.onSelectNextPage = onSelectNextPage
        }
    }

    /// Context passed to point selection callbacks.
    struct SelectionContext {
        public let point: ChartPoint
        public let index: Int

        /// Creates selection context.
        public init(point: ChartPoint, index: Int) {
            self.point = point
            self.index = index
        }
    }

    /// Presentation mode describing how the chart should emphasize bars, line, and selection.
    struct ChartPresentationMode: Hashable {
        /// Color strategy for bars in the current presentation mode.
        public enum BarColorStyle: Hashable {
            case seriesColors
            case unifiedTrendColor
        }

        /// Indicator style used when a point is selected.
        public enum SelectionIndicatorStyle: Hashable {
            case line
            case band
        }

        public let barColorStyle: BarColorStyle
        public let showsTrendLine: Bool
        public let selectionIndicatorStyle: SelectionIndicatorStyle
        public let showsSelectedPoint: Bool

        /// Creates a presentation mode.
        public init(
            barColorStyle: BarColorStyle,
            showsTrendLine: Bool,
            selectionIndicatorStyle: SelectionIndicatorStyle,
            showsSelectedPoint: Bool) {
            self.barColorStyle = barColorStyle
            self.showsTrendLine = showsTrendLine
            self.selectionIndicatorStyle = selectionIndicatorStyle
            self.showsSelectedPoint = showsSelectedPoint
        }

        /// A mode that emphasizes the unified trend line.
        public static var totalTrend: ChartPresentationMode {
            .init(
                barColorStyle: .unifiedTrendColor,
                showsTrendLine: true,
                selectionIndicatorStyle: .line,
                showsSelectedPoint: true)
        }

        /// A mode that emphasizes per-series bar breakdown.
        public static var breakdown: ChartPresentationMode {
            .init(
                barColorStyle: .seriesColors,
                showsTrendLine: false,
                selectionIndicatorStyle: .band,
                showsSelectedPoint: false)
        }
    }

    /// A selectable chart tab.
    struct ChartTab: Identifiable, Hashable {
        public let id: String
        public let title: String
        public let mode: ChartPresentationMode

        /// Creates a chart tab.
        public init(id: String, title: String, mode: ChartPresentationMode) {
            self.id = id
            self.title = title
            self.mode = mode
        }

        /// The built-in tab for the total trend presentation.
        public static var totalTrend: ChartTab {
            ChartTab(
                id: "totalTrend",
                title: "Total Trend",
                mode: .totalTrend)
        }

        /// The built-in tab for the breakdown presentation.
        public static var breakdown: ChartTab {
            ChartTab(
                id: "breakdown",
                title: "Breakdown",
                mode: .breakdown)
        }

        /// The default tab set used by sample and preview content.
        public static var defaults: [ChartTab] {
            [
                .totalTrend,
                .breakdown
            ]
        }
    }

    /// Stable identity for one chart point.
    struct ChartPointID: Hashable {
        public let groupID: String
        public let xKey: String

        /// Creates a chart point identifier.
        public init(groupID: String, xKey: String) {
            self.groupID = groupID
            self.xKey = xKey
        }
    }

    /// One logical chart point.
    struct ChartPoint: Identifiable {
        public let id: ChartPointID
        public let xKey: String
        public let xLabel: String
        public let values: [ChartSeriesKey: Double]

        /// Creates a chart point.
        public init(
            id: ChartPointID,
            xKey: String,
            xLabel: String,
            values: [ChartSeriesKey: Double]) {
            self.id = id
            self.xKey = xKey
            self.xLabel = xLabel
            self.values = values
        }
    }

    /// A grouped series of chart points, typically representing one year or category.
    struct ChartGroup: Identifiable {
        public let id: String
        public let displayTitle: String
        public let groupOrder: Int
        public let points: [ChartPoint]

        /// Creates a chart group.
        public init(id: String, displayTitle: String, groupOrder: Int, points: [ChartPoint]) {
            self.id = id
            self.displayTitle = displayTitle
            self.groupOrder = groupOrder
            self.points = points
        }
    }
}
