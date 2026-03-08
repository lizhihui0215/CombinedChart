import SwiftUI

public extension CombinedChartView {
    typealias Config = ChartConfig
    typealias Mode = ChartPresentationMode
    typealias Tab = ChartTab
    typealias DataGroup = ChartGroup
    typealias Point = ChartPoint
    typealias PointID = ChartPointID
    typealias Slots = ViewSlots
    typealias PagerItem = PagerEntry
    typealias Selection = SelectionContext
    typealias SelectionOverlay = SelectionOverlayContext

    struct DefaultEmptyStateView: View {
        public init() {}

        public var body: some View {
            Text("No data")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct PagerEntry: Identifiable, Hashable {
        public let id: String
        public let displayTitle: String
        public let startMonthIndex: Int

        public init(id: String, displayTitle: String, startMonthIndex: Int) {
            self.id = id
            self.displayTitle = displayTitle
            self.startMonthIndex = startMonthIndex
        }
    }

    struct ViewSlots {
        public let emptyState: AnyView
        public let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        public let pager: ((PagerContext) -> AnyView)?

        public static var `default`: ViewSlots {
            .init()
        }

        public init(
            emptyState: AnyView = AnyView(DefaultEmptyStateView()),
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.emptyState = emptyState
            self.selectionOverlay = selectionOverlay
            self.pager = pager
        }

        public init(
            @ViewBuilder emptyState: () -> some View,
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: selectionOverlay,
                pager: pager)
        }

        public init(@ViewBuilder emptyState: () -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: nil,
                pager: nil)
        }

        public init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View,
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: { context in AnyView(pager(context)) })
        }

        public init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: nil)
        }

        public init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: nil,
                pager: { context in AnyView(pager(context)) })
        }
    }

    struct SelectionOverlayContext {
        public let point: ChartPoint
        public let value: Double
        public let plotFrame: CGRect
        public let indicatorFrame: CGRect
        public let indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle

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

    struct PagerContext {
        public let entries: [PagerEntry]
        public let highlightedEntry: PagerEntry?
        public let canSelectPreviousPage: Bool
        public let canSelectNextPage: Bool
        public let onSelectPreviousPage: () -> Void
        public let onSelectEntry: (PagerEntry) -> Void
        public let onSelectNextPage: () -> Void

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

    struct SelectionContext {
        public let point: ChartPoint
        public let index: Int

        public init(point: ChartPoint, index: Int) {
            self.point = point
            self.index = index
        }
    }

    struct ChartPresentationMode: Hashable {
        public enum BarColorStyle: Hashable {
            case seriesColors
            case unifiedTrendColor
        }

        public enum SelectionIndicatorStyle: Hashable {
            case line
            case band
        }

        public let barColorStyle: BarColorStyle
        public let showsTrendLine: Bool
        public let selectionIndicatorStyle: SelectionIndicatorStyle
        public let showsSelectedPoint: Bool

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

        public static var totalTrend: ChartPresentationMode {
            .init(
                barColorStyle: .unifiedTrendColor,
                showsTrendLine: true,
                selectionIndicatorStyle: .line,
                showsSelectedPoint: true)
        }

        public static var breakdown: ChartPresentationMode {
            .init(
                barColorStyle: .seriesColors,
                showsTrendLine: false,
                selectionIndicatorStyle: .band,
                showsSelectedPoint: false)
        }
    }

    struct ChartTab: Identifiable, Hashable {
        public let id: String
        public let title: String
        public let mode: ChartPresentationMode

        public init(id: String, title: String, mode: ChartPresentationMode) {
            self.id = id
            self.title = title
            self.mode = mode
        }

        public static var totalTrend: ChartTab {
            ChartTab(
                id: "totalTrend",
                title: "Total Trend",
                mode: .totalTrend)
        }

        public static var breakdown: ChartTab {
            ChartTab(
                id: "breakdown",
                title: "Breakdown",
                mode: .breakdown)
        }

        public static var defaults: [ChartTab] {
            [
                .totalTrend,
                .breakdown
            ]
        }
    }

    struct ChartPointID: Hashable {
        public let groupID: String
        public let xKey: String

        public init(groupID: String, xKey: String) {
            self.groupID = groupID
            self.xKey = xKey
        }
    }

    struct ChartPoint: Identifiable {
        public let id: ChartPointID
        public let xKey: String
        public let xLabel: String
        public let values: [ChartSeriesKey: Double]

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

    struct ChartGroup: Identifiable {
        public let id: String
        public let displayTitle: String
        public let groupOrder: Int
        public let points: [ChartPoint]

        public init(id: String, displayTitle: String, groupOrder: Int, points: [ChartPoint]) {
            self.id = id
            self.displayTitle = displayTitle
            self.groupOrder = groupOrder
            self.points = points
        }
    }
}
