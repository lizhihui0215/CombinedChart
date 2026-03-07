//
//  LineAndBarChart.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import Charts
import SwiftUI

// swiftlint:disable file_length
enum ChartSeriesKey: String, CaseIterable, Hashable, Identifiable {
    case liabilities
    case saving
    case investment
    case otherLiquid
    case otherNonLiquid

    var id: Self {
        self
    }
}

struct ChartConfig {
    let monthsPerPage: Int
    let chartHeight: CGFloat
    let bar: ChartBarConfig
    let line: ChartLineConfig
    let axis: ChartAxisConfig
    let pager: ChartPagerConfig

    static let `default` = ChartConfig(
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
}

extension ChartConfig {
    struct ChartBarConfig {
        enum TrendBarColorStyle {
            case seriesColor
            case unified(Color)
        }

        let series: [ChartSeriesStyle]
        let trendBarColorStyle: TrendBarColorStyle
        let segmentGap: CGFloat
        let segmentGapColor: Color
        let barWidth: CGFloat
    }

    struct ChartLineConfig {
        let positiveLineColor: Color
        let negativeLineColor: Color
        let lineWidth: CGFloat
        let selection: SelectionConfig
    }

    struct ChartAxisConfig {
        let xAxisLabel: (XAxisLabelContext) -> String
        let yAxisLabel: (YAxisLabelContext) -> String
        let zeroLineColor: Color
        let zeroLineWidth: CGFloat
        let yAxisWidth: CGFloat
    }

    struct ChartPagerConfig {
        enum ArrowScrollMode {
            case byPage
            case byEntry
        }

        let isVisible: Bool
        let arrowScrollMode: ArrowScrollMode

        init(
            isVisible: Bool = true,
            arrowScrollMode: ArrowScrollMode = .byPage) {
            self.isVisible = isVisible
            self.arrowScrollMode = arrowScrollMode
        }
    }
}

extension ChartConfig.ChartBarConfig {
    var trendLineSeries: [ChartSeriesStyle] {
        series.filter(\.contributesToTrendLine)
    }

    struct ChartSeriesStyle: Identifiable {
        struct Appearance {
            let label: String
            let color: Color
        }

        struct ValueBehavior {
            enum TrendLineInclusion {
                case included
                case excluded
            }

            enum Sign {
                case positive
                case negative
            }

            enum ValuePolarity {
                case preserveSign
                case forcedSign(Sign)
            }

            let valuePolarity: ValuePolarity
            let trendLineInclusion: TrendLineInclusion

            func signedValue(for rawValue: Double) -> Double {
                switch valuePolarity {
                case .preserveSign:
                    rawValue
                case .forcedSign(.positive):
                    abs(rawValue)
                case .forcedSign(.negative):
                    -abs(rawValue)
                }
            }

            var contributesToTrendLine: Bool {
                trendLineInclusion == .included
            }
        }

        let id: ChartSeriesKey
        let appearance: Appearance
        let valueBehavior: ValueBehavior

        init(
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

        var label: String {
            appearance.label
        }

        var color: Color {
            appearance.color
        }

        var valuePolarity: ValueBehavior.ValuePolarity {
            valueBehavior.valuePolarity
        }

        var trendLineInclusion: ValueBehavior.TrendLineInclusion {
            valueBehavior.trendLineInclusion
        }

        func signedValue(for rawValue: Double) -> Double {
            valueBehavior.signedValue(for: rawValue)
        }

        var contributesToTrendLine: Bool {
            valueBehavior.contributesToTrendLine
        }
    }
}

extension ChartConfig.ChartLineConfig {
    struct SelectionConfig {
        let pointSize: CGFloat
        let selectionLineColorStrategy: LineColorStrategy
        let fillColor: Color
        let minimumSelectionWidth: CGFloat
    }

    enum LineColorStrategy {
        case fixedLine(Color)
        case color(positive: Color, negative: Color)
    }
}

extension ChartConfig.ChartAxisConfig {
    struct AxisPointInfo: Identifiable {
        let id: String
        let index: Int
        let xKey: String
        let xLabel: String
        let values: [ChartSeriesKey: Double]
    }

    struct XAxisLabelContext {
        let point: AxisPointInfo
        let visiblePoints: [AxisPointInfo]
    }

    struct YAxisLabelContext {
        let value: Double
        let visiblePoints: [AxisPointInfo]
    }
}

struct CombinedChartView: View {
    private let config: ChartConfig
    private let groups: [ChartGroup]
    private let tabs: [ChartTab]
    private let viewSlots: ViewSlots
    private let onPointTap: ((SelectionContext) -> Void)?
    @Binding private var selectedTab: ChartTab
    @Binding private var showDebugOverlay: Bool

    init(
        config: ChartConfig = .default,
        groups: [ChartGroup],
        tabs: [ChartTab] = ChartTab.defaults,
        selectedTab: Binding<ChartTab> = .constant(.totalTrend),
        showDebugOverlay: Binding<Bool> = .constant(false),
        viewSlots: ViewSlots = .default,
        onPointTap: ((SelectionContext) -> Void)? = nil) {
        self.config = config
        self.groups = groups
        self.tabs = tabs
        self.viewSlots = viewSlots
        self.onPointTap = onPointTap
        _selectedTab = selectedTab
        _showDebugOverlay = showDebugOverlay
    }

