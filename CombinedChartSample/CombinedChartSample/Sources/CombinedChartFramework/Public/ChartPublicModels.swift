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

    /// Realtime debug state emitted by the chart while rendering and dragging.
    struct DebugState: Equatable {
        public let selectedTabTitle: String
        public let scrollEngineTitle: String
        public let scrollTargetBehaviorTitle: String
        public let isDragging: Bool
        public let isDecelerating: Bool
        public let startIndex: Int
        public let visibleStartIndex: Int?
        public let visibleStartLabel: String?
        public let visibleStartThreshold: CGFloat
        public let contentOffsetX: CGFloat
        public let dragTranslationX: CGFloat
        public let targetContentOffsetX: CGFloat
        public let targetIndex: Int
        public let viewportWidth: CGFloat
        public let unitWidth: CGFloat
        public let chartWidth: CGFloat
        public let selectedPointIndex: Int?
        public let selectedPointGroupID: String?
        public let selectedPointXKey: String?
        public let selectedPointXLabel: String?
        public let selectedPointValue: Double?

        public init(
            selectedTabTitle: String,
            scrollEngineTitle: String,
            scrollTargetBehaviorTitle: String,
            isDragging: Bool,
            isDecelerating: Bool,
            startIndex: Int,
            visibleStartIndex: Int?,
            visibleStartLabel: String?,
            visibleStartThreshold: CGFloat,
            contentOffsetX: CGFloat,
            dragTranslationX: CGFloat,
            targetContentOffsetX: CGFloat,
            targetIndex: Int,
            viewportWidth: CGFloat,
            unitWidth: CGFloat,
            chartWidth: CGFloat,
            selectedPointIndex: Int?,
            selectedPointGroupID: String?,
            selectedPointXKey: String?,
            selectedPointXLabel: String?,
            selectedPointValue: Double?) {
            self.selectedTabTitle = selectedTabTitle
            self.scrollEngineTitle = scrollEngineTitle
            self.scrollTargetBehaviorTitle = scrollTargetBehaviorTitle
            self.isDragging = isDragging
            self.isDecelerating = isDecelerating
            self.startIndex = startIndex
            self.visibleStartIndex = visibleStartIndex
            self.visibleStartLabel = visibleStartLabel
            self.visibleStartThreshold = visibleStartThreshold
            self.contentOffsetX = contentOffsetX
            self.dragTranslationX = dragTranslationX
            self.targetContentOffsetX = targetContentOffsetX
            self.targetIndex = targetIndex
            self.viewportWidth = viewportWidth
            self.unitWidth = unitWidth
            self.chartWidth = chartWidth
            self.selectedPointIndex = selectedPointIndex
            self.selectedPointGroupID = selectedPointGroupID
            self.selectedPointXKey = selectedPointXKey
            self.selectedPointXLabel = selectedPointXLabel
            self.selectedPointValue = selectedPointValue
        }

        /// Legacy initializer that preserves the older month- and implementation-based labels.
        @available(*, deprecated, renamed: "init(selectedTabTitle:scrollEngineTitle:scrollTargetBehaviorTitle:isDragging:isDecelerating:startIndex:visibleStartIndex:visibleStartLabel:visibleStartThreshold:contentOffsetX:dragTranslationX:targetContentOffsetX:targetIndex:viewportWidth:unitWidth:chartWidth:selectedPointIndex:selectedPointGroupID:selectedPointXKey:selectedPointXLabel:selectedPointValue:)")
        public init(
            selectedTabTitle: String,
            scrollImplementationTitle: String,
            dragScrollModeTitle: String,
            isDragging: Bool,
            isDecelerating: Bool,
            startIndex: Int,
            visibleStartIndex: Int?,
            visibleStartLabel: String?,
            visibleStartThreshold: CGFloat,
            contentOffsetX: CGFloat,
            dragTranslationX: CGFloat,
            targetContentOffsetX: CGFloat,
            targetMonthIndex: Int,
            viewportWidth: CGFloat,
            unitWidth: CGFloat,
            chartWidth: CGFloat,
            selectedPointIndex: Int?,
            selectedPointGroupID: String?,
            selectedPointXKey: String?,
            selectedPointXLabel: String?,
            selectedPointValue: Double?) {
            self.init(
                selectedTabTitle: selectedTabTitle,
                scrollEngineTitle: scrollImplementationTitle,
                scrollTargetBehaviorTitle: dragScrollModeTitle,
                isDragging: isDragging,
                isDecelerating: isDecelerating,
                startIndex: startIndex,
                visibleStartIndex: visibleStartIndex,
                visibleStartLabel: visibleStartLabel,
                visibleStartThreshold: visibleStartThreshold,
                contentOffsetX: contentOffsetX,
                dragTranslationX: dragTranslationX,
                targetContentOffsetX: targetContentOffsetX,
                targetIndex: targetMonthIndex,
                viewportWidth: viewportWidth,
                unitWidth: unitWidth,
                chartWidth: chartWidth,
                selectedPointIndex: selectedPointIndex,
                selectedPointGroupID: selectedPointGroupID,
                selectedPointXKey: selectedPointXKey,
                selectedPointXLabel: selectedPointXLabel,
                selectedPointValue: selectedPointValue)
        }

        /// Legacy implementation-focused alias for `scrollEngineTitle`.
        @available(*, deprecated, renamed: "scrollEngineTitle")
        public var scrollImplementationTitle: String {
            scrollEngineTitle
        }

        /// Legacy drag-mode alias for `scrollTargetBehaviorTitle`.
        @available(*, deprecated, renamed: "scrollTargetBehaviorTitle")
        public var dragScrollModeTitle: String {
            scrollTargetBehaviorTitle
        }

        /// Legacy month-based alias for `targetIndex`.
        @available(*, deprecated, renamed: "targetIndex")
        public var targetMonthIndex: Int {
            targetIndex
        }
    }

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
        public let startIndex: Int

        /// Creates a pager item using a generic start index label.
        public init(id: String, displayTitle: String, startIndex: Int) {
            self.id = id
            self.displayTitle = displayTitle
            self.startIndex = startIndex
        }

        /// Legacy initializer that preserves the older month-based label.
        @available(*, deprecated, renamed: "init(id:displayTitle:startIndex:)")
        public init(id: String, displayTitle: String, startMonthIndex: Int) {
            self.init(
                id: id,
                displayTitle: displayTitle,
                startIndex: startMonthIndex)
        }

        /// Legacy month-based alias for `startIndex`.
        @available(*, deprecated, renamed: "startIndex")
        public var startMonthIndex: Int {
            startIndex
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
    @MainActor
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
            emptyState: AnyView? = nil,
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.emptyState = emptyState ?? AnyView(DefaultEmptyStateView())
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

        /// Creates slots with custom selection overlay and pager content.
        public init(
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View,
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: nil,
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: { context in AnyView(pager(context)) })
        }

        /// Creates slots with custom empty state, selection overlay, and pager content.
        public init(
            @ViewBuilder emptyState: () -> some View,
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
        public let config: ChartConfig
        public let entries: [PagerEntry]
        public let highlightedEntry: PagerEntry?
        public let canSelectPreviousPage: Bool
        public let canSelectNextPage: Bool
        public let onSelectPreviousPage: () -> Void
        public let onSelectEntry: (PagerEntry) -> Void
        public let onSelectNextPage: () -> Void

        /// Creates pager context.
        public init(
            config: ChartConfig,
            entries: [PagerEntry],
            highlightedEntry: PagerEntry?,
            canSelectPreviousPage: Bool,
            canSelectNextPage: Bool,
            onSelectPreviousPage: @escaping () -> Void,
            onSelectEntry: @escaping (PagerEntry) -> Void,
            onSelectNextPage: @escaping () -> Void) {
            self.config = config
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
    struct ChartPoint: Identifiable, Equatable {
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
    struct ChartGroup: Identifiable, Equatable {
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
