//
//  LineAndBarChart.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import Charts
import SwiftUI
import UIKit

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
        enum DisplayStyle {
            case allYears
            case highlightedYear
        }

        let isVisible: Bool
        let displayStyle: DisplayStyle

        init(
            isVisible: Bool = true,
            displayStyle: DisplayStyle = .allYears) {
            self.isVisible = isVisible
            self.displayStyle = displayStyle
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
    private let onSelect: ((ChartPoint) -> Void)?
    private let groups: [ChartGroup]
    private let tabs: [ChartTab]
    private let viewSlots: ViewSlots
    @Binding private var selectedTab: ChartTab
    @Binding private var showDebugOverlay: Bool

    init(
        config: ChartConfig = .default,
        groups: [ChartGroup],
        tabs: [ChartTab] = ChartTab.defaults,
        selectedTab: Binding<ChartTab> = .constant(.totalTrend),
        showDebugOverlay: Binding<Bool> = .constant(false),
        viewSlots: ViewSlots = .default,
        onSelect: ((ChartPoint) -> Void)? = nil) {
        self.config = config
        self.groups = groups
        self.tabs = tabs
        self.viewSlots = viewSlots
        _selectedTab = selectedTab
        _showDebugOverlay = showDebugOverlay
        self.onSelect = onSelect
    }

    // UI state.
    @State private var selectedIndex: Int? = 0
    @State private var scrollPage: Int = 0
    @State private var scrollOffsetX: CGFloat = 0
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

    struct ViewSlots {
        let emptyState: AnyView
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let pager: ((PagerContext) -> AnyView)?

        static var `default`: ViewSlots {
            .init(
                emptyState: AnyView(DefaultEmptyStateView()),
                selectionOverlay: nil,
                pager: nil)
        }

        static func emptyState(
            @ViewBuilder _ content: () -> some View) -> ViewSlots {
            .init(
                emptyState: AnyView(content()),
                selectionOverlay: nil,
                pager: nil)
        }

        static func custom(
            @ViewBuilder emptyState: () -> some View,
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View) -> ViewSlots {
            .init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in
                    AnyView(selectionOverlay(context))
                },
                pager: nil)
        }

        static func custom(
            @ViewBuilder emptyState: () -> some View,
            @ViewBuilder selectionOverlay: @escaping (SelectionOverlayContext) -> some View,
            @ViewBuilder pager: @escaping (PagerContext) -> some View) -> ViewSlots {
            .init(
                emptyState: AnyView(emptyState()),
                selectionOverlay: { context in
                    AnyView(selectionOverlay(context))
                },
                pager: { context in
                    AnyView(pager(context))
                })
        }
    }

    struct SelectionOverlayContext {
        let point: ChartPoint
        let index: Int
        let value: Double
        let xPosition: CGFloat
        let plotRect: CGRect
        let indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle
        let highlightWidth: CGFloat
    }

    struct PagerContext {
        let ranges: [YearPageRange]
        let highlightedTitle: String?
        let scrollPage: Int
        let maxScrollPage: Int
        let showAllYears: Bool
        let onSelectPreviousPage: () -> Void
        let onSelectRange: (YearPageRange) -> Void
        let onSelectNextPage: () -> Void
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
        let order: Int
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

        var title: String {
            source.displayTitle
        }

        var sortKey: Int {
            source.order
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
            ranges: yearPageRanges,
            highlightedTitle: (fullyVisibleYearRange ?? currentYearRange)?.displayTitle,
            scrollPage: scrollPage,
            maxScrollPage: maxScrollPage,
            showAllYears: config.pager.displayStyle == .allYears,
            onSelectPreviousPage: { selectPage(scrollPage - 1) },
            onSelectRange: { range in
                scrollPage = range.startPage
                updateSelection(to: range.startMonthIndex)
            },
            onSelectNextPage: { selectPage(scrollPage + 1) })

        if let pager = viewSlots.pager {
            pager(context)
        } else {
            CombinedChartPager(
                ranges: context.ranges,
                highlightedTitle: context.highlightedTitle,
                scrollPage: context.scrollPage,
                maxScrollPage: context.maxScrollPage,
                showAllYears: context.showAllYears,
                onSelectPreviousPage: context.onSelectPreviousPage,
                onSelectRange: context.onSelectRange,
                onSelectNextPage: context.onSelectNextPage)
        }
    }

    private var sortedGroups: [ChartDataGroup] {
        groups
            .map { ChartDataGroup(source: $0) }
            .sorted { $0.sortKey < $1.sortKey }
    }

    /// Data array for all years, ordered by year ascending.
    private var data: [ChartDataPoint] {
        sortedGroups.flatMap(\.points)
    }

    private var yearPageRanges: [YearPageRange] {
        var ranges: [YearPageRange] = []
        var cumulativeMonths = 0
        for group in sortedGroups {
            let startMonthIndex = cumulativeMonths
            let endMonthIndex = cumulativeMonths + max(group.points.count - 1, 0)
            let startPage = startMonthIndex / config.monthsPerPage
            let endPage = endMonthIndex / config.monthsPerPage
            ranges.append(
                YearPageRange(
                    displayTitle: group.title,
                    groupOrder: group.sortKey,
                    startMonthIndex: startMonthIndex,
                    endMonthIndex: endMonthIndex,
                    startPage: startPage,
                    endPage: endPage))
            cumulativeMonths += group.points.count
        }
        return ranges
    }

    private var currentYearRange: YearPageRange? {
        yearPageRanges.first { $0.contains(page: scrollPage) } ?? yearPageRanges.first
    }

    private var visibleMonthRange: ClosedRange<Int>? {
        guard unitWidth > 0, viewportWidth > 0, !data.isEmpty else { return nil }
        let offset = max(0, -scrollOffsetX)
        let start = max(0, Int(floor(offset / unitWidth)))
        let visibleCount = max(1, Int(round(viewportWidth / unitWidth)))
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
    private var maxScrollPage: Int {
        max(
            0,
            Int(ceil(Double(max(data.count - config.monthsPerPage, 0)) / Double(config.monthsPerPage))))
    }

    private var hasData: Bool {
        !data.isEmpty
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

    private func updateSelection(to index: Int?) {
        selectedIndex = index
        guard let index, data.indices.contains(index) else { return }
        onSelect?(data[index].source)
    }

    private func selectPage(_ page: Int) {
        let clampedPage = min(max(page, 0), maxScrollPage)
        scrollPage = clampedPage
        updateSelection(to: min(data.count - 1, clampedPage * config.monthsPerPage))
    }
}

extension CombinedChartView {
    var body: some View {
        VStack(spacing: 12) {
            Group {
                if hasData {
                    CombinedChartSection(
                        config: config,
                        selectedTab: selectedTab,
                        selectedIndex: $selectedIndex,
                        scrollOffsetX: $scrollOffsetX,
                        unitWidth: $unitWidth,
                        viewportWidth: $viewportWidth,
                        plotAreaInfo: $plotAreaInfo,
                        yTickPositions: $yTickPositions,
                        data: data,
                        yAxisTickValues: yAxisTickValues,
                        yAxisDisplayDomain: yAxisDisplayDomain,
                        maxScrollPage: maxScrollPage,
                        showDebugOverlay: showDebugOverlay,
                        selectionOverlay: viewSlots.selectionOverlay,
                        yAxisLabel: yAxisLabel(for:),
                        onSelectIndex: updateSelection(to:),
                        scrollPage: scrollPage)
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
        @Binding var scrollOffsetX: CGFloat
        @Binding var unitWidth: CGFloat
        @Binding var viewportWidth: CGFloat
        @Binding var plotAreaInfo: PlotAreaInfo?
        @Binding var yTickPositions: [Double: CGFloat]
        let data: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let maxScrollPage: Int
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let yAxisLabel: (Double) -> String
        let onSelectIndex: (Int?) -> Void
        let scrollPage: Int

        var body: some View {
            GeometryReader { geometry in
                let visibleCount = CGFloat(config.monthsPerPage)
                let computedViewportWidth = max(geometry.size.width - config.axis.yAxisWidth, 1)
                let computedUnitWidth = computedViewportWidth / visibleCount
                let chartWidth = max(computedViewportWidth, computedUnitWidth * CGFloat(data.count))

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

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack(alignment: .topLeading) {
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetKey.self,
                                            value: proxy.frame(in: .named("ChartScroll")).minX)
                                }
                                .frame(width: chartWidth, height: 1, alignment: .topLeading)

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
                                        let info = PlotAreaInfo(minY: plotRect.minY, height: plotRect.height)
                                        if plotAreaInfo != info {
                                            plotAreaInfo = info
                                        }
                                    },
                                    onYAxisTickPositions: { positions in
                                        if yTickPositions != positions {
                                            yTickPositions = positions
                                        }
                                    })
                                    .frame(width: chartWidth)
                                    .frame(maxHeight: .infinity)

                                HStack(spacing: 0) {
                                    ForEach(0...maxScrollPage, id: \.self) { page in
                                        Color.clear
                                            .frame(
                                                width: computedUnitWidth * CGFloat(config.monthsPerPage),
                                                height: 1)
                                            .id(page)
                                    }
                                }
                            }
                        }
                        .frame(width: computedViewportWidth)
                        .coordinateSpace(name: "ChartScroll")
                        .onPreferenceChange(ScrollOffsetKey.self) { scrollOffsetX = $0 }
                        .onChange(of: scrollPage) { newValue in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(newValue, anchor: .leading)
                            }
                        }
                    }
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
        let ranges: [YearPageRange]
        let highlightedTitle: String?
        let scrollPage: Int
        let maxScrollPage: Int
        let showAllYears: Bool
        let onSelectPreviousPage: () -> Void
        let onSelectRange: (YearPageRange) -> Void
        let onSelectNextPage: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Button(action: onSelectPreviousPage) {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(scrollPage > 0 ? .primary : .secondary)
                .disabled(scrollPage == 0)

                Spacer()

                if showAllYears {
                    HStack(spacing: 16) {
                        ForEach(ranges) { range in
                            Text(range.displayTitle)
                                .font(.callout.weight(range.displayTitle == highlightedTitle ? .semibold : .regular))
                                .foregroundStyle(range.displayTitle == highlightedTitle ? .primary : .secondary)
                                .onTapGesture {
                                    onSelectRange(range)
                                }
                        }
                    }
                } else {
                    Text(highlightedTitle ?? "")
                        .font(.callout.weight(.semibold))
                }

                Spacer()

                Button(action: onSelectNextPage) {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(scrollPage < maxScrollPage ? .primary : .secondary)
                .disabled(scrollPage >= maxScrollPage)
            }
            .padding(.horizontal, 8)
        }
    }

    struct ChartContainerSegment: Identifiable {
        let id = UUID()
        let start: Double
        let value: Double
        let color: Color
    }

    struct ChartContainerSegmentBarStyle {
        let gap: Double
        let gapColor: Color
        let drawGapMark: Bool
    }

    struct ChartContainerLineSegmentPath: Identifiable {
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

    private struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat {
            0
        }

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
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
            let monthValues = visibleData.map(\.xKey)
            let axisPointInfos = visibleData.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }
            let axisPointByKey = Dictionary(uniqueKeysWithValues: axisPointInfos.map { ($0.xKey, $0) })

            Chart {
                barMarks(useTrendBarColor: usesTrendBarColor)
                sharedMarks
            }
            .chartXScale(domain: monthValues)
            .chartXAxis {
                AxisMarks(values: monthValues) { value in
                    AxisValueLabel(centered: true) {
                        if let key = value.as(String.self) {
                            let labelContext = ChartConfig.ChartAxisConfig.XAxisLabelContext(
                                point: axisPointByKey[key] ?? .init(
                                    id: key,
                                    index: 0,
                                    xKey: key,
                                    xLabel: key,
                                    values: [:]),
                                visiblePoints: axisPointInfos)
                            Text(config.axis.xAxisLabel(labelContext))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: yAxisTickValues) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray)
                }
            }
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
        if plotRect.width > 0, plotRect.height > 0 {
            let currentRect = plotRect
            Color.clear
                .onAppear { onPlotAreaChange(currentRect) }
                .onChange(of: currentRect) { onPlotAreaChange($0) }
        }

        if plotRect.width > 0, plotRect.height > 0 {
            let positions = yAxisTickPositions(plotRect: plotRect, proxy: proxy)
            Color.clear
                .onAppear { onYAxisTickPositions(positions) }
                .onChange(of: positions) { onYAxisTickPositions($0) }
        }
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
            let highlightWidth = selectionHighlightWidth(
                at: selectionState.index,
                xPosition: selectionState.xPosition,
                proxy: proxy)

            Group {
                if let selectionOverlay {
                    selectionOverlay(
                        .init(
                            point: selectionState.point.source,
                            index: selectionState.index,
                            value: selectionState.value,
                            xPosition: selectionState.xPosition,
                            plotRect: plotRect,
                            indicatorStyle: selectedTab.mode.selectionIndicatorStyle,
                            highlightWidth: highlightWidth))
                } else if selectedTab.mode.selectionIndicatorStyle == .line {
                    Path { path in
                        path.move(to: CGPoint(x: selectionState.xPosition, y: plotRect.minY))
                        path.addLine(to: CGPoint(x: selectionState.xPosition, y: plotRect.maxY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(selectionLineColor(for: selectionState.value))
                } else {
                    Rectangle()
                        .fill(config.line.selection.fillColor)
                        .frame(width: highlightWidth, height: plotRect.height)
                        .position(x: selectionState.xPosition, y: plotRect.midY)
                }
            }
            .mask(plotMask(for: plotRect))
        }
    }

    @ViewBuilder
    func tapSelectionOverlay(plotRect: CGRect, proxy: ChartProxy) -> some View {
        if !visibleData.isEmpty {
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            let localX = value.location.x - plotRect.minX
                            let clampedX = min(max(localX, 0), plotRect.width)
                            if let key = proxy.value(atX: clampedX, as: String.self),
                               let index = visibleData.firstIndex(where: { $0.xKey == key }) {
                                selectedIndex = index
                                onSelectIndex(index)
                            }
                        })
        }
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
    func lineSegmentPaths(proxy: ChartProxy) -> [CombinedChartView.ChartContainerLineSegmentPath] {
        guard visibleData.count > 1 else { return [] }
        var segments: [CombinedChartView.ChartContainerLineSegmentPath] = []

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
                    CombinedChartView.ChartContainerLineSegmentPath(
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
                    CombinedChartView.ChartContainerLineSegmentPath(
                        path: linePath(from: startPoint, to: intersection),
                        color: lineColor(for: startValue)))
                segments.append(
                    CombinedChartView.ChartContainerLineSegmentPath(
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
        useTrendBarColor: Bool) -> [CombinedChartView.ChartContainerSegment] {
        var positiveStart: Double = 0
        var negativeStart: Double = 0
        var result: [CombinedChartView.ChartContainerSegment] = []

        for series in config.bar.series {
            let value = point.signedValue(for: series)
            let color = trendBarColor(for: series.color, useTrendBarColor: useTrendBarColor)
            if value >= 0 {
                result.append(CombinedChartView.ChartContainerSegment(start: positiveStart, value: value, color: color))
                positiveStart += value
            } else {
                result.append(CombinedChartView.ChartContainerSegment(start: negativeStart, value: value, color: color))
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
            let gap = gapValue()
            let style = CombinedChartView.ChartContainerSegmentBarStyle(
                gap: gap,
                gapColor: config.bar.segmentGapColor,
                drawGapMark: true)
            ForEach(segments(for: item, useTrendBarColor: useTrendBarColor)) { segment in
                segmentBar(
                    index: index,
                    segment: segment,
                    style: style)
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
        segment: CombinedChartView.ChartContainerSegment,
        style: CombinedChartView.ChartContainerSegmentBarStyle) -> some ChartContent {
        let bounds = adjustedSegmentBounds(start: segment.start, value: segment.value)
        BarMark(
            x: .value("Month", visibleData[index].xKey),
            yStart: .value("Value", bounds.low),
            yEnd: .value("Value", bounds.high),
            width: .fixed(config.bar.barWidth))
            .cornerRadius(0)
            .foregroundStyle(segment.color)
        if style.drawGapMark, style.gap > 0.0001, abs(segment.start) > 0.0001 {
            BarMark(
                x: .value("Month", visibleData[index].xKey),
                yStart: .value("Gap", segment.start - style.gap / 2.0),
                yEnd: .value("Gap", segment.start + style.gap / 2.0),
                width: .fixed(config.bar.barWidth))
                .foregroundStyle(style.gapColor)
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
                showDebugOverlay: $showDebugOverlay)
        }
        .padding()
    }
}

#Preview {
    LineAndBarChartPreviewHost()
}