    // UI state.
    @State private var selectedIndex: Int? = 0
    @State private var visibleStartMonthIndex: Int = 0
    @State private var unitWidth: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    @State private var plotAreaInfo: PlotAreaInfo?
    @State private var yTickPositions: [Double: CGFloat] = [:]
}

extension CombinedChartView {
    private struct DefaultEmptyStateView: View {
        var body: some View {
            Text("No data")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct PagerEntry: Identifiable, Hashable {
        let id: String
        let displayTitle: String
        let startMonthIndex: Int
    }

    struct ViewSlots {
        let emptyState: AnyView
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let pager: ((PagerContext) -> AnyView)?

        static var `default`: ViewSlots {
            .init()
        }

        init(
            emptyState: AnyView = AnyView(DefaultEmptyStateView()),
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.emptyState = emptyState
            self.selectionOverlay = selectionOverlay
            self.pager = pager
        }

        init(
            @ViewBuilder emptyState: () -> some View,
            selectionOverlay: ((SelectionOverlayContext) -> AnyView)? = nil,
            pager: ((PagerContext) -> AnyView)? = nil) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: selectionOverlay,
                pager: pager)
        }

        init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View,
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: { context in AnyView(pager(context)) })
        }

        init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in AnyView(selectionOverlay(context)) },
                pager: nil)
        }

        init(
            @ViewBuilder emptyState: () -> some View = { DefaultEmptyStateView() },
            @ViewBuilder pager: @escaping (PagerContext) -> some View) {
            self.init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: nil,
                pager: { context in AnyView(pager(context)) })
        }
    }

    struct SelectionOverlayContext {
        let point: ChartPoint
        let value: Double
        let plotFrame: CGRect
        let indicatorFrame: CGRect
        let indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle
    }

    struct PagerContext {
        let entries: [PagerEntry]
        let highlightedEntry: PagerEntry?
        let canSelectPreviousPage: Bool
        let canSelectNextPage: Bool
        let onSelectPreviousPage: () -> Void
        let onSelectEntry: (PagerEntry) -> Void
        let onSelectNextPage: () -> Void
    }

    struct SelectionContext {
        let point: ChartPoint
        let index: Int
    }

    struct ChartPresentationMode: Hashable {
        enum BarColorStyle: Hashable {
            case seriesColors
            case unifiedTrendColor
        }

        enum SelectionIndicatorStyle: Hashable {
            case line
            case band
        }

        let barColorStyle: BarColorStyle
        let showsTrendLine: Bool
        let selectionIndicatorStyle: SelectionIndicatorStyle
        let showsSelectedPoint: Bool

        static var totalTrend: ChartPresentationMode {
            .init(
                barColorStyle: .unifiedTrendColor,
                showsTrendLine: true,
                selectionIndicatorStyle: .line,
                showsSelectedPoint: true)
        }

        static var breakdown: ChartPresentationMode {
            .init(
                barColorStyle: .seriesColors,
                showsTrendLine: false,
                selectionIndicatorStyle: .band,
                showsSelectedPoint: false)
        }
    }

    /// Display mode descriptor for the same dataset.
    struct ChartTab: Identifiable, Hashable {
        let id: String
        let title: String
        let mode: ChartPresentationMode

        static var totalTrend: ChartTab {
            ChartTab(
                id: "totalTrend",
                title: "Total Trend",
                mode: .totalTrend)
        }

        static var breakdown: ChartTab {
            ChartTab(
                id: "breakdown",
                title: "Breakdown",
                mode: .breakdown)
        }

        static var defaults: [ChartTab] {
            [
                .totalTrend,
                .breakdown
            ]
        }
    }

    struct ChartPointID: Hashable {
        let groupID: String
        let xKey: String
    }

    struct ChartPoint: Identifiable {
        let id: ChartPointID
        let xKey: String
        let xLabel: String
        let values: [ChartSeriesKey: Double]
    }

    struct ChartGroup: Identifiable {
        let id: String
        let displayTitle: String
        let groupOrder: Int
        let points: [ChartPoint]
    }

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

        func signedValue(for series: ChartConfig.ChartBarConfig.ChartSeriesStyle) -> Double {
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

        func axisPointInfo(index: Int) -> ChartConfig.ChartAxisConfig.AxisPointInfo {
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

        var id: String {
            source.id
        }

        var displayTitle: String {
            source.displayTitle
        }

        var groupOrder: Int {
            source.groupOrder
        }

        var points: [ChartDataPoint] {
            source.points.map { .init(source: $0) }
        }
    }

    struct YearPageRange: Identifiable {
        var id: String {
            displayTitle
        }

        let displayTitle: String
        let groupOrder: Int
        let startMonthIndex: Int
        let endMonthIndex: Int
        let startPage: Int
        let endPage: Int

        func contains(page: Int) -> Bool {
            page >= startPage && page <= endPage
        }
    }

    struct PlotAreaInfo: Equatable {
        let minY: CGFloat
        let height: CGFloat
    }
}

extension CombinedChartView {
    @ViewBuilder
    private var pagerView: some View {
        let context = PagerContext(
            entries: pagerEntries,
            highlightedEntry: highlightedPagerEntry,
            canSelectPreviousPage: visibleStartMonthIndex > 0,
            canSelectNextPage: visibleStartMonthIndex < maxStartMonthIndex,
            onSelectPreviousPage: { selectPreviousPage() },
            onSelectEntry: { entry in
                selectMonthWindow(startingAt: entry.startMonthIndex)
            },
            onSelectNextPage: { selectNextPage() })

        if let pager = viewSlots.pager {
            pager(context)
        } else {
            CombinedChartPager(context: context)
        }
    }

    private var sortedGroups: [ChartDataGroup] {
        groups
            .map { ChartDataGroup(source: $0) }
            .sorted { $0.groupOrder < $1.groupOrder }
    }

    /// Data array for all years, ordered by year ascending.
    private var data: [ChartDataPoint] {
        sortedGroups.flatMap(\.points)
    }

    private var yearPageRanges: [YearPageRange] {
        var ranges: [YearPageRange] = []
        var cumulativeMonths = 0
        for group in sortedGroups {
            ranges.append(
                yearPageRange(
                    for: group,
                    startMonthIndex: cumulativeMonths))
            cumulativeMonths += group.points.count
        }
        return ranges
    }

    private func yearPageRange(
        for group: ChartDataGroup,
        startMonthIndex: Int) -> YearPageRange {
        let endMonthIndex = startMonthIndex + max(group.points.count - 1, 0)
        let startPage = startMonthIndex / config.monthsPerPage
        let endPage = endMonthIndex / config.monthsPerPage

        return .init(
            displayTitle: group.displayTitle,
            groupOrder: group.groupOrder,
            startMonthIndex: startMonthIndex,
            endMonthIndex: endMonthIndex,
            startPage: startPage,
            endPage: endPage)
    }

    private var currentYearRange: YearPageRange? {
        yearPageRanges.first {
            $0.startMonthIndex <= visibleStartMonthIndex &&
                $0.endMonthIndex >= visibleStartMonthIndex
        } ?? yearPageRanges.first
    }

    private var currentYearRangeIndex: Int? {
        guard let currentYearRange else { return nil }
        return yearPageRanges.firstIndex { $0.id == currentYearRange.id }
    }

    private var highlightedPagerEntry: PagerEntry? {
        guard let highlightedRange = fullyVisibleYearRange ?? currentYearRange else { return nil }
        return pagerEntries.first { $0.id == highlightedRange.id }
    }

    private var pagerEntries: [PagerEntry] {
        yearPageRanges.map { range in
            .init(
                id: range.id,
                displayTitle: range.displayTitle,
                startMonthIndex: range.startMonthIndex)
        }
    }

    private var visibleMonthRange: ClosedRange<Int>? {
        guard !data.isEmpty else { return nil }
        let start = min(max(visibleStartMonthIndex, 0), max(0, data.count - 1))
        let visibleCount = max(1, config.monthsPerPage)
        let end = min(data.count - 1, start + visibleCount - 1)
        return start...end
    }

    private var fullyVisibleYearRange: YearPageRange? {
        guard let visibleRange = visibleMonthRange else { return nil }
        return yearPageRanges.first { range in
            range.startMonthIndex <= visibleRange.lowerBound &&
                range.endMonthIndex >= visibleRange.upperBound
        }
    }

    /// Number of 4-month pages for arrow navigation.
    private var maxStartMonthIndex: Int {
        max(0, data.count - config.monthsPerPage)
    }

    private var hasData: Bool {
        !data.isEmpty
    }

    private var visibleStartMonthLabel: String? {
        guard data.indices.contains(visibleStartMonthIndex) else { return nil }
        return data[visibleStartMonthIndex].xLabel
    }

    /// Dynamic Y range to fit all visible bars/line.
    private var yDomain: ClosedRange<Double> {
        let minValue = data
            .map { $0.stackedExtents(using: config).min }
            .min() ?? -20
        let maxValue = data
            .map { $0.stackedExtents(using: config).max }
            .max() ?? 20
        let padding = max((maxValue - minValue) * 0.1, 2)
        return (minValue - padding)...(maxValue + padding)
    }

    /// Fixed 11 ticks based on the current Y range.
    private var yAxisTickValues: [Double] {
        let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
        let step = max(ceil(halfRange / 5.0), 1.0)
        return (-5...5).map { Double($0) * step }
    }

    /// Use tick extremes for the displayed Y domain so labels/grid align.
    private var yAxisDisplayDomain: ClosedRange<Double> {
        guard let first = yAxisTickValues.first, let last = yAxisTickValues.last else {
            return yDomain
        }
        return first...last
    }

    private var axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo] {
        data.enumerated().map { index, point in
            point.axisPointInfo(index: index)
        }
    }

    private func yAxisLabel(for amount: Double) -> String {
        config.axis.yAxisLabel(
            .init(
                value: amount,
                visiblePoints: axisPointInfos))
    }

    private func updateSelection(to index: Int?, emitsPointTap: Bool = true) {
        selectedIndex = index
        guard emitsPointTap, let index, data.indices.contains(index) else { return }
        let point = data[index].source
        onPointTap?(
            .init(
                point: point,
                index: index))
    }

    private func selectMonthWindow(startingAt monthIndex: Int) {
        let clampedMonthIndex = clampedStartMonthIndex(for: monthIndex)
        print(
            "[Select Month Window]",
            "requested=\(monthIndex)",
            "clamped=\(clampedMonthIndex)",
            "visibleStartMonthIndex(before)=\(visibleStartMonthIndex)")
        visibleStartMonthIndex = clampedMonthIndex
    }

    private func selectPreviousPage() {
        switch config.pager.arrowScrollMode {
        case .byPage:
            print(
                "[Pager Prev]",
                "visibleStartMonthIndex=\(visibleStartMonthIndex)",
                "target=\(visibleStartMonthIndex - config.monthsPerPage)")
            selectMonthWindow(startingAt: visibleStartMonthIndex - config.monthsPerPage)
        case .byEntry:
            guard let currentYearRangeIndex else { return }
            let previousIndex = max(0, currentYearRangeIndex - 1)
            print(
                "[Pager Prev Entry]",
                "currentYearRangeIndex=\(currentYearRangeIndex)",
                "targetStartMonthIndex=\(yearPageRanges[previousIndex].startMonthIndex)")
            selectMonthWindow(startingAt: yearPageRanges[previousIndex].startMonthIndex)
        }
    }

    private func selectNextPage() {
        switch config.pager.arrowScrollMode {
        case .byPage:
            print(
                "[Pager Next]",
                "visibleStartMonthIndex=\(visibleStartMonthIndex)",
                "target=\(visibleStartMonthIndex + config.monthsPerPage)")
            selectMonthWindow(startingAt: visibleStartMonthIndex + config.monthsPerPage)
        case .byEntry:
            guard let currentYearRangeIndex else { return }
            let nextIndex = min(yearPageRanges.count - 1, currentYearRangeIndex + 1)
            print(
                "[Pager Next Entry]",
                "currentYearRangeIndex=\(String(describing: currentYearRangeIndex))",
                "targetStartMonthIndex=\(yearPageRanges[nextIndex].startMonthIndex)")
            selectMonthWindow(startingAt: yearPageRanges[nextIndex].startMonthIndex)
        }
    }

    private func clampedStartMonthIndex(for monthIndex: Int) -> Int {
        min(max(monthIndex, 0), maxStartMonthIndex)
    }
}

extension CombinedChartView {
    var body: some View {
        VStack(spacing: 12) {
            if showDebugOverlay, let visibleStartMonthLabel {
                Text("Visible start month: \(visibleStartMonthIndex) (\(visibleStartMonthLabel))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Group {
                if hasData {
                    CombinedChartSection(
                        config: config,
                        selectedTab: selectedTab,
                        selectedIndex: $selectedIndex,
                        visibleStartMonthIndex: $visibleStartMonthIndex,
                        unitWidth: $unitWidth,
                        viewportWidth: $viewportWidth,
                        plotAreaInfo: $plotAreaInfo,
                        yTickPositions: $yTickPositions,
                        data: data,
                        yAxisTickValues: yAxisTickValues,
                        yAxisDisplayDomain: yAxisDisplayDomain,
                        showDebugOverlay: showDebugOverlay,
                        selectionOverlay: viewSlots.selectionOverlay,
                        yAxisLabel: yAxisLabel(for:),
                        onSelectIndex: { updateSelection(to: $0) })
                } else {
                    viewSlots.emptyState
                }
            }

            if hasData, config.pager.isVisible {
                pagerView
            }
        }
        .frame(height: config.chartHeight)
    }
}

private extension CombinedChartView {
    struct ChartYAxisLabels: View {
        let yAxisTickValues: [Double]
        let tickPositions: [Double: CGFloat]
        let plotArea: PlotAreaInfo?
        let labelText: (Double) -> String

        var body: some View {
            let topPadding = plotArea?.minY ?? 12
            let plotHeight = plotArea?.height ?? 320

            GeometryReader { _ in
                let maxLabelWidth: CGFloat = 44
                ZStack(alignment: .topLeading) {
                    ForEach(yAxisTickValues, id: \.self) { value in
                        if let yPos = tickPositions[value] {
                            Text(labelText(value))
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                                .frame(width: maxLabelWidth, alignment: .trailing)
                                .fixedSize(horizontal: false, vertical: true)
                                .position(x: 0, y: yPos)
                        }
                    }
                }
            }
            .frame(height: plotHeight)
            .padding(.top, topPadding)
        }
    }

    struct CombinedChartSection: View {
        let config: ChartConfig
        let selectedTab: ChartTab
        @Binding var selectedIndex: Int?
        @Binding var visibleStartMonthIndex: Int
        @Binding var unitWidth: CGFloat
        @Binding var viewportWidth: CGFloat
        @Binding var plotAreaInfo: PlotAreaInfo?
        @Binding var yTickPositions: [Double: CGFloat]
        let data: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let yAxisLabel: (Double) -> String
        let onSelectIndex: (Int?) -> Void
        @GestureState private var dragTranslationX: CGFloat = 0
        @State private var settlingOffsetX: CGFloat = 0

        private var maxStartMonthIndex: Int {
            max(0, data.count - config.monthsPerPage)
        }

        var body: some View {
            GeometryReader { geometry in
                let visibleCount = CGFloat(config.monthsPerPage)
                let computedViewportWidth = max(geometry.size.width - config.axis.yAxisWidth, 1)
                let computedUnitWidth = computedViewportWidth / visibleCount
                let chartWidth = max(computedViewportWidth, computedUnitWidth * CGFloat(data.count))
                let isDragging = dragTranslationX != 0
                let maxRightDragOffset = CGFloat(visibleStartMonthIndex) * computedUnitWidth
                let maxLeftDragOffset = CGFloat(maxStartMonthIndex - visibleStartMonthIndex) * computedUnitWidth
                let clampedDragTranslationX = min(
                    max(dragTranslationX, -maxLeftDragOffset),
                    maxRightDragOffset)
                let contentOffsetX = -CGFloat(visibleStartMonthIndex) * computedUnitWidth + settlingOffsetX +
                    clampedDragTranslationX

                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        ChartYAxisLabels(
                            yAxisTickValues: yAxisTickValues,
                            tickPositions: yTickPositions,
                            plotArea: plotAreaInfo,
                            labelText: yAxisLabel)

                        if let plotAreaInfo {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 1, height: plotAreaInfo.height)
                                .offset(y: plotAreaInfo.minY)
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        ChartContainer(
                            selectedTab: selectedTab,
                            selectedIndex: $selectedIndex,
                            visibleData: data,
                            yAxisTickValues: yAxisTickValues,
                            yAxisDisplayDomain: yAxisDisplayDomain,
                            plotAreaHeight: plotAreaInfo?.height ?? 0,
                            config: config,
                            showDebugOverlay: showDebugOverlay,
                            selectionOverlay: selectionOverlay,
                            onSelectIndex: onSelectIndex,
                            onPlotAreaChange: { plotRect in
                                guard !isDragging else { return }
                                let info = PlotAreaInfo(minY: plotRect.minY, height: plotRect.height)
                                if plotAreaInfo != info {
                                    plotAreaInfo = info
                                }
                            },
                            onYAxisTickPositions: { positions in
                                guard !isDragging else { return }
                                if yTickPositions != positions {
                                    yTickPositions = positions
                                }
                            })
                            .frame(width: chartWidth)
                            .frame(maxHeight: .infinity)
                    }
                    .compositingGroup()
                    .offset(x: contentOffsetX)
                    .frame(width: computedViewportWidth, alignment: .leading)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .updating($dragTranslationX) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let clampedTranslationX = min(
                                    max(value.translation.width, -maxLeftDragOffset),
                                    maxRightDragOffset)
                                let monthDelta = Int(round(-clampedTranslationX / computedUnitWidth))
                                let targetMonthIndex = min(
                                    max(visibleStartMonthIndex + monthDelta, 0),
                                    maxStartMonthIndex)
                                settlingOffsetX = clampedTranslationX
                                visibleStartMonthIndex = targetMonthIndex
                                settlingOffsetX = 0
                            })
                }
                .onAppear {
                    unitWidth = computedUnitWidth
                    viewportWidth = computedViewportWidth
                }
                .onChange(of: geometry.size) { _ in
                    unitWidth = computedUnitWidth
                    viewportWidth = computedViewportWidth
                }
            }
        }
    }

    struct CombinedChartPager: View {
        let context: PagerContext

        private var highlightedEntryTitle: String? {
            context.highlightedEntry?.displayTitle
        }

        var body: some View {
            HStack(spacing: 12) {
                Button(action: context.onSelectPreviousPage) {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(context.canSelectPreviousPage ? .primary : .secondary)
                .disabled(!context.canSelectPreviousPage)

                Spacer()

                Text(highlightedEntryTitle ?? "")
                    .font(.callout.weight(.semibold))

                Spacer()

                Button(action: context.onSelectNextPage) {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(context.canSelectNextPage ? .primary : .secondary)
                .disabled(!context.canSelectNextPage)
            }
            .padding(.horizontal, 8)
        }
    }

    struct BarSegment: Identifiable {
        let id = UUID()
        let start: Double
        let value: Double
        let color: Color
    }

    struct LineSegmentPath: Identifiable {
        let id = UUID()
        let path: Path
        let color: Color
    }

    struct ChartSelectionState {
        let point: ChartDataPoint
        let index: Int
        let value: Double
        let xPosition: CGFloat
    }

    struct SelectionLayout {
        let highlightWidth: CGFloat
        let indicatorFrame: CGRect
    }

    struct AxisRenderContext {
        let monthValues: [String]
        let pointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo]
        let pointInfoByKey: [String: ChartConfig.ChartAxisConfig.AxisPointInfo]
    }

    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    struct ChartContainer: View {
        let selectedTab: ChartTab
        @Binding var selectedIndex: Int?
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let onSelectIndex: (Int) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void

        var body: some View {
            let axisContext = axisRenderContext

            Chart {
                barMarks(useTrendBarColor: usesTrendBarColor)
                sharedMarks
            }
            .chartXScale(domain: axisContext.monthValues)
            .chartXAxis { chartXAxis(axisContext: axisContext) }
            .chartYAxis { chartYAxis }
            .chartYScale(domain: yAxisDisplayDomain)
            // Removed top padding to align plot area with fixed Y labels and overlays.
            .chartPlotStyle { plot in
                plot
            }
            // Tap in plot area to select the nearest month index.
            .chartOverlay { proxy in
                chartOverlay(proxy: proxy)
            }
        }

        private var axisRenderContext: AxisRenderContext {
            let pointInfos = visibleData.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            return .init(
                monthValues: visibleData.map(\.xKey),
                pointInfos: pointInfos,
                pointInfoByKey: Dictionary(uniqueKeysWithValues: pointInfos.map { ($0.xKey, $0) }))
        }

        @AxisContentBuilder
        private func chartXAxis(axisContext: AxisRenderContext) -> some AxisContent {
            AxisMarks(values: axisContext.monthValues) { value in
                AxisValueLabel(centered: true) {
                    if let key = value.as(String.self) {
                        Text(config.axis.xAxisLabel(
                            xAxisLabelContext(
                                for: key,
                                axisPointByKey: axisContext.pointInfoByKey,
                                axisPointInfos: axisContext.pointInfos)))
                            .font(.caption2)
                    }
                }
            }
        }

        @AxisContentBuilder
        private var chartYAxis: some AxisContent {
            AxisMarks(position: .leading, values: yAxisTickValues) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray)
            }
        }
    }
}

private extension CombinedChartView.ChartContainer {
    func chartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let plotRect = geometry[proxy.plotAreaFrame]

            syncPlotOverlay(plotRect: plotRect, proxy: proxy)

            ZStack(alignment: .topLeading) {
                trendLineOverlay(plotRect: plotRect, proxy: proxy)
                selectionOverlay(plotRect: plotRect, proxy: proxy)
                tapSelectionOverlay(plotRect: plotRect, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    func syncPlotOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if hasValidPlotFrame(plotRect) {
            let currentRect = plotRect
            let positions = yAxisTickPositions(plotRect: plotRect, proxy: proxy)

            Color.clear
                .onAppear { onPlotAreaChange(currentRect) }
                .onChange(of: currentRect) { onPlotAreaChange($0) }

            Color.clear
                .onAppear { onYAxisTickPositions(positions) }
                .onChange(of: positions) { onYAxisTickPositions($0) }
        }
    }

    func hasValidPlotFrame(_ plotRect: CGRect) -> Bool {
        plotRect.width > 0 && plotRect.height > 0
    }

    @ViewBuilder
    func trendLineOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if selectedTab.mode.showsTrendLine {
            let segments = lineSegmentPaths(proxy: proxy)
            ForEach(segments) { segment in
                segment.path
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: config.line.lineWidth))
            }
            .mask(plotMask(for: plotRect))
        }
    }

    @ViewBuilder
    func selectionOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if let selectionState = selectionState(plotRect: plotRect, proxy: proxy) {
            let context = selectionOverlayContext(
                selectionState: selectionState,
                plotRect: plotRect,
                proxy: proxy)

            selectionOverlayView(context: context)
                .mask(plotMask(for: plotRect))
        }
    }

    func xAxisLabelContext(
        for key: String,
        axisPointByKey: [String: ChartConfig.ChartAxisConfig.AxisPointInfo],
        axisPointInfos: [ChartConfig.ChartAxisConfig.AxisPointInfo]) -> ChartConfig.ChartAxisConfig.XAxisLabelContext {
        .init(
            point: axisPointByKey[key] ?? fallbackAxisPointInfo(for: key),
            visiblePoints: axisPointInfos)
    }

    func fallbackAxisPointInfo(for key: String) -> ChartConfig.ChartAxisConfig.AxisPointInfo {
        .init(
            id: key,
            index: 0,
            xKey: key,
            xLabel: key,
            values: [:])
    }

    @ViewBuilder
    func selectionOverlayView(context: CombinedChartView.SelectionOverlayContext) -> some View {
        if let selectionOverlay {
            selectionOverlay(context)
        } else {
            defaultSelectionOverlay(context: context)
        }
    }

    @ViewBuilder
    func defaultSelectionOverlay(context: CombinedChartView.SelectionOverlayContext) -> some View {
        if context.indicatorStyle == .line {
            selectionIndicatorLine(context: context)
        } else {
            selectionIndicatorBand(context: context)
        }
    }

    func selectionIndicatorLine(context: CombinedChartView.SelectionOverlayContext) -> some View {
        Path { path in
            path.move(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.minY))
            path.addLine(to: CGPoint(x: context.indicatorFrame.midX, y: context.plotFrame.maxY))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        .foregroundStyle(selectionLineColor(for: context.value))
    }

    func selectionIndicatorBand(context: CombinedChartView.SelectionOverlayContext) -> some View {
        Rectangle()
            .fill(config.line.selection.fillColor)
            .frame(width: context.indicatorFrame.width, height: context.indicatorFrame.height)
            .position(x: context.indicatorFrame.midX, y: context.indicatorFrame.midY)
    }

    func selectionOverlayContext(
        selectionState: CombinedChartView.ChartSelectionState,
        plotRect: CGRect,
        proxy: ChartProxy) -> CombinedChartView.SelectionOverlayContext {
        let indicatorStyle = selectedTab.mode.selectionIndicatorStyle
        let layout = selectionLayout(
            for: selectionState,
            plotRect: plotRect,
            proxy: proxy,
            indicatorStyle: indicatorStyle)

        return .init(
            point: selectionState.point.source,
            value: selectionState.value,
            plotFrame: plotRect,
            indicatorFrame: layout.indicatorFrame,
            indicatorStyle: indicatorStyle)
    }

    func selectionLayout(
        for selectionState: CombinedChartView.ChartSelectionState,
        plotRect: CGRect,
        proxy: ChartProxy,
        indicatorStyle: CombinedChartView.ChartPresentationMode.SelectionIndicatorStyle) -> CombinedChartView
        .SelectionLayout {
        let highlightWidth = selectionHighlightWidth(
            at: selectionState.index,
            xPosition: selectionState.xPosition,
            proxy: proxy)

        let indicatorFrame = switch indicatorStyle {
        case .line:
            CGRect(
                x: selectionState.xPosition,
                y: plotRect.minY,
                width: 0,
                height: plotRect.height)
        case .band:
            CGRect(
                x: selectionState.xPosition - (highlightWidth / 2),
                y: plotRect.minY,
                width: highlightWidth,
                height: plotRect.height)
        }

        return .init(
            highlightWidth: highlightWidth,
            indicatorFrame: indicatorFrame)
    }

    func tapSelectionOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: plotRect.width, height: plotRect.height)
            .position(x: plotRect.midX, y: plotRect.midY)
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let tapLocation = value.location
                        guard plotRect.contains(tapLocation) else { return }

                        let nearestIndex = visibleData.enumerated()
                            .compactMap { index, point -> (Int, CGFloat)? in
                                guard let xPosition = proxy.position(forX: point.xKey) else { return nil }
                                return (index, abs(xPosition - tapLocation.x))
                            }
                            .min { $0.1 < $1.1 }?
                            .0

                        guard let nearestIndex else { return }
                        onSelectIndex(nearestIndex)
                    })
    }

    func yAxisTickPositions(plotRect: CGRect, proxy: ChartProxy) -> [Double: CGFloat] {
        Dictionary(
            uniqueKeysWithValues: yAxisTickValues.compactMap { value in
                if let yPos = proxy.position(forY: value) {
                    return (value, yPos - plotRect.minY)
                }
                return nil
            })
    }

    func plotMask(for plotRect: CGRect) -> some View {
        Rectangle()
            .frame(width: plotRect.width, height: plotRect.height)
            .position(x: plotRect.midX, y: plotRect.midY)
    }

    func selectionState(
        plotRect: CGRect,
        proxy: ChartProxy) -> CombinedChartView.ChartSelectionState? {
        guard let selectedIndex, visibleData.indices.contains(selectedIndex) else {
            return nil
        }

        let point = visibleData[selectedIndex]
        let selectedKey = point.xKey
        guard let xPos = proxy.position(forX: selectedKey) else {
            return nil
        }

        let value = point.trendLineValue(using: config)
        return CombinedChartView.ChartSelectionState(
            point: point,
            index: selectedIndex,
            value: value,
            xPosition: xPos)
    }

    func selectionHighlightWidth(at index: Int, xPosition: CGFloat, proxy: ChartProxy) -> CGFloat {
        let step: CGFloat = {
            if index + 1 < visibleData.count,
               let nextX = proxy.position(forX: visibleData[index + 1].xKey) {
                return nextX - xPosition
            }
            if index - 1 >= 0,
               let previousX = proxy.position(forX: visibleData[index - 1].xKey) {
                return xPosition - previousX
            }
            return config.bar.barWidth
        }()

        return max(step * 0.9, config.line.selection.minimumSelectionWidth)
    }

    var usesTrendBarColor: Bool {
        guard selectedTab.mode.barColorStyle == .unifiedTrendColor else {
            return false
        }

        if case .unified = config.bar.trendBarColorStyle {
            return true
        }

        return false
    }

    func lineColor(for value: Double) -> Color {
        value >= 0 ? config.line.positiveLineColor : config.line.negativeLineColor
    }

    func selectionLineColor(for value: Double) -> Color {
        switch config.line.selection.selectionLineColorStrategy {
        case .fixedLine(let color):
            color
        case .color(let positive, let negative):
            value >= 0 ? positive : negative
        }
    }

    func gapValue() -> Double {
        guard plotAreaHeight > 0 else { return 0 }
        let domainSpan = yAxisDisplayDomain.upperBound - yAxisDisplayDomain.lowerBound
        let points = Double(config.bar.segmentGap)
        return max(0, (points / Double(plotAreaHeight)) * domainSpan)
    }

    /// Build line segments for the overlay so we can color positive and negative parts separately.
    func lineSegmentPaths(proxy: ChartProxy) -> [CombinedChartView.LineSegmentPath] {
        guard visibleData.count > 1 else { return [] }
        var segments: [CombinedChartView.LineSegmentPath] = []

        for index in 0..<(visibleData.count - 1) {
            let start = visibleData[index]
            let end = visibleData[index + 1]
            let startValue = start.trendLineValue(using: config)
            let endValue = end.trendLineValue(using: config)

            // Convert data points into chart-space points. If any position is missing, skip this pair.
            guard let startPoint = linePoint(for: start.xKey, value: startValue, proxy: proxy),
                  let endPoint = linePoint(for: end.xKey, value: endValue, proxy: proxy) else { continue }

            // If both points are on the same side of zero, the segment is single-colored.
            if isSameSideOrZero(startValue, endValue) {
                segments.append(
                    CombinedChartView.LineSegmentPath(
                        path: linePath(from: startPoint, to: endPoint),
                        color: lineColor(for: startValue)))
                continue
            }

            // Crossing zero: split the segment at the exact intersection point.
            if let intersection = zeroIntersection(
                from: startPoint,
                to: endPoint,
                startValue: startValue,
                endValue: endValue) {
                segments.append(
                    CombinedChartView.LineSegmentPath(
                        path: linePath(from: startPoint, to: intersection),
                        color: lineColor(for: startValue)))
                segments.append(
                    CombinedChartView.LineSegmentPath(
                        path: linePath(from: intersection, to: endPoint),
                        color: lineColor(for: endValue)))
            }
        }

        return segments
    }

    /// Map a data point into the chart's coordinate space.
    func linePoint(for xKey: String, value: Double, proxy: ChartProxy) -> CGPoint? {
        guard let xPos = proxy.position(forX: xKey),
              let yPos = proxy.position(forY: value) else { return nil }
        return CGPoint(x: xPos, y: yPos)
    }

    /// Determine whether two values are on the same side of zero or touch zero.
    func isSameSideOrZero(_ startValue: Double, _ endValue: Double) -> Bool {
        startValue == 0 || endValue == 0 || (startValue >= 0) == (endValue >= 0)
    }

    /// Compute intersection point with the zero line by linear interpolation.
    func zeroIntersection(
        from start: CGPoint,
        to end: CGPoint,
        startValue: Double,
        endValue: Double) -> CGPoint? {
        let denominator = startValue - endValue
        guard abs(denominator) > 0.000001 else { return nil }
        let interpolationFactor = startValue / denominator
        return CGPoint(
            x: start.x + (end.x - start.x) * interpolationFactor,
            y: start.y + (end.y - start.y) * interpolationFactor)
    }

    /// Construct a straight line path between two points.
    func linePath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    func segments(
        for point: CombinedChartView.ChartDataPoint,
        useTrendBarColor: Bool) -> [CombinedChartView.BarSegment] {
        var positiveStart: Double = 0
        var negativeStart: Double = 0
        var result: [CombinedChartView.BarSegment] = []

        for series in config.bar.series {
            let value = point.signedValue(for: series)
            let color = trendBarColor(for: series.color, useTrendBarColor: useTrendBarColor)
            if value >= 0 {
                result.append(CombinedChartView.BarSegment(start: positiveStart, value: value, color: color))
                positiveStart += value
            } else {
                result.append(CombinedChartView.BarSegment(start: negativeStart, value: value, color: color))
                negativeStart += value
            }
        }

        return result
    }

    func trendBarColor(for seriesColor: Color, useTrendBarColor: Bool) -> Color {
        guard useTrendBarColor else { return seriesColor }

        switch config.bar.trendBarColorStyle {
        case .seriesColor:
            return seriesColor
        case .unified(let color):
            return color
        }
    }

    @ChartContentBuilder
    func barMarks(useTrendBarColor: Bool) -> some ChartContent {
        ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, item in
            ForEach(segments(for: item, useTrendBarColor: useTrendBarColor)) { segment in
                segmentBar(
                    index: index,
                    segment: segment,
                    gap: gapValue())
            }
        }
    }

    /// Marks shared by both modes (zero line + selection dot).
    @ChartContentBuilder
    var sharedMarks: some ChartContent {
        RuleMark(y: .value("Zero", 0))
            .foregroundStyle(config.axis.zeroLineColor)
            .lineStyle(StrokeStyle(lineWidth: config.axis.zeroLineWidth))

        if selectedTab.mode.showsSelectedPoint, let selectedIndex,
           visibleData.indices.contains(selectedIndex) {
            let value = visibleData[selectedIndex].trendLineValue(using: config)
            PointMark(
                x: .value("Selected Month", visibleData[selectedIndex].xKey),
                y: .value("Selected Value", value))
                .foregroundStyle(lineColor(for: value))
                .symbolSize(config.line.selection.pointSize)
        }

        if showDebugOverlay {
            ForEach(visibleData, id: \.id) { item in
                RuleMark(x: .value("Debug X", item.xKey))
                    .foregroundStyle(Color.red.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [2, 3]))
            }
        }
    }

    /// Draw one stacked segment and apply a small gap so segments are visually separated.
    @ChartContentBuilder
    func segmentBar(
        index: Int,
        segment: CombinedChartView.BarSegment,
        gap: Double) -> some ChartContent {
        let bounds = adjustedSegmentBounds(start: segment.start, value: segment.value)
        BarMark(
            x: .value("Month", visibleData[index].xKey),
            yStart: .value("Value", bounds.low),
            yEnd: .value("Value", bounds.high),
            width: .fixed(config.bar.barWidth))
            .cornerRadius(0)
            .foregroundStyle(segment.color)
        if gap > 0.0001, abs(segment.start) > 0.0001 {
            BarMark(
                x: .value("Month", visibleData[index].xKey),
                yStart: .value("Gap", segment.start - gap / 2.0),
                yEnd: .value("Gap", segment.start + gap / 2.0),
                width: .fixed(config.bar.barWidth))
                .foregroundStyle(config.bar.segmentGapColor)
        }
    }

    /// Convert a signed segment into a visual bar range with a small gap.
    func adjustedSegmentBounds(start: Double, value: Double) -> (low: Double, high: Double) {
        let end = start + value
        let rawLow = min(start, end)
        let rawHigh = max(start, end)
        return (rawLow, rawHigh)
    }
}

private struct LineAndBarChartPreviewHost: View {
    private let groups = ChartSampleData.makeGroups(variance: 0.6)
    private let config = ChartSampleData.makeConfig()
    private let tabs = CombinedChartView.ChartTab.defaults
    @State private var selectedTab: CombinedChartView.ChartTab = .totalTrend
    @State private var showDebugOverlay = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HKD")
                    .font(.headline)
                Spacer()
            }

            Picker("", selection: $selectedTab) {
                ForEach(tabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Debug axis alignment", isOn: $showDebugOverlay)
                .font(.caption)
                .toggleStyle(SwitchToggleStyle(tint: .gray))

            CombinedChartView(
                config: config,
                groups: groups,
                tabs: tabs,
                selectedTab: $selectedTab,
                showDebugOverlay: $showDebugOverlay,
                onPointTap: { context in
                    print(
                        "Tapped point:",
                        "groupID=\(context.point.id.groupID)",
                        "xKey=\(context.point.xKey)",
                        "index=\(context.index)")
                })
        }
        .padding()
    }
}

#Preview {
    LineAndBarChartPreviewHost()
}
